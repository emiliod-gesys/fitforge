import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Brief de producto FORGEN para el equipo de la página web.
///
/// Ejecutar:
///   dart run tool/generate_forgen_web_brief_pdf.dart
Future<void> main() async {
  final desktopCandidates = [
    '${Platform.environment['USERPROFILE']}\\OneDrive\\Escritorio',
    '${Platform.environment['USERPROFILE']}\\Desktop',
    '${Platform.environment['USERPROFILE']}\\OneDrive\\Desktop',
  ];

  Directory? outDir;
  for (final path in desktopCandidates) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      outDir = dir;
      break;
    }
  }
  outDir ??= Directory('docs');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outPath = '${outDir.path}${Platform.pathSeparator}FORGEN_brief_web.pdf';
  final pdf = pw.Document();

  final h1 = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
  final h2 = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  final body = const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.35);
  final muted = const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700);

  pw.Widget section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 14),
        pw.Text(title, style: h2),
        pw.SizedBox(height: 6),
        ...children,
      ],
    );
  }

  pw.Widget bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ', style: body),
            pw.Expanded(child: pw.Text(text, style: body)),
          ],
        ),
      );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      footer: (context) => pw.Text(
        'FORGEN — Brief web · p. ${context.pageNumber}/${context.pagesCount}',
        style: muted,
        textAlign: pw.TextAlign.right,
      ),
      build: (context) => [
        pw.Text('FORGEN', style: h1),
        pw.SizedBox(height: 4),
        pw.Text(
          'Brief de producto para diseño / desarrollo de la página web',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Documento interno · marca visible: FORGEN · identidad técnica App Store/Play '
          'conservada (Bundle ID io.fitforge.app / applicationId io.fitforge.fitforge) '
          'para no romper TestFlight.',
          style: muted,
        ),

        section('1. Qué es FORGEN', [
          pw.Text(
            'FORGEN es una app móvil de fitness (Android e iOS) construida con Flutter y '
            'Supabase. Combina entrenamiento de fuerza, cardio (carrera / HYROX / caminata), '
            'nutrición, hidratación, progreso gamificado, coach con IA y una capa social '
            'con amigos, feed y clasificaciones.',
            style: body,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Tagline de producto: «Forja tu mejor versión».',
            style: body,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Público: personas que entrenan en gimnasio o outdoors y quieren un solo lugar '
            'para planificar, registrar, medir progreso, comer con presupuesto calórico y '
            'motivarse con amigos / coach.',
            style: body,
          ),
        ]),

        section('2. Propuesta de valor (para copy de landing)', [
          bullet(
            'Entrena con rutinas propias, sugeridas o generadas por IA, y registra series '
            'con peso, reps, RIR y descanso.',
          ),
          bullet(
            'Ve recuperación muscular, records personales (1RM), volumen, hitos y nivel XP.',
          ),
          bullet(
            'Nutrición del día: presupuesto calórico, macros, agua, actividad quemada '
            '(entrenos + actividad manual).',
          ),
          bullet(
            'Coach IA con tu propia API key (OpenAI / Gemini / Claude) — la clave vive en el dispositivo.',
          ),
          bullet(
            'Social: amigos, feed 24 h, PRs compartidos, leaderboards amigos/global.',
          ),
          bullet(
            'Modo entrenador: alumnos, recuperación, nutrición y rutinas de estudiantes.',
          ),
        ]),

        section('3. Navegación principal (pestañas)', [
          bullet('Entrenar — hub de sesión del día + rutinas (sugerencia, recientes, mapa muscular).'),
          bullet('Coach IA — chat de coach, límites diarios, generación de rutinas/programas.'),
          bullet('Comida — presupuesto del día, comidas, agua, energía gastada.'),
          bullet('Progreso — nivel, stats, volumen semanal, métricas corporales, hitos, PRs.'),
          bullet('Social — Feed / Amigos / Clasificaciones.'),
          bullet('Estudiantes — solo si el usuario es entrenador.'),
          bullet('Perfil — datos, métricas, metas, nutrición, apariencia, API keys, cuenta.'),
        ]),

        section('4. Entrenamiento (detalle)', [
          bullet(
            'Rutinas: crear/editar, favoritos, límite según plan (Gymrat / Gymrat Pro).',
          ),
          bullet(
            'Sesión activa: lista de ejercicios, series, swap por similares, repetición '
            'desde historial, validación anti-trampas para leaderboards.',
          ),
          bullet(
            'Biblioteca grande de ejercicios (catálogo propio + extendido), imágenes, demos.',
          ),
          bullet(
            'Cardio runner: cinta / outdoor / caminata con GPS, splits, pace; integración Health.',
          ),
          bullet('HYROX: estaciones y tiempos de carrera.'),
          bullet(
            'Recuperación muscular estimada (~48 h) con mapa corporal compacto y detalle.',
          ),
          bullet(
            'Post-entreno: resumen, calorías estimadas, XP, PRs nuevos, compartir tarjeta.',
          ),
          bullet('Companion Wear OS / Apple Watch (acciones y sesión en muñeca).'),
        ]),

        section('5. Nutrición e hidratación', [
          bullet(
            'Presupuesto calórico diario basado en métricas + ajuste (déficit / superávit / mantenimiento).',
          ),
          bullet('Registro de comidas (búsqueda, catálogo regional, escaneo / quick add).'),
          bullet('Macros visibles (proteína, carbs, grasa, etc.).'),
          bullet(
            'Agua: vasos 250 ml o cantidad libre, meta automática o override en perfil (L/oz).',
          ),
          bullet(
            'Energía gastada: entrenos FORGEN + actividades manuales (nombre + kcal).',
          ),
          bullet(
            'El presupuesto de comida usa datos de FORGEN; Health puede importar peso/grasa '
            'y exportar entrenos, sin mezclar ciegamente el presupuesto.',
          ),
        ]),

        section('6. Progreso y gamificación', [
          bullet('Nivel de jugador con XP y badges por rango.'),
          bullet('Records personales por ejercicio (fuerza y cardio).'),
          bullet('Hitos acumulados (reps, volumen, distancia, calorías, entrenos) con tiers.'),
          bullet('Stats mensuales: entrenos, volumen, PRs, racha semanal.'),
          bullet('Gráfico de volumen semanal y snapshot de métricas corporales.'),
        ]),

        section('7. Social y coach', [
          bullet('Amigos por búsqueda (email/nombre), solicitudes, perfil de amigo, PRs.'),
          bullet('Feed efímero (~24 h): posts, reacciones, comentarios, adjuntar PR.'),
          bullet('Leaderboards: amigos/global, métricas (nivel, volumen, etc.), periodos.'),
          bullet('Push notifications (FCM) cuando hay actividad social relevante.'),
          bullet(
            'Coach IA: consejos, rutinas JSON guardables, nutrición; límites diarios salvo plan ilimitado.',
          ),
        ]),

        section('8. Cuenta, planes e i18n', [
          bullet('Auth: email/contraseña (+ Turnstile), Google Sign-In, reset password.'),
          bullet('Planes: Free / Gymrat / Gymrat Pro (ver sección 8b).'),
          bullet('Idiomas: español e inglés.'),
          bullet('Unidades: kg/lb y L/oz según preferencia.'),
          bullet('Acentos de color configurables (cobalto por defecto; personalización en planes de pago).'),
          bullet('Offline parcial: historial/entrenos con sincronización al volver online.'),
        ]),

        section('8b. Detalle de planes (fuente de verdad del producto)', [
          pw.Text(
            'Todo lo no listado como exclusividad de un plan está disponible en Free '
            '(entrenar, rutinas básicas, comida por búsqueda/quick/manual, agua, progreso, social, etc.).',
            style: body,
          ),
          pw.SizedBox(height: 8),
          pw.Text('Free', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          bullet('Hasta 10 rutinas guardadas.'),
          bullet('Coach IA: 5 mensajes/día (con IA del plan).'),
          bullet('Sin IA proactiva al entrenar (salvo que el usuario ponga su propia API key / BYOK).'),
          bullet('Sin color de acento personalizable.'),
          bullet('Sin código de barras para comida.'),
          bullet('Sin foto de comida con IA (salvo Free + BYOK).'),
          bullet('Sin modo entrenador / pestaña Alumnos.'),
          bullet(
            'Excepción BYOK: si Free guarda su propia API key (OpenAI/Gemini/Claude), '
            'desbloquea IA proactiva, foto de comida con visión y Coach sin tope diario del plan; '
            'el código de barras sigue bloqueado (solo Gymrat+).',
          ),
          pw.SizedBox(height: 6),
          pw.Text('Gymrat', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          bullet('Hasta 20 rutinas guardadas.'),
          bullet('Coach IA: 30 mensajes/día.'),
          bullet('IA proactiva durante el entreno.'),
          bullet('Color de acento personalizable.'),
          bullet('Registro de comida por código de barras (Open Food Facts).'),
          bullet('Sin foto de comida con IA (eso es Gymrat Pro).'),
          bullet('Sin modo entrenador.'),
          pw.SizedBox(height: 6),
          pw.Text('Gymrat Pro', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          bullet('Hasta 50 rutinas guardadas.'),
          bullet('Coach IA ilimitado (sin tope diario del plan).'),
          bullet('IA proactiva + color de acento.'),
          bullet('Código de barras para comida.'),
          bullet('Foto de comida con IA (visión).'),
          bullet('Modo entrenador personal (alumnos, recuperación/nutrición/rutinas de estudiantes).'),
        ]),

        section('9. Stack técnico (contexto para la web)', [
          bullet('Cliente: Flutter (Android / iOS; web solo para desarrollo).'),
          bullet('Backend: Supabase (Postgres + Auth + Edge Functions + Storage).'),
          bullet('Push: Firebase Cloud Messaging.'),
          bullet('IA: claves del usuario → OpenAI / Gemini / Claude (no se guardan en servidor FORGEN).'),
          bullet(
            'Marca en UI/store listing: FORGEN. IDs técnicos legacy fitforge conservados '
            'para continuidad de TestFlight / Play updates.',
          ),
        ]),

        section('10. Identidad visual actual (para alinear la web)', [
          bullet('Nombre: FORGEN (mayúsculas en lockup).'),
          bullet('Fondo de producto: negro / carbón.'),
          bullet('Azul de marca del logo ≈ #305890 (forgenBlue).'),
          bullet('UI: dark theme, cards redondeadas, acento cobalto configurable.'),
          bullet(
            'Assets: isotipo geométrico (F dentro de curva tipo D/G) + lockup isotipo+FORGEN; '
            'icono de launcher negro con isotipo azul.',
          ),
          bullet('Evitar look genérico “IA purple gradient”; la app es dark athletic/tech.'),
        ]),

        section('11. Mensajes que la web debería transmitir', [
          bullet('No es solo un contador de series: es entrenamiento + comida + progreso + social + IA.'),
          bullet('Tú controlas tu IA (bring your own key) — privacidad de claves en dispositivo.'),
          bullet('Motivación social real (amigos, feed, rankings), no solo tracking solitario.'),
          bullet('Sirve para gym, carrera y HYROX en un mismo producto.'),
          bullet('Disponible como app móvil; la web de marketing debe apuntar a descarga / TestFlight / stores.'),
        ]),

        section('12. Qué NO confundir', [
          bullet(
            'El repo/código interno aún puede decir “fitforge” (clases, package). Eso no es la marca de usuario.',
          ),
          bullet(
            'No inventar features de escritorio web app: el producto es móvil; la página es marketing/landing.',
          ),
          bullet(
            'No prometer “IA ilimitada gratis”: Free tiene 5 msgs/día; Gymrat 30; Pro ilimitado '
            '(salvo Free con BYOK, que trata mensajes de otra forma).',
          ),
          bullet(
            'Código de barras de comida: solo Gymrat y Gymrat Pro (no Free).',
          ),
          bullet(
            'Foto de comida con IA: Gymrat Pro (o Free con API key propia).',
          ),
        ]),

        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'Resumen de una línea: FORGEN es la app que forja tu mejor versión — '
            'entrenas, comes, mides y te impulsas con IA y comunidad, en un solo lugar.',
            style: body,
          ),
        ),
      ],
    ),
  );

  final file = File(outPath);
  await file.writeAsBytes(await pdf.save());
  stdout.writeln('PDF generado: ${file.absolute.path}');
}
