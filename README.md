# 📱 Warp Mobile AI IDE

> **Mobile-first AI IDE bringing Warp + multi-model AI to iPhone and Android**

Develop, test, and collaborate entirely from your phone. No more desktop constraints – code anywhere, anytime.

## 🌍 Vision

Portare la potenza di Warp + AI multimodello direttamente su iPhone e Android, permettendo agli sviluppatori di programmare, testare e collaborare interamente dal telefone.

## 🔑 The Problem

Current AI IDEs and terminals are desktop-first (Warp, VS Code + Copilot, Cursor). Mobile lacks a fluid experience for:

- ✍️ AI-assisted code writing
- 🤖 Multi-model AI support (ChatGPT, Claude, Gemini)
- 🔗 Natural GitHub integration
- 📱 Native mobile app testing

Existing tools like Replit, StackBlitz, or FlutterFlow have mobile versions but aren't mobile-native and lack Warp-like workflow.

## 💡 Solution

A mobile-first AI IDE combining:

### 🖥️ Warp-Style Terminal
- Intelligent command completion
- AI-powered prompt assistance
- Code refactoring, debugging, and explanations
- Multi-language support (Flutter/Dart, C, C#, Python, JS...)

### 🤖 Multi-AI Integration
- User choice between ChatGPT, Claude, Gemini
- Fallback to free on-device models
- Freemium model: limited free prompts, unlimited with subscription

### 📱 Native Mobile Preview
- Flutter development with in-device testing
- Hot-reload experience
- Real-time preview

### 🔗 Native GitHub Integration
- Clone repos, manage branches, commit, create PRs
- AI-generated visual diffs
- Mobile-first collaboration

### 📲 Mobile-Optimized UX
- Touch-optimized UI (swipe, snippet cards, drag&drop code blocks)
- Offline support with lightweight models
- No connectivity blockers

## ⚙️ Tech Stack

- **Flutter** - Cross-platform, powerful UI, in-device preview
- **AI Integration**:
  - Cloud APIs (OpenAI, Anthropic, Google)
  - On-device LLM (LLaMA, Mistral small, quantized with tflite_flutter or llama.cpp)
- **GitHub API** - Repository, branch, commit, PR management
- **Cloud Build Services** - Codemagic, Firebase for automated testing and deployment

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Xcode (for iOS development)
- Android Studio (for Android development)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/warp-mobile-ai-ide.git
cd warp-mobile-ai-ide

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Development

```bash
# Run tests
flutter test

# Build for iOS
flutter build ios

# Build for Android
flutter build apk
```

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── ai/                 # AI service abstractions
│   ├── github/             # GitHub integration
│   └── terminal/           # Terminal emulation
├── features/
│   ├── editor/             # Code editor
│   ├── terminal/           # Terminal interface
│   ├── preview/            # App preview
│   └── collaboration/      # GitHub/collaboration features
└── shared/
    ├── widgets/            # Reusable UI components
    ├── utils/              # Utilities
    └── constants/          # App constants
```

## 🛣️ Roadmap

See [ROADMAP.md](ROADMAP.md) for detailed development phases and milestones.

## 🏗️ Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for technical design decisions and patterns.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
