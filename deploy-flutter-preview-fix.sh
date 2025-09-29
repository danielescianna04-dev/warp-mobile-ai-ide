#!/bin/bash

# Deploy script per il fix Flutter Preview
# Questo script aggiorna lo stack CloudFormation con le nuove configurazioni

set -e

PROJECT_NAME="warp-mobile-ai-ide"
ENVIRONMENT="prod"
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"
TEMPLATE_FILE="aws/cloudformation-template.yaml"

echo "🚀 Deploying Flutter Preview Fix..."
echo "📁 Project: $PROJECT_NAME"
echo "🌍 Environment: $ENVIRONMENT"
echo "📄 Template: $TEMPLATE_FILE"
echo ""

# Verifica che il template esista
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Errore: File template non trovato: $TEMPLATE_FILE"
    exit 1
fi

echo "🔍 Validating CloudFormation template..."
aws cloudformation validate-template --template-body file://$TEMPLATE_FILE

if [ $? -ne 0 ]; then
    echo "❌ Template validation failed!"
    exit 1
fi

echo "✅ Template validation successful"
echo ""

echo "🔄 Updating CloudFormation stack: $STACK_NAME"
aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://$TEMPLATE_FILE \
    --parameters ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
                 ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
    --capabilities CAPABILITY_NAMED_IAM

if [ $? -ne 0 ]; then
    echo "❌ Stack update failed!"
    echo "💡 Possibili cause:"
    echo "   - Stack non esiste (usa create-stack invece di update-stack)"
    echo "   - Nessune modifiche da applicare"
    echo "   - Errori di permessi IAM"
    exit 1
fi

echo "⏳ Waiting for stack update to complete..."
aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Stack update completed successfully!"
    echo ""
    echo "📊 Stack outputs:"
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[*].{Key:OutputKey,Value:OutputValue}' --output table
    echo ""
    echo "✅ Il fix per Flutter Preview è stato applicato!"
    echo "🔧 Modifiche applicate:"
    echo "   ✓ Security Group ECS ora permette porte 8080-8084"
    echo "   ✓ Task Definition espone porte Flutter web server"
    echo "   ✓ ECS tasks ora hanno IP pubblico abilitato"
    echo ""
    echo "🧪 Test del fix:"
    echo "   1. Riavvia l'app Flutter"
    echo "   2. Esegui 'flutter run' nel terminale"
    echo "   3. Verifica che l'URL preview punti all'IP pubblico"
    echo "   4. Clicca il pulsante preview per testare la connessione"
else
    echo "❌ Stack update failed to complete within timeout"
    exit 1
fi