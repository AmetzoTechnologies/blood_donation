import 'user.dart';

class UserModel {
  User? user;

  UserModel({this.user});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    user: json['user'] == null
        ? null
        : User.fromJson(Map<String, dynamic>.from(json['user'])),
  );

  Map<String, dynamic> toJson() => {if (user != null) 'user': user?.toJson()};
}
