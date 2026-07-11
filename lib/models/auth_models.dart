// lib/models/auth_models.dart
// Provider-agnostic auth models. Slack, Google, Apple, email, or a custom
// backend can all map into this shape.

enum AuthProvider {
  guest,
  slack,
  email,
  google,
  apple;

  String get displayName {
    switch (this) {
      case AuthProvider.guest:
        return 'Guest';
      case AuthProvider.slack:
        return 'Slack';
      case AuthProvider.email:
        return 'Email';
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
    }
  }
}

class AppUser {
  final String id;
  final String displayName;
  final String email;
  final bool isGuest;
  final List<LinkedIdentity> identities;

  const AppUser({
    required this.id,
    this.displayName = '',
    this.email = '',
    this.isGuest = false,
    this.identities = const [],
  });

  factory AppUser.guest({
    required String id,
    String displayName = '',
  }) =>
      AppUser(
        id: id,
        displayName: displayName,
        isGuest: true,
        identities: [
          LinkedIdentity(
            provider: AuthProvider.guest,
            providerUserId: id,
          ),
        ],
      );

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        isGuest: json['isGuest'] as bool? ?? false,
        identities: (json['identities'] as List<dynamic>?)
                ?.map((item) =>
                    LinkedIdentity.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'isGuest': isGuest,
        'identities': identities.map((item) => item.toJson()).toList(),
      };
}

class LinkedIdentity {
  final AuthProvider provider;
  final String providerUserId;
  final String email;
  final String workspaceId;
  final String workspaceName;

  const LinkedIdentity({
    required this.provider,
    required this.providerUserId,
    this.email = '',
    this.workspaceId = '',
    this.workspaceName = '',
  });

  factory LinkedIdentity.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String?;
    return LinkedIdentity(
      provider: AuthProvider.values.firstWhere(
        (provider) => provider.name == providerName,
        orElse: () => AuthProvider.guest,
      ),
      providerUserId: json['providerUserId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? '',
      workspaceName: json['workspaceName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'providerUserId': providerUserId,
        'email': email,
        'workspaceId': workspaceId,
        'workspaceName': workspaceName,
      };
}

class AuthUnavailableException implements Exception {
  final String message;
  const AuthUnavailableException(this.message);

  @override
  String toString() => message;
}
