const serverlessExpress = require('@vendia/serverless-express');
const fetch = require('node-fetch');
const app = require('./backend/server-production');

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
  // Export handler for zip packaging
  module.exports = { handler };
}
