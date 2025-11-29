import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/visibility_selector.dart';
import '../widgets/media_upload_area.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  VisibilityOption _selectedVisibility = VisibilityOption.public;
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _handleFileSelected(String filePath) {
    setState(() {
      _selectedFilePath = filePath;
      _selectedFileName = filePath.split('/').last;
    });
  }

  void _handleRemoveFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
    });
  }

  Future<void> _handleUpload() async {
    if (_selectedFilePath == null) {
      // TODO: Show error message
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Implement actual upload logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      
      if (mounted) {
        Get.back();
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Navigation Bar with Large Title - matching home screen
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Upload'),
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
                  // Video/audio Title Field
                  CustomTextField(
                    label: 'Video/audio Title',
                    hint: 'Enter video/audio Title here',
                    controller: _titleController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  // Description Field
                  CustomTextField(
                    label: 'Description',
                    hint: 'Write a brief description',
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  // Tags/Categories Field
                  CustomTextField(
                    label: 'Tags/Categories',
                    hint: 'Enter tags, separated by commas',
                    controller: _tagsController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),
                  // Visibility Selector
                  VisibilitySelector(
                    selectedOption: _selectedVisibility,
                    onChanged: (option) {
                      setState(() {
                        _selectedVisibility = option;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Media Upload Area
                  MediaUploadArea(
                    selectedFileName: _selectedFileName,
                    onFileSelected: _handleFileSelected,
                    onRemove: _selectedFileName != null ? _handleRemoveFile : null,
                  ),
                  const SizedBox(height: 40),
                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: colors.onSurface,
                      onPressed: _isUploading ? null : _handleUpload,
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Upload',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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

