import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../apis/course_api.dart';
import '../../models/course.dart';
import '../../widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);
const _kGray = Color(0xFF64748B);
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);

class PreviewClassPage extends StatefulWidget {
  final String teacherName;
  final int onlineCourseId;

  const PreviewClassPage({
    super.key,
    required this.teacherName,
    required this.onlineCourseId,
  });

  @override
  State<PreviewClassPage> createState() => _PreviewClassPageState();
}

class _PreviewClassPageState extends State<PreviewClassPage> {
  OnlineLessonInfo? _lesson;
  bool _loading = true;
  String? _error;
  bool _infoOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lesson = await CourseApi.getOnlineLessonDetail(widget.onlineCourseId);
      if (mounted) setState(() { _lesson = lesson; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    final sorted = lesson.videos.toList()
      ..sort((a, b) => a.videoSequence.compareTo(b.videoSequence));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 뒤로가기
          GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go('/lesson-overview'),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios, size: 16, color: _kGray),
                SizedBox(width: 4),
                Text('목록으로',
                    style: TextStyle(fontSize: 14, color: _kGray)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 강의 제목
          Text(
            lesson.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // 강의 정보 아코디언
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // 헤더
                GestureDetector(
                  onTap: () => setState(() => _infoOpen = !_infoOpen),
                  child: Container(
                    color: const Color(0xFFD9D9D9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('강의 정보',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                        AnimatedRotation(
                          turns: _infoOpen ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.play_arrow,
                              size: 22, color: Color(0xFF4B5563)),
                        ),
                      ],
                    ),
                  ),
                ),
                // 내용
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      _InfoRow(label: '선생님',
                          value: '${widget.teacherName} 선생님',
                          isFirst: true),
                      _InfoRow(label: '강좌 범위', value: lesson.lessonRange),
                      _InfoRow(label: '강좌 설명', value: lesson.lessonDesc),
                    ],
                  ),
                  crossFadeState: _infoOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 영상 목록
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // 테이블 헤더
                Container(
                  color: const Color(0xFFD9D9D9),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text('강의명',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text('길이',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 60),
                    ],
                  ),
                ),
                // 영상 행
                ...sorted.map((v) => _VideoRow(
                      video: v,
                      onlineCourseId: widget.onlineCourseId,
                      courseTitle: lesson.title,
                      formatDuration: _formatDuration,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 영상 행 ───────────────────────────────────────────────

class _VideoRow extends StatefulWidget {
  final OnlineVideo video;
  final int onlineCourseId;
  final String courseTitle;
  final String Function(int) formatDuration;

  const _VideoRow({
    required this.video,
    required this.onlineCourseId,
    required this.courseTitle,
    required this.formatDuration,
  });

  @override
  State<_VideoRow> createState() => _VideoRowState();
}

class _VideoRowState extends State<_VideoRow> {
  bool _hovered = false;

  String get _displayName {
    final name = widget.video.mediaName;
    return name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = widget.video.isPreview;
    return MouseRegion(
      cursor: canPlay ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: canPlay
            ? () => context.push(
                  Uri(path: '/online-lesson', queryParameters: {
                    'onlineCourseId': '${widget.onlineCourseId}',
                    'videoId': '${widget.video.videoId}',
                    'courseName': widget.courseTitle,
                  }).toString(),
                )
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('무료 체험 강의가 아닙니다'),
                    duration: Duration(seconds: 2),
                  ),
                ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered
                ? _kBlue.withValues(alpha: 0.05)
                : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  widget.video.duration != null
                      ? widget.formatDuration(widget.video.duration!)
                      : '00:00:00',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _kGray),
                ),
              ),
              SizedBox(
                width: 60,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: canPlay ? _kBlue : const Color(0xFFD1D5DB),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: canPlay
                            ? _kBlue
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 강의 정보 행 ───────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isFirst ? Colors.black : const Color(0xFFC3C3C3),
            width: isFirst ? 2 : 1,
          ),
          bottom: const BorderSide(color: Color(0xFFC3C3C3), width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              color: const Color(0xFFEEEEEE),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Text(value,
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
