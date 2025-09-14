# 🏗️ Architecture

## Overview

Warp Mobile AI IDE follows a clean architecture pattern with clear separation of concerns, leveraging Flutter's reactive programming model and dependency injection for scalability and maintainability.

## Core Principles

- **Mobile-First**: Every component designed with mobile constraints and opportunities in mind
- **Modular**: Feature-based architecture for independent development and testing
- **Reactive**: Event-driven architecture using streams and state management
- **Extensible**: Plugin-based AI integration for easy model addition/removal
- **Offline-Capable**: Graceful degradation when network is unavailable

## Architecture Layers

### 1. Presentation Layer (`lib/features/`)
- **Responsibility**: UI components, user interactions, state management
- **Technologies**: Flutter Widgets, Provider/Bloc for state management
- **Structure**:
  ```
  features/
  ├── editor/
  │   ├── presentation/
  │   │   ├── pages/
  │   │   ├── widgets/
  │   │   └── providers/
  │   └── data/
  ├── terminal/
  ├── preview/
  └── collaboration/
  ```

### 2. Domain Layer (`lib/core/`)
- **Responsibility**: Business logic, use cases, domain entities
- **Technologies**: Pure Dart classes, abstract interfaces
- **Components**:
  - **AI Service**: Abstract interface for multi-model AI integration
  - **GitHub Service**: Repository operations and collaboration
  - **Terminal Engine**: Command processing and execution
  - **Code Analysis**: Syntax highlighting, error detection

### 3. Data Layer (`lib/core/*/repositories/`)
- **Responsibility**: Data persistence, API communication, caching
- **Technologies**: HTTP clients, local storage (SQLite/Hive), secure storage
- **Components**:
  - **AI Repository**: Manages AI model communications
  - **GitHub Repository**: Handles Git operations and GitHub API
  - **Settings Repository**: User preferences and configuration
  - **Project Repository**: Local project management

## AI Integration Architecture

### Multi-Model Support
```dart
abstract class AIService {
  Future<String> generateCode(String prompt, String context);
  Future<String> explainCode(String code);
  Future<String> debugCode(String code, String error);
  Stream<String> streamCompletion(String prompt);
}

class AIServiceFactory {
  static AIService create(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return OpenAIService();
      case AIProvider.claude:
        return ClaudeService();
      case AIProvider.gemini:
        return GeminiService();
      case AIProvider.onDevice:
        return OnDeviceAIService();
    }
  }
}
```

### On-Device AI Integration
- **TensorFlow Lite Flutter**: For quantized models
- **ONNX Runtime**: Cross-platform inference
- **Model Management**: Dynamic model downloading and caching
- **Fallback Strategy**: Cloud → Edge → Offline modes

## Terminal Architecture

### Command Processing Pipeline
1. **Input Parsing**: Command tokenization and validation
2. **Context Analysis**: Current directory, git state, project type
3. **AI Enhancement**: Command suggestion and auto-completion
4. **Execution**: Native shell integration with sandboxing
5. **Output Processing**: Syntax highlighting and formatting

### Virtual File System
- **Abstraction Layer**: Unified interface for local and remote files
- **Caching Strategy**: Intelligent caching for frequently accessed files
- **Sync Manager**: Real-time synchronization with remote repositories

## State Management

### Global State (Provider Pattern)
- **AppState**: Global app configuration and user session
- **ProjectState**: Current project context and metadata
- **AIState**: AI model selection and conversation history
- **ThemeState**: UI theme and personalization

### Feature State (Bloc Pattern)
- **EditorBloc**: File editing, syntax highlighting, code completion
- **TerminalBloc**: Command history, session management
- **PreviewBloc**: App preview and hot-reload state
- **GitBloc**: Version control operations and status

## Security Architecture

### API Key Management
- **Secure Storage**: Platform-specific secure storage for API keys
- **Key Rotation**: Automatic key refresh and validation
- **Permissions**: Granular permissions for different AI services

### Code Security
- **Sandboxing**: Limited execution environment for terminal commands
- **Input Validation**: Comprehensive input sanitization
- **Privacy**: Local processing preference, data anonymization

## Performance Optimizations

### Mobile-Specific Optimizations
- **Lazy Loading**: Load features and AI models on-demand
- **Memory Management**: Intelligent caching and cleanup
- **Battery Optimization**: Background processing limitations
- **Network Efficiency**: Request batching and compression

### Code Editor Performance
- **Virtual Scrolling**: Efficient rendering of large files
- **Incremental Parsing**: Only reparse modified code sections
- **Syntax Highlighting**: Worker isolates for heavy processing

## Offline Capabilities

### Local-First Architecture
- **Conflict Resolution**: Smart merge strategies for offline changes
- **Queue Management**: Action queuing for when connectivity returns
- **Progressive Sync**: Incremental synchronization of changes

### On-Device Features
- **Local AI Models**: Basic code completion and analysis
- **Project Management**: Full project operations without network
- **Terminal Emulation**: Native command execution

## Testing Strategy

### Testing Pyramid
- **Unit Tests**: Core business logic and utilities (70%)
- **Integration Tests**: Service interactions and data flow (20%)
- **Widget Tests**: UI components and user interactions (10%)

### AI Testing
- **Mock AI Services**: Deterministic responses for testing
- **Response Validation**: Output quality and safety checks
- **Performance Benchmarks**: Latency and accuracy metrics

## Deployment Architecture

### CI/CD Pipeline
- **GitHub Actions**: Automated testing and building
- **CodeMagic**: Mobile-specific build optimizations
- **Firebase**: Crash reporting and analytics

### Distribution Strategy
- **App Stores**: Primary distribution via iOS App Store and Google Play
- **Beta Testing**: TestFlight and Firebase App Distribution
- **Feature Flags**: Gradual feature rollout and A/B testing

## Scalability Considerations

### Horizontal Scaling
- **Microservices**: Independent AI service scaling
- **CDN**: Global asset distribution
- **Caching**: Multi-layer caching strategy

### Vertical Scaling
- **Resource Management**: Dynamic resource allocation
- **Load Balancing**: AI request distribution
- **Database Optimization**: Efficient query patterns

## Future Architecture Evolution

### Planned Enhancements
- **WebAssembly Integration**: Browser-based development environment
- **Cloud IDE Sync**: Seamless desktop ↔ mobile synchronization
- **Collaborative Editing**: Real-time multi-user editing
- **AI Model Training**: Custom model fine-tuning capabilities

### Technology Roadmap
- **Flutter 3.x**: Latest Flutter features and performance improvements
- **Dart 3.x**: Enhanced language features and null safety
- **Advanced AI**: GPT-4+ integration, specialized coding models
- **AR/VR Support**: Immersive development experiences