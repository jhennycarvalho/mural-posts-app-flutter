// Verificação de rede real. Execute com: dart run tool/live_api_check.dart
import 'dart:io';
import 'package:mural_posts/models/post.dart';
import 'package:mural_posts/services/api_service.dart';

Future<void> main() async {
  final api = ApiService();
  try {
    final posts = await api.getPosts();
    if (posts.isEmpty) throw StateError('GET não retornou publicações.');
    stdout.writeln('GET /posts: OK (${posts.length} publicações)');
    final created = await api.createPost(
      const Post(
        id: 0,
        userId: 1,
        title: 'Teste acadêmico Mural',
        body: 'Teste de integração HTTP real.',
        key: 'draft',
      ),
    );
    stdout.writeln('POST /posts: OK (ID ${created.id})');
    final updated = await api.updatePost(
      posts.first.copyWith(title: 'Teste PUT Mural'),
    );
    if (updated.title != 'Teste PUT Mural') {
      throw StateError('PUT não refletiu o título.');
    }
    stdout.writeln('PUT /posts/${updated.id}: OK');
    if (!await api.deletePost(posts.first.id)) {
      throw StateError('DELETE não confirmado.');
    }
    stdout.writeln('DELETE /posts/${posts.first.id}: OK');
    final reloaded = await api.getPosts();
    if (!reloaded.any((p) => p.id == posts.first.id)) {
      throw StateError('Servidor apresentou persistência inesperada.');
    }
    stdout.writeln(
      'GET posterior: dados originais permanecem no servidor, como esperado.',
    );
  } finally {
    api.close();
  }
}
