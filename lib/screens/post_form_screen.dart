import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, required this.provider, this.post});
  final PostProvider provider;
  final Post? post;
  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.post?.title ?? '');
  late final _body = TextEditingController(text: widget.post?.body ?? '');
  late final _user = TextEditingController(
    text: widget.post?.userId.toString() ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _user.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = (widget.post ??
            const Post(id: 0, userId: 1, title: '', body: '', key: 'draft'))
        .copyWith(
      title: _title.text.trim(),
      body: _body.text.trim(),
      userId: int.parse(_user.text.trim()),
    );
    try {
      if (widget.post == null) {
        await widget.provider.createPost(draft);
      } else {
        await widget.provider.updatePost(draft);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.post == null
                ? 'Publicação criada nesta sessão.'
                : 'Alterações aplicadas nesta sessão.',
          ),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.post == null ? 'Nova publicação' : 'Editar publicação',
            ),
            automaticallyImplyLeading: !_saving,
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.post?.createdInSession == true) ...[
                          const Text(
                            'Este ID foi criado na sessão. A API pode recusar '
                            'sua edição por não existir no servidor. Nesse caso, os dados serão mantidos.',
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _title,
                          enabled: !_saving,
                          decoration:
                              const InputDecoration(labelText: 'Título'),
                          textCapitalization: TextCapitalization.sentences,
                          validator: _required,
                          minLines: 1,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _body,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Conteúdo',
                            alignLabelWithHint: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          minLines: 6,
                          maxLines: 12,
                          validator: _required,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _user,
                          enabled: !_saving && widget.post == null,
                          decoration: const InputDecoration(
                            labelText: 'ID do usuário',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (_required(value) != null) {
                              return 'Informe o ID do usuário.';
                            }
                            final id = int.tryParse(value!.trim());
                            return id == null || id <= 0
                                ? 'Use um número inteiro maior que zero.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_saving ? 'Salvando…' : 'Salvar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
