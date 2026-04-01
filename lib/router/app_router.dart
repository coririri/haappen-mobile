import 'package:go_router/go_router.dart';
import 'package:haanppen_mobile/pages/lesson/lesson_page.dart';
import 'package:haanppen_mobile/pages/lesson_overview/lesson_overview_page.dart';
import 'package:haanppen_mobile/pages/login/login_page.dart';
import 'package:haanppen_mobile/pages/main/main_page.dart';
import 'package:haanppen_mobile/pages/my_class/my_class_page.dart';
import 'package:haanppen_mobile/pages/privacy/privacy_page.dart';
import 'package:haanppen_mobile/pages/question_board/question_board_page.dart';
import 'package:haanppen_mobile/pages/write_question/write_question_page.dart';
import 'package:haanppen_mobile/pages/question_detail/question_detail_page.dart';
import 'package:haanppen_mobile/pages/user_information/user_information_page.dart';
import 'package:haanppen_mobile/services/auth_service.dart';

const _publicRoutes = {'/login', '/privacy'};

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthService.instance,
  redirect: (context, state) async {
    final path = state.matchedLocation;
    if (_publicRoutes.contains(path)) return null;
    if (!await AuthService.instance.isAuthenticated()) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/question-board',
      builder: (context, state) => const QuestionBoardPage(),
    ),
    GoRoute(
      path: '/write-question',
      builder: (context, state) => const WriteQuestionPage(),
    ),
    GoRoute(
      path: '/question/:id',
      builder: (context, state) => QuestionDetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/my-class',
      builder: (context, state) {
        final classIndex = int.tryParse(state.uri.queryParameters['classIndex'] ?? '0') ?? 0;
        final sortIndex = int.tryParse(state.uri.queryParameters['sortIndex'] ?? '0') ?? 0;
        final courseType = state.uri.queryParameters['courseType'] ?? '';
        return MyClassPage(
          classIndex: classIndex,
          sortIndex: sortIndex,
          courseType: courseType,
        );
      },
    ),
    GoRoute(
      path: '/lesson-overview',
      builder: (context, state) => const LessonOverviewPage(),
    ),
    GoRoute(
      path: '/lesson',
      builder: (context, state) => LessonPage(
        courseId: int.tryParse(state.uri.queryParameters['courseId'] ?? '') ?? 0,
        date: state.uri.queryParameters['date'] ?? '',
      ),
    ),
    GoRoute(
      path: '/user-information',
      builder: (context, state) => const UserInformationPage(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPage(),
    ),
  ],
);
