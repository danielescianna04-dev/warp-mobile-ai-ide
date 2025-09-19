const serverlessExpress = require('@vendia/serverless-express');
// Using native fetch in Node.js 18
const app = require('./backend/server-production');
const ecsApp = require('./backend/ecs-server');

// Create Lambda handler
const handler = serverlessExpress({ app });

// For container runtime, we need to handle Lambda Runtime API directly
if (process.env.AWS_LAMBDA_RUNTIME_API) {
  console.log('🔥 Lambda container runtime detected');
  // This is a Lambda container runtime - set up the handler
  const lambdaRuntime = async () => {
    while (true) {
      try {
        const nextUrl = `http://${process.env.AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next`;
        const response = await fetch(nextUrl);
        const requestId = response.headers.get('lambda-runtime-aws-request-id');
        const event = await response.json();
        
        // Process the event
        const result = await handler(event, {});
        
        // Send response
        const responseUrl = `http://${process.env.AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/${requestId}/response`;
        await fetch(responseUrl, {
          method: 'POST',
          body: JSON.stringify(result),
          headers: { 'Content-Type': 'application/json' }
        });
      } catch (error) {
        console.error('Lambda runtime error:', error);
        // Send error
        const errorUrl = `http://${process.env.AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/error`;
        await fetch(errorUrl, {
          method: 'POST',
          body: JSON.stringify({ errorMessage: error.message, errorType: error.name }),
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }
  };
  lambdaRuntime();
} else {
  // No Lambda runtime API - this is either zip packaging or ECS container
  // Check if we're in a container environment (ECS)
  if (process.env.ECS_CONTAINER_METADATA_URI || process.env.ECS_CONTAINER_METADATA_URI_V4 || process.env.PORT) {
    console.log('🚀 ECS container mode detected - starting ECS server');
    const port = process.env.PORT || 3000;
    // Use the dedicated ECS server instead of production server
    const ecsServerApp = require('./backend/ecs-server');
    console.log('✅ ECS server started on port', port);
    console.log('🎯 Ready to handle heavy commands from Lambda hybrid backend');
  } else {
    // Export handler for zip packaging
    console.log('📦 Lambda zip mode - exporting handler');
    module.exports.handler = handler;
  }
}
