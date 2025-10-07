const express = require('express');
const { exec, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const cron = require('node-cron');
const http = require('http');


// Function to get public IP of ECS task using native HTTP
function getTaskPublicIP() {
    return new Promise((resolve) => {
        // Try to get public IP from AWS checkip service
        const req = http.request('http://checkip.amazonaws.com/', { timeout: 5000 }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                const ip = data.trim();
                if (ip && /^\d+\.\d+\.\d+\.\d+$/.test(ip)) {
                    console.log(`\ud83c\udf10 Detected public IP: ${ip}`);
                    resolve(ip);
                } else {
                    console.log('\u26a0\ufe0f Invalid IP format from checkip service');
                    resolve(null);
                }
            });
        });
        
        req.on('error', (error) => {
            console.error('Error getting public IP:', error.message);
            resolve(null);
        });
        
        req.on('timeout', () => {
            console.log('\u23f1\ufe0f Public IP request timeout');
            req.destroy();
            resolve(null);
        });
        
        req.end();
    });
}

// Function to detect running web servers
async function detectRunningServers() {
    try {
        const { exec } = require('child_process');
        const { promisify } = require('util');
        const execAsync = promisify(exec);
        
        const exposedPorts = {};
        const loadBalancerUrl = 'https://api.drape.info';
        
        // Check both IPv4 and IPv6
        const files = ['/proc/net/tcp', '/proc/net/tcp6'];
        
        for (const file of files) {
            try {
                const result = await execAsync(`cat ${file} | tail -n +2`);
                const lines = result.stdout.split('\n').filter(line => line.trim());
                
                for (const line of lines) {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length < 4) continue;
                    
                    // Parse local address (format: hex_ip:hex_port)
                    const localAddr = parts[1];
                    const [, hexPort] = localAddr.split(':');
                    if (!hexPort) continue;
                    
                    const port = parseInt(hexPort, 16);
                    
                    // Check if port is in LISTEN state (0A = LISTEN)
                    const state = parts[3];
                    if (state === '0A' && port >= 3000 && port <= 9999) {
                        console.log(`🌐 Detected server on port ${port} (${file})`);
                        exposedPorts[`${port}/tcp`] = `${loadBalancerUrl}/proxy/${port}`;
                    }
                }
            } catch (err) {
                // File might not exist, continue
            }
        }
        
        return exposedPorts;
    } catch (error) {
        console.error('Error detecting servers:', error.message);
        return {};
    }
}
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

// Proxy with CSS inlining for iOS WebView
app.get('/proxy/:port/*', async (req, res) => {
    const port = req.params.port;
    const path = req.params[0] || '';
    const targetUrl = `http://localhost:${port}/${path}`;
    
    console.log(`🔀 Proxying request to: ${targetUrl}`);
    
    const http = require('http');
    const proxyReq = http.request(targetUrl, (proxyRes) => {
        // If HTML, inline CSS
        if (proxyRes.headers['content-type']?.includes('text/html')) {
            let html = '';
            proxyRes.on('data', chunk => html += chunk);
            proxyRes.on('end', async () => {
                // Fetch CSS and inline it
                try {
                    const cssUrl = `http://localhost:${port}/styles.css`;
                    const cssReq = http.request(cssUrl, (cssRes) => {
                        let css = '';
                        cssRes.on('data', chunk => css += chunk);
                        cssRes.on('end', () => {
                            // Inject CSS into HTML
                            html = html.replace('</head>', `<style>${css}</style></head>`);
                            res.setHeader('Content-Type', 'text/html');
                            res.setHeader('Access-Control-Allow-Origin', '*');
                            res.send(html);
                        });
                    });
                    cssReq.on('error', () => {
                        // If CSS fetch fails, send HTML as-is
                        res.setHeader('Content-Type', 'text/html');
                        res.setHeader('Access-Control-Allow-Origin', '*');
                        res.send(html);
                    });
                    cssReq.end();
                } catch (e) {
                    res.setHeader('Content-Type', 'text/html');
                    res.setHeader('Access-Control-Allow-Origin', '*');
                    res.send(html);
                }
            });
        } else {
            // For non-HTML, proxy as-is
            const headers = {
                ...proxyRes.headers,
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            };
            res.writeHead(proxyRes.statusCode, headers);
            proxyRes.pipe(res);
        }
    });
    
    proxyReq.on('error', (error) => {
        console.error(`Proxy error for port ${port}:`, error.message);
        res.status(502).json({ error: `Server on port ${port} not responding` });
    });
    
    proxyReq.end();
});

