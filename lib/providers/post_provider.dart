import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../services/api_service.dart';

/// Sobrepõe alterações da sessão aos dados retornados por cada GET.
class PostProvider extends ChangeNotifier {
  PostProvider(this._api);
  final ApiService _api;
  List<Post> _remote = [];
  final Map<String, Post> _created = {};
  final Map<String, Post> _edited = {};
  final Set<String> _deleted = {};
  bool loading = false;
  bool saving = false;
  String? error;
  int _sequence = 0;

  List<Post> get posts => List.unmodifiable([
        ..._created.values.toList().reversed,
        ..._remote
            .where((post) => !_deleted.contains(post.key))
            .map((post) => _edited[post.key] ?? post),
      ]);

  Post? find(String key) {
    for (final post in posts) {
      if (post.key == key) return post;
    }
    return null;
  }

  Future<void> loadPosts() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      _remote = await _api.getPosts();
    } on ApiException catch (exception) {
      error = exception.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    if (saving) throw const ApiException('Aguarde a operação em andamento.');
    saving = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<Post> createPost(Post draft) => _mutate(() async {
        final response = await _api.createPost(draft);
        final post = response.copyWith(
          key: 'local-${++_sequence}',
          createdInSession: true,
        );
        _created[post.key] = post;
        return post;
      });

  Future<Post> updatePost(Post post) => _mutate(() async {
        final response = await _api.updatePost(post);
        final updated = response.copyWith(
          key: post.key,
          createdInSession: post.createdInSession,
        );
        if (post.createdInSession) {
          _created[post.key] = updated;
        } else {
          _edited[post.key] = updated;
        }
        return updated;
      });

  Future<void> deletePost(Post post) => _mutate(() async {
        final success = await _api.deletePost(post.id);
        if (!success) {
          throw const ApiException('A API não confirmou a exclusão.');
        }
        if (post.createdInSession) {
          _created.remove(post.key);
        } else {
          _deleted.add(post.key);
          _edited.remove(post.key);
        }
      });

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }
}
