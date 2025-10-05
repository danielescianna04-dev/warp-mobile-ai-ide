import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _selectedModel = 'auto'; // Solo AI mode nella preview
  bool _isSelectingElements = false; // Modalità selezione elementi UI
  List<Map<String, dynamic>> _selectedElements = []; // Elementi UI selezionati
  
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
  
  void _initializeWebView() async {
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
      );
    
    // Check if it's a local asset
    if (widget.url.startsWith('asset:')) {
      final assetPath = widget.url.substring(6); // Remove 'asset:' prefix
      try {
        final htmlContent = await rootBundle.loadString(assetPath);
        await _webViewController.loadHtmlString(
          htmlContent,
          baseUrl: 'about:blank',
        );
      } catch (e) {
        print('Error loading asset: $e');
        await _webViewController.loadHtmlString(
          '<html><body><h1>Errore caricamento demo</h1><p>$e</p></body></html>',
        );
      }
    } else {
      await _webViewController.loadRequest(Uri.parse(widget.url));
    }
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
    
    String contextInfo = '';
    if (_selectedElements.isNotEmpty) {
      final elementNames = _selectedElements.map((e) => e['name']).join(', ');
      contextInfo = ' (${_selectedElements.length} elementi: $elementNames)';
    }
    
    // TODO: Integrate with AI for real-time modifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Richiesta AI: $command$contextInfo'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
    
    _inputController.clear();
    
    // Auto-reload dopo comando (simulato)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _refreshWebView();
      }
    });
  }
  
  void _toggleElementSelection() {
    setState(() {
      _isSelectingElements = !_isSelectingElements;
      if (!_isSelectingElements) {
        // Esci dalla modalità selezione
        _selectedElements.clear();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSelectingElements 
              ? '🎯 Clicca sugli elementi nella preview da modificare'
              : '✅ Modalità selezione disattivata',
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Inject JavaScript per abilitare la selezione elementi
    if (_isSelectingElements) {
      _injectSelectionScript();
    } else {
      _removeSelectionScript();
    }
  }
  
  void _injectSelectionScript() {
    // JavaScript per evidenziare elementi al hover e catturare i click
    final script = '''
      (function() {
        window.selectedElements = [];
        
        document.body.style.cursor = 'crosshair';
        
        function highlightElement(e) {
          e.target.style.outline = '2px solid #6366f1';
          e.target.style.outlineOffset = '2px';
        }
        
        function unhighlightElement(e) {
          if (!e.target.classList.contains('warp-selected')) {
            e.target.style.outline = '';
          }
        }
        
        function selectElement(e) {
          e.preventDefault();
          e.stopPropagation();
          
          const element = e.target;
          const tagName = element.tagName.toLowerCase();
          const className = element.className || 'no-class';
          const id = element.id || 'no-id';
          
          if (element.classList.contains('warp-selected')) {
            element.classList.remove('warp-selected');
            element.style.outline = '';
            element.style.backgroundColor = '';
          } else {
            element.classList.add('warp-selected');
            element.style.outline = '3px solid #6366f1';
            element.style.backgroundColor = 'rgba(99, 102, 241, 0.1)';
          }
          
          window.parent.postMessage({
            type: 'elementSelected',
            element: { tagName, className, id }
          }, '*');
        }
        
        document.addEventListener('mouseover', highlightElement, true);
        document.addEventListener('mouseout', unhighlightElement, true);
        document.addEventListener('click', selectElement, true);
        
        window.warpCleanup = function() {
          document.body.style.cursor = '';
          document.removeEventListener('mouseover', highlightElement, true);
          document.removeEventListener('mouseout', unhighlightElement, true);
          document.removeEventListener('click', selectElement, true);
          
          document.querySelectorAll('.warp-selected').forEach(el => {
            el.classList.remove('warp-selected');
            el.style.outline = '';
            el.style.backgroundColor = '';
          });
        };
      })();
    ''';
    
    _webViewController.runJavaScript(script);
  }
  
  void _removeSelectionScript() {
    _webViewController.runJavaScript('if (window.warpCleanup) window.warpCleanup();');
  }
  
  
  void _showModelSelector() {
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seleziona Modello AI',
              style: TextStyle(
                color: AppColors.titleText(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildModelOption('auto', 'Auto', 'Selezione automatica', brightness),
            _buildModelOption('claude', 'Claude', 'Anthropic Claude', brightness),
            _buildModelOption('gpt', 'GPT-4', 'OpenAI GPT-4', brightness),
            _buildModelOption('gemini', 'Gemini', 'Google Gemini', brightness),
          ],
        ),
      ),
    );
  }
  
  void _showSelectedElements() {
    if (_selectedElements.isEmpty) return;
    
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Elementi Selezionati',
                    style: TextStyle(
                      color: AppColors.titleText(brightness),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedElements.clear();
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancella',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._selectedElements.map((element) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.widgets_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      element['name'],
                      style: TextStyle(
                        color: AppColors.titleText(brightness),
                        fontSize: 14,
                        fontFamily: 'SF Mono',
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  
  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.dart')) return Icons.code;
    if (filename.endsWith('.yaml') || filename.endsWith('.yml')) return Icons.settings;
    if (filename.endsWith('.md')) return Icons.description;
    if (filename.endsWith('.json')) return Icons.data_object;
    return Icons.insert_drive_file;
  }
  
  Widget _buildModelOption(String value, String label, String description, Brightness brightness) {
    final isSelected = _selectedModel == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedModel = value;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🤖 Modello: $label'),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border(brightness).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.bodyText(brightness),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.titleText(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.bodyText(brightness),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildModelSelector() {
    final brightness = Theme.of(context).brightness;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Element selector button - modalità point & click
        GestureDetector(
          onTap: _toggleElementSelection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isSelectingElements
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (brightness == Brightness.dark
                      ? const Color(0xFF3a3a3a).withValues(alpha: 0.6)
                      : const Color(0xFFcccccc).withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(8),
              border: _isSelectingElements
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : Border.all(
                      color: brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSelectingElements 
                      ? Icons.touch_app_rounded
                      : Icons.touch_app_outlined,
                  size: 14,
                  color: _isSelectingElements
                      ? AppColors.primary
                      : AppColors.bodyText(brightness),
                ),
                if (_selectedElements.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedElements.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Model selector
        GestureDetector(
          onTap: _showModelSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? const Color(0xFF3a3a3a).withValues(alpha: 0.6)
                  : const Color(0xFFcccccc).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedModel == 'auto' ? 'Auto' : _selectedModel.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.titleText(brightness),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.bodyText(brightness),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildToolsButton() {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📎 Funzione attach file in arrivo...'),
            duration: Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF3a3a3a).withValues(alpha: 0.6)
              : const Color(0xFFcccccc).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add,
          color: AppColors.bodyText(brightness),
          size: 20,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          // WebView fullscreen
          Column(
            children: [
              // Custom AppBar with glassmorphism
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brightness == Brightness.dark
                          ? const Color(0xFF1a1a2e).withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      brightness == Brightness.dark
                          ? const Color(0xFF0f0f1e).withValues(alpha: 0.95)
                          : const Color(0xFFF8F9FF).withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface(brightness).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border(brightness).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.titleText(brightness),
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title with icon
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.2),
                                          AppColors.primary.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.visibility_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Preview Live',
                                    style: TextStyle(
                                      color: AppColors.titleText(brightness),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isSelectingElements ? '🎯 Seleziona elementi' : '🎨 Modifica con AI',
                                style: TextStyle(
                                  color: AppColors.bodyText(brightness).withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Refresh button
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface(brightness).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border(brightness).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: AppColors.bodyText(brightness),
                                size: 20,
                              ),
                              onPressed: _refreshWebView,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              tooltip: 'Ricarica',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // WebView fullscreen
              Expanded(
                child: Stack(
                  children: [
                    // WebView senza margini
                    WebViewWidget(
                      controller: _webViewController,
                    ),
                    // Selection mode indicator
                    if (_isSelectingElements)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Modalità Selezione',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_selectedElements.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_selectedElements.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Floating input box con blur
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: TerminalInputBox(
              controller: _inputController,
              focusNode: _inputFocus,
              hintText: 'Chiedi all\'AI di modificare...',
              showModeToggle: false,
              showModelSelector: true,
              isTerminalMode: false,
              useSyntaxHighlighting: false,
              useTransparentStyle: true, // Colori trasparenti grigiastri
              onSend: _sendCommand,
              modelSelector: _buildModelSelector(),
              toolsButton: _buildToolsButton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
