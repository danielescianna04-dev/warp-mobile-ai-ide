# 🚀 Endpoint Diretto ECS (Senza Lambda)

## ✅ Endpoint Funzionante

```
http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com
```

## 📡 API Endpoints Disponibili

### Health Check
```bash
GET /health
```

### Esegui Comando
```bash
POST /execute-heavy
Content-Type: application/json

{
  "command": "flutter run",
  "repository": "my-app",
  "workingDir": "/tmp/projects/my-app"
}
```

### Flutter Run (Long-running)
```bash
POST /flutter/run
Content-Type: application/json

{
  "command": "flutter run",
  "repository": "my-app"
}
```

### Flutter Web Start
```bash
POST /flutter/web/start
Content-Type: application/json

{
  "repository": "my-app",
  "port": 8080
}
```

### Flutter Stop
```bash
POST /flutter/stop
Content-Type: application/json

{
  "repository": "my-app"
}
```

## 🔧 Modifica nell'App Flutter

Nel tuo file di configurazione Flutter, cambia:

```dart
// PRIMA (con Lambda - NON FUNZIONA)
final apiEndpoint = 'https://xxx.execute-api.us-west-2.amazonaws.com/prod';

// DOPO (diretto ECS - FUNZIONA)
final apiEndpoint = 'http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com';
```

## ⚠️ Differenze

| Feature | Con Lambda | Diretto ECS |
|---------|-----------|-------------|
| Routing intelligente | ✅ | ❌ |
| Auto-scaling | ✅ | ⚠️ Manuale |
| Costi | Lambda + ECS | Solo ECS |
| Latenza | +50-100ms | Diretta |
| Session management | ✅ | ❌ |

## 🎯 Test Rapido

```bash
# Test health
curl http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/health

# Test comando
curl -X POST http://warp-flutter-alb-1904513476.us-west-2.elb.amazonaws.com/execute-heavy \
  -H "Content-Type: application/json" \
  -d '{"command":"echo Hello","repository":"test"}'
```
