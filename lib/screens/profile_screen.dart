// lib/screens/profile_screen.dart
// The PAX's profile: avatar (uploadable), F3 name, region, and — when signed
// in to F3 Nation — emergency contact info pulled from their database. This
// is the "view profile" surface reachable from the home avatar.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart';
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/org_picker.dart';
import 'emergency_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  F3UserProfile? _f3;
  bool _loading = false;
  bool _uploading = false;
  // True when we had a token but the server still rejected the profile
  // fetch — almost always a dead/expired F3 Nation session (the refresh
  // token itself expired or was revoked), which silently falls back to a
  // stale access token rather than surfacing the failure. The fix is a full
  // sign-out + sign-in, not a retry.
  bool _sessionExpired = false;

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
      _sessionExpired = token != null && f3 == null;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePhotoFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showAvatarSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.f3card,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.profileChooseFromLibrary),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(l10n.profileTakePhoto),
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

  /// Edits the signed-in PAX's own F3 Nation record — writes through the
  /// app's trusted key (`F3ApiService.updateUserProfile`), identified by the
  /// numeric F3 user id (`AppProfileService.authUserId`), per Tackle's
  /// guidance to use `POST /v1/user` rather than the user-token `/me/profile`.
  Future<void> _editProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.read<AppProfileService>();
    final userId = int.tryParse(profile.authUserId);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSignInFirstToast)));
      return;
    }
    final f3NameCtrl = TextEditingController(text: _f3?.f3Name ?? '');
    final firstNameCtrl = TextEditingController(text: _f3?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: _f3?.lastName ?? '');
    final emailCtrl = TextEditingController(text: _f3?.email ?? '');
    final phoneCtrl = TextEditingController(text: _f3?.phone ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.f3card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileEditTitle,
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
                controller: f3NameCtrl,
                decoration: InputDecoration(labelText: l10n.profileF3NameField)),
            const SizedBox(height: 10),
            TextField(
                controller: firstNameCtrl,
                decoration: InputDecoration(labelText: l10n.profileFirstNameField)),
            const SizedBox(height: 10),
            TextField(
                controller: lastNameCtrl,
                decoration: InputDecoration(labelText: l10n.profileLastNameField)),
            const SizedBox(height: 10),
            TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.profileEmailField)),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.profilePhoneField)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(l10n.profileSave),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;

    final api = context.read<F3ApiService>();
    setState(() => _loading = true);
    final err = await api.updateUserProfile(
      userId: userId,
      f3Name: f3NameCtrl.text.trim(),
      firstName: firstNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await _fetch();
  }

  Future<void> _changeRegion() async {
    final api = context.read<F3ApiService>();
    final picked =
        await showOrgPickerSheet(context, fetchOrgs: api.getOrgs);
    if (picked == null) return;
    api.userOrgId = picked.id;
    if (mounted) {
      context.read<AppProfileService>().updateProfile(
            role: AppRole.q,
            region: picked.name,
          );
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text(l10n.profileSignOutTitle),
        content: Text(l10n.profileSignOutBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.profileCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.profileSignOut)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthService>().signOut();
    // This screen was reached via Navigator.push (from Home/Settings), so it
    // sits on top of the app's single Navigator as its own route. Swapping
    // auth state makes the root (_AppEntry in main.dart) rebuild into
    // LoginGateScreen underneath, but that alone doesn't pop this pushed
    // route — without this, the user stays stuck looking at Profile's own
    // "not linked" state instead of landing on the login screen.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        backgroundColor: context.f3bg,
      ),
      body: Consumer2<AppProfileService, AuthService>(
        builder: (context, profile, auth, _) {
          final linked = _isLinked(auth);
          final name =
              profile.displayName.isEmpty ? l10n.rolePaxName : profile.displayName;
          return RefreshIndicator(
            onRefresh: _fetch,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.f3card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.f3divider),
                  ),
                  child: Column(children: [
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
                        child: Tooltip(
                          message: AppLocalizations.of(context)!.profileChangePhoto,
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
                  ]),
                ),
                const SizedBox(height: 24),

                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (!linked)
                  _InfoRow(
                    icon: Icons.link_off_rounded,
                    label: l10n.profileNotLinked,
                    value: l10n.profileNotLinkedDesc,
                  )
                else if (_sessionExpired) ...[
                  _InfoRow(
                    icon: Icons.warning_rounded,
                    label: l10n.profileSessionExpired,
                    value: l10n.profileSessionExpiredDesc,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.profileSignOut),
                    ),
                  ),
                ] else ...[
                  Row(children: [
                    Expanded(child: _SectionLabel(l10n.profileSectionF3Nation)),
                    TextButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(l10n.profileEdit),
                    ),
                  ]),
                  _InfoRow(
                      icon: Icons.badge_rounded,
                      label: l10n.profileF3NameField,
                      value: _f3?.f3Name ?? name),
                  if ((_f3?.firstName ?? '').isNotEmpty ||
                      (_f3?.lastName ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.person_rounded,
                        label: l10n.profileNameField,
                        value:
                            '${_f3?.firstName ?? ''} ${_f3?.lastName ?? ''}'
                                .trim()),
                  if ((_f3?.email ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.email_rounded,
                        label: l10n.profileEmailField,
                        value: _f3!.email),
                  if ((_f3?.phone ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.phone_rounded,
                        label: l10n.profilePhoneField,
                        value: _f3!.phone!),
                  if ((_f3?.homeRegionName ?? '').isNotEmpty)
                    _InfoRow(
                        icon: Icons.map_rounded,
                        label: l10n.profileHomeRegionField,
                        value: _f3!.homeRegionName!),
                  const SizedBox(height: 8),
                  Material(
                    color: context.f3card,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EmergencyScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          const Icon(Icons.medical_services_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.profileEmergencyInfo,
                                    style: TextStyle(
                                        color: context.f3textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                Text(l10n.profileEmergencyInfoSub,
                                    style: TextStyle(
                                        color: context.f3textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: context.f3textMuted),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: context.f3card,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _changeRegion,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          const Icon(Icons.tune_rounded,
                              color: F3Colors.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(l10n.profileChangeRegion,
                                style: TextStyle(
                                    color: context.f3textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: context.f3textMuted),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.profileSignOut),
                    ),
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
