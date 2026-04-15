import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<(UserModel, String?, Map<String, dynamic>?)> login(String email, String password,) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = UserModel.fromSupabaseUser(response.user!);

    final userData = await _supabase
        .from('usuarios')
        .select('rol_id, roles(nombre, permisos)')
        .eq('id', response.user!.id)
        .maybeSingle();

    final rolId = userData?['rol_id'] as String?;
    final permisos = userData?['roles']?['permisos'] as Map<String, dynamic>?;

    return (user, rolId, permisos);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  Future<Map<String, dynamic>?> getPermisos(String userId) async {
  final response = await _supabase
      .from('usuarios')
      .select('roles(permisos)')
      .eq('id', userId)
      .maybeSingle();

  return response?['roles']?['permisos'] as Map<String, dynamic>?;
  }

  Future<String?> getRolId(String userId) async {
    final response = await _supabase
        .from('usuarios')
        .select('rol_id')
        .eq('id', userId)
        .maybeSingle();

    return response?['rol_id'] as String?;
  }
}
