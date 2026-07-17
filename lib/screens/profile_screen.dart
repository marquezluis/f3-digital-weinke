// lib/screens/profile_screen.dart
// The PAX's profile: avatar (uploadable), F3 name, region, and — when signed
// in to F3 Nation — emergency contact info pulled from their database. This
// is the "view profile" surface reachable from the home avatar.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  F3UserProfile? _f3;
  bool _loading = false;
  bool _uploading = false;

  bool _isLinked(AuthService auth) =>
      auth.currentUser?.identities
          .any((i) => i.provider == AuthProvider.f3nation) ??
      false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    if (!_isLinked(auth)) return;
    setState(() => _loading = true);
    final token = await auth.getF3AccessToken();
    F3UserProfile? f3;
    if (token != null) {
      f3 = await api.getMyProfile(userAccessToken: token);
    }
    if (!mounted) return;
    setState(() {
      _f3 = f3;
      _loading = false;
    });
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      setState(() => _uploading = true);
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      // Copy into app documents so it survives cache clears.
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/avatar.jpg');
      await dest.writeAsBytes(await picked.readAsBytes());
      if (!mounted) return;
      await context.read<AppProfileService>().setLocalAvatarPath(dest.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Photo failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showAvatarSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.f3card,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from library'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(AppProfileService p) {
    if (p.localAvatarPath.isNotEmpty && File(p.localAvatarPath).existsSync()) {
      return FileImage(File(p.localAvatarPath));
    }
    if (p.avatarUrl.isNotEmpty) return NetworkImage(p.avatarUrl);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: context.f3bg,
      ),
      body: Consumer2<AppProfileService, AuthService>(
        builder: (context, profile, auth, _) {
          final linked = _isLinked(auth);
          final name =
              profile.displayName.isEmpty ? 'PAX' : profile.displayName;
          return RefreshIndicator(
            onRefresh: _fetch,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            F3Colors.accent.withValues(alpha: 0.14),
                        foregroundImage: _avatarImage(profile),
                        child: _avatarImage(profile) == null
                            ? Text(
                                name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                    color: F3Colors.accent,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: F3Colors.accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _uploading ? null : _showAvatarSheet,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _uploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(name,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
                if (profile.region.isNotEmpty)
                  Center(
                    child: Text(profile.region,
                        style: TextStyle(
                            color: context.f3textSecondary, fontSize: 14)),
                  ),
                const SizedBox(height: 24),

                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (!linked)
                  _InfoRow(
                    icon: Icons.link_off_rounded,
                    label: 'Not linked to F3 Nation',
                    value: 'Sign in from Settings to pull your profile, '
                        'region, and emergency info.',
                  )
                else ...[
                  _SectionLabel('F3 NATION'),
                  _InfoRow(
                      icon: Icons.badge_rounded,
                      label: 'F3 Name',
                      value: _f3?.f3Name ?? name),
                  if ((_f3?.firstName ?? '').isNotEmpty ||
                      (_f3?.lastName ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.person_rounded,
                        label: 'Name',
                        value:
                            '${_f3?.firstName ?? ''} ${_f3?.lastName ?? ''}'
                                .trim()),
                  if ((_f3?.email ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: _f3!.email),
                  if ((_f3?.homeRegionName ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.map_rounded,
                        label: 'Home Region',
                        value: _f3!.homeRegionName!),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.medical_services_rounded,
                    label: 'Emergency info',
                    value: 'Managed in the F3 Nation .me app. '
                        'Editing here is coming soon.',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: F3Colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.f3textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: context.f3textPrimary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
