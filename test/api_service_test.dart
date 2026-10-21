import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mural_posts/models/post.dart';
import 'package:mural_posts/services/api_service.dart';

http.Response jsonResponse(String body, int code) => http.Response(body, code,
    headers: {'content-type': 'application/json; charset=utf-8'});

const post = Post(
  id: 1,
  userId: 2,
  title: 'Título',
  body: 'Conteúdo',
  key: 'api-1',
);
void main() {
  test('GET, POST, PUT e DELETE usam URL, método e JSON corretos', () async {
    final methods = <String>[];
    final api = ApiService(
      client: MockClient((request) async {
        methods.add(request.method);
        expect(request.url.host, 'jsonplaceholder.typicode.com');
        expect(
          request.url.path,
          request.method == 'GET' || request.method == 'POST'
              ? '/posts'
              : '/posts/1',
        );
        if (request.method == 'GET') {
          return jsonResponse(jsonEncode([post.toJson()]), 200);
        }
        if (request.method == 'DELETE') return jsonResponse('', 204);
        expect(request.headers['content-type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Título');
        expect(body['userId'], 2);
        expect(body.containsKey('id'), request.method == 'PUT');
        return jsonResponse(
          jsonEncode(post.toJson()),
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );
    addTearDown(api.close);
    expect((await api.getPosts()).single.id, 1);
    expect((await api.createPost(post)).title, 'Título');
    expect((await api.updatePost(post)).body, 'Conteúdo');
    expect(await api.deletePost(1), isTrue);
    expect(methods, ['GET', 'POST', 'PUT', 'DELETE']);
  });

  test('HTTP inesperado, JSON inválido e falha de rede são tratados', () async {
    for (final code in [400, 404, 500]) {
      final api = ApiService(
        client: MockClient((_) async => jsonResponse('{}', code)),
      );
      await expectLater(api.getPosts(), throwsA(isA<ApiException>()));
      api.close();
    }
    final invalid = ApiService(
      client: MockClient((_) async => jsonResponse('{', 200)),
    );
    await expectLater(invalid.getPosts(), throwsA(isA<ApiException>()));
    invalid.close();
    final offline = ApiService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      offline.getPosts(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('conexão'),
        ),
      ),
    );
    offline.close();
  });

  test('timeout é convertido em mensagem compreensível', () async {
    final api = ApiService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      api.getPosts(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('demorou'),
        ),
      ),
    );
    api.close();
  });

  test('PUT recusado para ID criado na sessão explica a limitação', () async {
    final api = ApiService(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/posts/101');
        return jsonResponse('{}', 500);
      }),
    );
    await expectLater(
      api.updatePost(post.copyWith(id: 101, createdInSession: true)),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('não existe no servidor'),
        ),
      ),
    );
    api.close();
  });
}
