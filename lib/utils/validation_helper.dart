/// helper class to summarize common validation which are used
/// in several places
class ValidationHelper {
  static String portValidation(text) {
    int port = int.tryParse(text);
    if (port != null && port > 0 && port <= 65535) {
      return null;
    }
    return 'Invalid port';
  }

  static String ipValidation(text) {
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
}
