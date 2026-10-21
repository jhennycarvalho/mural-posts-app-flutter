# Mural — Publicações via API REST

Aplicativo acadêmico em Flutter para listar, criar, editar e excluir publicações da JSONPlaceholder. As operações usam requisições HTTP reais ao recurso `/posts`.

## O que o aplicativo faz

- Lista publicações com ID, título, resumo e identificação do usuário.
- Exibe o conteúdo completo em uma tela de detalhes.
- Permite criar e editar publicações em formulários validados.
- Solicita confirmação antes da exclusão.
- Mostra carregamento, erros de conexão e opção de tentar novamente.
- Atualiza a lista ao arrastar para baixo, preservando as alterações da sessão.

A interface usa Material Design 3, azul, verde suave e tons neutros. Nenhuma conta ou chave de API é necessária.

## Tecnologias e organização

Flutter, Dart, `http` e `ChangeNotifier`. O estado é passado às telas pelo construtor, sem pacote adicional de gerenciamento de estado. Não há banco de dados ou armazenamento persistente local.

```text
lib/
  main.dart
  models/post.dart
  services/api_service.dart
  providers/post_provider.dart
  screens/
    home_screen.dart
    post_detail_screen.dart
    post_form_screen.dart
  widgets/
    post_card.dart
    post_actions.dart
  utils/app_theme.dart
test/                    # Testes com respostas HTTP controladas
tool/live_api_check.dart # Verificação com a API pública real
```

`ApiService` cuida de JSON, códigos HTTP e timeout de 20 segundos. `PostProvider` combina os dados do servidor com criações, edições e exclusões em memória. `post_actions.dart` centraliza a confirmação de exclusão usada na lista e nos detalhes.

## Abrir no Android Studio

Requisitos: Flutter estável compatível com o `pubspec.yaml`, plugins Flutter e Dart, Android SDK, internet e um celular Android. O Flutter e o Android Studio devem estar instalados no Windows 11.

1. Extraia o ZIP em uma pasta curta, por exemplo `C:\Projetos\mural_posts`.
2. No Android Studio, escolha **Open** e abra a pasta que contém `pubspec.yaml`. Abra a raiz do projeto, em vez de apenas `android`.
3. Em **Settings > Languages & Frameworks > Flutter**, confira o caminho do Flutter SDK. A localização exata do menu pode variar conforme a versão.
4. Abra **View > Tool Windows > Terminal** e execute:

```powershell
flutter doctor
flutter pub get
```

Corrija as pendências da seção **Android toolchain**. No SDK Manager, instale a plataforma Android e o Build-Tools solicitados pela compilação, além de Android SDK Command-line Tools e Platform-Tools. Para revisar as licenças:

```powershell
flutter doctor --android-licenses
```

O arquivo `android/local.properties` é específico do computador e será gerado pelo Flutter. Não copie caminhos de outro computador para ele.

## Conectar o celular e executar

1. No celular, abra **Configurações > Sobre o telefone > Informações do software** e toque sete vezes em **Número da versão/compilação**. Os nomes variam por fabricante.
2. Nas **Opções do desenvolvedor**, ative **Depuração USB**.
3. Conecte um cabo USB com transferência de dados e aceite a autorização de depuração exibida no celular.
4. No terminal do Android Studio, confira:

```powershell
flutter devices
```

Selecione o celular na barra superior, abra `lib/main.dart` e clique em **Run**. Alternativamente, use o terminal integrado:

```powershell
flutter run -d ID_DO_DISPOSITIVO
```

Substitua `ID_DO_DISPOSITIVO` pelo identificador listado. Se o celular não aparecer, teste outro cabo/porta USB, confira a autorização e o driver USB do fabricante no Windows. Mantenha o celular conectado à internet.

### Computador com 8 GB de RAM

Prefira o celular físico e mantenha os emuladores fechados. O `android/gradle.properties` limita os processos do Gradle ao projeto. Não é preciso mudar configurações globais. A primeira compilação precisa baixar dependências e costuma demorar mais; as seguintes aproveitam o cache.

## Endpoints utilizados

Base: `https://jsonplaceholder.typicode.com`

| Operação | Método e caminho | Resposta aceita |
| --- | --- | --- |
| Listar | `GET /posts` | 200 |
| Criar | `POST /posts` | 201 |
| Editar | `PUT /posts/{id}` | 200 |
| Excluir | `DELETE /posts/{id}` | 200 ou 204 |

Exemplo de corpo enviado no cadastro:

```json
{
  "title": "Atividade de Flutter",
  "body": "Publicação criada para testar a integração REST.",
  "userId": 1
}
```

