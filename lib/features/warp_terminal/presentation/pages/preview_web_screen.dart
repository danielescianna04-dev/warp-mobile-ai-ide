import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/constants/app_colors.dart';
import '../widgets/terminal_input_box.dart';

class PreviewWebScreen extends StatefulWidget {
  final String url;
  
  const PreviewWebScreen({super.key, required this.url});
  
  @override
  State<PreviewWebScreen> createState() => _PreviewWebScreenState();
}

class _PreviewWebScreenState extends State<PreviewWebScreen> {
  late final WebViewController _webViewController;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  bool _isLoading = true;
  String? _currentUrl;
  bool _editMode = false;
  
  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _initializeWebView();
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }
  
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            print('🔍 Navigation request: ${request.url}');
            // Intercept element click messages
            if (request.url.startsWith('flutter://element-clicked')) {
              print('✅ Intercepting element click');
              final parts = request.url.split('?');
              if (parts.length > 1) {
                final encoded = parts[1];
                final decoded = Uri.decodeComponent(encoded);
                print('📦 Decoded data: $decoded');
                _handleElementClick(decoded);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('🌐 WebView loading: $url');
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            print('✅ WebView loaded: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Re-inject edit mode if active
            if (_editMode) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _toggleEditMode();
                setState(() {
                  _editMode = true;
                });
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description} (${error.errorCode})');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url.endsWith('/') ? widget.url : '${widget.url}/'));
  }
  
  void _handleElementClick(String jsonMessage) {
    print('🎯 Element clicked: $jsonMessage');
    
    // Parse and format element info
    try {
      final info = jsonMessage;
      _inputController.text = 'Modifica questo elemento:\n$info';
      _inputFocus.requestFocus();
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Elemento selezionato! Descrivi la modifica...'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      print('Error parsing element info: $e');
    }
  }
  
  void _refreshWebView() {
    setState(() {
      _isLoading = true;
    });
    _webViewController.reload();
  }
  
  void _toggleEditMode() async {
    setState(() {
      _editMode = !_editMode;
    });
    
    if (_editMode) {
      // Inject beautiful Edit Mode UI
      await _webViewController.runJavaScript('''
        (function() {
          if (window.__editModeActive) return;
          window.__editModeActive = true;
          
          // Add animated gradient overlay
          const overlay = document.createElement('div');
          overlay.id = '__edit_mode_overlay';
          overlay.style.cssText = `
            position: fixed; 
            top: 0; 
            left: 0; 
            right: 0; 
            bottom: 0; 
            background: linear-gradient(135deg, rgba(59, 130, 246, 0.08) 0%, rgba(147, 51, 234, 0.08) 100%);
            backdrop-filter: blur(2px);
            pointer-events: none; 
            z-index: 999998;
            animation: fadeIn 0.3s ease-out;
          `;
          document.body.appendChild(overlay);
          
          // Add floating banner with animation
          const banner = document.createElement('div');
          banner.id = '__edit_mode_banner';
          banner.style.cssText = `
            position: fixed; 
            top: 20px; 
            left: 50%; 
            transform: translateX(-50%) translateY(-10px);
            background: linear-gradient(135deg, #3B82F6 0%, #8B5CF6 100%);
            color: white; 
            padding: 12px 24px; 
            border-radius: 30px; 
            font-size: 15px; 
            font-weight: 600; 
            z-index: 1000000; 
            box-shadow: 0 8px 32px rgba(59, 130, 246, 0.4), 0 2px 8px rgba(0,0,0,0.1);
            animation: slideDown 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
            display: flex;
            align-items: center;
            gap: 8px;
          `;
          banner.innerHTML = '<span style="font-size: 18px;">✨</span> Edit Mode Attivo - Tocca un elemento';
          document.body.appendChild(banner);
          
          // Add CSS animations
          const style = document.createElement('style');
          style.textContent = \`
            @keyframes fadeIn {
              from { opacity: 0; }
              to { opacity: 1; }
            }
            @keyframes slideDown {
              from { 
                opacity: 0;
                transform: translateX(-50%) translateY(-30px);
              }
              to { 
                opacity: 1;
                transform: translateX(-50%) translateY(0);
              }
            }
            @keyframes pulse {
              0%, 100% { box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.7); }
              50% { box-shadow: 0 0 0 8px rgba(59, 130, 246, 0); }
            }
            .__edit_highlight {
              outline: 3px solid #3B82F6 !important;
              outline-offset: 2px !important;
              background: rgba(59, 130, 246, 0.05) !important;
              cursor: pointer !important;
              transition: all 0.2s ease !important;
              position: relative !important;
            }
            .__edit_highlight::before {
              content: '';
              position: absolute;
              top: -3px;
              left: -3px;
              right: -3px;
              bottom: -3px;
              border-radius: 4px;
              animation: pulse 2s infinite;
              pointer-events: none;
            }
          \`;
          document.head.appendChild(style);
          
          // Highlight on hover with smooth transition
          let lastHighlighted = null;
          document.addEventListener('mouseover', function(e) {
            if (lastHighlighted) {
              lastHighlighted.classList.remove('__edit_highlight');
            }
            e.target.classList.add('__edit_highlight');
            lastHighlighted = e.target;
          }, true);
          
          document.addEventListener('mouseout', function(e) {
            e.target.classList.remove('__edit_highlight');
          }, true);
          
          // Handle clicks with visual feedback
          document.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            const el = e.target;
            
            // Add click animation
            el.style.transform = 'scale(0.98)';
            setTimeout(() => el.style.transform = '', 200);
            
            const rect = el.getBoundingClientRect();
            const info = {
              tag: el.tagName.toLowerCase(),
              id: el.id || 'nessun id',
              classes: el.className.replace('__edit_highlight', '').trim() || 'nessuna classe',
              text: (el.innerText || el.textContent || '').substring(0, 100),
              width: Math.round(rect.width),
              height: Math.round(rect.height)
            };
            
            // Visual feedback
            const feedback = document.createElement('div');
            feedback.style.cssText = \`
              position: fixed;
              top: \${e.clientY}px;
              left: \${e.clientX}px;
              background: #3B82F6;
              color: white;
              padding: 8px 16px;
              border-radius: 20px;
              font-size: 13px;
              font-weight: 600;
              z-index: 1000001;
              pointer-events: none;
              animation: fadeOut 1s ease-out forwards;
              box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
            \`;
            feedback.textContent = '✓ Selezionato';
            document.body.appendChild(feedback);
            setTimeout(() => feedback.remove(), 1000);
            
            const styleAnim = document.createElement('style');
            styleAnim.textContent = '@keyframes fadeOut { to { opacity: 0; transform: translateY(-20px); } }';
            document.head.appendChild(styleAnim);
            
            // Send to Flutter
            const message = JSON.stringify(info);
            window.location.href = 'flutter://element-clicked?' + encodeURIComponent(message);
          }, true);
        })();
      ''');
    } else {
      // Remove edit mode with fade out
      await _webViewController.runJavaScript('''
        if (window.__editModeActive) {
          window.__editModeActive = false;
          const overlay = document.getElementById('__edit_mode_overlay');
          const banner = document.getElementById('__edit_mode_banner');
          if (overlay) {
            overlay.style.animation = 'fadeOut 0.3s ease-out';
            setTimeout(() => overlay.remove(), 300);
          }
          if (banner) {
            banner.style.animation = 'fadeOut 0.3s ease-out';
            setTimeout(() => banner.remove(), 300);
          }
        }
      ''');
      Future.delayed(const Duration(milliseconds: 400), () {
        _webViewController.reload();
      });
    }
  }
  
  void _sendCommand() {
    final command = _inputController.text.trim();
    if (command.isEmpty) return;
    
    // TODO: Integrate with AI for real-time modifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Command: $command'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    _inputController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF0D0D0D)
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.titleText(brightness),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Preview Flutter Web',
          style: TextStyle(
            color: AppColors.titleText(brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final Uri url = Uri.parse(widget.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(
              Icons.open_in_browser_rounded,
              color: AppColors.bodyText(brightness),
            ),
            tooltip: 'Apri in Safari',
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _refreshWebView,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.bodyText(brightness),
              ),
              tooltip: 'Ricarica',
            ),
        ],
      ),
      body: Column(
        children: [
          // WebView
          Expanded(
            child: WebViewWidget(
              controller: _webViewController,
            ),
          ),
          
          // Input box condiviso con terminal page
          TerminalInputBox(
            controller: _inputController,
            focusNode: _inputFocus,
            hintText: 'Modifica al volo con AI...',
            showModeToggle: true,
            showModelSelector: true,
            useSyntaxHighlighting: false,
            onSend: _sendCommand,
            onEditMode: _toggleEditMode,
          ),
        ],
      ),
    );
  }
}
