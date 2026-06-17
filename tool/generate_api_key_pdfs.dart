import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final outDir = Directory('assets/docs');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  await _writePdf(
    path: '${outDir.path}/openai_api_key_guide.pdf',
    title: 'FitForge — Obtener API Key de OpenAI',
    portal: 'https://platform.openai.com/api-keys',
    steps: const [
      'Abre platform.openai.com en tu navegador y crea una cuenta o inicia sesión.',
      'Verifica tu correo si es la primera vez. OpenAI puede pedir un número de teléfono.',
      'Entra a API keys: platform.openai.com/api-keys (menú lateral → API keys).',
      'Pulsa «Create new secret key» y ponle un nombre, por ejemplo «FitForge».',
      'Copia la clave en cuanto aparezca. Solo se muestra una vez.',
      'OpenAI puede pedir agregar un método de pago en Billing (pago por uso).',
      'Vuelve a FitForge, pega la clave, elige OpenAI y pulsa «Guardar API Key».',
    ],
    notes: const [
      'La clave se guarda solo en tu dispositivo (almacenamiento seguro).',
      'FitForge no almacena tu API key en servidores propios.',
      'Las llamadas a la IA van directamente a OpenAI.',
    ],
  );

  await _writePdf(
    path: '${outDir.path}/gemini_api_key_guide.pdf',
    title: 'FitForge — Obtener API Key de Gemini (Google)',
    portal: 'https://aistudio.google.com/apikey',
    steps: const [
      'Abre aistudio.google.com e inicia sesión con tu cuenta de Google.',
      'Acepta los términos de Google AI Studio si es tu primera vez.',
      'Ve a API keys: aistudio.google.com/apikey (menú «Get API key»).',
      'Pulsa «Create API key». Crea un proyecto nuevo o usa uno existente.',
      'Copia la API key generada y guárdala en un lugar seguro.',
      'Google ofrece un nivel gratuito con límites de uso.',
      'Vuelve a FitForge, pega la clave, elige Gemini y pulsa «Guardar API Key».',
    ],
    notes: const [
      'La clave se guarda solo en tu dispositivo (almacenamiento seguro).',
      'FitForge no almacena tu API key en servidores propios.',
      'Las llamadas a la IA van directamente a Google.',
    ],
  );

  stdout.writeln('PDF guides generated in assets/docs/');
}

Future<void> _writePdf({
  required String path,
  required String title,
  required String portal,
  required List<String> steps,
  required List<String> notes,
}) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(40)),
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Enlace oficial: $portal',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.blue700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Pasos',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...steps.asMap().entries.map(
              (e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        '${e.key + 1}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Notas importantes',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...notes.map((n) => pw.Bullet(text: n, style: const pw.TextStyle(fontSize: 10))),
        pw.SizedBox(height: 24),
        pw.Text(
          'FitForge — Guía generada para usuarios',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  final file = File(path);
  await file.writeAsBytes(await pdf.save());
}
