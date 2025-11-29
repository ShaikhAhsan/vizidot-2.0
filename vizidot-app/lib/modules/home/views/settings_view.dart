import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title - matching home screen
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
                  const SizedBox(height: 12),
                  // NOTIFICATIONS Section
                  const SectionHeader(title: 'NOTIFICATIONS'),
                  const SizedBox(height: 16),
                  SettingsItem(
                    icon: CupertinoIcons.bell,
                    title: 'Enable notifications',
                    isToggle: true,
                    toggleValue: _enableNotifications,
                    onToggleChanged: (value) {
                      setState(() {
                        _enableNotifications = value;
                      });
                    },
                    showArrow: false,
                  ),
                  SettingsItem(
                    icon: CupertinoIcons.chat_bubble_2,
                    title: 'Message',
                    isToggle: true,
                    toggleValue: _messageNotifications,
                    onToggleChanged: (value) {
                      setState(() {
                        _messageNotifications = value;
                      });
                    },
                    showArrow: false,
                  ),
                  const SizedBox(height: 32),
                  // APPLICATION Section
                  const SectionHeader(title: 'APPLICATION'),
                  const SizedBox(height: 16),
                  SettingsItem(
                    icon: CupertinoIcons.shield,
                    title: 'Privacy',
                    onTap: () {
                      // TODO: Navigate to privacy settings
                    },
                  ),
                  SettingsItem(
                    icon: CupertinoIcons.mic,
                    title: 'Language',
                    onTap: () {
                      // TODO: Navigate to language settings
                    },
                  ),
                  SettingsItem(
                    icon: CupertinoIcons.headphones,
                    title: 'Help Center',
                    onTap: () {
                      // TODO: Navigate to help center
                    },
                  ),
                  SettingsItem(
                    icon: CupertinoIcons.info_circle,
                    title: 'About',
                    onTap: () {
                      // TODO: Show about dialog
                    },
                    showArrow: false,
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
                  // Sign Out Button
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
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

