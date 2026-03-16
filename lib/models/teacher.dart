class Teacher {
  final int id;
  final String name;

  const Teacher({required this.id, required this.name});

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
