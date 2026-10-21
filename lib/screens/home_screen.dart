import 'package:flutter/material.dart';

import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/post_actions.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.provider});
  final PostProvider provider;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.provider.loadPosts();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.provider,
        builder: (context, _) {
          final provider = widget.provider;
          final posts = provider.posts;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mural'),
              actions: [
                IconButton(
                  tooltip: 'Atualizar publicações',
                  onPressed: provider.loading ? null : provider.loadPosts,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: provider.saving
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PostFormScreen(provider: provider),
                        ),
                      ),
              icon: const Icon(Icons.add),
              label: const Text('Nova publicação'),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    children: [
                      if (provider.loading || provider.saving)
                        const LinearProgressIndicator(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: provider.loadPosts,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                            itemCount: posts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ideias em circulação',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${posts.length} publicações · JSONPlaceholder',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Ambiente de testes. As alterações ficam '
                                        'nesta sessão e não são gravadas no servidor.',
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (provider.error != null) ...[
                                      Text(
                                        provider.error!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: provider.loading
                                            ? null
                                            : provider.loadPosts,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Tentar novamente'),
                                      ),
                                    ],
                                    if (posts.isEmpty &&
                                        !provider.loading &&
                                        provider.error == null)
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 32),
                                        child: Text(
                                          'Nenhuma publicação. Crie a primeira.',
                                        ),
                                      ),
                                  ],
                                );
                              }
                              final post = posts[index - 1];
                              return PostCard(
                                key: ValueKey(post.key),
                                post: post,
                                busy: provider.saving,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PostDetailScreen(
                                      provider: provider,
                                      postKey: post.key,
                                    ),
                                  ),
                                ),
                                onEdit: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PostFormScreen(
                                      provider: provider,
                                      post: post,
                                    ),
                                  ),
                                ),
                                onDelete: () {
                                  confirmDelete(context, provider, post);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
