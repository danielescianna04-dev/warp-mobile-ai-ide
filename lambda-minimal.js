// Minimal Lambda handler without external dependencies
// Uses native Node.js modules only

const https = require('https');
const crypto = require('crypto');

// Environment variables
const CLUSTER_NAME = process.env.ECS_CLUSTER_NAME;
const SERVICE_NAME = process.env.ECS_SERVICE_NAME;
const TASK_DEFINITION_ARN = process.env.ECS_TASK_DEFINITION_ARN;
const SUBNET_IDS = [process.env.ECS_SUBNET_1, process.env.ECS_SUBNET_2].filter(Boolean);
const SECURITY_GROUP_ID = process.env.ECS_SECURITY_GROUP;
const AWS_REGION = process.env.AWS_REGION || 'eu-north-1';

exports.handler = async (event) => {
  console.log('Lambda event received:', JSON.stringify(event, null, 2));
  console.log('Environment variables:', {
    CLUSTER_NAME,
    SERVICE_NAME,
    TASK_DEFINITION_ARN,
    SUBNET_IDS,
    SECURITY_GROUP_ID,
    AWS_REGION
  });
  
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-User-ID,X-Session-ID',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Content-Type': 'application/json'
  };
  
  try {
    // Handle CORS preflight
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'CORS OK' })
      };
    }
    
    // Get the path from the event
    let path = event.path || '/';
    if (event.pathParameters && event.pathParameters.proxy) {
      path = '/' + event.pathParameters.proxy;
    }
    
    console.log('Processing request:', event.httpMethod, path);
    
    // Route the request
    if (path === '/health') {
      return await handleHealthCheck();
    } else if (path === '/execute') {
      return await handleExecuteCommand(event);
    } else {
      return {
        statusCode: 404,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Not found', path: path })
      };
    }
    
  } catch (error) {
    console.error('Lambda error:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message,
        stack: error.stack
      })
    };
  }
};

async function handleHealthCheck() {
  try {
    console.log('Health check - simplified version');
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        status: 'healthy',
        environment: 'ecs-fargate',
        cluster: CLUSTER_NAME,
        service: SERVICE_NAME ? {
          name: 'warp-mobile-ai-ide-service',
          status: 'ACTIVE',
          runningCount: 1,
          desiredCount: 1
        } : null,
        timestamp: new Date().toISOString(),
        note: 'Simplified health check - ECS integration pending'
      })
    };
  } catch (error) {
    console.error('Health check error:', error);
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        status: 'unhealthy',
        environment: 'ecs-fargate',
        error: error.message,
        timestamp: new Date().toISOString()
      })
    };
  }
}

async function handleExecuteCommand(event) {
  try {
    const body = JSON.parse(event.body || '{}');
    const command = body.command;
    
    console.log('Executing command:', command);
    
    if (!command) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Command required', success: false })
      };
    }
    
    // Check if it's a flutter run command
    if (command.toLowerCase().includes('flutter') && command.toLowerCase().includes('run')) {
      return await handleFlutterRun(command);
    }
    
    // Regular command execution - mock response
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        output: `Command executed: ${command}\nECS backend is ready (simplified mode)`,
        executor: 'lambda-simplified',
        executionTime: 500,
        note: 'Full ECS integration pending'
      })
    };
    
  } catch (error) {
    console.error('Execute command error:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        error: 'Command execution failed',
        message: error.message,
        success: false
      })
    };
  }
}

async function handleFlutterRun(command) {
  try {
    console.log('Handling Flutter run command - simplified version');
    
    // For now, return a mock response with a placeholder IP
    // In a real implementation, this would query ECS for the actual public IP
    const mockPublicIP = '13.49.14.26'; // Using one of the API Gateway IPs as example
    const webUrl = `http://${mockPublicIP}:8080`;
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        output: `Flutter web app starting...\nAccess at: ${webUrl}\n\n⚠️ Note: This is a simplified response. Full ECS integration coming soon.`,
        webUrl: webUrl,
        webServerDetected: true,
        port: 8080,
        publicIP: mockPublicIP,
        executor: 'lambda-simplified',
        note: 'Using mock public IP - real ECS integration pending'
      })
    };
    
  } catch (error) {
    console.error('Flutter run error:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        error: 'Flutter run failed',
        message: error.message,
        success: false
      })
    };
  }
}

// AWS API helper functions (for future use)
function createAWSSignature(service, method, path, queryString, headers, body) {
  // This would implement AWS Signature Version 4
  // For now, just a placeholder
  return 'AWS4-HMAC-SHA256 placeholder';
}

async function makeAWSRequest(service, action, params) {
  // This would make direct HTTPS calls to AWS APIs
  // For now, just a placeholder
  return { success: false, message: 'Direct AWS API calls not implemented yet' };
}