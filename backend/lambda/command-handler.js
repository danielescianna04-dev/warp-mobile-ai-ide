// Lambda Handler - Command Execution
const UserManager = require('./user-manager');
const CommandExecutor = require('./command-executor');
const AIAgent = require('../ai-agent');

// Initialize managers (singleton pattern per Lambda container)
let userManager;
let commandExecutor; 
let aiAgent;

// Initialize on cold start
const initialize = async () => {
  if (!userManager) {
    userManager = new UserManager('/mnt/efs'); // EFS mount point
    commandExecutor = new CommandExecutor();
    aiAgent = new AIAgent();
    await aiAgent.initialize();
    console.log('🚀 Lambda handlers initialized');
  }
};

exports.handler = async (event, context) => {
  try {
    // Initialize on cold start
    await initialize();

    // Parse event (from API Gateway)
    const { httpMethod, path: requestPath, body, headers } = event;
    const requestBody = body ? JSON.parse(body) : {};

    console.log(`📡 ${httpMethod} ${requestPath}`, requestBody);

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-User-ID, X-Session-ID',
    };

    // Handle preflight OPTIONS
    if (httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'CORS preflight' })
      };
    }

    // Extract user info
    const userId = headers['X-User-ID'] || headers['x-user-id'] || 'anonymous';
    const sessionId = headers['X-Session-ID'] || headers['x-session-id'];

    // Route handlers
    switch (requestPath) {
      case '/session/create':
        return await handleCreateSession(userId, corsHeaders);
      
      case '/command/execute':
        return await handleExecuteCommand(requestBody, sessionId, corsHeaders);
        
      case '/ai/chat':
        return await handleAIChat(requestBody, sessionId, corsHeaders);
        
      case '/ai/agent':
        return await handleAIAgent(requestBody, sessionId, corsHeaders);
        
      case '/files/list':
        return await handleListFiles(requestBody, sessionId, corsHeaders);
        
      case '/files/read':
        return await handleReadFile(requestBody, sessionId, corsHeaders);
        
      case '/files/write':
        return await handleWriteFile(requestBody, sessionId, corsHeaders);

      case '/health':
        return await handleHealthCheck(corsHeaders);
        
      default:
        return {
          statusCode: 404,
          headers: corsHeaders,
          body: JSON.stringify({ error: 'Route not found' })
        };
    }

  } catch (error) {
    console.error('❌ Lambda handler error:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: error.message,
        timestamp: new Date().toISOString()
      })
    };
  }
};

// Handler functions
async function handleCreateSession(userId, headers) {
  try {
    const session = await userManager.createUserSession(userId);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: true,
        session: {
          sessionId: session.sessionId,
          userId: session.userId,
          workspaceDir: session.workspaceDir,
          quotaRemaining: session.fileQuota
        }
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleExecuteCommand(requestBody, sessionId, headers) {
  try {
    if (!sessionId) {
      throw new Error('Session ID required');
    }

    const { command, streaming = false } = requestBody;
    if (!command) {
      throw new Error('Command required');
    }

    const session = await userManager.getUserSession(sessionId);
    const result = await commandExecutor.executeCommand(command, session, streaming);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 400,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleAIChat(requestBody, sessionId, headers) {
  try {
    if (!sessionId) {
      throw new Error('Session ID required');
    }

    const { prompt, context } = requestBody;
    if (!prompt) {
      throw new Error('Prompt required');
    }

    const session = await userManager.getUserSession(sessionId);
    
    // Add session context to AI request
    const aiContext = {
      ...context,
      workingDir: session.workspaceDir,
      sessionId: session.sessionId,
      userId: session.userId
    };

    const response = await aiAgent.generateResponse(prompt, aiContext);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: true,
        response: response.content,
        model: response.model,
        provider: response.provider,
        responseTime: response.responseTime
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleAIAgent(requestBody, sessionId, headers) {
  try {
    if (!sessionId) {
      throw new Error('Session ID required');
    }

    const { task } = requestBody;
    if (!task) {
      throw new Error('Task required');
    }

    const session = await userManager.getUserSession(sessionId);
    
    // AI Agent will use CommandExecutor to perform actions
    const agentExecutor = {
      executeCommand: async (command) => {
        return await commandExecutor.executeCommand(command, session, false);
      },
      readFile: async (filePath) => {
        return await commandExecutor.readFile(filePath, session);
      },
      writeFile: async (filePath, content) => {
        return await commandExecutor.writeFile(filePath, content, session);
      }
    };

    const execution = await aiAgent.executeAutonomousTask(task, agentExecutor, null);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: true,
        task,
        status: execution.status,
        steps: execution.steps.length,
        duration: execution.duration,
        result: execution.result
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleListFiles(requestBody, sessionId, headers) {
  try {
    if (!sessionId) {
      throw new Error('Session ID required');
    }

    const { path: dirPath } = requestBody;
    const session = await userManager.getUserSession(sessionId);
    const result = await commandExecutor.listFiles(dirPath, session);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 400,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleReadFile(requestBody, sessionId, headers) {
  try {
    if (!sessionId) {
      throw new Error('Session ID required');
    }

    const { path: filePath } = requestBody;
    if (!filePath) {
      throw new Error('File path required');
    }

    const session = await userManager.getUserSession(sessionId);
    const result = await commandExecutor.readFile(filePath, session);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 400,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleWriteFile(requestBody, sessionId, headers) {
  try {
    if (!sessionId) {
      throw new Error('Session ID required');
    }

    const { path: filePath, content } = requestBody;
    if (!filePath || content === undefined) {
      throw new Error('File path and content required');
    }

    const session = await userManager.getUserSession(sessionId);
    const result = await commandExecutor.writeFile(filePath, content, session);
    
    return {
      statusCode: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify(result)
    };
  } catch (error) {
    return {
      statusCode: 400,
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: false, error: error.message })
    };
  }
}

async function handleHealthCheck(headers) {
  return {
    statusCode: 200,
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: '1.0.0-lambda',
      environment: 'AWS Lambda',
      uptime: process.uptime()
    })
  };
}