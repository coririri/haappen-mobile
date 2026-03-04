import 'package:go_router/go_router.dart';
import 'package:haanppen_mobile/pages/lesson_overview/lesson_overview_page.dart';
import 'package:haanppen_mobile/pages/login/login_page.dart';
import 'package:haanppen_mobile/pages/main/main_page.dart';
import 'package:haanppen_mobile/pages/my_class/my_class_page.dart';
import 'package:haanppen_mobile/pages/privacy/privacy_page.dart';
import 'package:haanppen_mobile/pages/question_board/question_board_page.dart';
import 'package:haanppen_mobile/pages/question_detail/question_detail_page.dart';
import 'package:haanppen_mobile/pages/user_information/user_information_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
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
      path: '/question/:id',
      builder: (context, state) => QuestionDetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/my-class',
      builder: (context, state) => MyClassPage(
        classIndex: int.tryParse(state.uri.queryParameters['classIndex'] ?? '0') ?? 0,
        sortIndex: int.tryParse(state.uri.queryParameters['sortIndex'] ?? '0') ?? 0,
        courseType: state.uri.queryParameters['courseType'] ?? '',
      ),
    ),
    GoRoute(
      path: '/lesson-overview',
      builder: (context, state) => const LessonOverviewPage(),
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
