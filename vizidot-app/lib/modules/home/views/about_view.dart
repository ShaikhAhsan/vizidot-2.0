import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/network/apis/settings_api.dart';
import 'link_web_view.dart';

/// Full About page. Content is loaded from the server (GET /api/v1/settings app config).
class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  AppSettingsData? _app;
  bool _loading = true;
  String? _error;
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadAbout();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAbout() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      String? token;
      if (Get.isRegistered<AuthService>()) {
        token = await Get.find<AuthService>().getIdToken();
      }
      final api = SettingsApi(baseUrl: baseUrl, authToken: token);
      final response = await api.getSettings(useAuth: true);
      if (!mounted) return;
      if (response != null) {
        setState(() {
          _app = response.app;
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Could not load about';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load about';
        });
      }
    }
  }

  Future<void> _openLink(String? url, String title) async {
    if (url == null || url.trim().isEmpty) return;
    final u = url.trim();
    if (u.startsWith('mailto:')) {
      final uri = Uri.parse(u);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    Get.to(() => LinkWebView(url: u, title: title));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('About'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => Get.back(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.arrow_left,
                  color: colors.onSurface,
                  size: 18,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            border: null,
            automaticallyImplyTitle: false,
            automaticallyImplyLeading: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _loading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                    )
                  : _error != null
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(color: colors.error),
                                ),
                                const SizedBox(height: 12),
                                CupertinoButton(
                                  onPressed: _loadAbout,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildListDelegate(
                            _buildContent(colors, textTheme),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(ColorScheme colors, TextTheme textTheme) {
    final app = _app!;
    final appName = app.appName?.trim().isNotEmpty == true
        ? app.appName!
        : 'Vizidot';
    final tagline = app.aboutTagline?.trim().isNotEmpty == true
        ? app.aboutTagline!
        : 'Connect with artists and stream exclusive content.';
    final description = app.aboutDescription?.trim().isNotEmpty == true
        ? app.aboutDescription!
        : app.aboutText?.trim().isNotEmpty == true
            ? app.aboutText!
            : 'Scan Vizidot codes to unlock music, videos, and artist content. Follow your favourite artists, save albums and tracks, and message artists directly.';
    final version = app.aboutVersion?.trim().isNotEmpty == true
        ? app.aboutVersion!
        : _appVersion;
    final build = app.aboutBuild?.trim().isNotEmpty == true
        ? app.aboutBuild!
        : _buildNumber;

    return [
      const SizedBox(height: 24),
      // App icon placeholder + name
      Center(
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                CupertinoIcons.music_note_2,
                size: 44,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              appName,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tagline,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      // Description card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          description,
          style: textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: colors.onSurface,
          ),
        ),
      ),
      const SizedBox(height: 28),
      // Version
      Center(
        child: Text(
          'Version $version (Build $build)',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withOpacity(0.6),
          ),
        ),
      ),
      const SizedBox(height: 32),
      // Links section
      Text(
        'Links',
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface.withOpacity(0.8),
        ),
      ),
      const SizedBox(height: 12),
      if (app.websiteUrl != null && app.websiteUrl!.trim().isNotEmpty)
        _AboutLinkTile(
          icon: CupertinoIcons.globe,
          title: 'Website',
          onTap: () => _openLink(app.websiteUrl, 'Website'),
        ),
      if (app.contactEmail != null && app.contactEmail!.trim().isNotEmpty)
        _AboutLinkTile(
          icon: CupertinoIcons.mail,
          title: 'Contact us',
          subtitle: app.contactEmail,
          onTap: () => _openLink('mailto:${app.contactEmail}', 'Contact'),
        ),
      if (app.helpCenterUrl != null && app.helpCenterUrl!.trim().isNotEmpty)
        _AboutLinkTile(
          icon: CupertinoIcons.question_circle,
          title: 'Help Center',
          onTap: () => _openLink(app.helpCenterUrl, 'Help Center'),
        ),
      if (app.privacyPolicyUrl != null && app.privacyPolicyUrl!.trim().isNotEmpty)
        _AboutLinkTile(
          icon: CupertinoIcons.shield,
          title: 'Privacy Policy',
          onTap: () => _openLink(app.privacyPolicyUrl, 'Privacy Policy'),
        ),
      if (app.termsUrl != null && app.termsUrl!.trim().isNotEmpty)
        _AboutLinkTile(
          icon: CupertinoIcons.doc_text,
          title: 'Terms of Service',
          onTap: () => _openLink(app.termsUrl, 'Terms of Service'),
        ),
      const SizedBox(height: 40),
    ];
  }
}

class _AboutLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _AboutLinkTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        alignment: Alignment.centerLeft,
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: colors.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
