import 'package:flutter_3/utils/enums.dart';

class UserCredentials {
  late String username;
  late String password;
  late UserType userType;

  // Singleton pattern to ensure only one instance of UserCredentials
  static final UserCredentials _instance = UserCredentials._internal();

  factory UserCredentials() {
    return _instance;
  }

  UserCredentials._internal();

  void setUserCredentials(String username, String password, UserType userType) {
    this.username = username;
    this.password = password;
    this.userType = userType;
  }

  Future<void> clearUserCredentials() async {
    username = '';
    password = '';
    userType = UserType.REGULAR;
  }

  UserType getUserType() {
    return userType;
  }
}
