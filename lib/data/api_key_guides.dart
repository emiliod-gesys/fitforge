import '../l10n/app_localizations.dart';

abstract final class ApiKeyGuides {
  static const openAiPortal = 'https://platform.openai.com/api-keys';
  static const geminiPortal = 'https://aistudio.google.com/apikey';

  static const openAiPdfAsset = 'assets/docs/openai_api_key_guide.pdf';
  static const geminiPdfAsset = 'assets/docs/gemini_api_key_guide.pdf';

  static List<String> openAiSteps(AppLocalizations l10n) => [
        l10n.openAiGuideStep1,
        l10n.openAiGuideStep2,
        l10n.openAiGuideStep3,
        l10n.openAiGuideStep4,
        l10n.openAiGuideStep5,
        l10n.openAiGuideStep6,
        l10n.openAiGuideStep7,
      ];

  static List<String> geminiSteps(AppLocalizations l10n) => [
        l10n.geminiGuideStep1,
        l10n.geminiGuideStep2,
        l10n.geminiGuideStep3,
        l10n.geminiGuideStep4,
        l10n.geminiGuideStep5,
        l10n.geminiGuideStep6,
        l10n.geminiGuideStep7,
      ];
}