// Fallback for other proxy requests
app.use('/proxy/:port', (req, res) => {
    const port = req.params.port;
    const targetUrl = `http://localhost:${port}${req.url}`;
    
    console.log(`🔀 Proxying request to: ${targetUrl}`);
    
    const http = require('http');
    const proxyReq = http.request(targetUrl, (proxyRes) => {
        // Add CORS headers
        const headers = {
            ...proxyRes.headers,
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        };
        res.writeHead(proxyRes.statusCode, headers);
        proxyRes.pipe(res);
    });
    
    proxyReq.on('error', (error) => {
        console.error(`Proxy error for port ${port}:`, error.message);
        res.status(502).json({ error: `Server on port ${port} not responding` });
    });
    
    req.pipe(proxyReq);
});

// Serve Flutter Web apps statically
app.use('/app/:repository', (req, res, next) => {
    const repository = req.params.repository;
    const appDir = `/tmp/public/${repository}`;
    
    // Check if app exists
    if (!fs.existsSync(appDir)) {
        return res.status(404).json({
            error: `Flutter app '${repository}' not found. Did you run /flutter/web/start first?`
        });
    }
    
    express.static(appDir)(req, res, next);
});

// Default route for Flutter Web apps (serve index.html)
app.get('/app/:repository', (req, res) => {
    const repository = req.params.repository;
    const indexPath = `/tmp/public/${repository}/index.html`;
    
    if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        res.status(404).json({
            error: `Flutter app '${repository}' not found. Did you run /flutter/web/start first?`
        });
    }
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
        let repoName = repository || 'default-project';
        if (repository || command.toLowerCase().includes('flutter')) {
            const repoDir = `/tmp/projects/${repoName.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
            
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
                    const initResult = await executeCommand(`cd ${repoDir} && flutter create . --project-name ${repoName.replace(/[^a-zA-Z0-9_]/g, '_')} --overwrite`, '/tmp');
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

        // Handle special commands
        let actualCommand = command;
        let useSpecialEndpoint = false;
        let friendlyMessage = null;
        
        // Check for persistent server commands
        const cmd = command.trim();
        const serverCommands = [
            { pattern: /^(python3?|py)\s+-m\s+http\.server(\s+\d+)?/, port: 8000, icon: '🐍', name: 'Python' },
            { pattern: /^npx\s+serve(\s+-p\s+\d+|\s+\d+)?/, port: 3000, icon: '📦', name: 'Node' },
            { pattern: /^serve(\s+-p\s+\d+|\s+\d+)?/, port: 3000, icon: '🚀', name: 'Serve' },
            { pattern: /^preview$/, port: 6789, icon: '🚀', name: 'Preview' },
            { pattern: /^node\s+\S+\.js/, port: 3000, icon: '🟢', name: 'Node.js' },
            { pattern: /^npm\s+(run\s+)?start/, port: 3000, icon: '📦', name: 'NPM' },
            { pattern: /^yarn\s+start/, port: 3000, icon: '🧶', name: 'Yarn' },
            { pattern: /^php\s+-S/, port: 8000, icon: '🐘', name: 'PHP' },
            { pattern: /^ruby\s+-run\s+-e\s+httpd/, port: 8080, icon: '💎', name: 'Ruby' }
        ];
        
        let matchedCommand = null;
        for (const serverCmd of serverCommands) {
            if (serverCmd.pattern.test(cmd)) {
                matchedCommand = serverCmd;
                break;
            }
        }
        
        if (matchedCommand) {
            // Extract port from command or use default
            let port = matchedCommand.port;
            const portPatterns = [
                /\s+(\d{4,5})(?:\s|$)/,
                /-p\s+(\d{4,5})/,
                /--port[=\s]+(\d{4,5})/,
                /:(\d{4,5})/
            ];
            
            for (const pattern of portPatterns) {
                const match = cmd.match(pattern);
                if (match) {
                    port = parseInt(match[1]);
                    break;
                }
            }
            
            // Check if server already running
            if (staticServerProcesses.has(repoName)) {
                const existing = staticServerProcesses.get(repoName);
                friendlyMessage = `✅ Server già attivo sulla porta ${existing.port}!\nClicca Preview per visualizzare`;
                
                res.json({
                    success: true,
                    output: friendlyMessage,
                    error: '',
                    exitCode: 0,
                    environment: 'ecs-fargate',
                    executionTime: 0,
                    workingDir: actualWorkingDir,
                    repository: repoName,
                    exposedPorts: await detectRunningServers(),
                    webUrl: `https://api.drape.info/proxy/${existing.port}`,
                    webServerDetected: true
                });
                return;
            }
            
            // Start server as persistent process
            const serverProcess = spawn('bash', ['-c', cmd], {
                cwd: actualWorkingDir,
                detached: false,
                stdio: ['ignore', 'pipe', 'pipe']
            });
            
            staticServerProcesses.set(repoName, {
                process: serverProcess,
                port,
                startTime: Date.now(),
                command: cmd
            });
            
            let startupOutput = '';
            serverProcess.stdout.on('data', (data) => {
                startupOutput += data.toString();
                console.log(`[Server ${repoName}]:`, data.toString());
            });
            
            serverProcess.stderr.on('data', (data) => {
                console.error(`[Server ${repoName} ERROR]:`, data.toString());
            });
            
            serverProcess.on('close', (code) => {
                console.log(`Server for ${repoName} exited with code ${code}`);
                staticServerProcesses.delete(repoName);
            });
            
            // Wait for server to start
            await new Promise(resolve => setTimeout(resolve, 2000));
            
            friendlyMessage = `${matchedCommand.icon} Server ${matchedCommand.name} avviato!\n\n✅ Porta ${port} attiva\nClicca Preview per visualizzare`;
            
            const exposedPorts = await detectRunningServers();
            res.json({
                success: true,
                output: friendlyMessage,
                error: '',
                exitCode: 0,
                environment: 'ecs-fargate',
                executionTime: 2000,
                workingDir: actualWorkingDir,
                repository: repoName,
                exposedPorts,
                webUrl: `https://api.drape.info/proxy/${port}`,
                webServerDetected: true
            });
            return;
        }
        
        // Check for special Flutter web commands
        console.log('🔍 DEBUG: Checking command for special handling:', command);
        console.log('🔍 DEBUG: Repository context:', repository);
        console.log('🔍 DEBUG: Working directory:', actualWorkingDir);
        
        if (command.toLowerCase().includes('start') && 
            (command.toLowerCase().includes('flutter') || command.toLowerCase().includes('web'))) {
            // Special handling for "start flutter web app" or similar
            console.log('✅ Detected Flutter web start command, redirecting to web endpoint');
            console.log('🔍 DEBUG: Using repoName:', repoName);
            
            // Call the Flutter web start endpoint internally
            const port = 8080;
            const webStartUrl = `http://localhost:${process.env.PORT || 3000}/flutter/web/start`;
            
            try {
                const http = require('http');
                const postData = JSON.stringify({ repository: repoName, port });
                
                const options = {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(postData)
                    }
                };
                
                // Make internal request to web start endpoint
                const webStartReq = http.request(webStartUrl, options, (webRes) => {
                    let data = '';
                    webRes.on('data', chunk => data += chunk);
                    webRes.on('end', () => {
                        try {
                            console.log('🔍 DEBUG: Raw response from /flutter/web/start:', data);
                            const result = JSON.parse(data);
                            console.log('🔍 DEBUG: Parsed result:', result);
                            
                            const response = {
                                success: result.success,
                                output: result.message || `Flutter web app started for ${repoName}`,
                                error: result.error || '',
                                exitCode: result.success ? 0 : 1,
                                environment: 'ecs-fargate',
                                executionTime: 5000,
                                workingDir: actualWorkingDir,
                                repository: repoName,
                                webUrl: result.url,
                                port: result.port
                            };
                            
                            console.log('🔍 DEBUG: Final response being sent:', response);
                            res.json(response);
                        } catch (parseError) {
                            res.json({
                                success: false,
                                output: '',
                                error: `Failed to start Flutter web app: ${parseError.message}`,
                                exitCode: 1,
                                environment: 'ecs-fargate',
                                repository: repoName
                            });
                        }
                    });
                });
                
                webStartReq.on('error', (error) => {
                    res.json({
                        success: false,
                        output: '',
                        error: `Failed to start Flutter web app: ${error.message}`,
                        exitCode: 1,
                        environment: 'ecs-fargate',
                        repository: repoName
                    });
                });
                
                webStartReq.write(postData);
                webStartReq.end();
                
                useSpecialEndpoint = true;
            } catch (specialError) {
                console.error('Special command handling error:', specialError);
                // Fall through to regular command execution
            }
        }
        
        if (!useSpecialEndpoint) {
            // Regular command execution
            console.log(`Executing in directory: ${actualWorkingDir}`);
            const result = await executeCommand(actualCommand, actualWorkingDir);
            
            // Detect running servers after command execution
            const exposedPorts = await detectRunningServers();
            const ports = Object.values(exposedPorts);
            const webUrl = ports[ports.length - 1] || null;
            const webServerDetected = Object.keys(exposedPorts).length > 0;
            
            if (webServerDetected) {
                console.log('🚀 Web server detected! Ports:', exposedPorts);
            }
            
            res.json({
                success: true,
                output: friendlyMessage || result.stdout,
                error: result.stderr,
                exitCode: result.code,
                environment: 'ecs-fargate',
                executionTime: result.executionTime,
                workingDir: actualWorkingDir,
                repository: repoName,
                exposedPorts,
                webUrl,
                webServerDetected
            });
        }

    } catch (error) {
        console.error('Command execution error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            environment: 'ecs-fargate',
            repository: repoName
        });
    }
});

