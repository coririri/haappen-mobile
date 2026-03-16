class QuestionMember {
  final int memberId;
  final String memberName;
  final int? memberGrade;
  final String role;

  const QuestionMember({
    required this.memberId,
    required this.memberName,
    this.memberGrade,
    required this.role,
  });

  factory QuestionMember.fromJson(Map<String, dynamic> json) => QuestionMember(
        memberId: json['memberId'] as int,
        memberName: json['memberName'] as String,
        memberGrade: json['memberGrade'] as int?,
        role: json['role'] as String,
      );
}

class Question {
  final int questionId;
  final String title;
  final String registeredDateTime;
  final bool solved;
  final int commentCount;
  final int viewCount;
  final QuestionMember owner;
  final QuestionMember? target;

  const Question({
    required this.questionId,
    required this.title,
    required this.registeredDateTime,
    required this.solved,
    required this.commentCount,
    required this.viewCount,
    required this.owner,
    this.target,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        questionId: json['questionId'] as int,
        title: json['title'] as String,
        registeredDateTime: json['registeredDateTime'] as String,
        solved: json['solved'] as bool,
        commentCount: json['commentCount'] as int,
        viewCount: json['viewCount'] as int,
        owner: QuestionMember.fromJson(json['owner'] as Map<String, dynamic>),
        target: json['target'] != null
            ? QuestionMember.fromJson(json['target'] as Map<String, dynamic>)
            : null,
      );
}

class QuestionPageInfo {
  final int totalItemSize;
  final int currentPage;
  final int pageSize;

  const QuestionPageInfo({
    required this.totalItemSize,
    required this.currentPage,
    required this.pageSize,
  });

  factory QuestionPageInfo.fromJson(Map<String, dynamic> json) =>
      QuestionPageInfo(
        totalItemSize: json['totalItemSize'] as int,
        currentPage: json['currentPage'] as int,
        pageSize: json['pageSize'] as int,
      );
}
