import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mural_posts/models/post.dart';
import 'package:mural_posts/providers/post_provider.dart';
import 'package:mural_posts/screens/home_screen.dart';
import 'package:mural_posts/screens/post_form_screen.dart';
import 'package:mural_posts/services/api_service.dart';
import 'package:mural_posts/utils/app_theme.dart';

http.Response jsonResponse(String body, int code) => http.Response(body, code,
    headers: {'content-type': 'application/json; charset=utf-8'});

const original = Post(
  id: 1,
  userId: 1,
  title: 'Publicação original',
  body: 'Conteúdo original',
  key: 'api-1',
);
void main() {
  testWidgets('campos vazios e ID zero impedem qualquer POST', (tester) async {
    var requests = 0;
    final provider = PostProvider(
      ApiService(
        client: MockClient((_) async {
          requests++;
          return jsonResponse('{}', 500);
        }),
      ),
    );
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PostFormScreen(provider: provider),
      ),
    );
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Preencha este campo.'), findsNWidgets(2));
    expect(requests, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'Título');
    await tester.enterText(find.byType(TextFormField).at(1), 'Conteúdo');
    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Use um número inteiro maior que zero.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('lista, detalhes, edição, criação e confirmação de exclusão', (
    tester,
  ) async {
    final methods = <String>[];
    final provider = PostProvider(
      ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          if (request.method == 'GET') {
            return jsonResponse(jsonEncode([original.toJson()]), 200);
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
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(provider: provider),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicação original'));
    await tester.pumpAndSettle();
    expect(find.text('PUBLICAÇÃO #1 · USUÁRIO 1'), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Título editado');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(provider.posts.single.title, 'Título editado');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova publicação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Nova ideia');
    await tester.enterText(find.byType(TextFormField).at(1), 'Meu conteúdo');
    await tester.enterText(find.byType(TextFormField).at(2), '3');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(provider.posts.length, 2);
    await tester.tap(find.byTooltip('Excluir publicação').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(methods.where((m) => m == 'DELETE'), isEmpty);
    await tester.tap(find.byTooltip('Excluir publicação').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(provider.posts.length, 1);
    expect(methods, ['GET', 'PUT', 'POST', 'DELETE']);
  });
}
