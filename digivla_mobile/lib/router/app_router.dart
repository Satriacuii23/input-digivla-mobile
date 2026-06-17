import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_provider.dart';
import '../core/auth/rbac.dart';
import '../models/article.dart';
import '../models/media.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/articles/article_edit_screen.dart';
import '../screens/articles/article_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/media/add_media_screen.dart';
import '../screens/media/edit_media_screen.dart';
import '../screens/media/media_detail_screen.dart';
import '../screens/media/media_list_screen.dart';
import '../screens/qc/article_qc_screen.dart';
import '../screens/tools/tools_screen.dart';
import '../screens/upload/multi_upload_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../screens/users/user_management_screen.dart';
import '../widgets/app_scaffold.dart';

GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) {
        return UserRbac.defaultHome(auth.user?.role);
      }
      if (loggedIn) {
        final path = state.matchedLocation;
        if (!UserRbac.canAccessRoute(auth.user?.role, path)) {
          return UserRbac.defaultHome(auth.user?.role);
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/tools', builder: (_, __) => const ToolsScreen()),
      GoRoute(path: '/users', builder: (_, __) => const UserManagementScreen()),

      for (final ch in ArticleChannel.values)
        GoRoute(
          path: '/qc/${ch.apiPath}',
          builder: (_, __) => ArticleQcScreen(channel: ch),
        ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/media', builder: (_, __) => const MediaListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tv', builder: (_, __) => const ArticleListScreen(channel: ArticleChannel.tv)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/radio', builder: (_, __) => const ArticleListScreen(channel: ArticleChannel.radio)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/online', builder: (_, __) => const ArticleListScreen(channel: ArticleChannel.online)),
          ]),
        ],
      ),

      GoRoute(path: '/media/add', builder: (_, __) => const AddMediaScreen()),
      GoRoute(
        path: '/media/preview/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MediaModel) return MediaDetailScreen(media: extra);
          return const Scaffold(body: Center(child: Text('Media tidak ditemukan')));
        },
      ),
      GoRoute(
        path: '/media/edit/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MediaModel) return EditMediaScreen(media: extra);
          return const Scaffold(body: Center(child: Text('Media tidak ditemukan')));
        },
      ),

      for (final ch in ArticleChannel.values) ...[
        GoRoute(
          path: '/${ch.apiPath}/upload',
          builder: (_, __) => UploadScreen(channel: ch),
        ),
        GoRoute(
          path: '/${ch.apiPath}/upload/multi',
          builder: (_, __) => MultiUploadScreen(channel: ch),
        ),
        GoRoute(
          path: '/${ch.apiPath}/preview/:id',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is ArticleModel) {
              return ArticleDetailScreen(channel: ch, article: extra);
            }
            return const Scaffold(body: Center(child: Text('Artikel tidak ditemukan')));
          },
        ),
        GoRoute(
          path: '/${ch.apiPath}/edit/:id',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is ArticleModel) {
              return ArticleEditScreen(channel: ch, article: extra);
            }
            return const Scaffold(body: Center(child: Text('Artikel tidak ditemukan')));
          },
        ),
      ],
    ],
  );
}
