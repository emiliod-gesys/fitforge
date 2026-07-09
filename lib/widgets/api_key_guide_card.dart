import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../core/theme/app_accent.dart';

class ApiKeyGuideCard extends StatelessWidget {
  final String title;
  final String portalLabel;
  final Uri portalUrl;
  final List<String> steps;
  final String? pdfAssetPath;
  final String? pdfFileName;
  final AppLocalizations l10n;

  const ApiKeyGuideCard({
    super.key,
    required this.title,
    required this.portalLabel,
    required this.portalUrl,
    required this.steps,
    this.pdfAssetPath,
    this.pdfFileName,
    required this.l10n,
  });

  Future<void> _openPortal() async {
    await launchUrl(portalUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _sharePdf() async {
    final asset = pdfAssetPath;
    final fileName = pdfFileName;
    if (asset == null || fileName == null) return;
    final data = await rootBundle.load(asset);
    await Share.shareXFiles(
      [
        XFile.fromData(
          data.buffer.asUint8List(),
          mimeType: 'application/pdf',
          name: fileName,
        ),
      ],
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: AppColors.border),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.picture_as_pdf_outlined, color: context.accentColor),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            portalLabel,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          children: [
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _openPortal,
                  icon: Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.apiGuideOpenPortal),
                ),
                if (pdfAssetPath != null && pdfFileName != null)
                  FilledButton.icon(
                    onPressed: _sharePdf,
                    style: FilledButton.styleFrom(backgroundColor: context.accentColor),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(l10n.apiGuideOpenPdf),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
