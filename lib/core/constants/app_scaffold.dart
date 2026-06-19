import 'package:flutter/material.dart';

/// Messenger raíz de la app (evita SnackBars atrapados en Scaffolds anidados).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
