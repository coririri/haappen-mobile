import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:haanppen_mobile/apis/media_api.dart';
import 'package:haanppen_mobile/apis/question_api.dart';
import 'package:haanppen_mobile/models/question.dart';
import 'package:haanppen_mobile/models/question_detail.dart';
import 'package:haanppen_mobile/services/api_client.dart';
import 'package:haanppen_mobile/services/storage_service.dart';
import 'package:haanppen_mobile/widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);
const _kRed = Color(0xFFEF4444);

class QuestionDetailPage extends StatefulWidget {
  final String id;
  const QuestionDetailPage({super.key, required this.id});

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  QuestionDetail? _detail;
  bool _isLoading = true;
  String? _currentUserName;

  // 수정 모드
  bool _isModify = false;
  late TextEditingController _titleEditCtrl;
  late TextEditingController _contentEditCtrl;
  List<String> _modifyImagePaths = []; // 기존 이미지 경로 (수정 모드)
  List<String> _newUploadedPaths = []; // 새로 업로드된 경로
  bool _isUploading = false;
  bool _isSaving = false;

  // 댓글 작성
  bool _isWriteComment = false;
  final _commentCtrl = TextEditingController();
  List<String> _commentImagePaths = [];
  bool _isCommentUploading = false;
  bool _isCommentSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleEditCtrl = TextEditingController();
    _contentEditCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _titleEditCtrl.dispose();
    _contentEditCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        QuestionApi.getQuestionDetail(int.parse(widget.id)),
        StorageService.getUserName(),
      ]);
      if (mounted) {
        final detail = results[0] as QuestionDetail;
        setState(() {
          _detail = detail;
          _currentUserName = results[1] as String?;
        });
      }
    } catch (e) {
      debugPrint('질문 상세 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reload() async {
    try {
      final detail =
          await QuestionApi.getQuestionDetail(int.parse(widget.id));
      if (mounted) setState(() => _detail = detail);
    } catch (e) {
      debugPrint('질문 재로드 실패: $e');
    }
  }

  void _startEdit() {
    final d = _detail!;
    _titleEditCtrl.text = d.title;
    _contentEditCtrl.text = d.content;
    _modifyImagePaths = List.from(d.rawImagePaths);
    _newUploadedPaths = [];
    setState(() => _isModify = true);
  }

  Future<void> _pickAndUploadImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 40);
    if (picked.isEmpty) return;
    setState(() => _isUploading = true);
    try {
      final uploaded = await Future.wait(picked.map((f) async {
        final bytes = await f.readAsBytes();
        return MediaApi.uploadImage(bytes, f.name);
      }));
      if (mounted) {
        setState(() => _newUploadedPaths = [..._newUploadedPaths, ...uploaded]);
      }
    } catch (e) {
      if (mounted) _showAlert('이미지 업로드 실패');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveEdit() async {
    if (_titleEditCtrl.text.trim().isEmpty) {
      _showAlert('제목을 입력하세요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await QuestionApi.modifyQuestion(
        id: int.parse(widget.id),
        title: _titleEditCtrl.text.trim(),
        content: _contentEditCtrl.text.trim(),
        existingImagePaths: _modifyImagePaths,
        newImagePaths: _newUploadedPaths,
        targetMemberId: _detail?.targetMember?.memberId,
      );
      await _reload();
      if (mounted) setState(() => _isModify = false);
    } catch (e) {
      if (mounted) _showAlert('수정에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await _showConfirmDialog('질문을 삭제하시겠습니까?');
    if (!confirmed) return;
    try {
      await QuestionApi.deleteQuestion(int.parse(widget.id));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showAlert('삭제에 실패했습니다.');
    }
  }

  Future<void> _pickCommentImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 40);
    if (picked.isEmpty) return;
    setState(() => _isCommentUploading = true);
    try {
      final uploaded = await Future.wait(picked.map((f) async {
        final bytes = await f.readAsBytes();
        return MediaApi.uploadImage(bytes, f.name);
      }));
      if (mounted) {
        setState(
            () => _commentImagePaths = [..._commentImagePaths, ...uploaded]);
      }
    } catch (e) {
      if (mounted) _showAlert('이미지 업로드 실패');
    } finally {
      if (mounted) setState(() => _isCommentUploading = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty && _commentImagePaths.isEmpty) {
      _showAlert('댓글 내용을 입력하세요.');
      return;
    }
    setState(() => _isCommentSubmitting = true);
    try {
      await QuestionApi.writeComment(
        questionId: int.parse(widget.id),
        content: content,
        images: _commentImagePaths,
      );
      _commentCtrl.clear();
      _commentImagePaths = [];
      await _reload();
      if (mounted) setState(() => _isWriteComment = false);
    } catch (e) {
      if (mounted) {
        final message = (e is ApiException && e.statusCode == 403)
            ? '학생은 댓글 작성을 할 수 없습니다.'
            : '댓글 작성에 실패했습니다.';
        _showAlert(message);
      }
    } finally {
      if (mounted) setState(() => _isCommentSubmitting = false);
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

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제', style: TextStyle(color: _kRed)),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool get _isOwner =>
      _currentUserName != null &&
      _detail != null &&
      _currentUserName == _detail!.registeredMember.memberName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kBlue))
                : _detail == null
                    ? const Center(child: Text('질문을 불러올 수 없습니다.'))
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAuthorBar(d),
              const SizedBox(height: 12),
              _buildTitleSection(d),
              _buildContentSection(d),
              _buildImagesSection(d),
              if (_isModify) _buildModifyActions(),
              if (!_isModify && _isOwner) _buildOwnerActions(),
              const Divider(height: 32, color: Color(0xFFE5E7EB)),
              _buildCommentsSection(d),
              if (_isWriteComment) _buildWriteComment(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── 작성자 바 ────────────────────────────────────────────
  Widget _buildAuthorBar(QuestionDetail d) {
    final gradeText = _gradeLabel(d.registeredMember);
    final dateText = _formatDate(d.registeredDateTime);

    return Container(
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.bookmark, size: 16, color: _kBlue),
          const SizedBox(width: 4),
          Text(gradeText,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151))),
          const SizedBox(width: 6),
          Text(d.registeredMember.memberName,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          const Spacer(),
          const Icon(Icons.access_time, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(dateText,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── 제목 ─────────────────────────────────────────────────
  Widget _buildTitleSection(QuestionDetail d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _isModify
          ? TextField(
              controller: _titleEditCtrl,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              decoration: _inputDeco('제목을 입력하세요'),
            )
          : Text(
              d.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827)),
            ),
    );
  }

  // ── 본문 ─────────────────────────────────────────────────
  Widget _buildContentSection(QuestionDetail d) {
    if (!_isModify && d.content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _isModify
          ? TextField(
              controller: _contentEditCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDeco('질문 내용을 입력하세요'),
            )
          : Text(d.content,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF374151), height: 1.6)),
    );
  }

  // ── 이미지 ───────────────────────────────────────────────
  Widget _buildImagesSection(QuestionDetail d) {
    final images = _isModify
        ? [
            ..._modifyImagePaths.map((p) =>
                _ImageItem(url: MediaApi.imageUrl(p), onDelete: () {
                  setState(() => _modifyImagePaths.remove(p));
                })),
            ..._newUploadedPaths.map((p) =>
                _ImageItem(url: MediaApi.imageUrl(p), onDelete: () {
                  setState(() => _newUploadedPaths.remove(p));
                })),
          ]
        : d.imageUrls
            .map((url) => _ImageItem(url: url, onDelete: null))
            .toList();

    if (images.isEmpty && !_isModify) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ...images,
          if (_isModify)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImages,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kBlue))
                    : const Icon(Icons.image_outlined, size: 16),
                label: Text(_isUploading ? '업로드 중...' : '이미지 추가',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  // ── 수정 모드 액션 ─────────────────────────────────────────
  Widget _buildModifyActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: (_isSaving || _isUploading) ? null : _saveEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('완료'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => setState(() => _isModify = false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kRed,
              side: const BorderSide(color: _kRed),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // ── 소유자 액션 ──────────────────────────────────────────
  Widget _buildOwnerActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _startEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('수정'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _delete,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // ── 댓글 섹션 ────────────────────────────────────────────
  Widget _buildCommentsSection(QuestionDetail d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 22, color: _kBlue),
              const SizedBox(width: 6),
              Text(
                '${d.comments.length}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00)),
              ),
              const SizedBox(width: 4),
              const Text('Comments',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (!_isWriteComment)
                TextButton.icon(
                  onPressed: () => setState(() => _isWriteComment = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('댓글 작성'),
                  style: TextButton.styleFrom(foregroundColor: _kBlue),
                ),
            ],
          ),
          const Divider(color: Color(0xFFE5E7EB)),
          ...d.comments.map((c) => _CommentCard(
                comment: c,
                currentUserName: _currentUserName,
                onReload: _reload,
              )),
        ],
      ),
    );
  }

  // ── 댓글 작성 폼 ─────────────────────────────────────────
  Widget _buildWriteComment() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDeco('댓글을 입력하세요'),
          ),
          if (_commentImagePaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(_commentImagePaths.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ImageItem(
                  url: MediaApi.imageUrl(_commentImagePaths[i]),
                  onDelete: () => setState(
                      () => _commentImagePaths.removeAt(i)),
                ),
              );
            }),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                    _isCommentUploading ? null : _pickCommentImages,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                ),
                icon: _isCommentUploading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kBlue))
                    : const Icon(Icons.image_outlined, size: 16),
                label: Text(
                  _commentImagePaths.isEmpty
                      ? '이미지'
                      : '이미지 (${_commentImagePaths.length})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  _commentCtrl.clear();
                  setState(() {
                    _commentImagePaths = [];
                    _isWriteComment = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kRed,
                  side: const BorderSide(color: _kRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
                child: const Text('취소', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_isCommentSubmitting || _isCommentUploading)
                    ? null
                    : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
                child: _isCommentSubmitting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('등록', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 유틸 ─────────────────────────────────────────────────
  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 14, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFFD1D5DB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFFD1D5DB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: _kBlue, width: 1.5)),
      );

  String _gradeLabel(QuestionMember member) {
    if (member.role == 'teacher') return '선생님';
    final grade = (member.memberGrade ?? 0) + 1;
    if (grade <= 6) return '초$grade';
    if (grade <= 9) return '중${grade - 6}';
    return '고${grade - 9}';
  }

  String _formatDate(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }
}

// ── 이미지 아이템 위젯 ──────────────────────────────────────
class _ImageItem extends StatelessWidget {
  final String url;
  final VoidCallback? onDelete;

  const _ImageItem({required this.url, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
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
          if (onDelete != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 댓글 카드 ────────────────────────────────────────────
class _CommentCard extends StatefulWidget {
  final QuestionComment comment;
  final String? currentUserName;
  final VoidCallback onReload;

  const _CommentCard({
    required this.comment,
    required this.currentUserName,
    required this.onReload,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _isEdit = false;
  late TextEditingController _editCtrl;
  List<String> _existingPaths = [];
  List<String> _newPaths = [];
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.comment.content);
    _existingPaths = List.from(widget.comment.rawImagePaths);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  bool get _isOwner =>
      widget.currentUserName != null &&
      widget.currentUserName == widget.comment.registeredMember.memberName;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 40);
    if (picked.isEmpty) return;
    setState(() => _isUploading = true);
    try {
      final uploaded = await Future.wait(picked.map((f) async {
        final bytes = await f.readAsBytes();
        return MediaApi.uploadImage(bytes, f.name);
      }));
      if (mounted) setState(() => _newPaths = [..._newPaths, ...uploaded]);
    } catch (e) {
      debugPrint('댓글 이미지 업로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await QuestionApi.modifyComment(
        commentId: widget.comment.commentId,
        content: _editCtrl.text.trim(),
        existingImagePaths: _existingPaths,
        newImagePaths: _newPaths,
      );
      widget.onReload();
      if (mounted) setState(() => _isEdit = false);
    } catch (e) {
      debugPrint('댓글 수정 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            content: const Text('댓글을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('삭제',
                      style: TextStyle(color: _kRed))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await QuestionApi.deleteComment(widget.comment.commentId);
      widget.onReload();
    } catch (e) {
      debugPrint('댓글 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final gradeText = c.registeredMember.role == 'teacher'
        ? '선생님'
        : () {
            final grade = (c.registeredMember.memberGrade ?? 0) + 1;
            if (grade <= 6) return '초$grade';
            if (grade <= 9) return '중${grade - 6}';
            return '고${grade - 9}';
          }();
    String dateText = '';
    try {
      final d = DateTime.parse(c.registeredDateTime);
      dateText =
          '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 작성자 + 날짜 + 수정/삭제 버튼
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(gradeText,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 4),
              Text(c.registeredMember.memberName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151))),
              const Spacer(),
              Text(dateText,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (_isOwner && !_isEdit) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _isEdit = true;
                    _editCtrl.text = c.content;
                    _existingPaths = List.from(c.rawImagePaths);
                    _newPaths = [];
                  }),
                  child: const Text('수정',
                      style:
                          TextStyle(fontSize: 11, color: _kBlue)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _delete,
                  child: const Text('삭제',
                      style: TextStyle(fontSize: 11, color: _kRed)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // 본문
          if (_isEdit) ...[
            TextField(
              controller: _editCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFD1D5DB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _kBlue, width: 1.5)),
              ),
            ),
            // 기존 이미지 (수정 모드)
            ..._existingPaths.map((p) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _ImageItem(
                    url: MediaApi.imageUrl(p),
                    onDelete: () =>
                        setState(() => _existingPaths.remove(p)),
                  ),
                )),
            // 새 이미지
            ..._newPaths.map((p) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _ImageItem(
                    url: MediaApi.imageUrl(p),
                    onDelete: () =>
                        setState(() => _newPaths.remove(p)),
                  ),
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImages,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side:
                        const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 14),
                  label: Text(
                    _isUploading ? '업로드 중...' : '이미지',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => setState(() => _isEdit = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRed,
                    side: const BorderSide(color: _kRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: const Text('취소',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: (_isSaving || _isUploading) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('완료',
                          style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ] else ...[
            Text(c.content,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    height: 1.5)),
            ...c.imageUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url,
                        width: double.infinity, fit: BoxFit.cover),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
