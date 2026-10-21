# Registro de validação

Preparação em 21/10/2026, em ambiente Linux. A execução em um celular Android com Windows 11 e Android Studio ainda deve ser conferida.

## O que foi executado

| Verificação | Resultado |
| --- | --- |
| Formatação com `dart format lib test tool` | Concluída. |
| Análise com `dart analyze` | `No issues found!` |
| Testes de `test/api_service_test.dart`, executados pelo runner Dart do pacote `test` | 4 testes aprovados. |
| Script `tool/live_api_check.dart`, executado diretamente pelo Dart | GET, POST, PUT e DELETE reais aprovados. |
| GET após as escritas | Os dados originais permaneceram no servidor, conforme a persistência simulada. |
| Leitura dos XMLs Android e inspeção do Gradle Wrapper | XMLs válidos; classe principal presente no JAR. Isso não comprova compilação. |

A análise e os testes do serviço usaram Dart 3.13.5, fontes do Flutter e uma configuração temporária com dependências resolvidas localmente. Os arquivos com caminhos específicos desse ambiente foram excluídos do ZIP. A resolução normal das dependências no computador do aluno será feita com `flutter pub get`.

Os quatro testes de serviço verificam:

1. Métodos GET, POST, PUT e DELETE, caminhos, payload JSON e respostas aceitas.
2. HTTP de erro, JSON inválido e falha de conexão.
3. Timeout e mensagem compreensível.
4. Tratamento de PUT recusado em registro criado apenas na sessão.

A primeira execução encontrou um problema na codificação UTF-8 das respostas simuladas dos testes. As respostas de teste foram corrigidas para declarar UTF-8; a execução posterior aprovou os quatro testes. O código do serviço também foi exercitado contra a API pública real.

Saída da verificação HTTP real:

```text
GET /posts: OK (100 publicações)
POST /posts: OK (ID 101)
PUT /posts/1: OK
DELETE /posts/1: OK
GET posterior: dados originais permanecem no servidor, como esperado.
```

Também foi realizado um POST adicional seguido de `PUT /posts/101`: a API respondeu HTTP 500, e o serviço devolveu a mensagem específica sobre registros criados apenas na sessão. Isso confirma a limitação documentada no README.

## O que permanece pendente

- Execução de `flutter pub get` pela ferramenta Flutter.
- Execução dos testes de estado (`test/post_provider_test.dart`).
- Execução dos testes de interface (`test/ui_test.dart`).
- Execução de `flutter analyze` e da suíte completa com `flutter test`.
- Compilação Android e geração do APK com `flutter build apk --release`.
- Testes manuais no celular, inclusive desconexão da internet, permissões e usabilidade.

A tentativa de inicializar a ferramenta Flutter foi rejeitada pela revisão automática do ambiente por tentar acessar um endereço interno de metadados da infraestrutura. Não foi repetida por outra rota. As verificações acima foram feitas com Dart e com acesso à API pública, sem depender dessa inicialização.

**Não há APK nesta entrega e o aplicativo não é apresentado como compilado, testado integralmente ou concluído segundo todos os critérios do enunciado.** O código-fonte, a estrutura Android e os testes estão preparados para continuar a validação no Android Studio.

No computador de desenvolvimento, abra a raiz do projeto e execute no terminal integrado:

```powershell
flutter pub get
flutter analyze
flutter test
dart run tool/live_api_check.dart
flutter devices
flutter run -d ID_DO_DISPOSITIVO
flutter build apk --release
```

O README contém o roteiro de teste manual, as instruções de depuração USB e a limitação da edição de IDs criados por POST na JSONPlaceholder.
