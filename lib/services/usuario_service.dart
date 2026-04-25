import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UsuarioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // REGISTRO DE NUEVO USUARIO
  // ============================================================

  /// Registra un nuevo usuario en auth.users
  /// El trigger en Supabase creará automáticamente el registro en 'usuarios' con activo = false
  Future<void> registrar(String email, String password, String nombre) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': nombre}, // Va a raw_user_meta_data
    );
  }

  // lib/services/usuario_service.dart

  /// Crear un nuevo usuario con contraseña temporal y rol asignado
  Future<void> crearUsuario({
    required String email,
    required String nombre,
    required String password,
    required String rolId,
  }) async {
    // 1. Crear usuario en auth.users con contraseña temporal
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nombre': nombre},
    );

    // 2. Esperar a que el trigger cree el registro en 'usuarios'
    // Pequeña pausa para asegurar que el trigger se ejecute
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. Obtener el auth_id del usuario recién creado
    final userData = await _supabase
        .from('usuarios')
        .select('auth_id')
        .eq('email', email)
        .maybeSingle();

    if (userData == null) return;

    // 4. Actualizar el rol en tu tabla usuarios
    await _supabase
        .from('usuarios')
        .update({'rol_id': rolId})
        .eq('auth_id', userData['id']);
  }

  // ============================================================
  // ADMIN: GESTIÓN DE SOLICITUDES (usuarios pendientes)
  // ============================================================

  /// Obtiene todas las solicitudes pendientes (usuarios con activo = false)
  /// JOIN con auth.users para obtener el email
  Future<List<Map<String, dynamic>>> obtenerSolicitudesPendientes() async {
    final response = await _supabase
        .from('usuarios')
        .select('''
          id,
          nombre,
          activo,
          auth_users!inner(email, created_at)
        ''')
        .eq('activo', false)
        .order('created_at', ascending: false); // Las más recientes primero

    return response;
  }

  /// Obtiene el detalle de una solicitud específica
  /// Incluye datos del usuario y lista de jugadores disponibles para vincular
  Future<Map<String, dynamic>> obtenerSolicitudDetalle(String usuarioId) async {
    // 1. Obtener datos del usuario pendiente
    final solicitud = await _supabase
        .from('usuarios')
        .select('''
          id,
          nombre,
          auth_users!inner(email, created_at)
        ''')
        .eq('id', usuarioId)
        .eq('activo', false)
        .single();

    // 2. Obtener lista de jugadores SIN usuario vinculado (para opción de vincular)
    final jugadoresDisponibles = await _supabase
        .from('jugadores')
        .select('id, nombre_completo, posicion')
        .filter('usuario_id', 'is', 'null') // Solo jugadores sin usuario
        .order('nombre_completo');

    return {
      'solicitud': solicitud,
      'jugadores_disponibles': jugadoresDisponibles,
    };
  }

  // ============================================================
  // ADMIN: APROBACIÓN DE SOLICITUDES
  // ============================================================

  /// Aprobar solicitud vinculando a un jugador EXISTENTE
  Future<void> aprobarConJugadorExistente({
    required String usuarioId,
    required String jugadorId,
    required String rolId, // Normalmente el ID del rol 'jugador'
  }) async {
    // 1. Actualizar usuario: activo = true, asignar rol
    await _supabase
        .from('usuarios')
        .update({'activo': true, 'rol_id': rolId})
        .eq('id', usuarioId);

    // 2. Vincular el jugador con este usuario
    await _supabase
        .from('jugadores')
        .update({'usuario_id': usuarioId})
        .eq('id', jugadorId);
  }

  /// Aprobar solicitud CREANDO un nuevo jugador
  Future<void> aprobarConJugadorNuevo({
    required String usuarioId,
    required String rolId,
    required String nombreCompleto,
    DateTime? fechaNacimiento,
    String? posicion,
  }) async {
    // 1. Crear nuevo jugador vinculado al usuario
    await _supabase.from('jugadores').insert({
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'posicion': posicion,
      'usuario_id': usuarioId, // Vincular desde el inicio
    });

    // 2. Actualizar usuario: activo = true, asignar rol
    await _supabase
        .from('usuarios')
        .update({'activo': true, 'rol_id': rolId})
        .eq('id', usuarioId);
  }

  // ============================================================
  // ADMIN: RECHAZO DE SOLICITUDES
  // ============================================================

  /// Rechazar una solicitud (eliminar el usuario)
  /// Esto elimina tanto de auth.users como de tu tabla 'usuarios' (por CASCADE)
  Future<void> rechazarSolicitud(String usuarioId) async {
    // Eliminar de auth.users (CASCADE eliminará de 'usuarios' automáticamente)
    await _supabase.auth.admin.deleteUser(usuarioId);
  }

  // ============================================================
  // ADMIN: LISTADO DE USUARIOS (TODOS)
  // ============================================================

  /// Obtener todos los usuarios del sistema (aprobados y pendientes)
  // Future<List<Map<String, dynamic>>> obtenerTodosLosUsuarios() async {
  //   final response = await _supabase
  //       .from('usuarios')
  //       .select('''
  //         id,
  //         nombre,
  //         activo,
  //         rol_id,
  //         roles(nombre),
  //         "auth.users"!inner(email, created_at)
  //       ''')
  //       .order('created_at', ascending: false);

  //   return response;
  // }

  Future<List<UserModel>> obtenerTodosLosUsuarios() async {
    final response = await _supabase
        .from('usuarios')
        .select('''
        id,
        auth_id,
        nombre,
        email,
        activo,
        rol_id,
        created_at,
        updated_at
      ''')
        .order('created_at', ascending: false);

    return response
        .map(
          (data) => UserModel(
            id: data['id'],
            authId: data['auth_id'],
            email: data['email'],
            nombre: data['nombre'],
            activo: data['activo'] ?? false,
            rolId: data['rol_id'] ?? '',
            createdAt: DateTime.parse(data['created_at']),
            updatedAt: DateTime.parse(data['updated_at']),
          ),
        )
        .toList();
  }

  // ============================================================
  // ADMIN: GESTIÓN DE USUARIOS APROBADOS
  // ============================================================

  /// Cambiar el rol de un usuario
  Future<void> cambiarRol(String usuarioId, String nuevoRolId) async {
    await _supabase
        .from('usuarios')
        .update({'rol_id': nuevoRolId})
        .eq('id', usuarioId);
  }

  /// Desactivar un usuario (no puede hacer login, pero se conservan sus datos)
  Future<void> desactivarUsuario(String usuarioId) async {
    await _supabase
        .from('usuarios')
        .update({'activo': false})
        .eq('id', usuarioId);
  }

  /// Reactivar un usuario previamente desactivado
  Future<void> reactivarUsuario(String usuarioId, String rolId) async {
    await _supabase
        .from('usuarios')
        .update({'activo': true, 'rol_id': rolId})
        .eq('id', usuarioId);
  }

  // ============================================================
  // HELPER: VERIFICACIÓN DE ESTADO
  // ============================================================

  /// Verificar si un usuario está aprobado (útil antes de permitir login)
  Future<bool> estaAprobado(String usuarioId) async {
    final response = await _supabase
        .from('usuarios')
        .select('activo')
        .eq('id', usuarioId)
        .maybeSingle();

    return response?['activo'] == true;
  }

  /// Obtener el jugador vinculado a un usuario
  Future<Map<String, dynamic>?> obtenerJugadorVinculado(
    String usuarioId,
  ) async {
    final response = await _supabase
        .from('jugadores')
        .select('id, nombre_completo, posicion')
        .eq('usuario_id', usuarioId)
        .maybeSingle();

    return response;
  }

  // ============================================================
  // GESTIÓN DE USUARIOS
  // ============================================================

  /// Crear usuario por coordinador usando Edge Function
  Future<void> crearUsuarioPorCoordinador({
    required String email,
    required String nombre,
    required String password,
    required String rolId,
  }) async {
    final response = await _supabase.functions.invoke(
      'create_user',
      body: {
        'email': email,
        'password': password,
        'nombre': nombre,
        'rolId': rolId,
      },
    );

    if (response.status != 200) {
      final errorData = response.data as Map<String, dynamic>;
      throw Exception(errorData['error'] ?? 'Error al crear usuario');
    }
  }
}
