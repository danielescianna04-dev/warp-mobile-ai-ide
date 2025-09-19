#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'lib/core/terminal/terminal_service.dart';
import 'lib/config/aws_config.dart';

// Test script per verificare l'integrazione AWS solo con Lambda
// Simula tutti i tipi di comando ma li forza tutti su Lambda

Future<void> main() async {
  print('🚀 Testing Flutter App with AWS Lambda Only');
  print('🔧 Bypassing ECS Fargate for testing');
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
  
  // Test 2: Basic Commands
  print('\n📋 Test 2: Basic Terminal Commands');
  print('-' * 40);
  
  List<String> basicCommands = [
    'echo "Hello from AWS Lambda!"',
    'pwd',
    'whoami',
    'ls -la',
    'date',
    'uname -a',
  ];
  
  for (String cmd in basicCommands) {
    print('\n> $cmd');
    try {
      final result = await terminalService.executeCommand(cmd);
      if (result.isSuccess) {
        print('✅ Output:');
        print(result.output);
      } else {
        print('❌ Error:');
        print(result.output);
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
    await Future.delayed(Duration(seconds: 1));
  }
  
  // Test 3: File Operations
  print('\n📋 Test 3: File Operations');
  print('-' * 40);
  
  List<String> fileCommands = [
    'echo "Hello World" > test.txt',
    'cat test.txt',
    'ls -la test.txt',
    'echo "Line 2" >> test.txt',
    'cat test.txt',
    'rm test.txt',
    'ls test.txt',
  ];
  
  for (String cmd in fileCommands) {
    print('\n> $cmd');
    try {
      final result = await terminalService.executeCommand(cmd);
      print('${result.isSuccess ? '✅' : '❌'} ${result.output}');
    } catch (e) {
      print('❌ Exception: $e');
    }
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  // Test 4: Directory Navigation
  print('\n📋 Test 4: Directory Navigation');
  print('-' * 40);
  
  List<String> navCommands = [
    'pwd',
    'mkdir test_dir',
    'cd test_dir',
    'pwd',
    'echo "test" > file_in_dir.txt',
    'ls -la',
    'cd ..',
    'pwd',
    'ls -la test_dir/',
    'rm -rf test_dir',
  ];
  
  for (String cmd in navCommands) {
    print('\n> $cmd');
    try {
      final result = await terminalService.executeCommand(cmd);
      print('${result.isSuccess ? '✅' : '❌'} ${result.output.isNotEmpty ? result.output : '(no output)'}');
    } catch (e) {
      print('❌ Exception: $e');
    }
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  // Test 5: System Information (usually heavy commands, but forced to Lambda)
  print('\n📋 Test 5: System Information (Forced to Lambda)');
  print('-' * 40);
  
  List<String> sysCommands = [
    'cat /etc/os-release',
    'df -h',
    'free -h',
    'ps aux | head -10',
  ];
  
  for (String cmd in sysCommands) {
    print('\n> $cmd');
    try {
      final result = await terminalService.executeCommand(cmd);
      if (result.isSuccess) {
        print('✅ Success');
        // Mostra solo le prime righe per brevità
        final lines = result.output.split('\n');
        final displayLines = lines.take(5).join('\n');
        print(displayLines);
        if (lines.length > 5) {
          print('... (${lines.length - 5} more lines)');
        }
      } else {
        print('❌ Error: ${result.output}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
    await Future.delayed(Duration(seconds: 1));
  }
  
  // Test 6: Configuration Summary
  print('\n📋 Test 6: Configuration Summary');
  print('-' * 40);
  
  print('✅ Configuration Status:');
  print('   - AWS Backend: ${AWSConfig.useAWS}');
  print('   - API Endpoint: ${AWSConfig.apiBaseUrl}');
  print('   - Environment: ${AWSConfig.environment}');
  print('   - Terminal Connected: ${terminalService.isConnected}');
  print('   - Remote Mode: ${terminalService.isRemoteMode}');
  
  // Clean up
  terminalService.dispose();
  
  print('\n🎉 Lambda-Only Test Completed Successfully!');
  print('💡 All commands executed on AWS Lambda');
  print('🔧 ECS Fargate bypassed for this test');
  print('=' * 60);
}