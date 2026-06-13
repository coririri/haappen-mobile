import '../models/course.dart';
import '../models/workbook.dart';

class WorkbookApi {
  static const List<Course> _courses = [
    Course(courseId: 9001, courseName: '수학(상) 문제집', type: 'workbook'),
    Course(courseId: 9002, courseName: '수학(하) 문제집', type: 'workbook'),
  ];

  static final Map<int, WorkbookDetail> _details = {
    9001: WorkbookDetail(
      courseId: 9001,
      title: '수학(상) 문제집',
      description: '고1 수학(상) 핵심 문제 풀이 강의입니다.\n다항식, 방정식과 부등식, 도형의 방정식 단원을 다룹니다.',
      problems: List.generate(100, (i) => WorkbookProblem(problemNumber: i + 1)),
    ),
    9002: WorkbookDetail(
      courseId: 9002,
      title: '수학(하) 문제집',
      description: '고1 수학(하) 핵심 문제 풀이 강의입니다.\n집합과 명제, 함수와 그래프, 경우의 수 단원을 다룹니다.',
      problems: List.generate(120, (i) => WorkbookProblem(problemNumber: i + 1)),
    ),
  };

  static List<Course> getWorkbookCourses() => _courses;

  static WorkbookDetail? getWorkbookDetail(int courseId) => _details[courseId];
}
