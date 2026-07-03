/// Role-Based Access Control — mirrors Frontend/V2/src/lib/auth/rbac.ts
enum AppRole {
  superadmin,
  admin,
  staffOnline,
  staffTvRadio,
  analis,
}

class UserRbac {
  static AppRole? normalizeRole(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'superadmin':
        return AppRole.superadmin;
      case 'admin':
        return AppRole.admin;
      case 'staff_online':
      case 'online':
      case 'user':
      case 'staff':
        return AppRole.staffOnline;
      case 'staff_tv_radio':
      case 'staff_tv':
      case 'staff_radio':
      case 'tv':
      case 'radio':
      case 'tvradio':
        return AppRole.staffTvRadio;
      case 'analis':
        return AppRole.analis;
      default:
        return null;
    }
  }

  static String roleLabel(String? raw) {
    switch (normalizeRole(raw)) {
      case AppRole.superadmin:
        return 'Super Admin';
      case AppRole.admin:
        return 'Administrator';
      case AppRole.staffOnline:
        return 'Staff Online';
      case AppRole.staffTvRadio:
        return 'Staff TV & Radio';
      case AppRole.analis:
        return 'Analis';
      default:
        return raw ?? 'Unknown';
    }
  }

  static bool _isFullAccess(AppRole? role) =>
      role == AppRole.superadmin || role == AppRole.admin;

  static bool canManageUsers(String? rawRole) {
    final role = normalizeRole(rawRole);
    return role == AppRole.superadmin || role == AppRole.admin;
  }

  static bool canUseTools(String? rawRole) {
    final role = normalizeRole(rawRole);
    return role == AppRole.superadmin || role == AppRole.admin || role == AppRole.analis;
  }

  static bool canQcChannel(String? rawRole, String channel) {
    final role = normalizeRole(rawRole);
    if (role == null) return false;
    if (_isFullAccess(role)) return true;
    switch (channel) {
      case 'tv':
      case 'radio':
        return role == AppRole.staffTvRadio;
      case 'online':
        return role == AppRole.staffOnline;
      default:
        return false;
    }
  }

  static bool canAccessRoute(String? rawRole, String path) {
    final role = normalizeRole(rawRole);
    if (role == null) return false;
    if (_isFullAccess(role)) return true;

    if (path == '/home' || path.startsWith('/home/')) return true;
    if (path == '/tools' || path.startsWith('/tools/')) return canUseTools(rawRole);
    if (path == '/users' || path.startsWith('/users/')) return canManageUsers(rawRole);

    if (path.startsWith('/qc/tv')) return canQcChannel(rawRole, 'tv');
    if (path.startsWith('/qc/radio')) return canQcChannel(rawRole, 'radio');
    if (path.startsWith('/qc/online')) return canQcChannel(rawRole, 'online');

    if (path.startsWith('/media/add') || path.startsWith('/media/edit')) {
      return canManageMedia(rawRole);
    }
    if (path.startsWith('/media')) {
      return role == AppRole.staffOnline || role == AppRole.staffTvRadio;
    }

    if (path.startsWith('/tv/upload') || path.startsWith('/tv/edit')) {
      return canWriteChannel(rawRole, 'tv');
    }
    if (path.startsWith('/radio/upload') || path.startsWith('/radio/edit')) {
      return canWriteChannel(rawRole, 'radio');
    }
    if (path.startsWith('/online/upload') || path.startsWith('/online/edit')) {
      return canWriteChannel(rawRole, 'online');
    }

    if (path.startsWith('/tv')) return canReadChannel(rawRole, 'tv');
    if (path.startsWith('/radio')) return canReadChannel(rawRole, 'radio');
    if (path.startsWith('/online')) return canReadChannel(rawRole, 'online');

    return false;
  }

  static bool canReadChannel(String? rawRole, String channel) {
    final role = normalizeRole(rawRole);
    if (role == null) return false;
    if (_isFullAccess(role)) return true;
    switch (channel) {
      case 'tv':
      case 'radio':
        return role == AppRole.staffTvRadio;
      case 'online':
        return role == AppRole.staffOnline;
      default:
        return false;
    }
  }

  static bool canWriteChannel(String? rawRole, String channel) {
    final role = normalizeRole(rawRole);
    if (role == null) return false;
    if (_isFullAccess(role)) return true;
    switch (channel) {
      case 'tv':
      case 'radio':
        return role == AppRole.staffTvRadio;
      case 'online':
        return role == AppRole.staffOnline;
      default:
        return false;
    }
  }

  static bool canDeleteArticles(String? rawRole) => _isFullAccess(normalizeRole(rawRole));

  static bool canManageMedia(String? rawRole) => _isFullAccess(normalizeRole(rawRole));

  static String defaultHome(String? rawRole) {
    switch (normalizeRole(rawRole)) {
      case AppRole.staffTvRadio:
        return '/tv';
      case AppRole.staffOnline:
        return '/online';
      case AppRole.analis:
        return '/tools/media-reach';
      default:
        return '/home';
    }
  }

  static List<String> allowedTabRoutes(String? rawRole) {
    final role = normalizeRole(rawRole);
    if (role == null) return const [];
    if (role == AppRole.superadmin || role == AppRole.admin) {
      return const ['/home', '/media', '/tv', '/radio', '/online'];
    }
    if (role == AppRole.staffTvRadio) return const ['/home', '/media', '/tv', '/radio'];
    if (role == AppRole.staffOnline) return const ['/home', '/media', '/online'];
    return const ['/home'];
  }
}
