import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String? email;
  final String? nombre;
  final bool? emailConfirmado;
  final bool activo; // Si el usuario ha sido aprobado
  final String rolId; // Rol del usuario

  UserModel({
    required this.id,
    this.email,
    this.nombre,
    this.emailConfirmado,
    required this.activo,
    required this.rolId,
  });

  factory UserModel.fromSupabaseUser(
    User user, {
    required bool activo,
    required String rolId,
    String? jugadorId,
  }) {
    return UserModel(
      id: user.id,
      email: user.email,
      nombre: user.userMetadata?['nombre'] ?? user.email?.split('@')[0],
      emailConfirmado: user.emailConfirmedAt != null,
      activo: activo,
      rolId: rolId,
    );
  }

  bool get puedeHacerLogin => activo;

  bool get esAdmin => rolId == 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
}
