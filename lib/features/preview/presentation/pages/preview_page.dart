import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> with TickerProviderStateMixin {
  late TabController _previewTabController;
  String _selectedDevice = 'iPhone 15';
  bool _isRunning = false;

  final List<String> _availableDevices = [
    'iPhone 15',
    'iPhone 15 Pro',
    'iPad Pro',
    'Pixel 8',
    'Galaxy S24',
  ];

  @override
  void initState() {
    super.initState();
    _previewTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _previewTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        backgroundColor: AppColors.surface(brightness),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Device selector
          PopupMenuButton<String>(
            onSelected: (device) {
              setState(() {
                _selectedDevice = device;
              });
            },
            itemBuilder: (context) => _availableDevices.map((device) {
              return PopupMenuItem<String>(
                value: device,
                child: Row(
                  children: [
                    Icon(
                      device.toLowerCase().contains('iphone') || device.toLowerCase().contains('ipad') 
                        ? Icons.phone_iphone
                        : Icons.phone_android,
                      size: 16,
                      color: AppColors.bodyText(brightness),
                    ),
                    const SizedBox(width: 8),
                    Text(device),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant(brightness),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedDevice.toLowerCase().contains('iphone') || _selectedDevice.toLowerCase().contains('ipad')
                      ? Icons.phone_iphone
                      : Icons.phone_android,
                    size: 14,
                    color: AppColors.bodyText(brightness),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedDevice,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.bodyText(brightness),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: AppColors.bodyText(brightness),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // TODO: Preview settings
            },
            icon: Icon(Icons.settings, color: AppColors.bodyText(brightness)),
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _previewTabController,
          tabs: [
            Tab(text: 'App Preview'),
            Tab(text: 'Inspector'),
            Tab(text: 'Logs'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.bodyText(brightness),
        ),
      ),
      body: TabBarView(
        controller: _previewTabController,
        children: [
          _buildAppPreview(),
          _buildInspector(),
          _buildLogs(),
        ],
      ),
    );
  }

  Widget _buildAppPreview() {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        // Control bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface(brightness),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: _isRunning 
                    ? LinearGradient(colors: [AppColors.warning, AppColors.error])
                    : AppColors.heroGradient(brightness),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isRunning = !_isRunning;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isRunning ? '🚀 App started on $_selectedDevice' : '⏹️ App stopped',
                        ),
                        backgroundColor: _isRunning ? AppColors.success : AppColors.warning,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: Icon(
                    _isRunning ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _isRunning ? 'Stop' : 'Run',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _isRunning ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔥 Hot reload triggered'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                } : null,
                icon: Icon(
                  Icons.refresh,
                  color: _isRunning ? AppColors.warning : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                tooltip: 'Hot Reload',
              ),
              IconButton(
                onPressed: _isRunning ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Hot restart triggered'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                } : null,
                icon: Icon(
                  Icons.restart_alt,
                  color: _isRunning ? AppColors.info : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                tooltip: 'Hot Restart',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isRunning ? AppColors.success.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isRunning ? AppColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isRunning ? 'Running' : 'Stopped',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isRunning ? AppColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Preview area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: _getDeviceWidth(),
                height: _getDeviceHeight(),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isRunning 
                    ? _buildRunningApp()
                    : _buildStoppedState(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunningApp() {
    final brightness = Theme.of(context).brightness;
    return Container(
      color: AppColors.background(brightness),
      child: Column(
        children: [
          // Status bar simulation
          Container(
            height: 44,
            color: AppColors.surface(brightness),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '9:41',
                  style: TextStyle(
                    color: AppColors.titleText(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_4_bar, size: 16, color: AppColors.titleText(brightness)),
                    const SizedBox(width: 4),
                    Icon(Icons.wifi, size: 16, color: AppColors.titleText(brightness)),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full, size: 16, color: AppColors.titleText(brightness)),
                  ],
                ),
              ],
            ),
          ),
          // App content simulation
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // App bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient(brightness),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.code,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Warp Mobile AI IDE',
                          style: TextStyle(
                            color: AppColors.titleText(brightness),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content area
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.editorBackground(brightness),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.play_circle, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'App is running!',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Hot reload enabled 🔥',
                            style: TextStyle(color: AppColors.bodyText(brightness), fontSize: 12),
                          ),
                          Text(
                            '• AI assistance active 🤖',
                            style: TextStyle(color: AppColors.bodyText(brightness), fontSize: 12),
                          ),
                          Text(
                            '• Terminal connected 💻',
                            style: TextStyle(color: AppColors.bodyText(brightness), fontSize: 12),
                          ),
                          const Spacer(),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.heroGradient(brightness),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.smartphone,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Mobile Development\nMade Easy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.titleText(brightness),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom navigation simulation
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.code, color: AppColors.primary, size: 24),
                        Icon(Icons.terminal, color: AppColors.bodyText(brightness), size: 24),
                        Icon(Icons.phone_android, color: AppColors.bodyText(brightness), size: 24),
                        Icon(Icons.people, color: AppColors.bodyText(brightness), size: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoppedState() {
    final brightness = Theme.of(context).brightness;
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'App Preview',
              style: TextStyle(
                color: AppColors.bodyText(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press Run to start the app',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspector() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Widget Inspector',
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isRunning ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInspectorItem('MaterialApp', 0),
                  _buildInspectorItem('Scaffold', 1),
                  _buildInspectorItem('Column', 2),
                  _buildInspectorItem('AppBar', 3),
                  _buildInspectorItem('Container', 3),
                  _buildInspectorItem('Text', 4),
                  _buildInspectorItem('BottomNavigationBar', 2),
                ],
              ),
            ) : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.widgets,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start the app to inspect widgets',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorItem(String widgetName, int level) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: EdgeInsets.only(left: level * 16.0, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.chevron_right,
            size: 16,
            color: AppColors.bodyText(brightness),
          ),
          const SizedBox(width: 4),
          Text(
            widgetName,
            style: TextStyle(
              color: AppColors.titleText(brightness),
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debug Console',
                style: TextStyle(
                  color: AppColors.titleText(brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.clear, color: AppColors.bodyText(brightness)),
                tooltip: 'Clear logs',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: _isRunning ? ListView(
                children: [
                  _buildLogItem('🚀 Flutter app started', AppColors.success),
                  _buildLogItem('📱 Connected to $_selectedDevice', AppColors.info),
                  _buildLogItem('🔥 Hot reload enabled', AppColors.warning),
                  _buildLogItem('✅ Build completed successfully', AppColors.success),
                  _buildLogItem('💻 Debug mode active', AppColors.info),
                  _buildLogItem('📦 All dependencies loaded', AppColors.success),
                  _buildLogItem('🤖 AI assistant ready', AppColors.primary),
                  _buildLogItem('⚡ Performance monitoring active', AppColors.info),
                ],
              ) : Center(
                child: Text(
                  'No logs available. Start the app to see debug output.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String message, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${DateTime.now().toIso8601String().substring(11, 19)} $message',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  double _getDeviceWidth() {
    switch (_selectedDevice) {
      case 'iPhone 15':
      case 'iPhone 15 Pro':
        return 200;
      case 'iPad Pro':
        return 280;
      case 'Pixel 8':
      case 'Galaxy S24':
        return 210;
      default:
        return 200;
    }
  }

  double _getDeviceHeight() {
    switch (_selectedDevice) {
      case 'iPhone 15':
      case 'iPhone 15 Pro':
        return 400;
      case 'iPad Pro':
        return 360;
      case 'Pixel 8':
      case 'Galaxy S24':
        return 420;
      default:
        return 400;
    }
  }
}