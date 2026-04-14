import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haanppen_mobile/apis/question_api.dart';
import 'package:haanppen_mobile/models/question.dart';
import 'package:haanppen_mobile/widgets/main_header.dart';

const _kBlue = Color(0xFF3B82F6);
const _kPageSize = 8;

class QuestionBoardPage extends StatefulWidget {
  const QuestionBoardPage({super.key});

  @override
  State<QuestionBoardPage> createState() => _QuestionBoardPageState();
}

class _QuestionBoardPageState extends State<QuestionBoardPage> {
  bool _isAllTab = true; // true = 전체 질문, false = 내 질문
  List<Question> _questions = [];
  QuestionPageInfo _pageInfo =
      const QuestionPageInfo(totalItemSize: 0, currentPage: 0, pageSize: 8);
  int _page = 0; // 0-based
  final _searchController = TextEditingController();
  String _searchValue = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final result = _isAllTab
          ? await QuestionApi.getQuestions(_page, _searchValue)
          : await QuestionApi.getMyQuestions(_page, _searchValue);
      if (mounted) {
        setState(() {
          _questions = result.questions;
          _pageInfo = result.pageInfo;
        });
      }
    } catch (e) {
      debugPrint('질문 목록 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTabChanged(bool isAll) {
    if (_isAllTab == isAll) return;
    setState(() {
      _isAllTab = isAll;
      _page = 0;
    });
    _loadQuestions();
  }

  void _onSearch() {
    setState(() {
      _searchValue = _searchController.text.trim();
      _page = 0;
    });
    _loadQuestions();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _loadQuestions();
  }

  int get _totalPages =>
      (_pageInfo.totalItemSize / _kPageSize).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          const MainHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 16),
                    _buildTable(),
                    const SizedBox(height: 16),
                    _buildPagination(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 탭 스위처
        Row(
          children: [
            _TabButton(
              text: '전체 질문',
              isActive: _isAllTab,
              onTap: () => _onTabChanged(true),
            ),
            const SizedBox(width: 8),
            _TabButton(
              text: '내 질문',
              isActive: !_isAllTab,
              onTap: () => _onTabChanged(false),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 검색바 + 질문 작성 버튼
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearch(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '질문 검색',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _kBlue),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: _onSearch,
                      child: const Icon(Icons.search,
                          size: 18, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/write-question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 0),
                  elevation: 0,
                ),
                icon: const Icon(Icons.edit, size: 14),
                label:
                    const Text('질문 작성', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable() {
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
          _buildTableHeader(),
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(
                  child: CircularProgressIndicator(color: _kBlue)),
            )
          else ...[
            ..._questions.map((q) => _QuestionRow(question: q)),
            // 빈 행 채우기
            ...List.generate(
              (_kPageSize - _questions.length).clamp(0, _kPageSize),
              (_) => const _EmptyRow(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF6F6F6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: const Row(
        children: [
          SizedBox(
            width: 56,
            child: Text('상태',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF374151))),
          ),
          Expanded(
            child: Text('제목',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF374151))),
          ),
          SizedBox(
            width: 72,
            child: Text('선생님',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

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

// ── 탭 버튼 ──────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton(
      {required this.text, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _kBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive ? _kBlue : const Color(0xFFD1D5DB)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── 질문 행 ───────────────────────────────────────────────
class _QuestionRow extends StatefulWidget {
  final Question question;
  const _QuestionRow({required this.question});

  @override
  State<_QuestionRow> createState() => _QuestionRowState();
}

class _QuestionRowState extends State<_QuestionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/question/${q.questionId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? _kBlue.withValues(alpha: 0.05)
              : Colors.white,
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          child: Column(
            children: [
              Row(
                children: [
                  // 상태 뱃지
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: _SolvedBadge(solved: q.solved),
                    ),
                  ),
                  // 제목
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text('${q.commentCount}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility_outlined,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text('${q.viewCount}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 선생님
                  SizedBox(
                    width: 72,
                    child: Text(
                      q.target?.memberName ?? '-',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
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
      height: 44,
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
    );
  }
}

// ── 해결/미해결 뱃지 ───────────────────────────────────────
class _SolvedBadge extends StatelessWidget {
  final bool solved;
  const _SolvedBadge({required this.solved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: solved
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        solved ? '해결' : '미해결',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color:
              solved ? const Color(0xFF16A34A) : const Color(0xFFD97706),
        ),
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
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.white : const Color(0xFF374151),
                  ),
                ),
        ),
      ),
    );
  }
}
