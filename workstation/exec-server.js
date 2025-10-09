// Simple HTTP server to execute commands in workstation
// Runs on port 80 (default workstation port) with /exec path
const express = require('express');
const { exec } = require('child_process');
const app = express();

app.use(express.json());

// Health check
app.get('/', (req, res) => {
    res.send('Workstation exec server running');
});

app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Execute command endpoint
app.post('/exec', (req, res) => {
    const { command } = req.body;
    
    if (!command) {
        return res.status(400).json({ error: 'Command required' });
    }
    
    console.log(`Executing: ${command}`);
    
    exec(command, { 
        cwd: '/home/user/workspace',
        timeout: 30000,
        maxBuffer: 1024 * 1024 * 10, // 10MB
        shell: '/bin/bash'
    }, (error, stdout, stderr) => {
        res.json({
            success: !error,
            output: stdout,
            error: stderr,
            exitCode: error ? error.code : 0
        });
    });
});

const PORT = process.env.PORT || 80;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Exec server running on port ${PORT}`);
});

