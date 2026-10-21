import 'package:flutter/material.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';

Future<bool> confirmDelete(
  BuildContext context,
  PostProvider provider,
  Post post,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir publicação?'),
      content: Text(
        '“${post.title}” será removida desta sessão após '
        'a confirmação da API.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await provider.deletePost(post);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação excluída desta sessão.')),
      );
    }
    return true;
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
}
