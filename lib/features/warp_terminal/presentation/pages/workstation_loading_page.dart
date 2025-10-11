import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../core/workstation/workstation_service.dart';

class WorkstationLoadingPage extends StatefulWidget {
  final String repositoryName;
  final String repositoryUrl;
  final String userId;
  
  const WorkstationLoadingPage({
    super.key,
    required this.repositoryName,
    required this.repositoryUrl,
    required this.userId,
  });

  @override
  State<WorkstationLoadingPage> createState() => _WorkstationLoadingPageState();
}

class _WorkstationLoadingPageState extends State<WorkstationLoadingPage> with SingleTickerProviderStateMixin {
  int _progress = 0;
  int _elapsed = 0;
  Timer? _elapsedTimer;
  String _status = 'Inizializzazione...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _elapsed++;
        });
      }
    });
    
    _initWorkspace();
  }
  
  Future<void> _initWorkspace() async {
    try {
      setState(() {
        _status = 'Verifica workspace esistente...';
        _progress = 10;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _status = 'Clonazione repository...';
        _progress = 20;
      });
      
      // Start periodic status updates
      Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted || _progress >= 90) {
          timer.cancel();
          return;
        }
        
        setState(() {
          if (_progress < 30) {
            _status = 'Download file da GitHub...';
            _progress = 30;
          } else if (_progress < 50) {
            _status = 'Caricamento su Cloud Storage...';
            _progress = 50;
          } else if (_progress < 70) {
            _status = 'Sincronizzazione file...';
            _progress = 70;
          } else if (_progress < 90) {
            _status = 'Finalizzazione workspace...';
            _progress = 85;
          }
        });
      });
      
      await WorkstationService.initWorkspace(
        userId: widget.userId,
        repoUrl: widget.repositoryUrl,
        repoName: widget.repositoryName,
      );
      
      setState(() {
        _progress = 90;
        _status = 'Analisi progetto...';
      });
      
      // Analyze project for missing files
      await WorkstationService.analyzeWorkspace(
        userId: widget.userId,
        repoName: widget.repositoryName,
      );
      
      setState(() {
        _progress = 100;
        _status = 'Pronto!';
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pop(context, true);
      }
      
      // Analyze in background after navigation
      WorkstationService.analyzeWorkspace(
        userId: widget.userId,
        repoName: widget.repositoryName,
      ).catchError((e) {
        print('⚠️ Background analysis error: $e');
      });
    } catch (e) {
      setState(() {
        _status = 'Errore: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}';
        _progress = 0;
      });
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }
  
  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.background(brightness),
                  AppColors.violetLight.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.violetLight,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cloud_done_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Preparazione Workspace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.repositoryName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  Container(
                    width: size.width * 0.85,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.border(brightness),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _progress == 100 ? Colors.green : AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (_progress > 0) ...[
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.background(brightness),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: _progress / 100,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.violetLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_progress%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ] else
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(_elapsed / 10).toStringAsFixed(1)}s',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _progress == 100
                        ? '✨ Workspace pronto per l\'uso!'
                        : 'Configurazione istantanea con Cloud Run...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
