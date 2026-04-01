import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../apis/course_api.dart';
import '../../models/course.dart';
import '../../widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);
const _kGray = Color(0xFF6B7280);

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
      final lesson =
          await CourseApi.getOnlineLessonDetail(widget.onlineCourseId);
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
      backgroundColor: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 뒤로가기
            GestureDetector(
              onTap: () => context.canPop() ? context.pop() : context.go('/lesson-overview'),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 16, color: _kGray),
                  SizedBox(width: 4),
                  Text('목록으로', style: TextStyle(fontSize: 14, color: _kGray)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 강의 제목
            Text(
              lesson.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            // 강의 정보 아코디언
            _buildAccordion(lesson),
            const SizedBox(height: 8),

            // 영상 목록 헤더
            Container(
              color: const Color(0xFFD9D9D9),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: const Row(
                children: [
                  Expanded(
                    child: Text('강의명',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text('길이',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  SizedBox(width: 64),
                ],
              ),
            ),

            // 영상 목록
            ...(lesson.videos.toList()
                  ..sort((a, b) => a.videoSequence.compareTo(b.videoSequence)))
                .map((v) => _buildVideoRow(v, lesson.title)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordion(OnlineLessonInfo lesson) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _infoOpen = !_infoOpen),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('강의 정보',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                AnimatedRotation(
                  turns: _infoOpen ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.play_arrow, size: 28, color: _kGray),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildInfoTable(lesson),
          crossFadeState: _infoOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildInfoTable(OnlineLessonInfo lesson) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFC3C3C3)),
          right: BorderSide(color: Color(0xFFC3C3C3)),
          bottom: BorderSide(color: Color(0xFFC3C3C3)),
        ),
      ),
      child: Column(
        children: [
          _InfoRow(label: '선생님', value: '${widget.teacherName} 선생님', isFirst: true),
          _InfoRow(label: '강좌 범위', value: lesson.lessonRange),
          _InfoRow(label: '강좌 설명', value: lesson.lessonDesc),
        ],
      ),
    );
  }

  Widget _buildVideoRow(OnlineVideo video, String courseTitle) {
    final title = video.mediaName.endsWith('.')
        ? video.mediaName
        : video.mediaName.contains('.')
            ? video.mediaName.substring(0, video.mediaName.lastIndexOf('.'))
            : video.mediaName;
    final duration = video.duration != null
        ? _formatDuration(video.duration!)
        : '00:00:00';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD9D9D9), width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              duration,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 64,
            child: GestureDetector(
              onTap: () {
                if (video.isPreview) {
                  context.push(
                    Uri(path: '/online-lesson', queryParameters: {
                      'onlineCourseId': '${widget.onlineCourseId}',
                      'videoId': '${video.videoId}',
                      'courseName': courseTitle,
                    }).toString(),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('무료 체험 강의가 아닙니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: video.isPreview
                          ? _kBlue
                          : const Color(0xFFD1D5DB),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Play',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: video.isPreview ? _kBlue : const Color(0xFFD1D5DB),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          bottom: const BorderSide(color: Color(0xFFC3C3C3)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              color: const Color(0xFFEEEEEE),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
