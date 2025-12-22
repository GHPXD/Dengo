/// Extensões úteis para a classe String.
///
/// Facilitam validações, formatações e transformações comuns
/// de strings na aplicação.
extension StringExtensions on String {
  /// Verifica se a string não é nula e não está vazia.
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Verifica se a string está vazia ou contém apenas espaços.
  bool get isBlank => trim().isEmpty;

  /// Capitaliza a primeira letra da string.
  ///
  /// Exemplo: "dengue" -> "Dengue"
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitaliza a primeira letra de cada palavra.
  ///
  /// Exemplo: "são paulo" -> "São Paulo"
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize())
        .join(' ');
  }

  /// Remove todos os espaços em branco.
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Verifica se a string é um email válido.
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Verifica se a string contém apenas números.
  bool get isNumeric {
    return RegExp(r'^\d+$').hasMatch(this);
  }

  /// Trunca a string com reticências se exceder o limite.
  ///
  /// Exemplo: "Texto muito longo".truncate(10) -> "Texto muit..."
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// Remove acentos da string.
  ///
  /// Útil para buscas e comparações case-insensitive.
  /// Exemplo: "São Paulo" -> "Sao Paulo"
  String removeAccents() {
    const withAccents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutAccents =
        'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

    String result = this;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Formata string como CPF (XXX.XXX.XXX-XX).
  /// Assume que a string contém apenas números.
  String formatAsCPF() {
    if (length != 11) return this;
    return '${substring(0, 3)}.${substring(3, 6)}.${substring(6, 9)}-${substring(9, 11)}';
  }

  /// Formata string como telefone brasileiro.
  /// (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
  String formatAsPhone() {
    final digits = removeWhitespace();
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return this;
  }
}

/// Extensões para String nullable.
extension NullableStringExtensions on String? {
  /// Verifica se a string é nula ou vazia.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Retorna a string ou um valor padrão se for nula/vazia.
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}
