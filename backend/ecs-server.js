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
    const { command, workingDir = '/workspace' } = req.body;
    
    if (!command) {
        return res.status(400).json({ error: 'Command is required' });
    }

    console.log(`Executing heavy command: ${command}`);
    resetIdleTimer();

    try {
        // Crea working directory se non esiste
        if (!fs.existsSync(workingDir)) {
            fs.mkdirSync(workingDir, { recursive: true });
        }

        const result = await executeCommand(command, workingDir);
        
        res.json({
            success: true,
            output: result.stdout,
            error: result.stderr,
            exitCode: result.code,
            environment: 'ecs-fargate',
            executionTime: result.executionTime
        });

    } catch (error) {
        console.error('Command execution error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            environment: 'ecs-fargate'
        });
    }
});

// Endpoint per Flutter doctor e setup
app.get('/flutter/doctor', async (req, res) => {
    resetIdleTimer();
    
    try {
        const result = await executeCommand('flutter doctor -v', '/workspace');
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
        docker: 'disabled'
    });
});

// Funzione per eseguire comandi con timeout esteso
function executeCommand(command, cwd = '/workspace') {
    return new Promise((resolve, reject) => {
        const startTime = Date.now();
        
        const child = spawn('bash', ['-c', command], {
            cwd: cwd,
            stdio: ['pipe', 'pipe', 'pipe'],
            env: {
                ...process.env,
                PATH: '/opt/flutter/bin:' + process.env.PATH,
                FLUTTER_HOME: '/opt/flutter'
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