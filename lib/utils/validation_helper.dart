/// Helper class to summarize common validation which are used
/// in several places
class ValidationHelper {
  static String portValidation(String text) {
    int port = int.tryParse(text);
    if (port != null && port > 0 && port <= 65535) {
      return null;
    }
    return 'Invalid port';
  }

  static String ipValidation(String text) {
    List<String> ip = text.split('.');
    if (ip.length == 4 &&
        ip.every((part) =>
            part.length > 0 &&
            part.length < 4 &&
            int.tryParse(part) != null &&
            int.parse(part) <= 255)) {
      return null;
    }
    return 'Not an IP address';
  }

  static String colorHexValidator(String text, {bool useAlpha = false}) {
    if (text.length == (useAlpha ? 8 : 6) &&
        (RegExp(r'^[a-fA-F0-9]+$').allMatches(text).isNotEmpty)) {
      return null;
    }
    return 'Not a valid color hex code';
  }

  static String colorRGBValidator(String text) {
    int val = int.tryParse(text);
    if (text.length <= 3 && val != null && val >= 0) {
      return null;
    }
    return 'Valid: 0 - 255';
  }
}
