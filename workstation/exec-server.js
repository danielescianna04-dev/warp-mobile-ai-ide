// Simple HTTP server to execute commands in workstation
const express = require('express');
const { exec } = require('child_process');
const app = express();

app.use(express.json());

app.post('/exec', (req, res) => {
    const { command } = req.body;
    
    if (!command) {
        return res.status(400).json({ error: 'Command required' });
    }
    
    console.log(`Executing: ${command}`);
    
    exec(command, { 
        cwd: '/home/user/workspace',
        timeout: 30000,
        maxBuffer: 1024 * 1024 * 10 // 10MB
    }, (error, stdout, stderr) => {
        res.json({
            success: !error,
            output: stdout,
            error: stderr,
            exitCode: error ? error.code : 0
        });
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Exec server running on port ${PORT}`);
});
