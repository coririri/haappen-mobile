import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../apis/course_api.dart';
import '../../constants/api_constants.dart';
import '../../models/course.dart';
import '../../services/storage_service.dart';
import '../../widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);

const _kGray = Color(0xFF64748B);

class OnlineLessonPage extends StatefulWidget {
  final int onlineCourseId;
  final int videoId;
  final String courseName;

  const OnlineLessonPage({
    super.key,
    required this.onlineCourseId,
    required this.videoId,
    required this.courseName,
  });

  @override
  State<OnlineLessonPage> createState() => _OnlineLessonPageState();
}

class _OnlineLessonPageState extends State<OnlineLessonPage> {
  OnlineVideo? _video;
  String? _error;
  bool _loading = true;

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final info = await CourseApi.getOnlineLessonDetail(widget.onlineCourseId);
      final video = info.videos.firstWhere(
        (v) => v.videoId == widget.videoId,
        orElse: () => info.videos.first,
      );
      final url =
          '${ApiConstants.baseUrl}/media/stream?resourceId=${video.mediaSrc}';
      setState(() {
        _video = video;
        _videoUrl = url;
        _loading = false;
      });
      if (!kIsWeb) await _initVideo(url);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _initVideo(String url) async {
    final token = await StorageService.getAccessToken();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {'Authorization': 'Bearer ${token ?? ''}'},
    );
    _videoController = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
    final video = _video!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCourseHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackButton(),
                const SizedBox(height: 16),
                const Center(
                  child: Text('영상 제목',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kGray)),
                ),
                const SizedBox(height: 8),
                _buildTitleBox(video),
                const SizedBox(height: 20),
                _buildVideoPlayer(),
                if (video.attachmentDetails.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildAttachments(video),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        widget.courseName,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/my-class');
        }
      },
      child: Row(
        children: const [
          Icon(Icons.arrow_back_ios, size: 16, color: _kGray),
          SizedBox(width: 4),
          Text('목록으로',
              style: TextStyle(fontSize: 14, color: _kGray)),
        ],
      ),
    );
  }

  Widget _buildTitleBox(OnlineVideo video) {
    final title = video.mediaName.contains('.')
        ? video.mediaName.substring(0, video.mediaName.lastIndexOf('.'))
        : video.mediaName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoUrl == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: kIsWeb || (!_videoInitialized && _videoController == null)
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        color: Colors.white70, size: 56),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(_videoUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('브라우저에서 재생'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : _videoInitialized && _videoController != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      _VideoControls(controller: _videoController!),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }

  Widget _buildAttachments(OnlineVideo video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.inventory_2, color: Color(0xFF7C3AED), size: 22),
            SizedBox(width: 8),
            Text('수업 자료',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
          ],
        ),
        const SizedBox(height: 12),
        ...video.attachmentDetails.map((a) => _AttachmentItem(attachment: a)),
      ],
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isPlaying = ctrl.value.isPlaying;
    final duration = ctrl.value.duration;
    final position = ctrl.value.position;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => setState(() => _visible = !_visible),
      child: AnimatedOpacity(
        opacity: _visible || !isPlaying ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black26,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VideoProgressIndicator(ctrl,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: _kBlue,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                  padding: EdgeInsets.zero),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          isPlaying ? ctrl.pause() : ctrl.play(),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_fmt(position)} / ${_fmt(duration)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    const Spacer(),
                    Expanded(
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) => ctrl.seekTo(Duration(
                            milliseconds:
                                (v * duration.inMilliseconds).round())),
                        activeColor: _kBlue,
                        inactiveColor: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AttachmentItem extends StatelessWidget {
  final AttachmentDetail attachment;
  const _AttachmentItem({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(attachment.url),
            mode: LaunchMode.externalApplication),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: _kGray, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${attachment.attachmentTitle} (Click)',
                style: const TextStyle(
                  fontSize: 15,
                  color: _kBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: _kBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
