/// What the inventory system knows about a student, from
/// `GET /api/v1/students.php?student_id=…`.
///
/// Four fields and no more, on purpose: there is no "list all students" in
/// that API, so a leaked app token cannot pull the student directory. Anything
/// richer — faculty, major, photo — belongs to the university's own student
/// API, not to this one.
class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.name,
    required this.nameKh,
    required this.yearLevel,
  });

  final String studentId;
  final String name;
  final String nameKh;

  /// `Year 2`, or empty when the registry has not recorded one.
  final String yearLevel;

  String nameFor({required bool khmer}) {
    final kh = nameKh.trim();
    final en = name.trim();

    return khmer ? (kh.isNotEmpty ? kh : en) : (en.isNotEmpty ? en : kh);
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['student_id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      nameKh: json['name_kh']?.toString().trim() ?? '',
      yearLevel: json['year_level']?.toString().trim() ?? '',
    );
  }
}
