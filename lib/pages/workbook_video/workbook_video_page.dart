import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/api_constants.dart';
import '../../services/storage_service.dart';
import '../../widgets/main_header.dart';

class WorkbookVideoPage extends StatefulWidget {
  final String videoPath;
  final String lectureName;
  final int problemNumber;

  const WorkbookVideoPage({
    super.key,
    required this.videoPath,
    required this.lectureName,
    required this.problemNumber,
  });

  @override
  State<WorkbookVideoPage> createState() => _WorkbookVideoPageState();
}

class _WorkbookVideoPageState extends State<WorkbookVideoPage> {
  late final Player _player;
  late final VideoController _videoController;
  bool _videoFailed = false;
  double _playbackRate = 1.0;

  String get _streamUrl =>
      '${ApiConstants.baseUrl}/media/stream?resourceId=${widget.videoPath}';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _player = Player();
      _videoController = VideoController(_player);
      _initVideo();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) _player.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    try {
      final token = await StorageService.getAccessToken();
      await _player.open(
        Media(_streamUrl,
            httpHeaders: {'Authorization': 'Bearer ${token ?? ''}'}),
        play: false,
      );
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  void _setRate(double rate) {
    if (kIsWeb) return;
    _player.setRate(rate);
    setState(() => _playbackRate = rate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      widget.lectureName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.push('/my-class'),
                          child: const Row(
                            children: [
                              Icon(Icons.chevron_left,
                                  size: 20, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Text('목록으로',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: Text(
                            '${widget.problemNumber}번 풀이 영상',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildVideoPlayer(),
                        const SizedBox(height: 8),
                        _buildSpeedControl(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline,
              size: 48, color: Color(0xFF7C3AED)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () =>
                launchUrl(Uri.parse(_streamUrl), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('브라우저에서 재생'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (kIsWeb || _videoFailed) {
      return _buildFallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Video(controller: _videoController),
      ),
    );
  }

  Widget _buildSpeedControl() {
    return Row(
      children: [
        const Text('배속',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        for (final rate in [0.5, 1.0, 1.5, 2.0])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _setRate(rate),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _playbackRate == rate
                      ? const Color(0xFF7C3AED)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _playbackRate == rate
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Text(
                  '${rate}x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _playbackRate == rate
                        ? Colors.white
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
