import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/property_post.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _tokenKey = 'plotpost_access_token';
  static const String _userIdKey = 'plotpost_user_id';

  String? _token;
  String? _userId;

  String get _baseUrl {
    final baseUrl = _configuredBaseUrl.isNotEmpty
        ? _configuredBaseUrl
        : (kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api');
    return baseUrl.replaceFirst(RegExp(r'/$'), '');
  }

  bool get isAuthenticated => _token != null;
  String? get userId => _userId;

  Future<void> restoreSession() async {
    _token = await _secureStorage.read(key: _tokenKey);
    _userId = await _secureStorage.read(key: _userIdKey);
  }

  Future<void> _saveToken(String token, Map<String, dynamic> user) async {
    _token = token;
    _userId = user['id'] as String?;
    await _secureStorage.write(key: _tokenKey, value: token);
    if (_userId case final id?) {
      await _secureStorage.write(key: _userIdKey, value: id);
    }
  }

  Future<void> signOut() async {
    _token = null;
    _userId = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final response = await _request(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      },
      authenticated: false,
    );
    final user = Map<String, dynamic>.from(response['user'] as Map);
    await _saveToken(response['token'] as String, user);
    return user;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    final user = Map<String, dynamic>.from(response['user'] as Map);
    await _saveToken(response['token'] as String, user);
    return user;
  }

  Future<void> requestPasswordReset(String email) async {
    await _request(
      'POST',
      '/auth/forgot-password',
      body: {'email': email},
      authenticated: false,
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _request(
      'POST',
      '/auth/reset-password',
      body: {'token': token, 'password': password},
      authenticated: false,
    );
  }

  Future<List<PropertyPost>> getListings({
    String query = '',
    String? type,
    String? deal,
  }) async {
    final uri = Uri.parse('$_baseUrl/listings').replace(
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (deal != null && deal.isNotEmpty) 'deal': deal,
      },
    );
    final response = await _requestUri('GET', uri, authenticated: false);
    return (response['listings'] as List<dynamic>).map((item) {
      final listing = item as Map<String, dynamic>;
      return PropertyPost.fromJson(
        listing,
        isUserPost: _userId != null && listing['ownerId'] == _userId,
      );
    }).toList();
  }

  Future<List<PropertyPost>> getMyListings() async {
    final response = await _request('GET', '/listings/mine');
    return (response['listings'] as List<dynamic>)
        .map(
          (item) => PropertyPost.fromJson(
            item as Map<String, dynamic>,
            isUserPost: true,
          ),
        )
        .toList();
  }

  Future<PropertyPost> createListing(
    PropertyPost post, {
    required List<XFile> images,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/listings'),
    );
    _addAuthorization(request);
    request.fields.addAll(_listingFields(post));
    for (final image in images) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    }

    final response = await _sendMultipart(request);
    return PropertyPost.fromJson(
      response['listing'] as Map<String, dynamic>,
      isUserPost: true,
    );
  }

  Future<PropertyPost> updateListing(
    PropertyPost post, {
    required List<XFile> images,
    required List<String> existingImages,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$_baseUrl/listings/${post.id}'),
    );
    _addAuthorization(request);
    request.fields.addAll(_listingFields(post));
    request.fields['existingImages'] = jsonEncode(existingImages);
    for (final image in images) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    }

    final response = await _sendMultipart(request);
    return PropertyPost.fromJson(
      response['listing'] as Map<String, dynamic>,
      isUserPost: true,
    );
  }

  Future<void> deleteListing(String id) async {
    await _request('DELETE', '/listings/$id');
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _request('GET', '/messages/conversations');
    return List<Map<String, dynamic>>.from(response['conversations'] as List);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final uri = Uri.parse('$_baseUrl/messages/users')
        .replace(queryParameters: {'q': query});
    final response = await _requestUri('GET', uri);
    return List<Map<String, dynamic>>.from(response['users'] as List);
  }

  Future<String> createConversation({
    required String recipientId,
    String? listingId,
  }) async {
    final requestBody = <String, dynamic>{'recipientId': recipientId};
    if (listingId != null) requestBody['listingId'] = listingId;
    final response = await _request(
      'POST',
      '/messages/conversations',
      body: requestBody,
    );
    return (response['conversation'] as Map<String, dynamic>)['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _request(
      'GET',
      '/messages/conversations/$conversationId/messages',
    );
    return List<Map<String, dynamic>>.from(response['messages'] as List);
  }

  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String text,
  ) async {
    final response = await _request(
      'POST',
      '/messages/conversations/$conversationId/messages',
      body: {'text': text},
    );
    return Map<String, dynamic>.from(response['message'] as Map);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _request('GET', '/notifications');
    return List<Map<String, dynamic>>.from(response['notifications'] as List);
  }

  Future<void> markNotificationRead(String id) async {
    await _request('PATCH', '/notifications/$id/read');
  }

  Map<String, String> _listingFields(PropertyPost post) => {
    'platform': post.platform,
    'title': post.title,
    'type': post.type,
    'deal': post.deal,
    'price': post.price,
    'location': post.location,
    'description': post.description,
    'socialUrl': post.socialUrl,
    'sellerPhone': post.sellerPhone,
    'area': post.area,
    'bedrooms': post.bedrooms,
    'bathrooms': post.bathrooms,
  };

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _requestUri(
      method,
      Uri.parse('$_baseUrl$path'),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _requestUri(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated) _addAuthorization(headers);

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeResponse(response);
    } on http.ClientException {
      throw const ApiException(
        'Could not connect to PlotPost. Check the API server URL.',
      );
    } finally {
      client.close();
    }
  }

  void _addAuthorization(Object requestOrHeaders) {
    if (_token == null) {
      throw const ApiException('Sign in to continue.');
    }
    if (requestOrHeaders is http.MultipartRequest) {
      requestOrHeaders.headers['Authorization'] = 'Bearer $_token';
      return;
    }
    if (requestOrHeaders is Map<String, String>) {
      requestOrHeaders['Authorization'] = 'Bearer $_token';
      return;
    }
    throw ArgumentError.value(requestOrHeaders, 'requestOrHeaders');
  }

  Future<Map<String, dynamic>> _sendMultipart(
    http.MultipartRequest request,
  ) async {
    final client = http.Client();
    try {
      final response = await client.send(request);
      return _decodeResponse(await http.Response.fromStream(response));
    } on http.ClientException {
      throw const ApiException(
        'Could not connect to PlotPost. Check the API server URL.',
      );
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode == 204) return {};
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid response (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    } on TypeError {
      throw ApiException(
        'The server returned an invalid response (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
