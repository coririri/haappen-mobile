import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../apis/course_api.dart';
import '../../constants/api_constants.dart';
import '../../models/lesson_detail.dart';
import '../../services/storage_service.dart';
import '../../widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);
const _kGray = Color(0xFF64748B);
const _kBg = Color(0xFFF8FAFC);

class LessonPage extends StatefulWidget {
  final int courseId;
  final String date;
  final String courseName;

  const LessonPage({
    super.key,
    required this.courseId,
    required this.date,
    required this.courseName,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  LessonDetail? _lesson;
  String? _error;
  bool _loading = true;
  int _videoIndex = 0;

  late final Player _player;
  late final VideoController _videoController;
  bool _videoFailed = false;
  String? _currentVideoUrl;
  double _playbackRate = 1.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _player = Player();
      _videoController = VideoController(_player);
    }
    _load();
  }

  @override
  void dispose() {
    if (!kIsWeb) _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final lesson = await CourseApi.getLessonByDateAndCourse(
        courseId: widget.courseId,
        localDate: widget.date,
      );
      if (lesson.memoMediaViews.isNotEmpty) {
        await _initVideo(lesson.memoMediaViews[0]);
      }
      if (mounted) {
        setState(() {
          _lesson = lesson;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _initVideo(MemoMedia media) async {
    final url =
        '${ApiConstants.baseUrl}/media/stream?resourceId=${media.mediaSource}';
    _currentVideoUrl = url;
    if (kIsWeb) return;

    try {
      final token = await StorageService.getAccessToken();
      await _player.open(
        Media(url, httpHeaders: {'Authorization': 'Bearer ${token ?? ''}'}),
        play: false,
      );
      if (mounted) setState(() => _videoFailed = false);
    } catch (e) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _setRate(double rate) {
    if (kIsWeb) return;
    _player.setRate(rate);
    setState(() => _playbackRate = rate);
  }

  Future<void> _changeVideo(int index) async {
    if (_lesson == null) return;
    setState(() {
      _videoIndex = index;
      _videoFailed = false;
    });
    await _initVideo(_lesson!.memoMediaViews[index]);
  }

  Future<void> _downloadAttachment(String mediaSource) async {
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}/file/download?fileSrc=$mediaSource');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 열 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!,
                              style: TextStyle(color: Colors.red[400])),
                        ))
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final lesson = _lesson!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackBar(),
          const SizedBox(height: 16),
          _buildLessonInfo(lesson),
          if (lesson.memoMediaViews.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildVideoSection(lesson),
          ],
        ],
      ),
    );
  }

  Widget _buildBackBar() {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.push('/my-class');
        }
      },
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios, size: 16, color: _kGray),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.date,
                  style: const TextStyle(fontSize: 12, color: _kGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(LessonDetail lesson) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.progressed.isNotEmpty) ...[
            const Text('제목',
                style: TextStyle(
                    fontSize: 12,
                    color: _kGray,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              lesson.progressed,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ],
          if (lesson.homework.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('수업 내용',
                style: TextStyle(
                    fontSize: 12,
                    color: _kGray,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _buildTextWithLinks(lesson.homework),
          ],
        ],
      ),
    );
  }

  Widget _buildTextWithLinks(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final spans = <InlineSpan>[];
    int last = 0;
    for (final match in urlRegex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final url = match.group(0)!;
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            url,
            style: const TextStyle(
                color: _kBlue, decoration: TextDecoration.underline),
          ),
        ),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 14, color: Color(0xFF1E293B), height: 1.6),
        children: spans,
      ),
    );
  }

  Widget _buildVideoSection(LessonDetail lesson) {
    final media = lesson.memoMediaViews[_videoIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVideoPlayer(),
        const SizedBox(height: 8),
        _buildSpeedControl(),
        const SizedBox(height: 4),
        _buildVideoNavigation(lesson),
        if (media.attachmentViews.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAttachments(media),
        ],
        const SizedBox(height: 16),
        _buildVideoList(lesson),
      ],
    );
  }

  Widget _buildSpeedControl() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Row(
      children: speeds.map((speed) {
        final isSelected = _playbackRate == speed;
        return GestureDetector(
          onTap: () => _setRate(speed),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${speed == speed.truncateToDouble() ? speed.toInt() : speed}x',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kGray,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVideoPlayer() {
    if (kIsWeb || _videoFailed) {
      return _buildFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: MaterialVideoControlsTheme(
            normal: const MaterialVideoControlsThemeData(
              seekBarMargin: EdgeInsets.only(bottom: 12, left: 12, right: 12),
              bottomButtonBarMargin: EdgeInsets.only(bottom: 4, left: 8, right: 8),
            ),
            fullscreen: const MaterialVideoControlsThemeData(),
            child: Video(
              controller: _videoController,
              controls: MaterialVideoControls,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline,
                  color: Colors.white70, size: 56),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _currentVideoUrl != null
                    ? () => launchUrl(Uri.parse(_currentVideoUrl!),
                        mode: LaunchMode.externalApplication)
                    : null,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('브라우저에서 재생'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoNavigation(LessonDetail lesson) {
    final total = lesson.memoMediaViews.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed:
              _videoIndex > 0 ? () => _changeVideo(_videoIndex - 1) : null,
          icon: const Icon(Icons.arrow_back_ios, size: 14),
          label: const Text('이전'),
          style: TextButton.styleFrom(foregroundColor: _kBlue),
        ),
        Text(
          '${_videoIndex + 1} / $total',
          style: const TextStyle(fontSize: 13, color: _kGray),
        ),
        TextButton.icon(
          onPressed: _videoIndex < total - 1
              ? () => _changeVideo(_videoIndex + 1)
              : null,
          icon: const Icon(Icons.arrow_forward_ios, size: 14),
          label: const Text('다음'),
          iconAlignment: IconAlignment.end,
          style: TextButton.styleFrom(foregroundColor: _kBlue),
        ),
      ],
    );
  }

  Widget _buildAttachments(MemoMedia media) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('첨부파일',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kGray)),
          const SizedBox(height: 10),
          ...media.attachmentViews.map((a) => _AttachmentRow(
                attachment: a,
                onDownload: () => _downloadAttachment(a.mediaSource),
              )),
        ],
      ),
    );
  }

  Widget _buildVideoList(LessonDetail lesson) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: lesson.memoMediaViews.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isActive = i == _videoIndex;
          return _VideoListRow(
            index: i,
            media: m,
            isActive: isActive,
            onTap: () => _changeVideo(i),
          );
        }).toList(),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final AttachmentView attachment;
  final VoidCallback onDownload;

  const _AttachmentRow({required this.attachment, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 16, color: _kGray),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.fileName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDownload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _kBlue.withValues(alpha: 0.3), width: 1),
              ),
              child: const Text('다운로드',
                  style: TextStyle(
                      fontSize: 12,
                      color: _kBlue,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoListRow extends StatefulWidget {
  final int index;
  final MemoMedia media;
  final bool isActive;
  final VoidCallback onTap;

  const _VideoListRow({
    required this.index,
    required this.media,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_VideoListRow> createState() => _VideoListRowState();
}

class _VideoListRowState extends State<_VideoListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isActive
                ? _kBlue.withValues(alpha: 0.06)
                : _hovered
                    ? _kBlue.withValues(alpha: 0.03)
                    : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.isActive ? _kBlue : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: widget.isActive
                      ? const Icon(Icons.play_arrow,
                          color: Colors.white, size: 16)
                      : Text(
                          '${widget.index + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kGray),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.media.title.isNotEmpty
                      ? widget.media.title
                      : widget.media.mediaName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color:
                        widget.isActive ? _kBlue : const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
