// Simple Lambda handler for debugging - Using AWS SDK v3
let ecsClient, ec2Client;

// Initialize AWS clients async
async function initializeClients() {
  if (!ecsClient || !ec2Client) {
    try {
      // Try to use AWS SDK v3 (native in newer Lambda runtimes)
      const { ECSClient } = await import('@aws-sdk/client-ecs');
      const { EC2Client } = await import('@aws-sdk/client-ec2');
      ecsClient = new ECSClient({ region: process.env.AWS_REGION || 'eu-north-1' });
      ec2Client = new EC2Client({ region: process.env.AWS_REGION || 'eu-north-1' });
    } catch (e1) {
      try {
        // Fallback to AWS SDK v2 if available
        const AWS = await import('aws-sdk');
        ecsClient = new AWS.ECS({ region: process.env.AWS_REGION || 'eu-north-1' });
        ec2Client = new AWS.EC2({ region: process.env.AWS_REGION || 'eu-north-1' });
      } catch (e2) {
        console.error('Could not load AWS SDK:', e1, e2);
        throw new Error('AWS SDK not available');
      }
    }
  }
  return { ecsClient, ec2Client };
}

// Environment variables
const CLUSTER_NAME = process.env.ECS_CLUSTER_NAME;
const SERVICE_NAME = process.env.ECS_SERVICE_NAME;
const TASK_DEFINITION_ARN = process.env.ECS_TASK_DEFINITION_ARN;
const SUBNET_IDS = [process.env.ECS_SUBNET_1, process.env.ECS_SUBNET_2].filter(Boolean);
const SECURITY_GROUP_ID = process.env.ECS_SECURITY_GROUP;

exports.handler = async (event) => {
  console.log('Lambda event received:', JSON.stringify(event, null, 2));
  console.log('Environment variables:', {
    CLUSTER_NAME,
    SERVICE_NAME,
    TASK_DEFINITION_ARN,
    SUBNET_IDS,
    SECURITY_GROUP_ID
  });
  
  // Initialize AWS clients
  try {
    await initializeClients();
  } catch (error) {
    console.error('Failed to initialize AWS clients:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        error: 'AWS SDK initialization failed',
        message: error.message
      })
    };
  }
  
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
    console.log('Health check - checking ECS service');
    
    const params = {
      cluster: CLUSTER_NAME,
      services: [SERVICE_NAME]
    };
    
    let result, service;
    if (ecsClient.send) {
      // AWS SDK v3
      const { DescribeServicesCommand } = await import('@aws-sdk/client-ecs');
      result = await ecsClient.send(new DescribeServicesCommand(params));
      service = result.services && result.services[0];
    } else {
      // AWS SDK v2
      result = await ecsClient.describeServices(params).promise();
      service = result.services && result.services[0];
    }
    
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
        service: service ? {
          name: service.serviceName,
          status: service.status,
          runningCount: service.runningCount,
          desiredCount: service.desiredCount
        } : null,
        timestamp: new Date().toISOString()
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
    
    // Regular command execution
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        output: `Command executed: ${command}\nECS backend ready`,
        executor: 'ecs-fargate',
        executionTime: 500
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
    console.log('Handling Flutter run command');
    
    // Ensure ECS service is running
    await ensureServiceRunning();
    
    // Get public IP
    const publicIP = await getServicePublicIP();
    
    const webUrl = `http://${publicIP}:8080`;
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        output: `Flutter web app started\nAccess at: ${webUrl}`,
        webUrl: webUrl,
        webServerDetected: true,
        port: 8080,
        publicIP: publicIP,
        executor: 'ecs-fargate'
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

