enum RestTimerAlertMode {
  sound,
  vibration,
  both;

  static RestTimerAlertMode fromCode(String? value) {
    return switch (value) {
      'sound' => RestTimerAlertMode.sound,
      'vibration' => RestTimerAlertMode.vibration,
      'both' => RestTimerAlertMode.both,
      _ => RestTimerAlertMode.both,
    };
  }

  String get storageCode => name;
}
