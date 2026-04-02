import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:haanppen_mobile/apis/media_api.dart';
import 'package:haanppen_mobile/apis/question_api.dart';
import 'package:haanppen_mobile/models/teacher.dart';
import 'package:haanppen_mobile/widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);

class WriteQuestionPage extends StatefulWidget {
  const WriteQuestionPage({super.key});

  @override
  State<WriteQuestionPage> createState() => _WriteQuestionPageState();
}

class _WriteQuestionPageState extends State<WriteQuestionPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // S3 업로드 후 서버에서 받은 경로 목록
  List<String> _imageUrls = [];
  bool _isUploading = false;

  List<Teacher> _teachers = [];
  int _selectedTeacherIndex = 0; // 0 = 지정 안함
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers = await QuestionApi.getAllTeachers();
      if (mounted) setState(() => _teachers = teachers);
    } catch (e) {
      debugPrint('선생님 목록 로드 실패: $e');
    }
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
                title: const Text('카메라로 촬영'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
                title: const Text('갤러리에서 선택'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    if (source == ImageSource.camera) {
      await _pickFromCamera();
    } else {
      await _pickFromGallery();
    }
  }

  Future<CroppedFile?> _cropImage(String path) {
    return ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '이미지 편집',
          toolbarColor: _kBlue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: '이미지 편집'),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return;

    final cropped = await _cropImage(picked.path);
    if (cropped == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await cropped.readAsBytes();
      final url = await MediaApi.uploadImage(bytes, picked.name);
      if (mounted) setState(() => _imageUrls = [..._imageUrls, url]);
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      if (mounted) _showAlert('이미지 업로드에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;

    final croppedFiles = <CroppedFile>[];
    for (final f in picked) {
      final cropped = await _cropImage(f.path);
      if (cropped != null) croppedFiles.add(cropped);
    }
    if (croppedFiles.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final uploaded = await Future.wait(
        croppedFiles.map((f) async {
          final bytes = await f.readAsBytes();
          return MediaApi.uploadImage(bytes, f.path.split('/').last);
        }),
      );
      if (mounted) {
        setState(() => _imageUrls = [..._imageUrls, ...uploaded]);
      }
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      if (mounted) _showAlert('이미지 업로드에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _imageUrls = [
        ..._imageUrls.sublist(0, index),
        ..._imageUrls.sublist(index + 1),
      ];
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showAlert('질문의 제목은 필수입니다.');
      return;
    }
    if (content.isEmpty && _imageUrls.isEmpty) {
      _showAlert('질문에 내용을 적어주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final targetId = _selectedTeacherIndex == 0
          ? null
          : _teachers[_selectedTeacherIndex - 1].id;

      await QuestionApi.writeQuestion(
        title: title,
        content: content,
        images: _imageUrls,
        targetMemberId: targetId,
      );
      if (mounted) context.go('/question-board');
    } catch (e) {
      debugPrint('질문 작성 실패: $e');
      if (mounted) _showAlert('질문 작성에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: _kBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionLabel('제목'),
                      const SizedBox(height: 6),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('선생님 지정'),
                      const SizedBox(height: 6),
                      _buildTeacherDropdown(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('질문 내용'),
                      const SizedBox(height: 6),
                      _buildContentField(),
                      if (_imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionLabel('첨부 이미지'),
                        const SizedBox(height: 6),
                        _buildImagePreviews(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration('제목을 입력하세요'),
    );
  }

  Widget _buildTeacherDropdown() {
    final items = ['지정 안함', ..._teachers.map((t) => t.name)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedTeacherIndex,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          items: List.generate(
            items.length,
            (i) => DropdownMenuItem(value: i, child: Text(items[i])),
          ),
          onChanged: (v) =>
              setState(() => _selectedTeacherIndex = v ?? 0),
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return TextField(
      controller: _contentController,
      maxLines: 6,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration('질문을 작성하세요'),
    );
  }

  Widget _buildImagePreviews() {
    return Column(
      children: List.generate(_imageUrls.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  MediaApi.imageUrl(_imageUrls[i]),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 160,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                          color: _kBlue),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deleteImage(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이미지 추가 버튼
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _showImageSourcePicker,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
            icon: _isUploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kBlue),
                  )
                : const Icon(Icons.image_outlined, size: 18),
            label: Text(
              _isUploading
                  ? '업로드 중...'
                  : _imageUrls.isEmpty
                      ? '이미지 추가'
                      : '이미지 추가 (${_imageUrls.length})',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const Spacer(),
          // 완료 버튼
          ElevatedButton.icon(
            onPressed: (_isSubmitting || _isUploading) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.edit, size: 16),
            label: const Text('완료', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
    );
  }
}
