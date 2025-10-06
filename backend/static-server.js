const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();

// CORS headers
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

// Serve static files from a directory
app.use(express.static(process.argv[2] || '.', {
    setHeaders: (res, filePath) => {
        // Set correct Content-Type for CSS
        if (filePath.endsWith('.css')) {
            res.setHeader('Content-Type', 'text/css');
        } else if (filePath.endsWith('.js')) {
            res.setHeader('Content-Type', 'application/javascript');
        } else if (filePath.endsWith('.html')) {
            res.setHeader('Content-Type', 'text/html');
        }
    }
}));

const port = process.argv[3] || 8000;
app.listen(port, () => {
    console.log(`Static server running on port ${port}`);
    console.log(`Serving files from: ${path.resolve(process.argv[2] || '.')}`);
});
