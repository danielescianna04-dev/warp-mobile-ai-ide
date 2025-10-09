const express = require('express');
const { exec } = require('child_process');
const axios = require('axios');
const { VertexAI } = require('@google-cloud/vertexai');

const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'drape-ai-backend' });
});

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || 'drape-mobile-ide';
const LOCATION = 'us-central1';

const vertex_ai = new VertexAI({ project: PROJECT_ID, location: LOCATION });

// Gemini AI endpoint with function calling
app.post('/ai/chat', async (req, res) => {
    const { prompt, conversationHistory = [], model = 'gemini-2.0-flash', workstationName } = req.body;
    
    if (!prompt) {
        return res.status(400).json({ error: 'Prompt is required' });
    }
    
    // Map old Claude/GPT models to Gemini
    const modelMap = {
        'claude-3.5': 'gemini-2.0-flash-exp',
        'claude-4.5': 'gemini-2.0-flash-exp',
        'claude-opus': 'gemini-2.0-flash-exp',
        'claude-haiku': 'gemini-2.0-flash-exp',
        'gpt-4': 'gemini-2.0-flash-exp',
        'gpt-5': 'gemini-2.0-flash-exp'
    };
    
    const geminiModel = modelMap[model] || model;
    
    try {
        const systemInstruction = workstationName 
            ? `Sei un assistente AI per sviluppatori. Hai accesso a un workstation cloud dove puoi eseguire comandi. Il workstation è: ${workstationName}. Quando l'utente chiede di eseguire comandi, installare pacchetti, o fare operazioni di sviluppo, usa la funzione execute_command. Rispondi sempre in italiano.`
            : 'Sei un assistente AI intelligente e versatile. Rispondi sempre in italiano in modo naturale e conversazionale.';

        const generativeModel = vertex_ai.getGenerativeModel({
            model: geminiModel,
            systemInstruction,
        });

        // Define functions
        const tools = workstationName ? [
            {
                functionDeclarations: [{
                    name: 'execute_command',
                    description: 'Esegui un comando bash nel workstation cloud dello sviluppatore',
                    parameters: {
                        type: 'object',
                        properties: {
                            command: {
                                type: 'string',
                                description: 'Il comando bash da eseguire (es: npm install, git status, ls -la)'
                            }
                        },
                        required: ['command']
                    }
                }]
            }
        ] : [{ googleSearch: {} }];

        const chat = generativeModel.startChat({
            tools,
            history: conversationHistory.map((msg, i) => ({
                role: i % 2 === 0 ? 'user' : 'model',
                parts: [{ text: msg }]
            }))
        });

        let result = await chat.sendMessage(prompt);
        let response = result.response;
        
        console.log('🔍 Gemini response:', JSON.stringify(response, null, 2));

        // Extract function call from response
        let functionCall = null;
        if (response.candidates && response.candidates[0]) {
            const parts = response.candidates[0].content.parts;
            for (const part of parts) {
                if (part.functionCall) {
                    functionCall = part.functionCall;
                    break;
                }
            }
        }

        // Handle function calls
        if (functionCall) {
            let functionResult = '';

            if (functionCall.name === 'execute_command') {
                console.log(`⚡ Execute: ${functionCall.args.command}`);
                try {
                    const { command } = functionCall.args;
                    const parent = `projects/${PROJECT_ID}/locations/${LOCATION}/workstationClusters/${CLUSTER}/workstationConfigs/${CONFIG}`;
                    const workstationPath = `${parent}/workstations/${workstationName}`;
                    
                    // Per ora simula esecuzione - in produzione usare SSH/exec API
                    functionResult = `✅ Comando eseguito: ${command}\n(Output simulato - integrazione completa in sviluppo)`;
                } catch (error) {
                    functionResult = `❌ Errore: ${error.message}`;
                }
            }

            if (functionCall.name === 'web_search') {
                console.log(`🔍 Web search: ${functionCall.args.query}`);
                try {
                    const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(functionCall.args.query)}&hl=it`;
                    const searchResponse = await axios.get(searchUrl, {
                        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
                        timeout: 10000
                    });
                    
                    const html = searchResponse.data;
                    const snippetMatches = html.match(/<div[^>]*class="[^"]*VwiC3b[^"]*"[^>]*>(.*?)<\/div>/gs);
                    const results = [];
                    
                    if (snippetMatches) {
                        for (let i = 0; i < Math.min(3, snippetMatches.length); i++) {
                            const snippet = snippetMatches[i]
                                .replace(/<[^>]*>/g, '')
                                .replace(/&nbsp;/g, ' ')
                                .replace(/&quot;/g, '"')
                                .trim();
                            if (snippet && snippet.length > 20) {
                                results.push(`• ${snippet}`);
                            }
                        }
                    }
                    
                    functionResult = results.length > 0 
                        ? `Risultati:\n${results.join('\n')}`
                        : `Nessun risultato per "${functionCall.args.query}"`;
                } catch (error) {
                    functionResult = 'Ricerca non disponibile';
                }
            }

            if (functionCall.name === 'github_operation') {
                console.log(`🐙 GitHub: ${functionCall.args.operation}`);
                const { promisify } = require('util');
                const execAsync = promisify(exec);
                
                try {
                    const { operation, repo_name, message, private: isPrivate } = functionCall.args;
                    
                    switch (operation) {
                        case 'create_repo':
                            const vis = isPrivate ? '--private' : '--public';
                            const r = await execAsync(`gh repo create ${repo_name} ${vis} --confirm`);
                            functionResult = `✅ Repository creato: ${repo_name}`;
                            break;
                        case 'status':
                            const s = await execAsync('git status');
                            functionResult = s.stdout;
                            break;
                        default:
                            functionResult = 'Operazione non supportata';
                    }
                } catch (error) {
                    functionResult = `❌ Errore: ${error.message}`;
                }
            }

            // Send function result back
            result = await chat.sendMessage([{
                functionResponse: {
                    name: functionCall.name,
                    response: { result: functionResult }
                }
            }]);
            response = result.response;
        }

        // Extract content from response
        let content = '';
        if (response.candidates && response.candidates[0]) {
            const parts = response.candidates[0].content.parts;
            for (const part of parts) {
                if (part.text) {
                    content += part.text;
                }
            }
        }
        
        if (!content) {
            content = 'Nessuna risposta disponibile';
        }
        
        res.json({
            success: true,
            content,
            model,
            usage: response.usageMetadata
        });
        
    } catch (error) {
        console.error('Gemini error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

const PORT = process.env.PORT || 8080;

// Workstation management con API client
const { WorkstationsClient } = require('@google-cloud/workstations').v1;
const workstationsClient = new WorkstationsClient();

const CLUSTER = 'drape-dev-cluster';
const CONFIG = 'drape-custom-config'; // Container custom ottimizzato

app.post('/workstation/create', async (req, res) => {
    const { userId, repoName, repoUrl } = req.body;
    // Nome fisso per utente - riutilizzabile
    const workstationName = `ws-user-${userId}`.toLowerCase().replace(/[^a-z0-9-]/g, '-').substring(0, 63);
    
    try {
        const parent = `projects/${PROJECT_ID}/locations/${LOCATION}/workstationClusters/${CLUSTER}/workstationConfigs/${CONFIG}`;
        const workstationPath = `${parent}/workstations/${workstationName}`;
        
        let workstation;
        let isNew = false;
        
        // Check se workstation esiste già
        try {
            console.log(`🔍 Checking if workstation exists: ${workstationName}`);
            [workstation] = await workstationsClient.getWorkstation({ name: workstationPath });
            console.log(`✅ Workstation exists, state: ${workstation.state}`);
            
            // Se esiste ma è spento, avvialo (asincrono)
            if (workstation.state === 'STATE_STOPPED' || workstation.state === 'STOPPED') {
                console.log(`🚀 Starting existing workstation (async)...`);
                // Non aspettare il completamento - ritorna subito
                workstationsClient.startWorkstation({ name: workstationPath }).catch(err => {
                    console.error('Start error:', err);
                });
                
                // Ritorna subito con stato "starting"
                return res.json({
                    success: true,
                    workstationName,
                    url: `https://${workstation.host}`,
                    isNew: false,
                    state: 'starting'
                });
            }
        } catch (notFoundError) {
            // Workstation non esiste, crealo
            console.log(`📦 Creating new workstation: ${workstationName}`);
            isNew = true;
            
            const [operation] = await workstationsClient.createWorkstation({
                parent,
                workstationId: workstationName,
                workstation: {}
            });
            await operation.promise();
            
            // Avvia workstation (asincrono)
            console.log(`🚀 Starting new workstation (async)...`);
            workstationsClient.startWorkstation({ name: workstationPath }).catch(err => {
                console.error('Start error:', err);
            });
            
            [workstation] = await workstationsClient.getWorkstation({ name: workstationPath });
            
            // Clone repo in background (non aspettare)
            if (repoUrl) {
                console.log(`📂 Will clone repo when workstation is ready: ${repoUrl}`);
            }
            
            // Ritorna subito
            return res.json({
                success: true,
                workstationName,
                url: `https://${workstation.host}`,
                isNew: true,
                state: 'starting'
            });
        }
        
        // Workstation già running
        res.json({
            success: true,
            workstationName,
            url: `https://${workstation.host}`,
            isNew: false,
            state: 'running'
        });
    } catch (error) {
        console.error('Workstation error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

app.post('/workstation/execute', async (req, res) => {
    const { workstationName, command } = req.body;
    
    if (!workstationName || !command) {
        return res.status(400).json({ error: 'workstationName and command required' });
    }
    
    try {
        const parent = `projects/${PROJECT_ID}/locations/${LOCATION}/workstationClusters/${CLUSTER}/workstationConfigs/${CONFIG}`;
        const workstationPath = `${parent}/workstations/${workstationName}`;
        
        // Ottieni l'host del workstation
        const [workstation] = await workstationsClient.getWorkstation({
            name: workstationPath
        });
        
        const host = workstation.host;
        
        console.log(`⚡ Executing command in ${workstationName}: ${command}`);
        
        // Chiama exec server nel workstation (porta 3000)
        const execUrl = `https://${host}:3000/exec`;
        
        const execResponse = await axios.post(execUrl, 
            { command },
            { 
                timeout: 30000,
                validateStatus: () => true // Accetta qualsiasi status
            }
        );
        
        if (execResponse.data && execResponse.data.success !== false) {
            res.json({ 
                success: true, 
                output: execResponse.data.output || execResponse.data.error || 'Command executed'
            });
        } else {
            res.json({ 
                success: true, 
                output: execResponse.data.error || 'Command executed with errors'
            });
        }
    } catch (error) {
        console.error('Execute error:', error.message);
        res.json({ 
            success: true, 
            output: `Command sent: ${command}\n\nNote: Exec server may not be ready yet. Try again in a few seconds or use the Terminal button to access the web IDE.`
        });
    }
});

async function executeInWorkstation(workstationName, command) {
    // Funzione helper per clonazione - usa approccio semplificato
    console.log(`Executing in workstation ${workstationName}: ${command}`);
    return 'Command executed';
}

app.post('/workstation/stop', async (req, res) => {
    const { workstationName } = req.body;
    
    try {
        const parent = `projects/${PROJECT_ID}/locations/${LOCATION}/workstationClusters/${CLUSTER}/workstationConfigs/${CONFIG}`;
        const workstationPath = `${parent}/workstations/${workstationName}`;
        
        const [operation] = await workstationsClient.stopWorkstation({
            name: workstationPath
        });
        
        await operation.promise();
        
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`🚀 Gemini backend running on port ${PORT}`);
});
