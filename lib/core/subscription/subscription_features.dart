import '../../models/profile.dart';

/// Capacidades por plan de suscripción.
extension SubscriptionFeatures on SubscriptionTier {
  /// IA proactiva al iniciar entrenamientos.
  bool get hasProactiveAi => !isFree;

  /// Foto de comida con IA (visión).
  bool get hasFoodPhotoAi => this == SubscriptionTier.gymratPro;

  /// Color de acento personalizable.
  bool get hasCustomAccent => !isFree;

  /// Modo entrenador personal (pestaña Alumnos).
  bool get hasTrainerMode => this == SubscriptionTier.gymratPro;

  /// Mensajes diarios del Coach IA con la IA incluida en el plan.
  /// `null` = ilimitado. Free con API propia también se trata como ilimitado.
  int? get coachDailyMessageLimit => switch (this) {
        SubscriptionTier.free => 5,
        SubscriptionTier.gymrat => 30,
        SubscriptionTier.gymratPro => null,
      };

  /// Rutinas guardadas en la biblioteca del usuario.
  int get maxSavedRoutines => switch (this) {
        SubscriptionTier.free => 10,
        SubscriptionTier.gymrat => 20,
        SubscriptionTier.gymratPro => 50,
      };
}
