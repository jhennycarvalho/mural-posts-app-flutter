import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mural_posts/models/post.dart';
import 'package:mural_posts/providers/post_provider.dart';
import 'package:mural_posts/services/api_service.dart';

http.Response jsonResponse(String body, int code) => http.Response(body, code,
    headers: {'content-type': 'application/json; charset=utf-8'});

const original = Post(
  id: 1,
  userId: 1,
  title: 'Original',
  body: 'Texto',
  key: 'api-1',
);
void main() {
  test(
    'refresh preserva edição, exclusão e criações com ID repetido',
    () async {
      final provider = PostProvider(
        ApiService(
          client: MockClient((request) async {
            if (request.method == 'GET') {
              return jsonResponse(
                jsonEncode([
                  original.toJson(),
                  original.copyWith(id: 2).toJson(),
                ]),
                200,
              );
            }
            if (request.method == 'DELETE') return jsonResponse('{}', 200);
            final data = jsonDecode(request.body) as Map<String, dynamic>;
            if (request.method == 'POST') data['id'] = 101;
            return jsonResponse(
              jsonEncode(data),
              request.method == 'POST' ? 201 : 200,
            );
          }),
        ),
      );
      addTearDown(provider.dispose);
      await provider.loadPosts();
      await provider.updatePost(
        provider.posts.first.copyWith(title: 'Editado'),
      );
      await provider.deletePost(provider.posts.last);
      final a = await provider.createPost(
        original.copyWith(title: 'Criação A'),
      );
      final b = await provider.createPost(
        original.copyWith(title: 'Criação B'),
      );
      expect(a.id, b.id);
      expect(a.key, isNot(b.key));
      await provider.loadPosts();
      expect(provider.posts.map((p) => p.title), [
        'Criação B',
        'Criação A',
        'Editado',
      ]);
      await provider.deletePost(a);
      expect(provider.find(a.key), isNull);
      expect(provider.find(b.key), isNotNull);
      await provider.loadPosts();
      expect(provider.posts.map((p) => p.title), ['Criação B', 'Editado']);
    },
  );

  test(
    'falhas não alteram estado local nem apagam dados já carregados',
    () async {
      bool fail = false;
      final provider = PostProvider(
        ApiService(
          client: MockClient((request) async {
            if (fail) throw http.ClientException('offline');
            return jsonResponse(jsonEncode([original.toJson()]), 200);
          }),
        ),
      );
      addTearDown(provider.dispose);
      await provider.loadPosts();
      fail = true;
      await expectLater(
        provider.updatePost(original.copyWith(title: 'Falha')),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        provider.deletePost(original),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        provider.createPost(original),
        throwsA(isA<ApiException>()),
      );
      await provider.loadPosts();
      expect(provider.posts.single.title, 'Original');
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
      expect(provider.saving, isFalse);
    },
  );

  test(
    'GET iniciado antes de edição não sobrescreve a edição ao terminar',
    () async {
      final delayed = Completer<http.Response>();
      int reads = 0;
      final provider = PostProvider(
        ApiService(
          client: MockClient((request) async {
            if (request.method == 'GET') {
              reads++;
              if (reads == 2) return delayed.future;
              return jsonResponse(jsonEncode([original.toJson()]), 200);
            }
            return jsonResponse(request.body, 200);
          }),
        ),
      );
      addTearDown(provider.dispose);
      await provider.loadPosts();
      final refresh = provider.loadPosts();
      await provider.updatePost(original.copyWith(title: 'Durante GET'));
      delayed.complete(jsonResponse(jsonEncode([original.toJson()]), 200));
      await refresh;
      expect(provider.posts.single.title, 'Durante GET');
    },
  );
}