O PUT inclui também o `id`. As requisições com corpo utilizam `Content-Type: application/json; charset=UTF-8`.

## Como a persistência simulada funciona

A JSONPlaceholder devolve respostas de sucesso para escritas, mas não grava as alterações no servidor. O app só modifica o estado local depois de receber uma resposta HTTP aceita. Uma falha mantém os dados e permite tentar novamente.

Durante a sessão, um novo GET atualiza os dados de origem e reaplica as criações, edições e exclusões locais. Assim, arrastar para atualizar não faz um item excluído reaparecer nem desfaz uma edição. Uma atualização sem internet mantém a lista anterior e exibe o erro.

Ao encerrar o processo do app ou fazer **hot restart**, esse estado é perdido. Ao abrir novamente, os dados originais voltam a ser carregados. Não se trata de armazenamento permanente.

### IDs repetidos e edição de publicações recém-criadas

A API costuma retornar `id: 101` para cada POST. Cada criação recebe uma chave interna própria, mantendo dois cadastros distintos mesmo com o mesmo ID de resposta. A interface mostra o ID retornado e identifica o item como criado na sessão.

Como `/posts/101` não é efetivamente criado no servidor, a API pode recusar `PUT /posts/101`. O app envia o PUT ao ID correto e, caso ele seja recusado, explica a limitação e preserva os dados. Não troca o ID por um registro existente nem indica sucesso local para uma operação HTTP que falhou.

**Para demonstrar UPDATE com sucesso, edite uma publicação original, como a de ID 1.** É possível testar CREATE em um novo item e DELETE separadamente. Essa restrição decorre do serviço escolhido e impede garantir a sequência criar → editar o mesmo registro com sucesso na API pública.

Documentação oficial: https://jsonplaceholder.typicode.com/

## Verificação automática

No terminal integrado do Android Studio:

```powershell
flutter analyze
flutter test
```

Os testes cobrem métodos e URLs HTTP, payloads, códigos de resposta, JSON inválido, timeout, falha de conexão, estado após refresh, IDs repetidos, formulários, detalhes, edição e confirmação/cancelamento da exclusão. Utilizam `MockClient`: verificam o código HTTP do aplicativo, mas não comprovam sozinhos disponibilidade ou respostas do servidor público.

Para executar somente os testes do serviço, sem iniciar o aplicativo, também é possível usar `dart test test/api_service_test.dart` depois de resolver as dependências.

Para exercitar o serviço com requisições reais:

```powershell
dart run tool/live_api_check.dart
```

O script executa GET, POST, PUT e DELETE, verifica uma alteração de título e confirma que um GET posterior ainda apresenta o registro original. Ele usa uma publicação original no PUT e no DELETE. Não há dados sensíveis; trata-se de uma API pública de testes.

Consulte `VALIDACAO.md` para os comandos efetivamente executados durante a preparação desta entrega.

## Roteiro de teste no celular

| Teste | Procedimento e resultado esperado |
| --- | --- |
| Listagem | Abrir conectado à internet. A lista deve carregar; tocar em um card deve abrir detalhes. |
| Cadastro | Título `Minha primeira publicação`, conteúdo `Teste da atividade de API REST` e usuário `1`. Salvar e conferir o novo card. |
| Edição | Editar uma publicação original, mudar o título para `Publicação revisada` e salvar. Lista e detalhes devem mostrar o novo título. |
| Exclusão | Tocar em excluir, cancelar e conferir que o item permanece. Repetir e confirmar: o card deve desaparecer. |
| Validação | Salvar com campos vazios e depois com usuário `0`. Nenhum envio deve ocorrer e os campos devem indicar o erro. |
| Conexão | Desligar internet e dados móveis e atualizar. Conferir erro e preservação dos cards. Tentar salvar: o formulário deve manter o texto para nova tentativa. |
| Sessão | Criar dois itens, editar e excluir itens originais e atualizar a lista. As alterações devem continuar visíveis e os dois novos itens devem permanecer distintos. |
| HTTP real | Executar `dart run tool/live_api_check.dart` e verificar as quatro operações. |

## Gerar um APK

No terminal do Android Studio:

```powershell
flutter pub get
flutter build apk --release
```

Resultado esperado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Transfira o arquivo ao celular e autorize a instalação dessa origem quando solicitado pelo Android. Para instalar diretamente no aparelho conectado, use `flutter install -d ID_DO_DISPOSITIVO` depois de gerar o APK.

O projeto usa a assinatura de depuração no build de release para facilitar a instalação acadêmica. Para publicação em loja, configure uma chave própria. Nenhuma chave privada é incluída no projeto.
