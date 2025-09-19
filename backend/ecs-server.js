const express = require('express');
const { exec, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const app = express();
const port = process.env.PORT || 3000;

// Auto-shutdown configurazione
let lastActivity = Date.now();
const IDLE_TIMEOUT = 10 * 60 * 1000; // 10 minuti
let shutdownTimer = null;

// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// CORS per l'app Flutter
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

// Reset timer ad ogni attività
function resetIdleTimer() {
    lastActivity = Date.now();
    
    if (shutdownTimer) {
        clearTimeout(shutdownTimer);
    }
    
    shutdownTimer = setTimeout(() => {
        console.log('Auto-shutdown: Nessuna attività da 10 minuti');
        process.exit(0);
    }, IDLE_TIMEOUT);
}

// Middleware per tracking attività
app.use((req, res, next) => {
    resetIdleTimer();
    next();
});

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        uptime: process.uptime(),
        lastActivity: new Date(lastActivity).toISOString(),
        environment: 'ecs-fargate'
    });
});

// Endpoint per eseguire comandi pesanti
app.post('/execute-heavy', async (req, res) => {
    const { command, workingDir = '/tmp', repository = null } = req.body;
    
    if (!command) {
        return res.status(400).json({ error: 'Command is required' });
    }

    console.log(`Executing heavy command: ${command}`);
    console.log(`Repository context: ${repository}`);
    console.log(`Working directory: ${workingDir}`);
    resetIdleTimer();

    try {
        let actualWorkingDir = workingDir;
        
        // Handle repository-specific commands
        if (repository) {
            const repoDir = `/tmp/projects/${repository.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
            
            // Create repository directory if it doesn't exist
            if (!fs.existsSync(repoDir)) {
                fs.mkdirSync(repoDir, { recursive: true });
                console.log(`Created repository directory: ${repoDir}`);
            }
            
            actualWorkingDir = repoDir;
            
            // For Flutter commands, check if we need to initialize a Flutter project
            if (command.toLowerCase().includes('flutter') && !fs.existsSync(path.join(repoDir, 'pubspec.yaml'))) {
                console.log('Flutter command detected but no pubspec.yaml found. Creating sample Flutter project...');
                
                try {
                    // Create a basic Flutter project structure
                    const initResult = await executeCommand(`cd ${repoDir} && flutter create . --project-name ${repository.replace(/[^a-zA-Z0-9_]/g, '_')} --overwrite`, '/tmp');
                    console.log('Flutter project initialized:', initResult.stdout);
                } catch (initError) {
                    console.error('Failed to initialize Flutter project:', initError.message);
                    // Continue anyway, let the original command fail with a more descriptive error
                }
            }
        } else {
            // No repository context - create working directory if needed
            if (!fs.existsSync(actualWorkingDir)) {
                fs.mkdirSync(actualWorkingDir, { recursive: true });
            }
        }

        console.log(`Executing in directory: ${actualWorkingDir}`);
        const result = await executeCommand(command, actualWorkingDir);
        
        res.json({
            success: true,
            output: result.stdout,
            error: result.stderr,
            exitCode: result.code,
            environment: 'ecs-fargate',
            executionTime: result.executionTime,
            workingDir: actualWorkingDir,
            repository: repository
        });

    } catch (error) {
        console.error('Command execution error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            environment: 'ecs-fargate',
            repository: repository
        });
    }
});

// Endpoint per Flutter doctor e setup
app.get('/flutter/doctor', async (req, res) => {
    resetIdleTimer();
    
    try {
        const result = await executeCommand('flutter doctor -v', '/tmp');
        res.json({
            success: true,
            output: result.stdout,
            error: result.stderr,
            environment: 'ecs-fargate'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Map to track running Flutter web processes
const flutterWebProcesses = new Map();

// Endpoint per avviare Flutter web app
app.post('/flutter/web/start', async (req, res) => {
    const { repository = 'flutter-app', port = 8080 } = req.body;
    resetIdleTimer();
    
    try {
        const repoDir = `/tmp/projects/${repository.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
        
        // Create repository directory if it doesn't exist
        if (!fs.existsSync(repoDir)) {
            fs.mkdirSync(repoDir, { recursive: true });
        }
        
        // Initialize Flutter project if needed
        if (!fs.existsSync(path.join(repoDir, 'pubspec.yaml'))) {
            console.log('Initializing Flutter web project...');
            const initResult = await executeCommand(`cd ${repoDir} && flutter create . --project-name ${repository.replace(/[^a-zA-Z0-9_]/g, '_')} --overwrite`, '/tmp');
            console.log('Flutter project initialized for web');
        }
        
        // Check if already running
        if (flutterWebProcesses.has(repository)) {
            return res.json({
                success: true,
                message: 'Flutter web app is already running',
                url: `http://localhost:${port}`,
                repository,
                port
            });
        }
        
        // Enable web support
        await executeCommand(`cd ${repoDir} && flutter config --enable-web`, repoDir);
        
        // Start Flutter web server
        const webProcess = spawn('bash', ['-c', `cd ${repoDir} && flutter run -d web-server --web-port=${port} --web-hostname=0.0.0.0 --disable-analytics`], {
            cwd: repoDir,
            stdio: ['pipe', 'pipe', 'pipe'],
            env: {
                ...process.env,
                PATH: '/opt/flutter/bin:' + process.env.PATH,
                FLUTTER_HOME: '/opt/flutter',
                PUB_CACHE: '/tmp/.pub-cache',
                FLUTTER_ROOT: '/opt/flutter',
                FLUTTER_SUPPRESS_ANALYTICS: 'true'
            }
        });
        
        // Store process reference
        flutterWebProcesses.set(repository, {
            process: webProcess,
            port: port,
            startTime: Date.now()
        });
        
        let startupOutput = '';
        
        // Handle process output
        webProcess.stdout.on('data', (data) => {
            const output = data.toString();
            startupOutput += output;
            console.log(`[Flutter Web ${repository}]:`, output);
        });
        
        webProcess.stderr.on('data', (data) => {
            const output = data.toString();
            startupOutput += output;
            console.log(`[Flutter Web ${repository} ERROR]:`, output);
        });
        
        webProcess.on('close', (code) => {
            console.log(`Flutter web process for ${repository} exited with code ${code}`);
            flutterWebProcesses.delete(repository);
        });
        
        // Wait a bit for the server to start
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        res.json({
            success: true,
            message: 'Flutter web app started successfully',
            url: `http://localhost:${port}`,
            repository,
            port,
            startupOutput
        });
        
    } catch (error) {
        console.error('Error starting Flutter web app:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Endpoint per ottenere lo stato delle app web
app.get('/flutter/web/status', (req, res) => {
    resetIdleTimer();
    
    const status = Array.from(flutterWebProcesses.entries()).map(([repo, info]) => ({
        repository: repo,
        port: info.port,
        uptime: Date.now() - info.startTime,
        url: `http://localhost:${info.port}`
    }));
    
    res.json({
        success: true,
        runningApps: status
    });
});

// Endpoint per fermare una app web
app.post('/flutter/web/stop', (req, res) => {
    const { repository } = req.body;
    resetIdleTimer();
    
    if (flutterWebProcesses.has(repository)) {
        const processInfo = flutterWebProcesses.get(repository);
        processInfo.process.kill('SIGTERM');
        flutterWebProcesses.delete(repository);
        
        res.json({
            success: true,
            message: `Flutter web app for ${repository} stopped`
        });
    } else {
        res.json({
            success: false,
            message: `No running Flutter web app found for ${repository}`
        });
    }
});

// Endpoint per servire contenuti statici (proxy per le app web)
app.get('/preview/:repository/*', (req, res) => {
    const { repository } = req.params;
    const requestPath = req.params[0] || '';
    resetIdleTimer();
    
    if (flutterWebProcesses.has(repository)) {
        const processInfo = flutterWebProcesses.get(repository);
        const targetUrl = `http://localhost:${processInfo.port}/${requestPath}`;
        
        // Proxy the request
        const http = require('http');
        const proxyReq = http.request(targetUrl, (proxyRes) => {
            // Set CORS headers
            res.set({
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': '*'
            });
            
            // Copy headers from proxy response
            Object.keys(proxyRes.headers).forEach(key => {
                res.set(key, proxyRes.headers[key]);
            });
            
            proxyRes.pipe(res);
        });
        
        proxyReq.on('error', (error) => {
            console.error('Proxy error:', error);
            res.status(502).json({
                success: false,
                error: 'Failed to proxy request to Flutter web app'
            });
        });
        
        proxyReq.end();
    } else {
        res.status(404).json({
            success: false,
            error: `No running Flutter web app found for repository: ${repository}`
        });
    }
});

// Endpoint per informazioni sistema
app.get('/system/info', (req, res) => {
    resetIdleTimer();
    
    res.json({
        platform: os.platform(),
        arch: os.arch(),
        cpus: os.cpus().length,
        memory: {
            total: Math.round(os.totalmem() / 1024 / 1024 / 1024 * 100) / 100 + ' GB',
            free: Math.round(os.freemem() / 1024 / 1024 / 1024 * 100) / 100 + ' GB'
        },
        uptime: process.uptime(),
        nodeVersion: process.version,
        environment: 'ecs-fargate',
        flutter: process.env.FLUTTER_HOME ? 'installed' : 'not found',
        python: 'available',
        docker: 'disabled',
        runningWebApps: flutterWebProcesses.size
    });
});

// Funzione per eseguire comandi con timeout esteso
function executeCommand(command, cwd = '/tmp') {
    return new Promise((resolve, reject) => {
        const startTime = Date.now();
        
        // Check if command contains Flutter and add appropriate flags
        let adjustedCommand = command;
        if (command.toLowerCase().includes('flutter')) {
            // Add --disable-analytics to avoid issues with root
            if (!command.includes('--disable-analytics')) {
                adjustedCommand = command + ' --disable-analytics';
            }
            console.log(`Adjusted Flutter command: ${adjustedCommand}`);
        }
        
        const child = spawn('bash', ['-c', adjustedCommand], {
            cwd: cwd,
            stdio: ['pipe', 'pipe', 'pipe'],
            env: {
                ...process.env,
                PATH: '/opt/flutter/bin:' + process.env.PATH,
                FLUTTER_HOME: '/opt/flutter',
                PUB_CACHE: '/tmp/.pub-cache',
                FLUTTER_ROOT: '/opt/flutter',
                // Disable Flutter analytics to avoid root warnings
                FLUTTER_SUPPRESS_ANALYTICS: 'true'
            }
        });

        let stdout = '';
        let stderr = '';

        child.stdout.on('data', (data) => {
            stdout += data.toString();
        });

        child.stderr.on('data', (data) => {
            stderr += data.toString();
        });

        child.on('close', (code) => {
            const executionTime = Date.now() - startTime;
            resolve({
                stdout,
                stderr,
                code,
                executionTime
            });
        });

        child.on('error', (error) => {
            reject(error);
        });

        // Timeout per comandi molto lunghi (30 minuti)
        setTimeout(() => {
            child.kill('SIGKILL');
            reject(new Error('Command timeout after 30 minutes'));
        }, 30 * 60 * 1000);
    });
}

// Gestione graceful shutdown
process.on('SIGTERM', () => {
    console.log('Ricevuto SIGTERM, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('Ricevuto SIGINT, shutting down gracefully');
    process.exit(0);
});

// Avvia il server
app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 ECS Fargate server running on port ${port}`);
    console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🐦 Flutter: ${process.env.FLUTTER_HOME ? 'Ready' : 'Not found'}`);
    console.log(`🐍 Python: Available`);
    console.log(`🐳 Docker: Disabled (to be added)`);
    console.log(`⏰ Auto-shutdown after ${IDLE_TIMEOUT / 60000} minutes of inactivity`);
    
    // Inizia il timer di auto-shutdown
    resetIdleTimer();
});