import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';

const kPrimaryBlue = Color(0xFF3B82F6);

class _NavItem {
  final String label;
  final String emoji;
  final String route;
  const _NavItem(this.label, this.emoji, this.route);
}

const _navItems = [
  _NavItem('내 강의', '📚', '/my-class'),
  _NavItem('질문', '❓', '/question-board'),
  _NavItem('강좌', '🎓', '/lesson-overview'),
];

class MainHeader extends StatefulWidget {
  const MainHeader({super.key});

  @override
  State<MainHeader> createState() => _MainHeaderState();
}

class _MainHeaderState extends State<MainHeader> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userName = await StorageService.getUserName();
    if (mounted) {
      setState(() {
        _userName = userName ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Image.asset(
                    'lib/assests/haanppen_logo.png',
                    width: 70,
                  ),
                ),
                const Text(
                  '학생',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/user-information'),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: kPrimaryBlue.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: kPrimaryBlue,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
        _buildNav(context),
      ],
    );
  }

  Widget _buildNav(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    return Row(
      children: _navItems.map((item) {
        final isActive = currentPath.startsWith(item.route.split('?').first);
        return Expanded(
          child: GestureDetector(
            onTap: () => context.go(item.route),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? kPrimaryBlue : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? kPrimaryBlue : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
