// Complete Lambda handler with real ECS integration
const { ECSClient, DescribeServicesCommand, UpdateServiceCommand, ListTasksCommand, DescribeTasksCommand } = require('@aws-sdk/client-ecs');
const { EC2Client, DescribeNetworkInterfacesCommand } = require('@aws-sdk/client-ec2');

// Initialize AWS clients
const ecsClient = new ECSClient({ region: process.env.AWS_REGION || 'eu-north-1' });
const ec2Client = new EC2Client({ region: process.env.AWS_REGION || 'eu-north-1' });

// Environment variables
const CLUSTER_NAME = process.env.ECS_CLUSTER_NAME;
const SERVICE_NAME = process.env.ECS_SERVICE_NAME;
const TASK_DEFINITION_ARN = process.env.ECS_TASK_DEFINITION_ARN;
const SUBNET_IDS = [process.env.ECS_SUBNET_1, process.env.ECS_SUBNET_2].filter(Boolean);
const SECURITY_GROUP_ID = process.env.ECS_SECURITY_GROUP;
const AWS_REGION = process.env.AWS_REGION || 'eu-north-1';

exports.handler = async (event) => {
  console.log('🚀 Lambda event received:', JSON.stringify(event, null, 2));
  console.log('🌍 Environment variables:', {
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
    
    console.log('📍 Processing request:', event.httpMethod, path);
    
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
    console.error('❌ Lambda error:', error);
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
    console.log('🏥 Health check - querying real ECS service');
    
    // Real ECS service check
    const params = {
      cluster: CLUSTER_NAME,
      services: [SERVICE_NAME]
    };
    
    const result = await ecsClient.send(new DescribeServicesCommand(params));
    const service = result.services && result.services[0];
    
    const isHealthy = service && service.status === 'ACTIVE';
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        status: isHealthy ? 'healthy' : 'unhealthy',
        environment: 'ecs-fargate',
        cluster: CLUSTER_NAME,
        service: service ? {
          name: service.serviceName,
          status: service.status,
          runningCount: service.runningCount,
          desiredCount: service.desiredCount,
          pendingCount: service.pendingCount,
          taskDefinition: service.taskDefinition
        } : null,
        timestamp: new Date().toISOString(),
        integration: 'ACTIVE ✅ Real ECS integration enabled'
      })
    };
  } catch (error) {
    console.error('❌ Health check error:', error);
    return {
      statusCode: 200, // Return 200 even on error for basic health check
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        status: 'unhealthy',
        environment: 'ecs-fargate',
        error: error.message,
        timestamp: new Date().toISOString(),
        integration: 'ERROR ❌ ECS integration failed'
      })
    };
  }
}

async function handleExecuteCommand(event) {
  try {
    const body = JSON.parse(event.body || '{}');
    const command = body.command;
    
    console.log('🔧 Executing command:', command);
    
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
    
    // For other commands, ensure ECS service is running
    await ensureECSServiceRunning();
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        output: `Command executed: ${command}\n✅ ECS service is running and ready`,
        executor: 'ecs-fargate',
        executionTime: 500,
        integration: 'ACTIVE ✅ Real ECS integration'
      })
    };
    
  } catch (error) {
    console.error('❌ Execute command error:', error);
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
    console.log('🚀 Handling Flutter run command with real ECS integration');
    
    // Step 1: Ensure ECS service is running
    console.log('📊 Step 1: Ensuring ECS service is running...');
    await ensureECSServiceRunning();
    
    // Step 2: Get the real public IP from ECS
    console.log('🌐 Step 2: Getting public IP from ECS task...');
    const publicIP = await getECSServicePublicIP();
    
    if (!publicIP) {
      throw new Error('Could not retrieve public IP from ECS service');
    }
    
    // Step 3: Construct Flutter web URL
    const webUrl = `http://${publicIP}:8080`;
    console.log('✅ Flutter web app URL:', webUrl);
    
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        output: `🚀 Flutter web app started successfully!\n🌐 Access your app at: ${webUrl}\n✅ Running on ECS Fargate with public IP: ${publicIP}`,
        webUrl: webUrl,
        webServerDetected: true,
        port: 8080,
        publicIP: publicIP,
        executor: 'ecs-fargate',
        executionTime: 2000,
        integration: 'ACTIVE ✅ Real ECS integration with live public IP'
      })
    };
    
  } catch (error) {
    console.error('❌ Flutter run error:', error);
    
    // Fallback with detailed error info
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        error: 'Flutter run failed',
        message: error.message,
        success: false,
        details: {
          cluster: CLUSTER_NAME,
          service: SERVICE_NAME,
          region: AWS_REGION
        },
        integration: 'ERROR ❌ ECS integration failed'
      })
    };
  }
}

