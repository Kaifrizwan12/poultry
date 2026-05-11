class UserModel {
  final String uid;
  final String name;
  final String email;
  final String farmType;

  UserModel(
      {required this.uid,
      required this.name,
      required this.email,
      required this.farmType});

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        farmType: m['farmType'] ?? '',
      );

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'name': name, 'email': email, 'farmType': farmType};
}