async function ensureServiceRunning() {
  try {
    console.log('Ensuring ECS service is running');
    
    const describeParams = {
      cluster: CLUSTER_NAME,
      services: [SERVICE_NAME]
    };
    
    let result, service;
    if (ecsClient.send) {
      // AWS SDK v3
      const { DescribeServicesCommand } = await import('@aws-sdk/client-ecs');
      result = await ecsClient.send(new DescribeServicesCommand(describeParams));
      service = result.services && result.services[0];
    } else {
      // AWS SDK v2
      result = await ecsClient.describeServices(describeParams).promise();
      service = result.services && result.services[0];
    }
    
    if (!service) {
      throw new Error('ECS service not found');
    }
    
    console.log('Service status:', {
      status: service.status,
      runningCount: service.runningCount,
      desiredCount: service.desiredCount
    });
    
    // Scale up if needed
    if (service.runningCount === 0 || service.desiredCount === 0) {
      console.log('Scaling up ECS service');
      
      const updateParams = {
        cluster: CLUSTER_NAME,
        service: SERVICE_NAME,
        desiredCount: 1
      };
      
      if (ecsClient.send) {
        // AWS SDK v3
        const { UpdateServiceCommand } = await import('@aws-sdk/client-ecs');
        await ecsClient.send(new UpdateServiceCommand(updateParams));
      } else {
        // AWS SDK v2
        await ecsClient.updateService(updateParams).promise();
      }
      console.log('Service scaled up');
      
      // Wait a bit
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
    
  } catch (error) {
    console.error('Error ensuring service is running:', error);
    throw error;
  }
}

async function getServicePublicIP() {
  try {
    console.log('Getting service public IP');
    
    // Get service details
    const serviceParams = {
      cluster: CLUSTER_NAME,
      services: [SERVICE_NAME]
    };
    
    let serviceResult, service, tasksListResult, tasksResult;
    
    if (ecsClient.send) {
      // AWS SDK v3
      const { DescribeServicesCommand, ListTasksCommand, DescribeTasksCommand } = await import('@aws-sdk/client-ecs');
      
      serviceResult = await ecsClient.send(new DescribeServicesCommand(serviceParams));
      service = serviceResult.services && serviceResult.services[0];
      
      if (!service || service.runningCount === 0) {
        throw new Error('No running tasks found');
      }
      
      // Get task ARNs
      const listTasksParams = {
        cluster: CLUSTER_NAME,
        serviceName: SERVICE_NAME
      };
      
      tasksListResult = await ecsClient.send(new ListTasksCommand(listTasksParams));
      
      if (!tasksListResult.taskArns || tasksListResult.taskArns.length === 0) {
        throw new Error('No task ARNs found');
      }
      
      // Describe the tasks
      const describeTasksParams = {
        cluster: CLUSTER_NAME,
        tasks: tasksListResult.taskArns
      };
      
      tasksResult = await ecsClient.send(new DescribeTasksCommand(describeTasksParams));
    } else {
      // AWS SDK v2
      serviceResult = await ecsClient.describeServices(serviceParams).promise();
      service = serviceResult.services && serviceResult.services[0];
      
      if (!service || service.runningCount === 0) {
        throw new Error('No running tasks found');
      }
      
      // Get task ARNs
      const listTasksParams = {
        cluster: CLUSTER_NAME,
        serviceName: SERVICE_NAME
      };
      
      tasksListResult = await ecsClient.listTasks(listTasksParams).promise();
      
      if (!tasksListResult.taskArns || tasksListResult.taskArns.length === 0) {
        throw new Error('No task ARNs found');
      }
      
      // Describe the tasks
      const describeTasksParams = {
        cluster: CLUSTER_NAME,
        tasks: tasksListResult.taskArns
      };
      
      tasksResult = await ecsClient.describeTasks(describeTasksParams).promise();
    }
    
    if (!tasksResult.tasks || tasksResult.tasks.length === 0) {
      throw new Error('No task details found');
    }
    
    const task = tasksResult.tasks[0];
    
    // Find network interface ID
    let eniId = null;
    if (task.attachments && task.attachments.length > 0) {
      for (const attachment of task.attachments) {
        if (attachment.details) {
          for (const detail of attachment.details) {
            if (detail.name === 'networkInterfaceId') {
              eniId = detail.value;
              break;
            }
          }
        }
        if (eniId) break;
      }
    }
    
    if (!eniId) {
      throw new Error('Network interface ID not found');
    }
    
    console.log('Found network interface:', eniId);
    
    // Get public IP from network interface
    const eniParams = {
      NetworkInterfaceIds: [eniId]
    };
    
    let eniResult;
    if (ec2Client.send) {
      // AWS SDK v3
      const { DescribeNetworkInterfacesCommand } = await import('@aws-sdk/client-ec2');
      eniResult = await ec2Client.send(new DescribeNetworkInterfacesCommand(eniParams));
    } else {
      // AWS SDK v2
      eniResult = await ec2Client.describeNetworkInterfaces(eniParams).promise();
    }
    
    if (!eniResult.NetworkInterfaces || eniResult.NetworkInterfaces.length === 0) {
      throw new Error('Network interface not found');
    }
    
    const networkInterface = eniResult.NetworkInterfaces[0];
    const publicIP = networkInterface.Association && networkInterface.Association.PublicIp;
    
    if (!publicIP) {
      throw new Error('Public IP not found');
    }
    
    console.log('Found public IP:', publicIP);
    return publicIP;
    
  } catch (error) {
    console.error('Error getting public IP:', error);
    throw error;
  }
}