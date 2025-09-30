import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

class GitHubRepository {
  final int id;
  final String name;
  final String fullName;
  final String? description;
  final String? language;
  final bool isPrivate;
  final int stargazersCount;
  final int forksCount;
  final DateTime updatedAt;
  final String cloneUrl;
  final String htmlUrl;
  final Map<String, dynamic>? owner;
  
  GitHubRepository({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    this.language,
    required this.isPrivate,
    required this.stargazersCount,
    required this.forksCount,
    required this.updatedAt,
    required this.cloneUrl,
    required this.htmlUrl,
    this.owner,
  });
  
  factory GitHubRepository.fromJson(Map<String, dynamic> json) {
    return GitHubRepository(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      fullName: json['full_name'] ?? '',
      description: json['description'],
      language: json['language'],
      isPrivate: json['private'] ?? false,
      stargazersCount: json['stargazers_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      cloneUrl: json['clone_url'] ?? '',
      htmlUrl: json['html_url'] ?? '',
      owner: json['owner'],
    );
  }
}

class GitHubUser {
  final int id;
  final String login;
  final String? name;
  final String? email;
  final String avatarUrl;
  final int publicRepos;
  final int followers;
  final int following;
  
  GitHubUser({
    required this.id,
    required this.login,
    this.name,
    this.email,
    required this.avatarUrl,
    required this.publicRepos,
    required this.followers,
    required this.following,
  });
  
  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      id: json['id'] ?? 0,
      login: json['login'] ?? '',
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'] ?? '',
      publicRepos: json['public_repos'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
    );
  }
}

