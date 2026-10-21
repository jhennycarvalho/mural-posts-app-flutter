import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();
  final http.Client _client;
  final Duration timeout;
  static const baseUrl = 'https://jsonplaceholder.typicode.com';
  static const _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  Future<T> _request<T>(
    Future<http.Response> Function() send,
    Set<int> expected,
    T Function(http.Response) decode,
  ) async {
    try {
      final response = await send().timeout(timeout);
      if (!expected.contains(response.statusCode)) {
        throw ApiException(
          'A API não concluiu a operação (HTTP '
          '${response.statusCode}). Tente novamente.',
          statusCode: response.statusCode,
        );
      }
      return decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('A conexão demorou demais. Tente novamente.');
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível acessar a API. '
        'Verifique sua conexão com a internet.',
      );
    } on FormatException {
      throw const ApiException(
        'A API retornou dados em um formato inesperado.',
      );
    } catch (_) {
      throw const ApiException(
        'Não foi possível concluir a solicitação. '
        'Verifique a conexão e tente novamente.',
      );
    }
  }

  Post _decodePost(http.Response response) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Resposta inválida.');
    }
    return Post.fromJson(data);
  }

  Future<List<Post>> getPosts() => _request(
        () => _client.get(Uri.parse('$baseUrl/posts'), headers: _headers),
        {200},
        (response) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is! List) throw const FormatException('Lista inválida.');
          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Item inválido.');
            }
            return Post.fromJson(item);
          }).toList();
        },
      );

  Future<Post> createPost(Post post) => _request(
        () => _client.post(
          Uri.parse('$baseUrl/posts'),
          headers: _headers,
          body: jsonEncode(post.toJson(includeId: false)),
        ),
        {201},
        _decodePost,
      );

  Future<Post> updatePost(Post post) async {
    try {
      return await _request(
        () => _client.put(
          Uri.parse('$baseUrl/posts/${post.id}'),
          headers: _headers,
          body: jsonEncode(post.toJson()),
        ),
        {200},
        _decodePost,
      );
    } on ApiException catch (error) {
      if (post.createdInSession && error.statusCode != null) {
        throw ApiException(
          'A API recusou a edição do ID ${post.id} '
          '(HTTP ${error.statusCode}). Esse registro foi criado apenas '
          'na sessão e não existe no servidor. Para demonstrar PUT, '
          'edite uma publicação original.',
          statusCode: error.statusCode,
        );
      }
      rethrow;
    }
  }

  Future<bool> deletePost(int id) => _request(
        () =>
            _client.delete(Uri.parse('$baseUrl/posts/$id'), headers: _headers),
        {200, 204},
        (_) => true,
      );

  void close() => _client.close();
}
