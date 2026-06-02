import 'package:flutter_test/flutter_test.dart';
import 'package:thesisapp/model/user.dart';

void main() {
  test('user role defaults to user', () {
    final user = User(name_kh: 'Student', student_id: '001', pwd: 'secret');

    expect(user.role, 'user');
    expect(user.isAdmin, isFalse);
  });

  test('admin role is normalized', () {
    final user = User(
      name_kh: 'Admin',
      student_id: 'admin',
      pwd: 'admin123',
      role: ' Admin ',
    );

    expect(user.role, 'admin');
    expect(user.isAdmin, isTrue);
  });
}