class GitHubService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'github_token';
  static const String _userKey = 'github_user';
  static const String _baseUrl = 'https://api.github.com';
  
  // GitHub OAuth App credentials - Public OAuth App per Warp Mobile AI IDE
  static const String _clientId = 'Ov23liTEHlCVBTatcQ7p';
  static const String _clientSecret = 'ce85e484ab580fbd054e6c47c52103ee8faedf07';
  static const String _redirectUri = 'warp-mobile://oauth/github';
  static const String _scope = 'repo,user:email,read:user';
  static const String _stateKey = 'oauth_state';
  
  Future<String?> getStoredToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<GitHubUser?> getStoredUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      return GitHubUser.fromJson(json.decode(userData));
    }
    return null;
  }
  
  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Generate a secure random string for OAuth state
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Start GitHub Device Flow (recommended for mobile apps)
  Future<Map<String, dynamic>?> startDeviceFlow() async {
    try {
      print('🚀 Starting GitHub Device Flow...');
      
      // Step 1: Request device and user codes
      final deviceResponse = await http.post(
        Uri.parse('https://github.com/login/device/code'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'scope': _scope,
        },
      );
      
      if (deviceResponse.statusCode == 200) {
        final deviceData = json.decode(deviceResponse.body);
        print('📱 Device flow initiated. User code: ${deviceData['user_code']}');
        return deviceData;
      } else {
        print('❌ Device flow initiation failed: ${deviceResponse.statusCode}');
        print('❌ Response: ${deviceResponse.body}');
      }
    } catch (e) {
      print('❌ Device flow error: $e');
    }
    return null;
  }
  
  /// Poll for device flow completion
  Future<bool> pollDeviceFlow(String deviceCode, int interval) async {
    try {
      while (true) {
        await Future.delayed(Duration(seconds: interval));
        
        final tokenResponse = await http.post(
          Uri.parse('https://github.com/login/oauth/access_token'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'client_id': _clientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
        );
        
        if (tokenResponse.statusCode == 200) {
          final tokenData = json.decode(tokenResponse.body);
          final error = tokenData['error'];
          
          if (error == 'authorization_pending') {
            print('⏳ Waiting for user authorization...');
            continue;
          } else if (error == 'slow_down') {
            print('🐌 Slowing down polling...');
            await Future.delayed(Duration(seconds: 5));
            continue;
          } else if (error == 'expired_token' || error == 'access_denied') {
            print('❌ Device flow failed: $error');
            return false;
          } else if (tokenData['access_token'] != null) {
            print('✅ Device flow completed successfully!');
            await _storage.write(key: _tokenKey, value: tokenData['access_token']);
            
            // Fetch and store user info
            final user = await fetchCurrentUser();
            if (user != null) {
              await _storage.write(key: _userKey, value: json.encode(user.toJson()));
              return true;
            }
          }
        }
        
        print('❌ Unexpected response during device flow polling: ${tokenResponse.body}');
        return false;
      }
    } catch (e) {
      print('❌ Device flow polling error: $e');
      return false;
    }
  }
  
  /// Start OAuth flow with improved security (fallback method)
  Future<bool> startOAuthFlow() async {
    try {
      // Generate secure random state for CSRF protection
      final state = _generateRandomString(32);
      await _storage.write(key: _stateKey, value: state);
      
      final authUrl = 'https://github.com/login/oauth/authorize'
          '?client_id=$_clientId'
          '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
          '&scope=${Uri.encodeComponent(_scope)}'
          '&state=$state'
          '&allow_signup=true';
      
      print('🚀 Launching GitHub OAuth URL: $authUrl');
      
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        return launched;
      } else {
        print('❌ Cannot launch GitHub OAuth URL');
        return false;
      }
    } catch (e) {
      print('❌ OAuth flow error: $e');
      return false;
    }
  }
  
  /// Handle OAuth callback - try with client_secret first, fallback to device flow
  Future<bool> handleAuthCallback(String code, String? receivedState) async {
    try {
      print('🔑 Starting OAuth callback with code: ${code.substring(0, 8)}...');
      print('🔑 Received state: $receivedState');
      
      // Verify state parameter to prevent CSRF attacks
      final storedState = await _storage.read(key: _stateKey);
      print('🔑 Stored state: $storedState');
      
      if (storedState != receivedState) {
        print('❌ OAuth state mismatch - possible CSRF attack');
        print('❌ Expected: $storedState, Got: $receivedState');
        await _storage.delete(key: _stateKey);
        return false;
      }
      
      // Determine if we have a client secret
      http.Response tokenResponse;
      
      if (_clientSecret.isNotEmpty && 
          _clientSecret != 'YOUR_CLIENT_SECRET_HERE' && 
          _clientSecret != 'PASTE_YOUR_CLIENT_SECRET_HERE') {
        // Try with client_secret (standard OAuth App flow)
        print('🔑 Exchanging code for token with client_secret...');
        tokenResponse = await http.post(
          Uri.parse('https://github.com/login/oauth/access_token'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'client_id': _clientId,
            'client_secret': _clientSecret,
            'code': code,
            'redirect_uri': _redirectUri,
          },
        );
      } else {
        // Try without client_secret (for GitHub Apps or public clients)
        print('🔑 Exchanging code for token without client_secret...');
        tokenResponse = await http.post(
          Uri.parse('https://github.com/login/oauth/access_token'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'client_id': _clientId,
            'code': code,
            'redirect_uri': _redirectUri,
          },
        );
      }
      
      print('🔑 Token exchange response: ${tokenResponse.statusCode}');
      print('🔑 Response body: ${tokenResponse.body}');
      
      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        final accessToken = tokenData['access_token'];
        final errorDescription = tokenData['error'];
        
        if (errorDescription != null) {
          print('❌ OAuth error from GitHub: $errorDescription');
          return false;
        }
        
        if (accessToken != null && accessToken is String && accessToken.isNotEmpty) {
          print('🔑 Successfully received access token');
          await _storage.write(key: _tokenKey, value: accessToken);
          
          // Clean up OAuth state
          await _storage.delete(key: _stateKey);
          
          // Fetch and store user info
          print('🔑 Fetching user info...');
          final user = await fetchCurrentUser();
          if (user != null) {
            await _storage.write(key: _userKey, value: json.encode(user.toJson()));
            print('✅ GitHub OAuth successful for user: ${user.login}');
            return true;
          } else {
            print('❌ Failed to fetch user info after getting token');
          }
        } else {
          print('❌ No valid access token in response: ${tokenResponse.body}');
        }
      } else {
        print('❌ Token exchange failed: ${tokenResponse.statusCode} - ${tokenResponse.body}');
      }
    } catch (e, stackTrace) {
      print('❌ GitHub auth callback error: $e');
      print('❌ Stack trace: $stackTrace');
    }
    
    // Clean up on failure
    await _storage.delete(key: _stateKey);
    return false;
  }
  
  Future<GitHubUser?> fetchCurrentUser() async {
    final token = await getStoredToken();
    if (token == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        return GitHubUser.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching GitHub user: $e');
    }
    return null;
  }
  
  Future<List<GitHubRepository>> fetchUserRepositories({
    String type = 'all', // all, owner, public, private, member
    String sort = 'updated', // created, updated, pushed, full_name
    String direction = 'desc', // asc, desc
    int perPage = 100,
    int page = 1,
  }) async {
    final token = await getStoredToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/repos?type=$type&sort=$sort&direction=$direction&per_page=$perPage&page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> reposJson = json.decode(response.body);
        return reposJson.map((repo) => GitHubRepository.fromJson(repo)).toList();
      } else {
        print('Error fetching repositories: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching GitHub repositories: $e');
    }
    return [];
  }
  
  Future<List<GitHubRepository>> searchRepositories(String query, {
    String sort = 'updated',
    String order = 'desc',
    int perPage = 30,
  }) async {
    final token = await getStoredToken();
    if (token == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/repositories?q=$query+user:${(await getStoredUser())?.login}&sort=$sort&order=$order&per_page=$perPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reposJson = data['items'] ?? [];
        return reposJson.map((repo) => GitHubRepository.fromJson(repo)).toList();
      }
    } catch (e) {
      print('Error searching GitHub repositories: $e');
    }
    return [];
  }
  
  /// Primary authentication method - tries Device Flow first, falls back to OAuth
  Future<bool> authenticate() async {
    try {
      // Try Device Flow first (more secure for mobile)
      print('🚀 Starting GitHub authentication with Device Flow...');
      final deviceData = await startDeviceFlow();
      
      if (deviceData != null) {
        final userCode = deviceData['user_code'] as String;
        final verificationUri = deviceData['verification_uri'] as String;
        final deviceCode = deviceData['device_code'] as String;
        final interval = deviceData['interval'] as int? ?? 5;
        
        print('📱 Please visit: $verificationUri');
        print('🔑 Enter this code: $userCode');
        
        // Launch the verification URL
        final uri = Uri.parse(verificationUri);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        
        // Start polling for completion
        return await pollDeviceFlow(deviceCode, interval);
      } else {
        print('❌ Device Flow failed, falling back to OAuth...');
        return await startOAuthFlow();
      }
    } catch (e) {
      print('❌ Authentication error: $e');
      return false;
    }
  }
  
  /// Create a new repository
  Future<GitHubRepository?> createRepository(String name, {
    String? description,
    bool isPrivate = false,
    bool autoInit = true,
  }) async {
    final token = await getStoredToken();
    if (token == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/user/repos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description ?? 'Created with Warp Mobile AI IDE',
          'private': isPrivate,
          'auto_init': autoInit,
        }),
      );
      
      if (response.statusCode == 201) {
        return GitHubRepository.fromJson(json.decode(response.body));
      } else {
        print('Error creating repository: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error creating GitHub repository: $e');
    }
    return null;
  }
  
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _stateKey);
  }
  
  // Alternative method: Personal Access Token authentication
  Future<bool> authenticateWithToken(String personalAccessToken) async {
    try {
      // Validate token by fetching user info
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'token $personalAccessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        await _storage.write(key: _tokenKey, value: personalAccessToken);
        
        final user = GitHubUser.fromJson(json.decode(response.body));
        await _storage.write(key: _userKey, value: json.encode({
          'id': user.id,
          'login': user.login,
          'name': user.name,
          'email': user.email,
          'avatar_url': user.avatarUrl,
          'public_repos': user.publicRepos,
          'followers': user.followers,
          'following': user.following,
        }));
        
        return true;
      }
    } catch (e) {
      print('Token authentication error: $e');
    }
    return false;
  }
}

// Extension to convert GitHubUser to JSON
extension GitHubUserJson on GitHubUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'public_repos': publicRepos,
      'followers': followers,
      'following': following,
    };
  }
}