import 'package:flutter_test/flutter_test.dart';
import 'package:thesisapp/model/user.dart';

void main() {
  test('user role defaults to user', () {
    final user = User(name_kh: 'Student', student_id: '001', pwd: 'secret', name_en: 'Student');

    expect(user.role, 'user');
  });

  test('role is normalized', () {
    final user = User(
      name_kh: 'Test User',
      student_id: 'test01',
      pwd: '123',
      role: ' User ',
      name_en: 'Test User',
    );

    expect(user.role, 'user');
  });
}
