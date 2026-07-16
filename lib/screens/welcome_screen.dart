// lib/screens/welcome_screen.dart
// First-run local profile setup. No account is required.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart';
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/local_app_lock_service.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _homeAoCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  AppRole _role = AppRole.q;
  bool _appLockEnabled = false;
  bool _lockSupported = true;
  bool _saving = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _loadLockSupport();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  Future<void> _loadLockSupport() async {
    final supported = await LocalAppLockService().isSupported;
    if (!mounted) return;
    setState(() {
      _lockSupported = supported;
      if (!supported) _appLockEnabled = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _homeAoCtrl.dispose();
    _regionCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthService>();
    final profile = context.read<AppProfileService>();

    final user = await auth.continueAsGuest(
      displayName: _nameCtrl.text,
    );
    await profile.completeWelcome(
      role: _role,
      displayName: _nameCtrl.text,
      homeAo: _homeAoCtrl.text,
      region: _regionCtrl.text,
      authUserId: user.id,
      appLockEnabled: _appLockEnabled,
    );
    if (!mounted) return;
    widget.onComplete();
  }

  /// The "real auth" first-run path: OAuth against F3 Nation, then hydrate
  /// the local profile straight from their database — no manual typing.
  /// Anything the F3 profile doesn't know (home AO, role) still comes from
  /// whatever the user set on this screen.
  Future<void> _signInWithF3() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();

    try {
      final user = await auth.signInWithF3Nation();
      F3UserProfile? f3;
      final token = await auth.getF3AccessToken();
      if (token != null) {
        f3 = await api.getMyProfile(userAccessToken: token);
      }

      final name = (f3?.displayName.isNotEmpty ?? false)
          ? f3!.displayName
          : (user.displayName.isNotEmpty ? user.displayName : _nameCtrl.text);
      await profile.completeWelcome(
        role: _role,
        displayName: name,
        homeAo: _homeAoCtrl.text,
        region: f3?.homeRegionName ?? _regionCtrl.text,
        authUserId: user.id,
        appLockEnabled: _appLockEnabled,
      );
      if (f3?.avatarUrl != null) {
        await profile.applyF3Profile(avatarUrl: f3!.avatarUrl);
      }
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), duration: const Duration(seconds: 6)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.f3bg,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              const SizedBox(height: 36),
              // ── Logo ────────────────────────────────────────────────────────
              const _AppLogo(),
              const SizedBox(height: 28),
              // ── Tagline ─────────────────────────────────────────────────────
              Text(
                l10n.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.f3textSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),
              // ── F3 Nation sign-in (primary path when configured) ────────────
              if (LocalAuthService.f3LoginAvailable) ...[
                ElevatedButton.icon(
                  onPressed: _saving ? null : _signInWithF3,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.shield_rounded),
                  label: const Text('Sign in with F3 Nation'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pulls your PAX profile — F3 name, region, avatar — '
                  'straight from F3 Nation. No typing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionLabel('OR SET UP MANUALLY'),
                const SizedBox(height: 14),
              ] else ...[
                // ── Divider with label ─────────────────────────────────────────
                _SectionLabel(l10n.welcomeSetupProfile),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: context.f3textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.welcomeF3Name,
                  hintText: l10n.welcomeF3NameHint,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _homeAoCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: context.f3textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.welcomeHomeAo,
                  hintText: l10n.welcomeHomeAoHint,
                  prefixIcon: const Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regionCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: context.f3textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.welcomeRegion,
                  hintText: l10n.welcomeRegionHint,
                  prefixIcon: const Icon(Icons.map_rounded),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(l10n.welcomeYourRole),
              const SizedBox(height: 12),
              ...AppRole.values.map((role) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoleTile(
                      role: role,
                      selected: _role == role,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _role = role);
                      },
                    ),
                  )),
              const SizedBox(height: 16),
              // ── Privacy note ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.f3elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.f3divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: context.f3textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.welcomePrivacy,
                        style: TextStyle(
                          color: context.f3textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── App lock ────────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: context.f3card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.f3divider),
                ),
                child: SwitchListTile(
                  value: _appLockEnabled,
                  onChanged: !_lockSupported || _saving
                      ? null
                      : (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _appLockEnabled = value);
                        },
                  activeThumbColor: F3Colors.accent,
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: Text(
                    l10n.welcomeProtectApp,
                    style: TextStyle(
                      color: context.f3textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    _lockSupported
                        ? l10n.welcomeProtectAppDesc
                        : l10n.welcomeProtectNotAvailable,
                    style: TextStyle(
                      color: context.f3textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // ── CTA ──────────────────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _saving ? null : _continue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(_saving ? l10n.welcomeCtaLoading : l10n.welcomeCta),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeSubtext,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App Logo Widget ────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom F3 shield illustration
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: F3Colors.accent.withValues(alpha: 0.30),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Shield CustomPainter
              const CustomPaint(
                size: Size(100, 100),
                painter: _F3ShieldPainter(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // App name
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: [
            TextSpan(
              text: 'DIGITAL ',
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                height: 1,
              ),
            ),
            TextSpan(
              text: 'WEINKE',
              style: TextStyle(
                color: F3Colors.accent,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                height: 1,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(
          'F3 NATION · SPARTAN UP',
          style: TextStyle(
            color: context.f3textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ── F3 Shield Painter ──────────────────────────────────────────────────────────

class _F3ShieldPainter extends CustomPainter {
  const _F3ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Shield silhouette
    final shieldPath = Path()
      ..moveTo(w * 0.50, h * 0.01)
      ..cubicTo(w * 0.97, h * 0.01, w * 0.97, h * 0.52, w * 0.76, h * 0.78)
      ..lineTo(w * 0.50, h * 0.99)
      ..lineTo(w * 0.24, h * 0.78)
      ..cubicTo(w * 0.03, h * 0.52, w * 0.03, h * 0.01, w * 0.50, h * 0.01)
      ..close();

    // Fill
    final fillPaint = Paint()
      ..color = F3Colors.accent
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, fillPaint);

    // Inner highlight (lighter area near top)
    final innerPath = Path()
      ..moveTo(w * 0.50, h * 0.09)
      ..cubicTo(w * 0.89, h * 0.09, w * 0.89, h * 0.48, w * 0.70, h * 0.70)
      ..lineTo(w * 0.50, h * 0.87)
      ..lineTo(w * 0.30, h * 0.70)
      ..cubicTo(w * 0.11, h * 0.48, w * 0.11, h * 0.09, w * 0.50, h * 0.09)
      ..close();
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);

    // Horizontal divider bar
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.44, w * 0.64, h * 0.05),
        Radius.circular(h * 0.02),
      ),
      barPaint,
    );

    // "F3" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'F3',
        style: TextStyle(
          color: Colors.white,
          fontSize: h * 0.32,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, h * 0.14),
    );

    // Small "NATION" text at bottom of shield
    final subPainter = TextPainter(
      text: TextSpan(
        text: 'NATION',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.70),
          fontSize: h * 0.08,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(
      canvas,
      Offset((w - subPainter.width) / 2, h * 0.52),
    );
  }

  @override
  bool shouldRepaint(_F3ShieldPainter old) => false;
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: context.f3divider, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          style: TextStyle(
            color: context.f3textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
      Expanded(child: Divider(color: context.f3divider, thickness: 1)),
    ]);
  }
}

// ── Role tile ─────────────────────────────────────────────────────────────────

class _RoleTile extends StatelessWidget {
  final AppRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  String _roleName(AppLocalizations l10n) {
    switch (role) {
      case AppRole.q:
        return l10n.roleQName;
      case AppRole.pax:
        return l10n.rolePaxName;
      case AppRole.siteQ:
        return role.displayName;
    }
  }

  String _roleDesc(AppLocalizations l10n) {
    switch (role) {
      case AppRole.q:
        return l10n.roleQDesc;
      case AppRole.pax:
        return l10n.rolePaxDesc;
      case AppRole.siteQ:
        return role.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color:
            selected ? F3Colors.accent.withValues(alpha: 0.12) : context.f3card,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? F3Colors.accent : context.f3divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? F3Colors.accent : context.f3textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _roleName(l10n),
                      style: TextStyle(
                        color: selected
                            ? context.f3textPrimary
                            : context.f3textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _roleDesc(l10n),
                      style: TextStyle(
                        color: context.f3textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
