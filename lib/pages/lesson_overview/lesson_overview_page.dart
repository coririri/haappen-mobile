import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../apis/lesson_overview_api.dart';
import '../../constants/api_constants.dart';
import '../../models/lesson_overview.dart';
import '../../widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);
const _kGray = Color(0xFF64748B);
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);
const _kDark = Color(0xFF1E293B);

class LessonOverviewPage extends StatefulWidget {
  const LessonOverviewPage({super.key});

  @override
  State<LessonOverviewPage> createState() => _LessonOverviewPageState();
}

class _LessonOverviewPageState extends State<LessonOverviewPage> {
  List<Category> _mainCategories = [];
  List<Category> _subCategories = [];
  List<CourseOverview> _courses = [];

  int _mainIndex = 0;
  int _subIndex = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final mains = await LessonOverviewApi.getRootCategories();
      if (!mounted) return;
      if (mains.isEmpty) {
        setState(() { _mainCategories = []; _loading = false; });
        return;
      }
      final defaultIndex = mains.indexWhere((c) => c.categoryName == '중등');
      final initialIndex = defaultIndex >= 0 ? defaultIndex : 0;
      final subs = await LessonOverviewApi.getSubCategories(mains[initialIndex].categoryId);
      final courses = await LessonOverviewApi.getCoursesByCategory(mains[initialIndex].categoryId);
      if (!mounted) return;
      setState(() {
        _mainCategories = mains;
        _subCategories = subs;
        _courses = courses;
        _mainIndex = initialIndex;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onMainChanged(int index) async {
    setState(() { _mainIndex = index; _subIndex = 0; _courses = []; });
    try {
      final subs = await LessonOverviewApi.getSubCategories(_mainCategories[index].categoryId);
      final courses = await LessonOverviewApi.getCoursesByCategory(_mainCategories[index].categoryId);
      if (!mounted) return;
      setState(() { _subCategories = subs; _courses = courses; });
    } catch (e) {
      debugPrint('메인 카테고리 변경 오류: $e');
    }
  }

  Future<void> _onSubChanged(int index) async {
    setState(() { _subIndex = index; _courses = []; });
    try {
      final categoryId = index == 0
          ? _mainCategories[_mainIndex].categoryId
          : _subCategories[index - 1].categoryId;
      final courses = await LessonOverviewApi.getCoursesByCategory(categoryId);
      if (!mounted) return;
      setState(() => _courses = courses);
    } catch (e) {
      debugPrint('서브 카테고리 변경 오류: $e');
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
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _buildDropdowns(),
        ),
        const Divider(height: 1, thickness: 1, color: _kBorder),
        Expanded(
          child: _courses.isEmpty
              ? const Center(
                  child: Text('강좌가 없습니다.',
                      style: TextStyle(color: _kGray, fontSize: 14)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) => _CourseSummaryCard(course: _courses[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdowns() {
    final subItems = ['전체', ..._subCategories.map((c) => c.categoryName)];
    return Row(
      children: [
        _DropdownMenu(
          items: _mainCategories.map((c) => c.categoryName).toList(),
          selectedIndex: _mainIndex,
          onChanged: _onMainChanged,
          width: 120,
        ),
        const SizedBox(width: 8),
        _DropdownMenu(
          items: subItems,
          selectedIndex: _subIndex,
          onChanged: _onSubChanged,
          width: 140,
        ),
      ],
    );
  }
}

// ── 드롭다운 ──────────────────────────────────────────────

class _DropdownMenu extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double width;

  const _DropdownMenu({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    required this.width,
  });

  @override
  State<_DropdownMenu> createState() => _DropdownMenuState();
}

class _DropdownMenuState extends State<_DropdownMenu> {
  bool _open = false;
  final _key = GlobalKey();
  OverlayEntry? _entry;

  void _toggle() {
    _open ? _close() : _openOverlay();
    setState(() => _open = !_open);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _openOverlay() {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(builder: (_) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () { _close(); setState(() => _open = false); },
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height,
            width: widget.width,
            child: Material(
              elevation: 4,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              shadowColor: Colors.black12,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _kBlue.withValues(alpha: 0.4)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: widget.items
                      .asMap()
                      .entries
                      .where((e) => e.key != widget.selectedIndex)
                      .map((e) => InkWell(
                            onTap: () {
                              _close();
                              setState(() => _open = false);
                              widget.onChanged(e.key);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 14, color: _kDark)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      );
    });

    Overlay.of(context).insert(_entry!);
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.items.isEmpty
        ? ''
        : widget.items[widget.selectedIndex.clamp(0, widget.items.length - 1)];

    return SizedBox(
      key: _key,
      width: widget.width,
      height: 38,
      child: GestureDetector(
        onTap: widget.items.isEmpty ? null : _toggle,
        child: Container(
          decoration: BoxDecoration(
            color: _open ? Colors.white : Colors.white,
            border: Border.all(
              color: _open ? _kBlue : _kBorder,
              width: _open ? 1.5 : 1,
            ),
            borderRadius: _open
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 14, color: _kDark),
                    overflow: TextOverflow.ellipsis),
              ),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.arrow_drop_down,
                    color: _open ? _kBlue : _kGray, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 강좌 카드 ─────────────────────────────────────────────

class _CourseSummaryCard extends StatelessWidget {
  final CourseOverview course;
  const _CourseSummaryCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          const SizedBox(width: 14),
          Expanded(child: _buildInfo(context)),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final src = course.imageSrc;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: src != null
          ? Image.network(
              '${ApiConstants.baseUrl}/media/$src',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.school, color: _kBlue, size: 32),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Chip(text: course.teacherName, icon: Icons.person_outline),
            if (course.lessonCategoryInfo.parentCategoryName.isNotEmpty)
              _Chip(text: course.lessonCategoryInfo.parentCategoryName),
            if (course.lessonCategoryInfo.categoryName.isNotEmpty)
              _Chip(text: course.lessonCategoryInfo.categoryName),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          course.courseName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
        ),
        const SizedBox(height: 10),
        _PreviewButton(course: course),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _Chip({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: _kBlue),
            const SizedBox(width: 3),
          ],
          Text(text,
              style: const TextStyle(fontSize: 11, color: _kBlue, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatefulWidget {
  final CourseOverview course;
  const _PreviewButton({required this.course});

  @override
  State<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<_PreviewButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          Uri(path: '/preview-class', queryParameters: {
            'teacherName': widget.course.teacherName,
            'onlineCourseId': '${widget.course.courseId}',
          }).toString(),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? _kBlue : Colors.white,
            border: Border.all(color: _kBlue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '강좌 무료 체험',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _hovered ? Colors.white : _kBlue,
            ),
          ),
        ),
      ),
    );
  }
}
