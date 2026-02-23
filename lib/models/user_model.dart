class UserModel {
  final String uid;
  final String? email;

  const UserModel({required this.uid, this.email});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(uid: map['uid'] as String, email: map['email'] as String?);
  }
}
