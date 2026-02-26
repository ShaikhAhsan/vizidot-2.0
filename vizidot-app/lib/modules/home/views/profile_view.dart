import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/utils/user_profile_service.dart';
import '../../../core/utils/app_config.dart';
import '../../../core/network/apis/settings_api.dart';
import '../../../routes/app_pages.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  ProfileTab _selectedTab = ProfileTab.personal;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  String? _fullProfileImageUrl(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) return null;
    if (profileImageUrl.startsWith('http')) return profileImageUrl;
    final base = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>().baseUrl : AppConfig.fromEnv().baseUrl;
    final baseUrl = base.replaceFirst(RegExp(r'/$'), '');
    return baseUrl + (profileImageUrl.startsWith('/') ? profileImageUrl : '/$profileImageUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = Get.isRegistered<UserProfileService>() ? Get.find<UserProfileService>().profile : null;
      final name = profile?.fullName ?? 'User';
      final role = profile?.caption?.trim().isNotEmpty == true ? profile!.caption! : 'Artist / Musician / Writer';
      final profileImageUrl = _fullProfileImageUrl(profile?.profileImageUrl);
      final hasArtists = profile?.hasAssignedArtists == true;

      return CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Profile'),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: () => Get.toNamed(AppRoutes.settings),
                  child: const Icon(CupertinoIcons.gear, color: Colors.black, size: 20),
                ),
              ),
              backgroundColor: Colors.transparent,
              border: null,
              automaticallyImplyTitle: false,
              automaticallyImplyLeading: false,
            ),
            if (hasArtists) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 0)),
              SliverToBoxAdapter(
                child: _ProfileTabBar(
                  selectedTab: _selectedTab,
                  onTabChanged: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
            ],
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: hasArtists
                    ? (_selectedTab == ProfileTab.personal
                        ? _sliverPersonalTab(profileImageUrl: profileImageUrl, name: name, role: role, extraTopPadding: 20)
                        : _sliverArtistTab(profile))
                    : _sliverPersonalTab(profileImageUrl: profileImageUrl, name: name, role: role, extraTopPadding: 0),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _sliverPersonalTab({
    required String? profileImageUrl,
    required String name,
    required String role,
    double extraTopPadding = 0,
  }) {
    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 10 + extraTopPadding),
        ProfileHeader(
          profileImageUrl: profileImageUrl,
          fallbackAssetPath: 'assets/artists/Choc B.png',
          name: name,
          role: role,
        ),
        const SizedBox(height: 20),
        ProfileMenuItem(
          icon: CupertinoIcons.person,
          title: 'Personal data',
          onTap: () => Get.toNamed(AppRoutes.personalData),
        ),
        if (Get.isRegistered<AuthService>() && Get.find<AuthService>().canChangePassword)
          ProfileMenuItem(
            icon: CupertinoIcons.lock,
            title: 'Change password',
            onTap: () => Get.toNamed(AppRoutes.changePassword),
          ),
        ProfileMenuItem(
          icon: CupertinoIcons.lightbulb,
          title: 'Announcements',
          onTap: () => Get.toNamed(AppRoutes.notifications),
        ),
        const SizedBox(height: 40),
        Center(
          child: Text(
            'Version $_version (Build $_buildNumber)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sliverArtistTab(UserProfileData? profile) {
    if (profile?.hasAssignedArtists != true) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ArtistTabEmptyState(),
      );
    }
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 30),
        _ProfileArtistSection(
          artists: profile!.assignedArtists!,
          fullProfileImageUrl: _fullProfileImageUrl,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

enum ProfileTab { personal, artist }

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final ProfileTab selectedTab;
  final ValueChanged<ProfileTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark
              ? colors.surfaceContainerHighest.withOpacity(0.6)
              : colors.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colors.outline.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: _ProfileTabButton(
                  label: 'Personal',
                  icon: CupertinoIcons.person_fill,
                  isSelected: selectedTab == ProfileTab.personal,
                  onTap: () => onTabChanged(ProfileTab.personal),
                  colors: colors,
                  textTheme: textTheme,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 56,
                child: _ProfileTabButton(
                  label: 'Artist',
                  icon: CupertinoIcons.music_note_2,
                  isSelected: selectedTab == ProfileTab.artist,
                  onTap: () => onTabChanged(ProfileTab.artist),
                  colors: colors,
                  textTheme: textTheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final ColorScheme colors;
  final TextTheme textTheme;

  const _ProfileTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.shadow.withOpacity(isSelected ? 0.1 : 0),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: SizedBox.expand(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? colors.primary
                      : (enabled ? colors.onSurface.withOpacity(0.5) : colors.onSurface.withOpacity(0.3)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colors.onSurface
                        : (enabled ? colors.onSurface.withOpacity(0.7) : colors.onSurface.withOpacity(0.4)),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtistTabEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_2,
              size: 64,
              color: colors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No artist assigned',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your assigned artist profile will appear here once linked to your account.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section showing assigned artists in same layout as Personal: header (image, name, bio) + Messages menu row with counter.
class _ProfileArtistSection extends StatelessWidget {
  const _ProfileArtistSection({
    required this.artists,
    required this.fullProfileImageUrl,
  });

  final List<AssignedArtistData> artists;
  final String? Function(String?) fullProfileImageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < artists.length; i++) ...[
          if (i > 0) const SizedBox(height: 40),
          _ArtistProfileBlock(
            artist: artists[i],
            fullProfileImageUrl: fullProfileImageUrl,
          ),
        ],
      ],
    );
  }
}

/// One artist profile: same as Personal tab (ProfileHeader + Messages menu item with counter).
class _ArtistProfileBlock extends StatelessWidget {
  const _ArtistProfileBlock({
    required this.artist,
    required this.fullProfileImageUrl,
  });

  final AssignedArtistData artist;
  final String? Function(String?) fullProfileImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = fullProfileImageUrl(artist.imageUrl);
    final bio = artist.bio?.trim().isNotEmpty == true
        ? artist.bio!
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileHeader(
          profileImageUrl: imageUrl,
          fallbackAssetPath: null,
          name: artist.name,
          role: bio,
        ),
        const SizedBox(height: 20),
        _MessagesMenuItem(
          artistId: artist.artistId,
          artistName: artist.name,
          artistImageUrl: imageUrl,
        ),
      ],
    );
  }
}

/// Messages menu row in same style as Personal data / Announcements, with Firestore message count.
class _MessagesMenuItem extends StatelessWidget {
  const _MessagesMenuItem({
    required this.artistId,
    required this.artistName,
    this.artistImageUrl,
  });

  final int artistId;
  final String artistName;
  final String? artistImageUrl;

  static const String _chatsCollection = 'chats';
  static const String _messagesSubcollection = 'messages';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final uid = auth.FirebaseAuth.instance.currentUser?.uid;
    final chatId =
        uid != null ? 'user_${uid}_artist_$artistId' : 'user__artist_$artistId';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: uid != null
          ? FirebaseFirestore.instance
              .collection(_chatsCollection)
              .doc(chatId)
              .collection(_messagesSubcollection)
              .snapshots()
          : Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        Widget? trailing;
        if (count > 0) {
          trailing = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: textTheme.labelSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        }
        return ProfileMenuItem(
          icon: CupertinoIcons.chat_bubble_2,
          title: 'Messages',
          onTap: () {
            Get.toNamed(
              AppRoutes.artistMessage,
              arguments: {
                'artistId': artistId,
                'artistName': artistName,
                'artistImageUrl': artistImageUrl,
              },
            );
          },
          trailing: trailing,
        );
      },
    );
  }
}
