class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final fullName = [json['first_name'], json['last_name']]
        .whereType<String>()
        .join(' ')
        .trim();
    return AppUser(
      id: json['id'].toString(),
      name: json['name'] as String? ?? (fullName.isEmpty ? email : fullName),
      email: email,
      photoUrl: (json['photo_url'] ?? json['avatar'] ?? json['picture']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
      };
}
