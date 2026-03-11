import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../apis/banner_api.dart';
import '../../apis/course_api.dart';
import '../../widgets/main_header.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _hoveredDay;
  List<NoticeBanner> _banners = [];
  List<CourseMemo> _monthlyCourses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadBanners(), _loadMonthlyCourses(_focusedDay)]);
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await NoticeBannerApi.getNoticeBanners();
      if (mounted) setState(() => _banners = banners);
    } catch (_) {}
  }

  Future<void> _loadMonthlyCourses(DateTime month) async {
    try {
      final monthInfo = DateFormat('yyyy-MM-dd').format(month);
      final courses = await CourseApi.getMonthlyCourses(monthInfo);
      if (mounted) setState(() => _monthlyCourses = courses);
    } catch (_) {}
  }

  List<CourseMemo> get _selectedCourses {
    final selected = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return _monthlyCourses
        .where((c) =>
            DateFormat('yyyy-MM-dd').format(c.registeredDateTime) == selected)
        .toList();
  }

  Set<String> get _markedDates => _monthlyCourses
      .map((c) => DateFormat('yyyy-MM-dd').format(c.registeredDateTime))
      .toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 16),
                  _buildTodayLessons(),
                  const SizedBox(height: 16),
                  _buildNotices(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadMonthlyCourses(focusedDay);
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: kPrimaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          todayTextStyle: const TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          selectedDecoration: BoxDecoration(
            color: kPrimaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          defaultTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          weekendTextStyle: const TextStyle(fontSize: 14, color: Color(0xFFEF4444)),
          outsideTextStyle: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
          markerDecoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markersMaxCount: 1,
          markersOffset: const PositionedOffset(bottom: 4),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final isHovered = _hoveredDay != null && isSameDay(_hoveredDay, day);
            final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hoveredDay = day),
              onExit: (_) => setState(() => _hoveredDay = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isHovered
                      ? kPrimaryBlue.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isWeekend ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                  ),
                ),
              ),
            );
          },
          markerBuilder: (context, day, _) {
            final key = DateFormat('yyyy-MM-dd').format(day);
            if (_markedDates.contains(key)) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        eventLoader: (day) {
          final key = DateFormat('yyyy-MM-dd').format(day);
          return _markedDates.contains(key) ? [true] : [];
        },
        daysOfWeekHeight: 28,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF94A3B8), size: 22),
          rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
          headerPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
        ),
        rowHeight: 46,
      ),
    );
  }

  Widget _buildTodayLessons() {
    final selectedLabel = DateFormat('M월 d일', 'ko_KR').format(_selectedDay);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedLabel 강의',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          if (_selectedCourses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '강의가 없습니다.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ),
            )
          else
            ..._selectedCourses.map((course) => _CourseTile(course: course)),
        ],
      ),
    );
  }

  Widget _buildNotices() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📢', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text(
                '공지사항',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_banners.isEmpty)
            const Text(
              '공지사항이 없습니다.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            )
          else
            ...List.generate(_banners.length * 2 - 1, (i) {
              if (i.isOdd) {
                return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
              }
              final b = _banners[i ~/ 2];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 16, color: kPrimaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b.bannerContent,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final CourseMemo course;

  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy-MM-dd').format(course.registeredDateTime);
    final dateLabel = DateFormat('yyyy.MM.dd 수업').format(course.registeredDateTime);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => context.go(
              '/lesson?date=$date&courseId=${course.courseId}',
            ),
            style: TextButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('수업 보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
