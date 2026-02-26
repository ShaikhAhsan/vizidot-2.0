import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

import '../../../core/utils/app_config.dart';
import '../../../core/utils/auth_service.dart';
import '../../../core/utils/user_profile_service.dart';
import '../../../core/network/apis/settings_api.dart';
import '../widgets/profile_image_upload.dart';
import '../widgets/custom_text_field.dart';

class PersonalDataView extends StatefulWidget {
  const PersonalDataView({super.key});

  @override
  State<PersonalDataView> createState() => _PersonalDataViewState();
}

class _PersonalDataViewState extends State<PersonalDataView> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _captionController;

  bool _loading = true;
  bool _saving = false;
  String? _profileImageUrl;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _captionController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  String get _baseUrl {
    final base = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>().baseUrl : AppConfig.fromEnv().baseUrl;
    return base.replaceFirst(RegExp(r'/$'), '');
  }

  String? _fullProfileImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return _baseUrl + (url.startsWith('/') ? url : '/$url');
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    if (Get.isRegistered<UserProfileService>()) {
      final profile = Get.find<UserProfileService>().profile;
      if (profile != null) {
        setState(() {
          _firstNameController.text = profile.firstName;
          _lastNameController.text = profile.lastName;
          _emailController.text = profile.email;
          _captionController.text = profile.caption ?? '';
          _profileImageUrl = _fullProfileImageUrl(profile.profileImageUrl);
          _loading = false;
        });
        return;
      }
    }
    if (!Get.isRegistered<AuthService>()) {
      setState(() {
        _loading = false;
        _loadError = 'Not logged in';
      });
      return;
    }
    try {
      final auth = Get.find<AuthService>();
      final token = await auth.getIdToken();
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = SettingsApi(baseUrl: baseUrl, authToken: token);
      final response = await api.getSettings(useAuth: true);
      final profile = response?.profile;
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _firstNameController.text = profile.firstName;
          _lastNameController.text = profile.lastName;
          _emailController.text = profile.email;
          _captionController.text = profile.caption ?? '';
          _profileImageUrl = _fullProfileImageUrl(profile.profileImageUrl);
        });
        if (Get.isRegistered<UserProfileService>()) {
          Get.find<UserProfileService>().setProfile(profile);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not load profile');
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Converts image bytes to JPEG. Uses image package (supports JPEG, PNG, WebP, etc.).
  Future<Uint8List?> _imageBytesToJpeg(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    if (!Get.isRegistered<AuthService>()) return;
    if (!mounted) return;
    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Profile photo'),
        message: const Text('Take a new photo or choose from library'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
            child: const Text('Take photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
            child: const Text('Choose from library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (xFile == null || !mounted) return;

    // Square crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: xFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop to square',
          lockAspectRatio: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop to square',
          aspectRatioLockEnabled: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final bytes = await File(cropped.path).readAsBytes();
    final jpegBytes = await _imageBytesToJpeg(bytes);
    if (jpegBytes == null || !mounted) {
      Get.snackbar('', 'Could not process image. Use JPEG or PNG.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _saving = true);
    try {
      final token = await Get.find<AuthService>().getIdToken();
      if (token == null) {
        debugPrint('[profile-image] No auth token');
        setState(() => _saving = false);
        return;
      }
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      debugPrint('[profile-image] Uploading to $baseUrl (${jpegBytes.length} bytes)');
      final api = SettingsApi(baseUrl: baseUrl, authToken: token);
      final newUrl = await api.uploadProfileImageFromBytes(jpegBytes);
      if (!mounted) return;
      if (newUrl != null) {
        debugPrint('[profile-image] Done: $newUrl');
        setState(() => _profileImageUrl = _fullProfileImageUrl(newUrl));
        if (Get.isRegistered<UserProfileService>()) {
          await Get.find<UserProfileService>().loadFromApi();
        }
      } else {
        final msg = api.lastProfileImageError ?? 'Failed to upload image';
        debugPrint('[profile-image] Failed: $msg');
        Get.snackbar('', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      debugPrint('[profile-image] Exception: $e');
      if (mounted) Get.snackbar('', 'Failed to upload image', snackPosition: SnackPosition.BOTTOM);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final caption = _captionController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      Get.snackbar('', 'First name and last name are required', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!Get.isRegistered<AuthService>()) return;
    setState(() => _saving = true);
    try {
      final token = await Get.find<AuthService>().getIdToken();
      if (token == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }
      final config = Get.isRegistered<AppConfig>() ? Get.find<AppConfig>() : AppConfig.fromEnv();
      final baseUrl = config.baseUrl.replaceFirst(RegExp(r'/$'), '');
      final api = SettingsApi(baseUrl: baseUrl, authToken: token);
      await api.updateSettings(firstName: firstName, lastName: lastName, caption: caption);
      if (Get.isRegistered<UserProfileService>()) {
        await Get.find<UserProfileService>().loadFromApi();
      }
      if (!mounted) return;
      Get.snackbar('', 'Profile updated', snackPosition: SnackPosition.BOTTOM);
      setState(() => _saving = false);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        Get.snackbar('', 'Failed to update profile', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
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
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: colors.error, fontSize: 14),
                      ),
                    )
                  else ...[
                    Center(
                      child: ProfileImageUpload(
                        imageUrl: _profileImageUrl,
                        fallbackAssetPath: 'assets/artists/Choc B.png',
                        onTap: _saving ? null : _pickAndUploadImage,
                      ),
                    ),
                    const SizedBox(height: 40),
                    CustomTextField(
                      label: 'First name',
                      controller: _firstNameController,
                      hint: 'First name...',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Last name',
                      controller: _lastNameController,
                      hint: 'Last name...',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Email',
                      controller: _emailController,
                      hint: 'Enter your email address',
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Caption',
                      controller: _captionController,
                      hint: 'Dj/Producer/Artist',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: colors.onSurface,
                        onPressed: () {
                          if (!_saving) _saveProfile();
                        },
                        child: _saving
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : const Text(
                                'Update info',
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
