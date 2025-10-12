import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/auth_service.dart';
import '../../../routes/app_pages.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: colors.primary, child: const Icon(Icons.person_outline)),
            title: const Text('User'),
            subtitle: const Text('user@example.com'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Get.find<AuthService>().signOut();
                Get.offAllNamed(AppRoutes.signIn);
              },
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}


