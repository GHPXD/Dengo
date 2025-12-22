/// Helpers para manipulação de tempo e datas.
///
/// Métodos utilitários relacionados a hora do dia, períodos, etc.
class TimeHelpers {
  TimeHelpers._(); // Construtor privado

  // ══════════════════════════════════════════════════════════════════════════
  // CONSTANTES DE HORÁRIOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Hora limite para "Bom dia" (antes das 12h)
  static const int morningHourLimit = 12;

  /// Hora limite para "Boa tarde" (antes das 18h)
  static const int afternoonHourLimit = 18;

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Retorna saudação contextual baseada na hora atual.
  ///
  /// - **00:00 - 11:59**: "Bom dia"
  /// - **12:00 - 17:59**: "Boa tarde"
  /// - **18:00 - 23:59**: "Boa noite"
  ///
  /// **Uso**:
  /// ```dart
  /// Text(TimeHelpers.getGreeting()) // "Boa tarde"
  /// ```
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < morningHourLimit) {
      return 'Bom dia';
    } else if (hour < afternoonHourLimit) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  /// Retorna ícone correspondente ao período do dia.
  static String getGreetingIcon() {
    final hour = DateTime.now().hour;

    if (hour < morningHourLimit) {
      return '☀️'; // Manhã
    } else if (hour < afternoonHourLimit) {
      return '🌤️'; // Tarde
    } else {
      return '🌙'; // Noite
    }
  }

  /// Verifica se é período comercial (9h-18h, seg-sex).
  static bool isBusinessHours() {
    final now = DateTime.now();
    final isWeekday =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    final isBusinessTime = now.hour >= 9 && now.hour < 18;

    return isWeekday && isBusinessTime;
  }

  /// Verifica se é fim de semana (sábado ou domingo).
  static bool isWeekend() {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }
}
