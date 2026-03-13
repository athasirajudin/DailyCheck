enum UserRole { admin, pembimbing, intern }

UserRole userRoleFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'ADMIN':
      return UserRole.admin;
    case 'PEMBIMBING':
      return UserRole.pembimbing;
    case 'INTERN':
      return UserRole.intern;
    default:
      throw ArgumentError('Unknown role: $value');
  }
}

String userRoleToApi(UserRole role) {
  return switch (role) {
    UserRole.admin => 'ADMIN',
    UserRole.pembimbing => 'PEMBIMBING',
    UserRole.intern => 'INTERN',
  };
}

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String email;
  final String fullName;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      role: userRoleFromApi((json['role'] ?? '').toString()),
    );
  }
}

