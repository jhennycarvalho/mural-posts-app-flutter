/// [key] identifica um item na sessão, pois vários POSTs podem retornar ID 101.
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.key,
    this.createdInSession = false,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
  final String key;
  final bool createdInSession;

  factory Post.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['userId'];
    final title = json['title'];
    final body = json['body'];
    if (id is! int || userId is! int || title is! String || body is! String) {
      throw const FormatException('Publicação com dados inválidos.');
    }
    return Post(
      id: id,
      userId: userId,
      title: title,
      body: body,
      key: 'api-$id',
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) => {
        if (includeId) 'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };

  Post copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? key,
    bool? createdInSession,
  }) =>
      Post(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        key: key ?? this.key,
        createdInSession: createdInSession ?? this.createdInSession,
      );
}
