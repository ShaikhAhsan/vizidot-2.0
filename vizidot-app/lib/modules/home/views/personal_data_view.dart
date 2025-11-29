import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../widgets/profile_image_upload.dart';
import '../widgets/custom_text_field.dart';

class PersonalDataView extends StatefulWidget {
  const PersonalDataView({super.key});

  @override
  State<PersonalDataView> createState() => _PersonalDataViewState();
}

class _PersonalDataViewState extends State<PersonalDataView> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: 'Jakob Lee');
    _emailController = TextEditingController(text: 'james.taylor@gmail.com');
    _captionController = TextEditingController(text: 'Dj/Producer/Artist');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          // Navigation Bar with Large Title - matching home screen
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Personal data'),
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
                  const SizedBox(height: 32),
                  // Profile Image Upload
                  Center(
                    child: ProfileImageUpload(
                      imagePath: 'assets/artists/Choc B.png',
                      onTap: () {
                        // TODO: Open image picker
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Full Name Field
                  CustomTextField(
                    label: 'Full name',
                    controller: _fullNameController,
                    hint: 'write a full name...',
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),
                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'Enter your email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Caption Field
                  CustomTextField(
                    label: 'Caption',
                    controller: _captionController,
                    hint: 'Dj/Producer/Artist',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 40),
                  // Update Info Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: colors.onSurface,
                      onPressed: () {
                        // TODO: Update user info
                        Get.back();
                      },
                      child: const Text(
                        'Update info',
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

