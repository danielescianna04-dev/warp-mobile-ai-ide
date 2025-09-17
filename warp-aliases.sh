# Warp Mobile AI IDE - Quick Aliases
# Add these to your ~/.zshrc file

# Project navigation
alias warp-root='cd /Users/getmad/Projects/warp-mobile-ai-ide'
alias warp-backend='cd /Users/getmad/Projects/warp-mobile-ai-ide/backend'
alias warp-unsplash='cd /Users/getmad/Projects/warp-mobile-ai-ide/unsplash-gallery'

# Service management
alias warp-start='cd /Users/getmad/Projects/warp-mobile-ai-ide && ./start-all.sh'
alias warp-stop='cd /Users/getmad/Projects/warp-mobile-ai-ide && ./stop-all.sh'

# Development shortcuts
alias warp-dev-backend='warp-backend && npm run dev'
alias warp-dev-react='warp-unsplash && npm run dev'
alias warp-dev-flutter='warp-root && flutter run'

# Log viewing
alias warp-logs-backend='tail -f /Users/getmad/Projects/warp-mobile-ai-ide/logs/backend.log'
alias warp-logs-react='tail -f /Users/getmad/Projects/warp-mobile-ai-ide/logs/unsplash.log'

# Quick status check
alias warp-status='lsof -i :3001,:5173,:5174 | grep LISTEN'

echo "🚀 Warp aliases loaded!"
echo "Available commands: warp-start, warp-stop, warp-dev-*, warp-logs-*"