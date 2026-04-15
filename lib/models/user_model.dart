import'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String? email;
  final String? nombre;
  final bool? emailConfirmado;

  UserModel({
    required this.id,
    this.email,
    this.nombre,
    this.emailConfirmado,
  });

  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      nombre: user.userMetadata?['nombre'] ?? user.email?.split('@')[0],
      emailConfirmado: user.emailConfirmedAt != null,
    );
  }
}