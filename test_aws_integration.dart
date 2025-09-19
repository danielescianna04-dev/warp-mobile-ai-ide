#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'lib/core/terminal/terminal_service.dart';
import 'lib/config/aws_config.dart';

Future<void> main() async {
  print('🚀 Testing Flutter App AWS Backend Integration');
  print('=' * 60);
  
  // Initialize Terminal Service
  final terminalService = TerminalService();
  
  // Test 1: Initialize AWS Session
  print('\n📋 Test 1: Initialize AWS Session');
  print('-' * 40);
  
  try {
    await terminalService.initialize(useRemoteTerminal: true);
    
    if (terminalService.isConnected) {
      print('✅ AWS session initialized successfully');
      print('🔗 Connected to: ${AWSConfig.apiBaseUrl}');
    } else {
      print('❌ Failed to initialize AWS session');
      return;
    }
  } catch (e) {
    print('❌ Session initialization error: $e');
    return;
  }
  
  // Test 2: Execute Light Commands (should go to Lambda)
  print('\n📋 Test 2: Light Commands (Lambda routing)');
  print('-' * 40);
  
  List<String> lightCommands = [
    'echo "Hello from AWS Lambda!"',
    'pwd',
    'whoami',
    'ls -la',
  ];
  
  for (String cmd in lightCommands) {
    print('\n> Executing: $cmd');
    try {
      final result = await terminalService.executeCommand(cmd);
      if (result.isSuccess) {
        print('✅ Success:');
        print(result.output);
      } else {
        print('❌ Failed:');
        print(result.output);
      }
    } catch (e) {
      print('❌ Command execution error: $e');
    }
    
    // Small delay between commands
    await Future.delayed(Duration(seconds: 1));
  }
  
  // Test 3: Execute Heavy Commands (should go to ECS)
  print('\n📋 Test 3: Heavy Commands (ECS routing)');
  print('-' * 40);
  
  List<String> heavyCommands = [
    'flutter --version',
    'python3 --version',
    'dart --version',
    'node --version',
  ];
  
  for (String cmd in heavyCommands) {
    print('\n> Executing: $cmd');
    try {
      final result = await terminalService.executeCommand(cmd);
      if (result.isSuccess) {
        print('✅ Success:');
        print(result.output);
      } else {
        print('❌ Failed:');
        print(result.output);
      }
    } catch (e) {
      print('❌ Command execution error: $e');
    }
    
    // Longer delay for heavy commands
    await Future.delayed(Duration(seconds: 2));
  }
  
  // Test 4: AI Chat (if available)
  print('\n📋 Test 4: AI Chat Integration');
  print('-' * 40);
  
  try {
    print('> Sending AI chat request...');
    
    // Listen to terminal output stream for AI responses
    final subscription = terminalOutputStreamController.stream.listen((result) {
      if (result.output.contains('🤖 AI:')) {
        print('✅ AI Response received:');
        print(result.output);
      }
    });
    
    await terminalService.sendAIChat(
      'Hello! Can you help me understand what Flutter commands I can run?',
      model: 'gpt-4',
      temperature: 0.7,
    );
    
    // Wait for response
    await Future.delayed(Duration(seconds: 5));
    subscription.cancel();
    
  } catch (e) {
    print('❌ AI chat error: $e');
  }
  
  // Test 5: Configuration Validation
  print('\n📋 Test 5: Configuration Validation');
  print('-' * 40);
  
  print('✅ AWS Configuration:');
  print('   - API Base URL: ${AWSConfig.apiBaseUrl}');
  print('   - Use AWS: ${AWSConfig.useAWS}');
  print('   - Environment: ${AWSConfig.environment}');
  print('   - Session Timeout: ${AWSConfig.sessionTimeout.inHours}h');
  print('   - Command Timeout: ${AWSConfig.commandTimeout.inMinutes}min');
  
  print('✅ Terminal Service Status:');
  print('   - Remote Mode: ${terminalService.isRemoteMode}');
  print('   - Connected: ${terminalService.isConnected}');
  print('   - Current Directory: ${terminalService.currentDirectory}');
  print('   - Has Web Server: ${terminalService.hasWebServerRunning}');
  
  if (terminalService.exposedPorts.isNotEmpty) {
    print('✅ Exposed Ports:');
    terminalService.exposedPorts.forEach((port, url) {
      print('   - $port: $url');
    });
  }
  
  // Clean up
  print('\n🧹 Cleaning up...');
  terminalService.dispose();
  
  print('\n🎉 AWS Integration Test Completed!');
  print('=' * 60);
}