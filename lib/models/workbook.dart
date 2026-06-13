class WorkbookProblem {
  final int problemNumber;

  const WorkbookProblem({required this.problemNumber});
}

class WorkbookDetail {
  final int courseId;
  final String title;
  final String description;
  final List<WorkbookProblem> problems;

  const WorkbookDetail({
    required this.courseId,
    required this.title,
    required this.description,
    required this.problems,
  });
}
