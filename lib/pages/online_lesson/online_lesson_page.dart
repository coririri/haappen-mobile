import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
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

  late final Player _player;
  late final VideoController _videoController;
  bool _videoFailed = false;
  String? _videoUrl;
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
      final info = await CourseApi.getOnlineLessonDetail(widget.onlineCourseId);
      final video = info.videos.firstWhere(
        (v) => v.videoId == widget.videoId,
        orElse: () => info.videos.first,
      );
      final url =
          '${ApiConstants.baseUrl}/media/stream?resourceId=${video.mediaSrc}';

      if (!kIsWeb) await _initVideo(url);

      if (mounted) {
        setState(() {
          _video = video;
          _videoUrl = url;
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

  void _setRate(double rate) {
    if (kIsWeb) return;
    _player.setRate(rate);
    setState(() => _playbackRate = rate);
  }

  Future<void> _initVideo(String url) async {
    try {
      final token = await StorageService.getAccessToken();
      await _player.open(
        Media(url, httpHeaders: {'Authorization': 'Bearer ${token ?? ''}'}),
        play: false,
      );
    } catch (e) {
      if (mounted) setState(() => _videoFailed = true);
    }
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
                _buildTitleBox(video),
                const SizedBox(height: 20),
                _buildVideoPlayer(),
                const SizedBox(height: 8),
                _buildSpeedControl(),
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
          context.push('/my-class');
        }
      },
      child: Row(
        children: const [
          Icon(Icons.arrow_back_ios, size: 16, color: _kGray),
          SizedBox(width: 4),
          Text('목록으로', style: TextStyle(fontSize: 14, color: _kGray)),
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
    if (_videoUrl == null) return const SizedBox.shrink();

    if (kIsWeb || _videoFailed) {
      return _buildFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Video(
            controller: _videoController,
            controls: MaterialVideoControls,
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
        ),
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
            const Icon(Icons.inventory_2_outlined, color: _kGray, size: 22),
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
