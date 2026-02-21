import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_config.dart';
import 'link_web_view.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/network/apis/settings_api.dart';
import '../../../routes/app_pages.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_item.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/delete_account_dialog.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _enableNotifications = true;
  bool _messageNotifications = false;
  AppSettingsData _appConfig = AppSettingsData();
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _loadError = null;
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
          if (response.user != null) {
            _enableNotifications = response.user!.enableNotifications;
            _messageNotifications = response.user!.messageNotifications;
          }
          _appConfig = response.app;
          _loading = false;
          _loadError = null;
        });
      } else {
        setState(() {
          _loading = false;
          _loadError = 'Could not load settings';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load settings';
        });
      }
    }
  }

  Future<void> _updateToggle({bool? enableNotifications, bool? messageNotifications}) async {
    if (!Get.isRegistered<AuthService>()) return;
    final token = await Get.find<AuthService>().getIdToken();
    if (token == null || token.isEmpty) return;
    final config = AppConfig.fromEnv();
    final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final api = SettingsApi(baseUrl: baseUrl, authToken: token);
    await api.updateSettings(
      enableNotifications: enableNotifications,
      messageNotifications: messageNotifications,
    );
  }

  void _openLinkInApp(String? url, String screenTitle) {
    if (url == null || url.trim().isEmpty) {
      if (mounted) {
        Get.snackbar('', 'Link not configured.', snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }
    Get.to(() => LinkWebView(url: url.trim(), title: screenTitle));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Settings'),
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
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  ] else if (_loadError != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: colors.error, fontSize: 14),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: _loadSettings,
                      child: const Text('Retry'),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const SectionHeader(title: 'NOTIFICATIONS'),
                    const SizedBox(height: 16),
                    SettingsItem(
                      icon: CupertinoIcons.bell,
                      title: 'Enable notifications',
                      isToggle: true,
                      toggleValue: _enableNotifications,
                      onToggleChanged: (value) {
                        setState(() => _enableNotifications = value);
                        _updateToggle(enableNotifications: value);
                      },
                      showArrow: false,
                    ),
                    SettingsItem(
                      icon: CupertinoIcons.chat_bubble_2,
                      title: 'Message',
                      isToggle: true,
                      toggleValue: _messageNotifications,
                      onToggleChanged: (value) {
                        setState(() => _messageNotifications = value);
                        _updateToggle(messageNotifications: value);
                      },
                      showArrow: false,
                    ),
                    const SizedBox(height: 32),
                    const SectionHeader(title: 'APPLICATION'),
                    const SizedBox(height: 16),
                    SettingsItem(
                      icon: CupertinoIcons.shield,
                      title: 'Privacy',
                      onTap: () => _openLinkInApp(_appConfig.privacyPolicyUrl, 'Privacy'),
                    ),
                    SettingsItem(
                      icon: CupertinoIcons.mic,
                      title: 'Language',
                      onTap: () => Get.toNamed(AppRoutes.language),
                    ),
                    SettingsItem(
                      icon: CupertinoIcons.headphones,
                      title: 'Help Center',
                      onTap: () => _openLinkInApp(_appConfig.helpCenterUrl, 'Help Center'),
                    ),
                    SettingsItem(
                      icon: CupertinoIcons.info_circle,
                      title: 'About',
                      onTap: () => Get.toNamed(AppRoutes.about),
                    ),
                    SettingsItem(
                      icon: CupertinoIcons.delete,
                      title: 'Delete Account',
                      onTap: () {
                        DeleteAccountDialog.show(context);
                      },
                      showArrow: false,
                      isDestructive: true,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: colors.onSurface,
                        onPressed: () {
                          LogoutDialog.show(context);
                        },
                        child: const Text(
                          'Sign out',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
