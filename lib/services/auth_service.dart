import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<(UserModel, String?, Map<String, dynamic>?)> login(
    String email,
    String password,
  ) async {
    // Autenticar con Supabase Auth
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Obtener datos adicionales de tu tabla 'usuarios'
    final userData = await _supabase
        .from('usuarios')
        .select('activo, rol_id, roles(nombre, permisos), jugador_id')
        .eq('id', response.user!.id)
        .maybeSingle();

    // Verificar si el usuario está aprobado (activo = true)
    // Si no está aprobado, lanzar excepción para impedir el login
    if (userData == null || userData['activo'] != true) {
      throw Exception('Tu cuenta está pendiente de aprobación por el coordinador.');
    }

    // Construir UserModel con los datos de auth.users
    final user = UserModel.fromSupabaseUser(
      response.user!,
      activo: userData['activo'],
      rolId: userData['rol_id'],
      jugadorId: userData['jugador_id'],
    );

    // Extraer rol ID y permisos para devolverlos en la tupla
    final rolId = userData['rol_id'] as String?;
    final permisos = userData['roles']?['permisos'] as Map<String, dynamic>?;

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

  // Obtener los permisos del rol de un usuario (para UI condicional)
  Future<Map<String, dynamic>?> getPermisos(String userId) async {
    final response = await _supabase
        .from('usuarios')
        .select('roles(permisos)')
        .eq('id', userId)
        .maybeSingle();

    return response?['roles']?['permisos'] as Map<String, dynamic>?;
  }

  // Obtener solo el ID del rol (para comparaciones rápidas)
  Future<String?> getRolId(String userId) async {
    final response = await _supabase
        .from('usuarios')
        .select('rol_id')
        .eq('id', userId)
        .maybeSingle();

    return response?['rol_id'] as String?;
  }
  
  // Registrar un nuevo usuario (crea cuenta pendiente de aprobación)
  Future<void> registrar(String email, String password, String nombre) async {
    // El trigger en Supabase se encargará de crear el registro en 'usuarios'
    // con activo = false (pendiente de aprobación)
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': nombre},  // ← Va a raw_user_meta_data
    );
  }
}