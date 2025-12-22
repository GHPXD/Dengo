import 'package:intl/intl.dart';

/// Extensões úteis para a classe DateTime.
///
/// Facilitam formatação de datas em português brasileiro
/// e operações comuns de data/hora no contexto da aplicação.
extension DateTimeExtensions on DateTime {
  /// Formata data no formato brasileiro: DD/MM/YYYY
  ///
  /// Exemplo: 08/12/2025
  String toFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Formata data com mês abreviado: DD MMM YYYY
  ///
  /// Exemplo: 08 Dez 2025
  String toFormattedDateWithMonth() {
    return DateFormat('dd MMM yyyy', 'pt_BR').format(this);
  }

  /// Formata data completa: Dia da semana, DD de Mês de YYYY
  ///
  /// Exemplo: Domingo, 08 de Dezembro de 2025
  String toFormattedDateFull() {
    return DateFormat("EEEE, dd 'de' MMMM 'de' yyyy", 'pt_BR').format(this);
  }

  /// Formata apenas a hora: HH:MM
  ///
  /// Exemplo: 14:30
  String toFormattedTime() {
    return DateFormat('HH:mm').format(this);
  }

  /// Formata data e hora: DD/MM/YYYY às HH:MM
  ///
  /// Exemplo: 08/12/2025 às 14:30
  String toFormattedDateTime() {
    return DateFormat("dd/MM/yyyy 'às' HH:mm").format(this);
  }

  /// Retorna a diferença em dias a partir de hoje.
  ///
  /// Útil para calcular "há X dias" em feeds e históricos.
  int get daysFromNow {
    final now = DateTime.now();
    final difference = now.difference(this);
    return difference.inDays;
  }

  /// Verifica se a data é hoje.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Verifica se a data é amanhã.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Retorna representação relativa: "Hoje", "Amanhã", "Há X dias"
  ///
  /// Útil para exibir timestamps de forma amigável.
  String toRelativeString() {
    if (isToday) return 'Hoje';
    if (isTomorrow) return 'Amanhã';

    final days = daysFromNow;
    if (days == 1) return 'Há 1 dia';
    if (days > 1 && days <= 7) return 'Há $days dias';
    if (days > 7 && days <= 30) {
      final weeks = (days / 7).floor();
      return weeks == 1 ? 'Há 1 semana' : 'Há $weeks semanas';
    }

    return toFormattedDate();
  }
}
