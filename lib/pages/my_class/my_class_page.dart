import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haanppen_mobile/apis/course_api.dart';
import 'package:haanppen_mobile/models/course.dart';
import 'package:haanppen_mobile/widgets/main_header.dart';


const _kBlue = Color(0xFF3B82F6);
const _kPageSize = 8;

class MyClassPage extends StatefulWidget {
  final int classIndex;
  final int sortIndex;
  final String courseType;

  const MyClassPage({
    super.key,
    required this.classIndex,
    required this.sortIndex,
    required this.courseType,
  });

  @override
  State<MyClassPage> createState() => _MyClassPageState();
}

class _MyClassPageState extends State<MyClassPage> {
  List<Course> _courseList = [];
  int _selectedClassIndex = -1; // -1 = 미선택
  int _selectedSortIndex = 0;
  bool _sortAsc = false; // 날짜 기본: 내림차순
  List<Lesson> _lessons = [];
  LessonPageInfo _pageInfo =
      const LessonPageInfo(totalItemSize: 0, currentPage: 0, pageSize: 8);
  int _page = 0;
  OnlineLessonInfo? _onlineLessonInfo;
  bool _isLoading = true;
  bool _isLessonLoading = false;
  bool _isInfoOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedClassIndex = widget.classIndex;
    _selectedSortIndex = widget.sortIndex;
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        CourseApi.getOwnCourses(),
        CourseApi.getOwnOnlineCourses(),
      ]);
      final offline = results[0];
      final online = results[1];
      if (mounted) {
        setState(() => _courseList = [...offline, ...online]);
        // 외부에서 classIndex가 넘어온 경우에만 자동 로드
        if (_selectedClassIndex >= 0) await _loadLessons();
      }
    } catch (e) {
      debugPrint('강의 목록 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLessons() async {
    if (_courseList.isEmpty) return;
    final course = _courseList[_selectedClassIndex];
    if (course.type == 'offline') {
      setState(() => _isLessonLoading = true);
      try {
        final result = await CourseApi.getLessonsByClassId(
          courseId: course.courseId,
          sortIndex: _selectedSortIndex,
          sortAsc: _sortAsc,
          page: _page,
        );
        if (mounted) {
          setState(() {
            _lessons = result.lessons;
            _pageInfo = result.pageInfo;
          });
        }
      } catch (e) {
        debugPrint('레슨 로드 실패: $e');
      } finally {
        if (mounted) setState(() => _isLessonLoading = false);
      }
    } else {
      setState(() => _isLessonLoading = true);
      try {
        final info =
            await CourseApi.getOnlineLessonDetail(course.courseId);
        if (mounted) setState(() => _onlineLessonInfo = info);
      } catch (e) {
        debugPrint('온라인 강의 로드 실패: $e');
      } finally {
        if (mounted) setState(() => _isLessonLoading = false);
      }
    }
  }

  void _onClassChanged(BuildContext context, int index) {
    final courseType = _courseList[index].type;
    context.go(
      '/my-class?classIndex=$index&sortIndex=$_selectedSortIndex&courseType=$courseType',
    );
    setState(() {
      _selectedClassIndex = index;
      _page = 0;
      _onlineLessonInfo = null;
      _isInfoOpen = false;
    });
    _loadLessons();
  }

  void _onSortChanged(int index) {
    setState(() {
      if (_selectedSortIndex == index) {
        _sortAsc = !_sortAsc; // 같은 컬럼 → 방향 토글
      } else {
        _selectedSortIndex = index;
        _sortAsc = index == 1; // 이름은 기본 오름차순, 날짜는 내림차순
      }
      _page = 0;
    });
    _loadLessons();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _loadLessons();
  }

  int get _totalPages =>
      (_pageInfo.totalItemSize / _kPageSize).ceil().clamp(1, 999);

  String get _currentType =>
      (_courseList.isEmpty || _selectedClassIndex < 0)
          ? ''
          : _courseList[_selectedClassIndex].type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kBlue))
                : _courseList.isEmpty
                    ? _buildEmpty()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          '등록된 수업이 없습니다.',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151)),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          _buildCourseDropdown(),
          const SizedBox(height: 12),
          if (_selectedClassIndex < 0) ...[
            const SizedBox(height: 60),
            const Icon(Icons.menu_book_outlined, size: 48, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text(
              '강의를 선택해주세요',
              style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
            ),
          ] else if (_currentType == 'offline') ...[
            _isLessonLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(
                        child: CircularProgressIndicator(color: _kBlue)))
                : _buildLessonList(),
            const SizedBox(height: 12),
            if (_totalPages > 1) _buildPagination(),
          ],
          if (_currentType == 'online')
            _isLessonLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(
                        child: CircularProgressIndicator(color: _kBlue)))
                : _buildOnlineLessonList(),
        ],
      ),
    );
  }

  // ── 강좌 선택 드롭다운 ────────────────────────────────────
  Widget _buildCourseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedClassIndex < 0 ? null : _selectedClassIndex,
          isExpanded: true,
          hint: const Text('강의 선택',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          items: List.generate(
            _courseList.length,
            (i) => DropdownMenuItem(
              value: i,
              child: Row(
                children: [
                  Text(_courseList[i].courseName),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _courseList[i].type == 'offline'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _courseList[i].type == 'offline' ? '오프라인' : '온라인',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _courseList[i].type == 'offline'
                            ? const Color(0xFF16A34A)
                            : _kBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          onChanged: (v) {
            if (v != null) _onClassChanged(context, v);
          },
        ),
      ),
    );
  }

  // ── 오프라인 레슨 목록 ─────────────────────────────────────
  Widget _buildLessonList() {
    final course = _courseList[_selectedClassIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // 헤더
          Container(
            color: const Color(0xFFD9D9D9),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _onSortChanged(0),
                  child: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('날짜',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedSortIndex == 0
                                    ? _kBlue
                                    : const Color(0xFF374151))),
                        Icon(
                          _selectedSortIndex == 0 && _sortAsc
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 18,
                          color: _selectedSortIndex == 0
                              ? _kBlue
                              : const Color(0xFFAAAAAA),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onSortChanged(1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('강의명',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedSortIndex == 1
                                    ? _kBlue
                                    : const Color(0xFF374151))),
                        Icon(
                          _selectedSortIndex == 1 && _sortAsc
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 18,
                          color: _selectedSortIndex == 1
                              ? _kBlue
                              : const Color(0xFFAAAAAA),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 레슨 행
          ..._lessons.map((lesson) => _LessonRow(
                lesson: lesson,
                course: course,
              )),
          // 빈 행
          ...List.generate(
            (_kPageSize - _lessons.length).clamp(0, _kPageSize),
            (_) => const _EmptyRow(),
          ),
        ],
      ),
    );
  }

  // ── 온라인 강의 목록 ──────────────────────────────────────
  Widget _buildOnlineLessonList() {
    final course = _courseList[_selectedClassIndex];
    final info = _onlineLessonInfo;
    if (info == null) return const SizedBox.shrink();

    final sortedVideos = [...info.videos]
      ..sort((a, b) => a.videoSequence.compareTo(b.videoSequence));

    return Column(
      children: [
        // 강의 정보 아코디언
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => _isInfoOpen = !_isInfoOpen),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(12),
                      bottom: _isInfoOpen
                          ? Radius.zero
                          : const Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('강의 정보',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Icon(
                        _isInfoOpen
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 24,
                        color: const Color(0xFF374151),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildInfoTable(
                    course.teacherName ?? '', info),
                crossFadeState: _isInfoOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 비디오 목록
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
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
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text('길이',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              ...sortedVideos.map((video) => _VideoRow(
                    video: video,
                    onlineCourseId: course.courseId,
                    courseName: info.title,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTable(String teacherName, OnlineLessonInfo info) {
    return Column(
      children: [
        _InfoRow(label: '선생님', value: '$teacherName 선생님', isFirst: true),
        _InfoRow(label: '강좌 범위', value: info.lessonRange),
        _InfoRow(label: '강좌 설명', value: info.lessonDesc),
      ],
    );
  }

  // ── 페이지네이션 ──────────────────────────────────────────
  Widget _buildPagination() {
    final start = (_page ~/ 5) * 5;
    final end = (start + 5).clamp(0, _totalPages);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageBtn(
          icon: Icons.chevron_left,
          enabled: _page > 0,
          onTap: () => _onPageChanged(_page - 1),
        ),
        ...List.generate(end - start, (i) {
          final p = start + i;
          return _PageBtn(
            label: '${p + 1}',
            isActive: p == _page,
            onTap: () => _onPageChanged(p),
          );
        }),
        _PageBtn(
          icon: Icons.chevron_right,
          enabled: _page < _totalPages - 1,
          onTap: () => _onPageChanged(_page + 1),
        ),
      ],
    );
  }
}

// ── 오프라인 레슨 행 ──────────────────────────────────────
class _LessonRow extends StatefulWidget {
  final Lesson lesson;
  final Course course;
  const _LessonRow({required this.lesson, required this.course});

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.lesson.targetDate.length >= 10
        ? widget.lesson.targetDate.substring(2, 10)
        : widget.lesson.targetDate;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          Uri(path: '/lesson', queryParameters: {
            'date': widget.lesson.targetDate,
            'courseId': '${widget.course.courseId}',
            'courseName': widget.course.courseName,
          }).toString(),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered ? _kBlue.withValues(alpha: 0.05) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  dateStr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBlue, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.lesson.progressed,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kBlue),
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

// ── 빈 행 ─────────────────────────────────────────────────
class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
    );
  }
}

// ── 비디오 행 ─────────────────────────────────────────────
class _VideoRow extends StatefulWidget {
  final OnlineVideo video;
  final int onlineCourseId;
  final String courseName;
  const _VideoRow({
    required this.video,
    required this.onlineCourseId,
    required this.courseName,
  });

  @override
  State<_VideoRow> createState() => _VideoRowState();
}

class _VideoRowState extends State<_VideoRow> {
  bool _hovered = false;

  String _secondToTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _displayName {
    final name = widget.video.mediaName;
    return name.endsWith('.mp4') ? name.substring(0, name.length - 4) : name;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          Uri(path: '/online-lesson', queryParameters: {
            'onlineCourseId': '${widget.onlineCourseId}',
            'videoId': '${widget.video.videoId}',
            'courseName': widget.courseName,
          }).toString(),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered ? _kBlue.withValues(alpha: 0.05) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                      ? _secondToTime(widget.video.duration!)
                      : '00:00:00',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
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
  const _InfoRow(
      {required this.label, required this.value, this.isFirst = false});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFFEEEEEE),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 페이지 버튼 ────────────────────────────────────────────
class _PageBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    this.label,
    this.icon,
    this.isActive = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isActive;
    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? _kBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? _kBlue : const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon,
                  size: 16,
                  color: enabled
                      ? const Color(0xFF374151)
                      : const Color(0xFFD1D5DB))
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF374151),
                  ),
                ),
        ),
      ),
    );
  }
}
