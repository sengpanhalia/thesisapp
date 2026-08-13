const String APIUrlUserKh_ = 'https://api.usea.edu.kh/apidata.php?';
const String APIStLoginKh = APIUrlUserKh_ + 'action=login_student';

// Local PHP API that calls USEA API and syncs user data to local database
// NOTE: Use 10.0.2.2 for Android emulator, or your PC's local IP for physical device
const String APILocalLoginUrl = 'http://10.0.2.2/usea_main_api_official/user_data_from_api_login.php';