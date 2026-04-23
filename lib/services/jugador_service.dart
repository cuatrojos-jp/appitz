import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jugador_model.dart';

// Encargado de toda la comunicación con Supabase para jugadores
class JugadorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Crear un nuevo jugador
  Future<JugadorModel> crearJugador(JugadorModel jugador) async {
    final response = await _supabase
        .from('jugadores')
        .insert(jugador.toJson())
        .select() // Devuelve el registro creado
        .single();

    return JugadorModel.fromJson(response);
  }

  // Obtener todos los jugadores
  Future<List<JugadorModel>> obtenerJugadores() async {
    final response = await _supabase
        .from('jugadores')
        .select('*')
        .order('nombre_completo');

    return response
        .map<JugadorModel>((json) => JugadorModel.fromJson(json))
        .toList();
  }

  // Actualizar un jugador existente
  Future<JugadorModel> actualizarJugador(JugadorModel jugador) async {
    final response = await _supabase
        .from('jugadores')
        .update(jugador.toJson())
        .eq('id', jugador.id!)
        .select()
        .single();

    return JugadorModel.fromJson(response);
  }

  // Eliminar un jugador
  Future<void> eliminarJugador(String id) async {
    await _supabase.from('jugadores').delete().eq('id', id);
  }
}
