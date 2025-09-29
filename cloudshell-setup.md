# Setup in AWS CloudShell

Esegui questi comandi in CloudShell per configurare e deployare il fix:

## 1. Setup Directory
```bash
mkdir -p ~/warp-mobile-ai-ide/aws
cd ~/warp-mobile-ai-ide
```

## 2. Crea il Deploy Script
```bash
cat > deploy-flutter-preview-fix.sh << 'EOF'
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
EOF

chmod +x deploy-flutter-preview-fix.sh
```

## 3. Controlla gli Stack Esistenti
```bash
echo "📋 Checking existing CloudFormation stacks..."
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[?contains(StackName, `warp-mobile-ai-ide`)].{Name:StackName,Status:StackStatus,Created:CreationTime}' --output table
```

## 4. Carica il Template CloudFormation
Ora devi caricare il file `aws/cloudformation-template.yaml` con le modifiche.

**Opzioni:**
- **Upload via UI**: Usa il pulsante "Upload Files" in CloudShell
- **Copia manuale**: Usa l'editor integrato di CloudShell per creare il file

## 5. Esegui il Deploy
```bash
# Assicurati di essere nella directory giusta
cd ~/warp-mobile-ai-ide

# Esegui il deploy
./deploy-flutter-preview-fix.sh
```

## Troubleshooting

Se lo stack non esiste ancora:
```bash
# Usa create-stack invece di update-stack
aws cloudformation create-stack \
    --stack-name "warp-mobile-ai-ide-prod" \
    --template-body file://aws/cloudformation-template.yaml \
    --parameters ParameterKey=ProjectName,ParameterValue=warp-mobile-ai-ide \
                 ParameterKey=Environment,ParameterValue=prod \
    --capabilities CAPABILITY_NAMED_IAM
```

Per vedere lo stato dello stack:
```bash
aws cloudformation describe-stacks --stack-name "warp-mobile-ai-ide-prod"
```