class AppUser {
  final int id;
  final String name;
  final String email;
  final String currency;

  AppUser({required this.id, required this.name, required this.email, required this.currency});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        currency: json['currency'] ?? 'USD',
      );
}
