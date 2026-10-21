import 'package:flutter/material.dart';

import 'providers/post_provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() => runApp(const MuralApp());

class MuralApp extends StatefulWidget {
  const MuralApp({super.key});
  @override
  State<MuralApp> createState() => _MuralAppState();
}

class _MuralAppState extends State<MuralApp> {
  late final PostProvider provider = PostProvider(ApiService());
  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mural',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: HomeScreen(provider: provider),
      );
}
