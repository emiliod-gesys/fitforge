import 'package:fitforge/services/ai_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el asistente de voz empieza apagado y se puede encender', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AiPreferences.isVoiceAssistantEnabled(), isFalse);

    await AiPreferences.setVoiceAssistantEnabled(false);
    expect(await AiPreferences.isVoiceAssistantEnabled(), isFalse);

    await AiPreferences.setVoiceAssistantEnabled(true);
    expect(await AiPreferences.isVoiceAssistantEnabled(), isTrue);
  });
}
