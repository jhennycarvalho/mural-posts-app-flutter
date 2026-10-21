import 'package:flutter/material.dart';

import '../providers/post_provider.dart';
import '../widgets/post_actions.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.provider,
    required this.postKey,
  });
  final PostProvider provider;
  final String postKey;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          final post = provider.find(postKey);
          return Scaffold(
            appBar: AppBar(title: const Text('Publicação')),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: post == null
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child:
                              Text('Esta publicação não está mais na lista.'),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PUBLICAÇÃO #${post.id} · USUÁRIO ${post.userId}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              SelectableText(
                                post.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 24),
                              SelectableText(
                                post.body,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(height: 1.65),
                              ),
                              const SizedBox(height: 32),
                              if (post.createdInSession) ...[
                                const Text(
                                  'Criada nesta sessão. O ID informado pela API pode se repetir.',
                                ),
                                const SizedBox(height: 20),
                              ],
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: provider.saving
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (_) => PostFormScreen(
                                                  provider: provider,
                                                  post: post,
                                                ),
                                              ),
                                            ),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: provider.saving
                                        ? null
                                        : () async {
                                            final deleted = await confirmDelete(
                                              context,
                                              provider,
                                              post,
                                            );
                                            if (deleted && context.mounted) {
                                              Navigator.pop(context);
                                            }
                                          },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Excluir'),
                                  ),
                                ],
                              ),
                              if (provider.saving)
                                const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: LinearProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      );
}
