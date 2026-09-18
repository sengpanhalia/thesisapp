class UserDetail {
  late final String faculty_name, degree_name, major_name, year_name, semester_name, name_kh, name_en, student_id, stage_name, term_name, academic_year, shift_name, room_name, status_name, date_of_birth, phone_number, profile_pic, job, work_place, gender;

  UserDetail({
    required this.faculty_name,
    required this.degree_name,
    required this.major_name,
    required this.year_name,
    required this.semester_name,
    required this.name_kh,
    required this.name_en,
    required this.student_id,
    required this.stage_name,
    required this.term_name,
    required this.academic_year,
    required this.shift_name,
    required this.room_name,
    required this.status_name,
    required this.date_of_birth,
    required this.phone_number,
    required this.profile_pic,
    required this.job,
    required this.work_place,
    this.gender = '',
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    String field(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;

        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }

      return '';
    }

    return UserDetail(
      faculty_name: json['faculty_name'] ?? '',
      degree_name: json['degree_name'] ?? '',
      major_name: json['major_name'] ?? '',
      year_name: json['year_name'] ?? '',
      semester_name: json['semester_name'] ?? '',
      name_kh: json['name_kh'] ?? '',
      name_en: json['name_en'] ?? '',
      student_id: json['student_id'] ?? '',
      stage_name: field([
        'stage_name',
        'promotion',
        'promotion_name',
        'generation',
        'generation_name',
        'batch',
        'batch_name',
      ]),
      term_name: field(['term_name', 'term', 'term_no']),
      academic_year: json['academic_year'] ?? '',
      shift_name: json['shift_name'] ?? '',
      room_name: json['room_name'] ?? '',
      status_name: json['status_name'] ?? '',
      date_of_birth: json['date_of_birth'] ?? '',
      phone_number: json['phone_number'] ?? '',
      profile_pic: json['profile_pic'] ?? '',
      job: json['job'] ?? '',
      work_place: json['work_place'] ?? '',
      gender: json['gender'] ?? json['sex_name'] ?? json['sex'] ?? json['gender_name'] ?? '',
    );
  }
}
