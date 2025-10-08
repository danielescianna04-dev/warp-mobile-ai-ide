const express = require('express');
const { exec } = require('child_process');
const axios = require('axios');
const { VertexAI } = require('@google-cloud/vertexai');

const app = express();
app.use(express.json());

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || 'drape-mobile-ide';
const LOCATION = 'us-central1';

const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });

// Gemini AI endpoint with function calling
app.post('/ai/chat', async (req, res) => {
    const { prompt, conversationHistory = [], model = 'gemini-2.0-flash' } = req.body;
    
    if (!prompt) {
        return res.status(400).json({ error: 'Prompt is required' });
    }
    
    try {
        const generativeModel = vertexAI.getGenerativeModel({
            model: model,
            systemInstruction: 'Sei un assistente AI intelligente e versatile. Rispondi sempre in italiano in modo naturale e conversazionale. Usa le funzioni disponibili quando necessario per fornire informazioni accurate e aggiornate.',
        });

        // Define functions
        const functions = {
            web_search: {
                name: 'web_search',
                description: 'Cerca informazioni su internet per dati attuali, notizie, fatti o informazioni in tempo reale.',
                parameters: {
                    type: 'object',
                    properties: {
                        query: {
                            type: 'string',
                            description: 'La query di ricerca'
                        }
                    },
                    required: ['query']
                }
            },
            github_operation: {
                name: 'github_operation',
                description: 'Esegui operazioni GitHub: crea repository, commit, push, clone, status, log.',
                parameters: {
                    type: 'object',
                    properties: {
                        operation: {
                            type: 'string',
                            enum: ['create_repo', 'clone', 'commit', 'push', 'status', 'log'],
                            description: 'Operazione GitHub da eseguire'
                        },
                        repo_name: { type: 'string', description: 'Nome repository' },
                        message: { type: 'string', description: 'Messaggio commit' },
                        private: { type: 'boolean', description: 'Repo privato' }
                    },
                    required: ['operation']
                }
            }
        };

        const chat = generativeModel.startChat({
            tools: [{ functionDeclarations: Object.values(functions) }],
            history: conversationHistory.map((msg, i) => ({
                role: i % 2 === 0 ? 'user' : 'model',
                parts: [{ text: msg }]
            }))
        });

        let result = await chat.sendMessage(prompt);
        let response = result.response;

        // Handle function calls
        if (response.functionCalls && response.functionCalls.length > 0) {
            const functionCall = response.functionCalls[0];
            let functionResult = '';

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

        const content = response.candidates[0].content.parts[0].text;
        
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
app.listen(PORT, () => {
    console.log(`🚀 Gemini backend running on port ${PORT}`);
});
