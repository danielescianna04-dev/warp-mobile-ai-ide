#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'lib/core/terminal/terminal_service.dart';
import 'lib/config/aws_config.dart';

Future<void> main() async {
  print('🚀 Testing ECS Fargate - Heavy Commands');
  print('=' * 60);
  
  final terminalService = TerminalService();
  
  try {
    await terminalService.initialize(useRemoteTerminal: true);
    
    if (!terminalService.isConnected) {
      print('❌ Failed to initialize AWS session');
      return;
    }
    
    print('✅ AWS session initialized');
    print('🔗 Connected to: ${AWSConfig.apiBaseUrl}');
    
    // Test heavy commands that should go to ECS
    List<String> heavyCommands = [
      'flutter --version',
      'python3 --version',
      'dart --version',
      'node --version',
      'npm --version',
    ];
    
    for (String cmd in heavyCommands) {
      print('\n🎯 Testing: $cmd');
      print('-' * 40);
      
      try {
        final result = await terminalService.executeCommand(cmd);
        if (result.isSuccess) {
          print('✅ SUCCESS');
          // Show execution details
          final lines = result.output.split('\n');
          for (String line in lines) {
            if (line.contains('Executed on') || line.contains('Smart Routing')) {
              print('🚀 $line');
            } else if (line.isNotEmpty && !line.startsWith('\n')) {
              // Show first few lines of output
              if (lines.indexOf(line) < 3) {
                print('📋 $line');
              }
            }
          }
        } else {
          print('❌ FAILED');
          print('📋 Error: ${result.output}');
        }
      } catch (e) {
        print('❌ EXCEPTION: $e');
      }
      
      // Wait between commands
      await Future.delayed(Duration(seconds: 2));
    }
    
    // Test if we can detect ECS execution
    print('\n🎯 ECS Detection Test');
    print('-' * 40);
    
    final result = await terminalService.executeCommand('echo "Testing ECS Fargate execution"');
    if (result.output.contains('ECS Fargate')) {
      print('✅ ECS Fargate detected in output');
    } else if (result.output.contains('AWS Lambda')) {
      print('⚡ Command executed on Lambda (light command)');
    }
    
  } catch (e) {
    print('❌ Test error: $e');
  } finally {
    terminalService.dispose();
  }
  
  print('\n🎉 ECS Fargate Test Completed!');
  print('=' * 60);
}