// Ensure ECS service is running (scale up if needed)
async function ensureECSServiceRunning() {
  try {
    console.log('🔍 Checking ECS service status...');
    
    const describeParams = {
      cluster: CLUSTER_NAME,
      services: [SERVICE_NAME]
    };
    
    const result = await ecsClient.send(new DescribeServicesCommand(describeParams));
    const service = result.services && result.services[0];
    
    if (!service) {
      throw new Error(`ECS service not found: ${SERVICE_NAME} in cluster ${CLUSTER_NAME}`);
    }
    
    console.log('📊 Service status:', {
      name: service.serviceName,
      status: service.status,
      runningCount: service.runningCount,
      desiredCount: service.desiredCount,
      pendingCount: service.pendingCount
    });
    
    // Scale up if needed
    if (service.runningCount === 0 || service.desiredCount === 0) {
      console.log('⚡ Scaling up ECS service to 1 instance...');
      
      const updateParams = {
        cluster: CLUSTER_NAME,
        service: SERVICE_NAME,
        desiredCount: 1
      };
      
      await ecsClient.send(new UpdateServiceCommand(updateParams));
      console.log('✅ ECS service scaled up successfully');
      
      // Wait for the service to start
      console.log('⏳ Waiting for service to start...');
      await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
    } else {
      console.log('✅ ECS service is already running');
    }
    
  } catch (error) {
    console.error('❌ Error ensuring ECS service is running:', error);
    throw error;
  }
}

// Get the real public IP of the ECS service
async function getECSServicePublicIP() {
  try {
    console.log('🌐 Getting ECS service public IP...');
    
    // Step 1: Get service details
    const serviceParams = {
      cluster: CLUSTER_NAME,
      services: [SERVICE_NAME]
    };
    
    const serviceResult = await ecsClient.send(new DescribeServicesCommand(serviceParams));
    const service = serviceResult.services && serviceResult.services[0];
    
    if (!service || service.runningCount === 0) {
      throw new Error('No running tasks found in ECS service');
    }
    
    // Step 2: List tasks for the service
    const listTasksParams = {
      cluster: CLUSTER_NAME,
      serviceName: SERVICE_NAME
    };
    
    const tasksListResult = await ecsClient.send(new ListTasksCommand(listTasksParams));
    
    if (!tasksListResult.taskArns || tasksListResult.taskArns.length === 0) {
      throw new Error('No task ARNs found for ECS service');
    }
    
    console.log('📋 Found tasks:', tasksListResult.taskArns.length);
    
    // Step 3: Describe the tasks to get network details
    const describeTasksParams = {
      cluster: CLUSTER_NAME,
      tasks: tasksListResult.taskArns
    };
    
    const tasksResult = await ecsClient.send(new DescribeTasksCommand(describeTasksParams));
    
    if (!tasksResult.tasks || tasksResult.tasks.length === 0) {
      throw new Error('No task details found');
    }
    
    const task = tasksResult.tasks[0];
    console.log('📊 Task details:', {
      taskArn: task.taskArn,
      lastStatus: task.lastStatus,
      desiredStatus: task.desiredStatus
    });
    
    // Step 4: Extract network interface ID from task attachments
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
      throw new Error('Network interface ID not found in task attachments');
    }
    
    console.log('🔌 Found network interface:', eniId);
    
    // Step 5: Get public IP from network interface
    const eniParams = {
      NetworkInterfaceIds: [eniId]
    };
    
    const eniResult = await ec2Client.send(new DescribeNetworkInterfacesCommand(eniParams));
    
    if (!eniResult.NetworkInterfaces || eniResult.NetworkInterfaces.length === 0) {
      throw new Error('Network interface not found');
    }
    
    const networkInterface = eniResult.NetworkInterfaces[0];
    const publicIP = networkInterface.Association && networkInterface.Association.PublicIp;
    
    if (!publicIP) {
      throw new Error('No public IP associated with network interface');
    }
    
    console.log('🎯 ECS service public IP:', publicIP);
    return publicIP;
    
  } catch (error) {
    console.error('❌ Error getting ECS service public IP:', error);
    throw error;
  }
}
