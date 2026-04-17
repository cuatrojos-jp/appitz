import 'package:flutter/material.dart';
import '../models/Usuario.dart';

Color avatarBgForRol(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.admin:
      return const Color(0xFFFFEBEE);
    case RolUsuario.coordinador:
      return const Color(0xFFE3F2FD);
    case RolUsuario.jugador:
      return const Color(0xFFE8F5E9);
  }
}

Color avatarFgForRol(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.admin:
      return const Color(0xFFC62828);
    case RolUsuario.coordinador:
      return const Color(0xFF1565C0);
    case RolUsuario.jugador:
      return const Color(0xFF2E7D32);
  }
}