// Track Node.js server processes
const nodeServerProcesses = new Map();
const staticServerProcesses = new Map();

// Endpoint per avviare server Node.js in background
app.post('/node/server/start', async (req, res) => {
    const { file, port = 8080, repository = 'node-app' } = req.body;
    
    if (!file) {
        return res.status(400).json({ error: 'File path is required' });
    }
    
    resetIdleTimer();
    
    try {
        // Check if server is already running for this repository
        if (nodeServerProcesses.has(repository)) {
            const loadBalancerUrl = 'https://api.drape.info';
            const webUrl = `${loadBalancerUrl}/proxy/${port}`;
            
            return res.json({
                success: true,
                message: `Node.js server already running for ${repository}`,
                url: webUrl,
                repository,
                port
            });
        }
        
        console.log(`Starting Node.js server: ${file} on port ${port}`);
        
        // Start Node.js server process
        const serverProcess = spawn('node', [file], {
            cwd: path.dirname(file),
            stdio: ['ignore', 'pipe', 'pipe'],
            detached: false
        });
        
        nodeServerProcesses.set(repository, {
            process: serverProcess,
            port,
            startTime: Date.now(),
            file
        });
        
        let startupOutput = '';
        
        serverProcess.stdout.on('data', (data) => {
            const output = data.toString();
            startupOutput += output;
            console.log(`[Node Server ${repository}]:`, output);
        });
        
        serverProcess.stderr.on('data', (data) => {
            const output = data.toString();
            startupOutput += output;
            console.log(`[Node Server ${repository} ERROR]:`, output);
        });
        
        serverProcess.on('close', (code) => {
            console.log(`Node server for ${repository} exited with code ${code}`);
            nodeServerProcesses.delete(repository);
        });
        
        // Wait a bit for server to start
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const loadBalancerUrl = 'https://api.drape.info';
        const webUrl = `${loadBalancerUrl}/proxy/${port}`;
        
        console.log(`🌐 Node.js server URL: ${webUrl}`);
        
        res.json({
            success: true,
            message: 'Node.js server started successfully',
            url: webUrl,
            repository,
            port,
            startupOutput
        });
        
    } catch (error) {
        console.error('Error starting Node.js server:', error);
        res.status(500).json({
            success: false,
            error: error.message
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

// Endpoint per testare la configurazione di Flutter
app.get('/flutter/test', async (req, res) => {
    resetIdleTimer();
    
    try {
        const tests = [];
        
        // Test 1: which flutter
        try {
            const whichResult = await executeCommand('which flutter', '/tmp');
            tests.push({
                name: 'Flutter Binary Location',
                success: whichResult.code === 0,
                result: whichResult.stdout.trim() || 'Not found',
                error: whichResult.stderr
            });
        } catch (e) {
            tests.push({
                name: 'Flutter Binary Location',
                success: false,
                result: 'Command failed',
                error: e.message
            });
        }
        
        // Test 2: flutter --version
        try {
            const versionResult = await executeCommand('flutter --version', '/tmp');
            tests.push({
                name: 'Flutter Version',
                success: versionResult.code === 0,
                result: versionResult.stdout.trim(),
                error: versionResult.stderr
            });
        } catch (e) {
            tests.push({
                name: 'Flutter Version',
                success: false,
                result: 'Command failed',
                error: e.message
            });
        }
        
        // Test 3: PATH check
        const currentPath = process.env.PATH || '';
        const hasFlutterInPath = currentPath.includes('/opt/flutter/bin');
        tests.push({
            name: 'Flutter in PATH',
            success: hasFlutterInPath,
            result: hasFlutterInPath ? 'Flutter found in PATH' : 'Flutter NOT in PATH',
            error: hasFlutterInPath ? '' : `Current PATH: ${currentPath}`
        });
        
        // Test 4: Directory existence
        const flutterExists = require('fs').existsSync('/opt/flutter/bin/flutter');
        tests.push({
            name: 'Flutter Binary File',
            success: flutterExists,
            result: flutterExists ? 'File exists' : 'File not found',
            error: flutterExists ? '' : '/opt/flutter/bin/flutter not found'
        });
        
        res.json({
            success: true,
            tests: tests,
            environment: {
                PATH: process.env.PATH,
                FLUTTER_HOME: process.env.FLUTTER_HOME,
                DART_HOME: process.env.DART_HOME,
                PUB_CACHE: process.env.PUB_CACHE
            }
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
        
        // Try to clone repository if it looks like a GitHub repo and doesn't exist
        if (!fs.existsSync(path.join(repoDir, 'pubspec.yaml'))) {
            // Check if this looks like it could be a GitHub repository
            if (repository.includes('-') || repository.includes('_')) {
                console.log(`🔍 Attempting to clone repository: ${repository}`);
                try {
                    // Try to clone from GitHub
                    const githubUsername = process.env.GITHUB_USERNAME || 'getmad';
                    const githubToken = process.env.GITHUB_TOKEN;
                    
                    let githubUrl;
                    if (githubToken) {
                        // Use authenticated URL for private repositories
                        githubUrl = `https://${githubToken}@github.com/${githubUsername}/${repository}.git`;
                        console.log(`🔄 Cloning private repository from GitHub...`);
                    } else {
                        // Use public URL
                        githubUrl = `https://github.com/${githubUsername}/${repository}.git`;
                        console.log(`🔄 Cloning public repository from: https://github.com/${githubUsername}/${repository}.git`);
                    }
                    
                    // Remove existing directory if it exists but is empty
                    if (fs.existsSync(repoDir)) {
                        await executeCommand(`rm -rf ${repoDir}`, '/tmp');
                    }
                    
                    const cloneResult = await executeCommand(`git clone ${githubUrl} ${repoDir}`, '/tmp');
                    console.log('✅ Repository cloned successfully:', cloneResult.stdout);
                    
                    // Verify that pubspec.yaml exists after cloning
                    if (!fs.existsSync(path.join(repoDir, 'pubspec.yaml'))) {
                        throw new Error('Cloned repository does not contain pubspec.yaml');
                    }
                    
                    // Fetch Flutter dependencies
                    console.log('📦 Installing Flutter dependencies...');
                    await executeCommand(`cd ${repoDir} && flutter pub get`, '/tmp');
                    console.log('✅ Flutter dependencies installed');
                    
                    // Enable web support (in case it's not enabled)
                    console.log('🌍 Ensuring Flutter web support is enabled...');
                    await executeCommand('flutter config --enable-web', '/tmp');
                    console.log('✅ Flutter web support confirmed');
                } catch (cloneError) {
                    console.log(`⚠️ Failed to clone repository: ${cloneError.message}`);
                    console.log('🔄 Falling back to creating new Flutter project');
                    
                    // Fallback: create new Flutter project
                    if (!fs.existsSync(repoDir)) {
                        fs.mkdirSync(repoDir, { recursive: true });
                    }
                    const initResult = await executeCommand(`cd ${repoDir} && flutter create . --project-name ${repository.replace(/[^a-zA-Z0-9_]/g, '_')} --overwrite`, '/tmp');
                    console.log('Flutter project initialized for web');
                }
            } else {
                console.log('Initializing Flutter web project...');
                const initResult = await executeCommand(`cd ${repoDir} && flutter create . --project-name ${repository.replace(/[^a-zA-Z0-9_]/g, '_')} --overwrite`, '/tmp');
                console.log('Flutter project initialized for web');
            }
        } else {
            console.log(`✅ Found existing Flutter project in ${repoDir}`);
        }
        
        // Check if already running
        if (flutterWebProcesses.has(repository)) {
            // Get public IP for existing process too
            const publicIP = await getTaskPublicIP();
            let existingWebUrl = `http://localhost:${port}`;
            
            // Replace localhost with public IP if available
            if (publicIP) {
                existingWebUrl = `http://${publicIP}:${port}`;
                console.log(`🌐 Updated existing web URL with public IP: ${existingWebUrl}`);
            }
            
            return res.json({
                success: true,
                message: 'Flutter web app is already running',
                url: existingWebUrl,
                repository,
                port,
                publicIP: publicIP
            });
        }
        
        // Enable web support
        await executeCommand(`cd ${repoDir} && flutter config --enable-web`, repoDir);
        
        // Debug: check Flutter devices first
        try {
            const devicesResult = await executeCommand(`cd ${repoDir} && flutter devices`, repoDir);
            console.log('Available Flutter devices:', devicesResult.stdout);
        } catch (e) {
            console.log('Error checking Flutter devices:', e.message);
        }
        
        // Build Flutter web app and copy to public directory
        console.log('Building Flutter web app...');
        await executeCommand(`cd ${repoDir} && flutter build web --verbose`, repoDir);
        console.log('Flutter web build completed');
        
        // Copy build to express public directory
        const publicDir = '/tmp/public';
        if (!fs.existsSync(publicDir)) {
            fs.mkdirSync(publicDir, { recursive: true });
        }
        
        // Copy Flutter web build to public directory with repository name
        const repoPublicDir = `/tmp/public/${repository}`;
        await executeCommand(`cp -r ${repoDir}/build/web ${repoPublicDir}`, repoDir);
        console.log(`Flutter web app copied to ${repoPublicDir}`);
        
        // Instead of Python server, we'll serve via Express static route
        const flutterCommand = `echo "Flutter web build ready at ${repoPublicDir}"`;
        console.log(`Starting web server with command: ${flutterCommand}`);
        
        const webProcess = spawn('bash', ['-c', flutterCommand], {
            cwd: repoDir,
            stdio: ['pipe', 'pipe', 'pipe'],
            detached: false,
            env: {
                ...process.env,
                PATH: '/opt/flutter/bin:' + process.env.PATH,
                FLUTTER_HOME: '/opt/flutter',
                PUB_CACHE: '/tmp/.pub-cache',
                FLUTTER_ROOT: '/opt/flutter',
                FLUTTER_SUPPRESS_ANALYTICS: 'true',
                FLUTTER_WEB: 'true'
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
        
        // Wait for the server to start and show serving message
        let serverStarted = false;
        let startupTimeout;
        
        await new Promise((resolve, reject) => {
            // Set a timeout for startup
            startupTimeout = setTimeout(() => {
                if (!serverStarted) {
                    console.log('Flutter web server startup timeout, but continuing...');
                    resolve();
                }
            }, 20000); // 20 seconds timeout
            
            // Listen for server ready signal
            const checkOutput = (data) => {
                const output = data.toString();
                if (output.includes('Serving at') || output.includes('localhost:' + port) || 
                    output.includes('Web development server running')) {
                    serverStarted = true;
                    clearTimeout(startupTimeout);
                    resolve();
                }
            };
            
            webProcess.stdout.on('data', checkOutput);
            webProcess.stderr.on('data', checkOutput);
        });
        
        // Use Load Balancer URL instead of IP:port
        const loadBalancerUrl = 'https://api.drape.info';
        const webUrl = `${loadBalancerUrl}/app/${repository}`;
        console.log(`🌐 Final Flutter URL: ${webUrl}`);
        console.log(`📦 App available at: ${webUrl}`);
        
        const publicIP = await getTaskPublicIP();
        
        res.json({
            success: true,
            message: 'Flutter web app started successfully',
            url: webUrl,
            repository,
            port,
            startupOutput,
            publicIP: publicIP
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
app.get('/flutter/web/status', async (req, res) => {
    resetIdleTimer();
    
    // Get public IP for status URLs
    const publicIP = await getTaskPublicIP();
    
    const status = Array.from(flutterWebProcesses.entries()).map(([repo, info]) => {
        let url = `http://localhost:${info.port}`;
        
        // Replace localhost with public IP if available
        if (publicIP) {
            url = `http://${publicIP}:${info.port}`;
        }
        
        return {
            repository: repo,
            port: info.port,
            uptime: Date.now() - info.startTime,
            url: url,
            publicIP: publicIP
        };
    });
    
    res.json({
        success: true,
        runningApps: status,
        publicIP: publicIP
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

// Endpoint per fermare server statici
app.post('/server/stop', (req, res) => {
    const { repository } = req.body;
    resetIdleTimer();
    
    if (staticServerProcesses.has(repository)) {
        const processInfo = staticServerProcesses.get(repository);
        processInfo.process.kill('SIGTERM');
        staticServerProcesses.delete(repository);
        
        res.json({
            success: true,
            message: `Server for ${repository} stopped`
        });
    } else {
        res.json({
            success: false,
            message: `No running server found for ${repository}`
        });
    }
});

// Endpoint per ottenere lo stato di tutti i server
app.get('/server/status', async (req, res) => {
    resetIdleTimer();
    
    const servers = [];
    
    // Static servers
    for (const [repo, info] of staticServerProcesses.entries()) {
        servers.push({
            repository: repo,
            type: 'static',
            port: info.port,
            command: info.command || 'static-server',
            uptime: Date.now() - info.startTime,
            url: `https://api.drape.info/proxy/${info.port}`
        });
    }
    
    // Node servers
    for (const [repo, info] of nodeServerProcesses.entries()) {
        servers.push({
            repository: repo,
            type: 'node',
            port: info.port,
            file: info.file,
            uptime: Date.now() - info.startTime,
            url: `https://api.drape.info/proxy/${info.port}`
        });
    }
    
    // Flutter web apps
    for (const [repo, info] of flutterWebProcesses.entries()) {
        servers.push({
            repository: repo,
            type: info.type || 'flutter-web',
            port: info.port,
            command: info.command,
            uptime: Date.now() - info.startTime,
            url: info.type === 'flutter-run' ? `https://api.drape.info/proxy/${info.port}` : `https://api.drape.info/app/${repo}`
        });
    }
    
    res.json({
        success: true,
        servers,
        exposedPorts: await detectRunningServers()
    });
});

// NEW: Endpoint dedicato per flutter run (long-running process)
app.post('/flutter/run', async (req, res) => {
    const { repository = 'flutter-app', command = 'flutter run', workingDir = null } = req.body;
    resetIdleTimer();
    
    console.log(`🚀 Starting Flutter run for repository: ${repository}`);
    console.log(`🚀 Command: ${command}`);
    console.log(`🚀 Working directory: ${workingDir}`);
    
    try {
        const repoDir = workingDir || `/tmp/projects/${repository.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
        
        // Create repository directory if it doesn't exist
        if (!fs.existsSync(repoDir)) {
            fs.mkdirSync(repoDir, { recursive: true });
        }
        
        // Initialize Flutter project if needed
        if (!fs.existsSync(path.join(repoDir, 'pubspec.yaml'))) {
            console.log('Initializing Flutter project for flutter run...');
            const initResult = await executeCommand(`cd ${repoDir} && flutter create . --project-name ${repository.replace(/[^a-zA-Z0-9_]/g, '_')} --overwrite`, '/tmp');
            console.log('Flutter project initialized for run');
        }
        
        // Check if already running
        if (flutterWebProcesses.has(repository)) {
            const existing = flutterWebProcesses.get(repository);
            
            // Get public IP for existing process too
            const publicIP = await getTaskPublicIP();
            let existingWebUrl = `http://localhost:${existing.port}`;
            
            // Replace localhost with public IP if available
            if (publicIP) {
                existingWebUrl = `http://${publicIP}:${existing.port}`;
                console.log(`🌐 Updated existing web URL with public IP: ${existingWebUrl}`);
            }
            
            return res.json({
                success: true,
                message: 'Flutter app is already running',
                webUrl: existingWebUrl,
                repository,
                port: existing.port,
                status: 'running',
                uptime: Date.now() - existing.startTime,
                publicIP: publicIP
            });
        }
        
        // Determine port (8080 for web, or detect from command)
        let port = 8080;
        const portMatch = command.match(/--web-port[=\s]+(\d+)/);
        if (portMatch) {
            port = parseInt(portMatch[1]);
        }
        
        // Enable web support
        await executeCommand(`cd ${repoDir} && flutter config --enable-web`, repoDir);
        
        // Build the Flutter run command with web target
        let flutterCommand = command;
        if (command.trim() === 'flutter run') {
            // Default to web-server for flutter run
            flutterCommand = `flutter run -d web-server --web-port=${port} --web-hostname=0.0.0.0 --disable-analytics`;
        } else if (!command.includes('-d web') && !command.includes('--device')) {
            // Add web target if not specified
            flutterCommand = command + ` -d web-server --web-port=${port} --web-hostname=0.0.0.0`;
        }
        
        console.log(`🚀 Executing: ${flutterCommand}`);
        
        // Start Flutter run as long-running process
        const flutterProcess = spawn('bash', ['-c', `cd ${repoDir} && ${flutterCommand}`], {
            cwd: repoDir,
            stdio: ['pipe', 'pipe', 'pipe'],
            detached: false,
            env: {
                ...process.env,
                PATH: '/opt/flutter/bin:' + process.env.PATH,
                FLUTTER_HOME: '/opt/flutter',
                PUB_CACHE: '/tmp/.pub-cache',
                FLUTTER_ROOT: '/opt/flutter',
                FLUTTER_SUPPRESS_ANALYTICS: 'true',
                FLUTTER_WEB: 'true'
            }
        });
        
        // Store process reference
        flutterWebProcesses.set(repository, {
            process: flutterProcess,
            port: port,
            startTime: Date.now(),
            command: flutterCommand,
            type: 'flutter-run'
        });
        
        let startupOutput = '';
        let webUrl = null;
        
        // Handle process output
        flutterProcess.stdout.on('data', (data) => {
            const output = data.toString();
            startupOutput += output;
            console.log(`[Flutter Run ${repository}]:`, output);
            
            // Extract web server URL from output
            if (!webUrl) {
                const urlPatterns = [
                    /A web server for Flutter web application is available at:\s*(https?:\/\/[^\s]+)/i,
                    /Serving at\s*(https?:\/\/[^\s]+)/i,
                    /(https?:\/\/localhost:\d+)/i,
                    /(https?:\/\/127\.0\.0\.1:\d+)/i,
                    /(https?:\/\/0\.0\.0\.0:\d+)/i
                ];
                
                for (const pattern of urlPatterns) {
                    const match = output.match(pattern);
                    if (match && match[1]) {
                        webUrl = match[1];
                        console.log(`🌐 Detected Flutter web URL: ${webUrl}`);
                        break;
                    }
                }
            }
        });
        
        flutterProcess.stderr.on('data', (data) => {
            const output = data.toString();
            startupOutput += output;
            console.log(`[Flutter Run ${repository} ERROR]:`, output);
        });
        
        flutterProcess.on('close', (code) => {
            console.log(`Flutter run process for ${repository} exited with code ${code}`);
            flutterWebProcesses.delete(repository);
        });
        
        flutterProcess.on('error', (error) => {
            console.error(`Flutter run process error for ${repository}:`, error);
            flutterWebProcesses.delete(repository);
        });
        
        // Wait a bit for startup and URL detection
        await new Promise((resolve) => {
            let resolved = false;
            
            // Check every 2 seconds for web server URL
            const urlCheck = setInterval(() => {
                if (webUrl && !resolved) {
                    resolved = true;
                    clearInterval(urlCheck);
                    clearTimeout(startupTimeout);
                    resolve();
                }
            }, 2000);
            
            // Timeout after 30 seconds
            const startupTimeout = setTimeout(() => {
                if (!resolved) {
                    resolved = true;
                    clearInterval(urlCheck);
                    console.log('Flutter run startup completed (timeout)');
                    resolve();
                }
            }, 30000);
        });
        
        // Get public IP of ECS task
        const publicIP = await getTaskPublicIP();
        console.log(`🌐 Task public IP: ${publicIP}`);
        
        // Return immediate response (process runs in background)
        let finalWebUrl = webUrl || `http://localhost:${port}`;
        
        // Replace localhost with public IP if available
        if (publicIP && finalWebUrl.includes('localhost')) {
            finalWebUrl = finalWebUrl.replace('localhost', publicIP);
            console.log(`🌐 Updated web URL with public IP: ${finalWebUrl}`);
        } else if (publicIP && !finalWebUrl.includes('://')) {
            finalWebUrl = `http://${publicIP}:${port}`;
            console.log(`🌐 Created web URL with public IP: ${finalWebUrl}`);
        }
        
        res.json({
            success: true,
            message: 'Flutter run started successfully in background',
            output: startupOutput,
            webUrl: finalWebUrl,
            repository,
            port,
            status: 'running',
            executor: 'ecs-fargate-background',
            routing: 'flutter-run-background',
            publicIP: publicIP
        });
        
    } catch (error) {
        console.error('Error starting Flutter run:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            repository
        });
    }
});

// NEW: Endpoint per fermare flutter run
app.post('/flutter/stop', (req, res) => {
    const { repository } = req.body;
    resetIdleTimer();
    
    console.log(`🛑 Stopping Flutter process for repository: ${repository}`);
    
    if (flutterWebProcesses.has(repository)) {
        const processInfo = flutterWebProcesses.get(repository);
        
        // Send SIGINT (equivalent to Ctrl+C)
        processInfo.process.kill('SIGINT');
        
        setTimeout(() => {
            // Force kill if still running after 5 seconds
            if (flutterWebProcesses.has(repository)) {
                processInfo.process.kill('SIGKILL');
                flutterWebProcesses.delete(repository);
            }
        }, 5000);
        
        res.json({
            success: true,
            message: `Flutter process for ${repository} stopped`,
            repository
        });
    } else {
        res.json({
            success: false,
            message: `No running Flutter process found for ${repository}`,
            repository
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
        
        // Ensure Flutter and Dart are in PATH
        const flutterPath = '/opt/flutter/bin';
        const dartPath = '/opt/flutter/bin/cache/dart-sdk/bin';
        const currentPath = process.env.PATH || '';
        const fullPath = `${flutterPath}:${dartPath}:${currentPath}`;
        
        console.log(`🔍 Debug: Using PATH: ${fullPath}`);
        console.log(`🔍 Debug: FLUTTER_HOME: /opt/flutter`);
        
        const child = spawn('bash', ['-c', adjustedCommand], {
            cwd: cwd,
            stdio: ['pipe', 'pipe', 'pipe'],
            env: {
                ...process.env,
                PATH: fullPath,
                FLUTTER_HOME: '/opt/flutter',
                DART_HOME: '/opt/flutter/bin/cache/dart-sdk',
                PUB_CACHE: '/tmp/.pub-cache',
                FLUTTER_ROOT: '/opt/flutter',
                // Disable Flutter analytics to avoid root warnings
                FLUTTER_SUPPRESS_ANALYTICS: 'true',
                // Additional environment variables for Flutter
                FLUTTER_DISABLE_ANALYTICS: 'true'
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

// Health check endpoint for ALB
app.get('/', (req, res) => {
    res.status(200).json({ status: 'healthy', service: 'warp-backend' });
});

// Avvia il server
app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 ECS Fargate server running on port ${port}`);
    console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🐦 Flutter: ${process.env.FLUTTER_HOME ? 'Ready' : 'Not found'}`);
    console.log(`🐍 Python: Available`);
    console.log(`🐳 Docker: Disabled (to be added)`);
    console.log(`⏰ Auto-shutdown after ${IDLE_TIMEOUT / 60000} minutes of inactivity`);
    
    // Debug PATH information
    console.log(`🔍 Debug - Current PATH: ${process.env.PATH}`);
    console.log(`🔍 Debug - FLUTTER_HOME: ${process.env.FLUTTER_HOME}`);
    
    // Test Flutter availability at startup
    executeCommand('which flutter', '/tmp').then(result => {
        console.log(`🔍 Debug - Flutter location: ${result.stdout.trim() || 'NOT FOUND'}`);
        if (result.stderr) {
            console.log(`🔍 Debug - Flutter location error: ${result.stderr}`);
        }
    }).catch(err => {
        console.log(`🔍 Debug - Flutter test failed: ${err.message}`);
    });
    
    // Inizia il timer di auto-shutdown
    resetIdleTimer();
});
