import '../api/api_config.dart';

class UrlUtils {
  static String fixLocalhost(String? url) {
    if (url == null || url.isEmpty) return '';
    
    String fixedUrl = url;
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final host = baseUri.host;
    final origin = baseUri.origin;

    // 1. Si c'est un chemin relatif commençant par /uploads
    if (fixedUrl.startsWith('/uploads')) {
      return '$origin$fixedUrl';
    }

    // 2. Remplacer localhost/127.0.0.1 par le bon hôte
    fixedUrl = fixedUrl
        .replaceAll('localhost', host)
        .replaceAll('127.0.0.1', host)
        .replaceAll('::1', host);

    // 3. S'assurer qu'il y a un schéma (http://)
    if (!fixedUrl.startsWith('http://') && !fixedUrl.startsWith('https://')) {
      // Si ça ressemble à un hôte (ex: 192.168...:3003/uploads)
      fixedUrl = 'http://$fixedUrl';
    }

    // 4. Nettoyer les ports doubles accidentels (ex: :3003:3003)
    final port = baseUri.port.toString();
    if (port.isNotEmpty && fixedUrl.contains(':$port:$port')) {
      fixedUrl = fixedUrl.replaceAll(':$port:$port', ':$port');
    }

    return fixedUrl;
  }
}
