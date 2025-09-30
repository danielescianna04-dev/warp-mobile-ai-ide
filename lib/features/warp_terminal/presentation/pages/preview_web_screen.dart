import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }
  
  void _refreshWebView() {
    setState(() {
      _isLoading = true;
    });
    _webViewController.reload();
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
          // URL bar minimal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFF5F5F5),
              border: Border(
                bottom: BorderSide(
                  color: brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE5E5E5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: AppColors.bodyText(brightness).withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUrl ?? widget.url,
                    style: TextStyle(
                      color: AppColors.bodyText(brightness),
                      fontSize: 12,
                      fontFamily: 'SF Mono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
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
            showModeToggle: false,
            showModelSelector: false,
            onSend: _sendCommand,
          ),
        ],
      ),
    );
  }
}
