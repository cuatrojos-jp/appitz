import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String? authId; // ID del usuario en auth.users
  final String? email;
  final String? nombre;
  final bool activo; // Si el usuario ha sido aprobado
  final String rolId; // Rol del usuario
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.authId,
    this.email,
    this.nombre,
    required this.activo,
    required this.rolId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromSupabaseUser(
    User user, {
    required bool activo,
    required String rolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: user.id,
      authId: user.id,
      email: user.email,
      nombre: user.userMetadata?['nombre'] ?? user.email?.split('@')[0],
      activo: activo,
      rolId: rolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get puedeHacerLogin => activo;

  bool get esAdmin {
    const adminRoleId = 'a0d38955-fa67-4751-a36b-777fcf4d8ed9';
    return rolId == adminRoleId;
  }

  String get iniciales {
    if (nombre != null && nombre!.isNotEmpty) {
      final partes = nombre!.split(' ');
      if (partes.length >= 2) {
        return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
      }
      return nombre![0].toUpperCase();
    }
    return '?';
  }
}
