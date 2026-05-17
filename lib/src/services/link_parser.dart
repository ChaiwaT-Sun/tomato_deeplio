import 'package:tomato_deeplio/src/exceptions/smart_links_exception.dart';
import 'package:tomato_deeplio/src/models/smart_link.dart';
import 'package:tomato_deeplio/src/smart_links_config.dart';

/// Parses raw URL strings into [SmartLink] objects.
class LinkParser {
  final TomatoDeeplioConfig config;

  const LinkParser(this.config);

  /// Parses [rawUrl] into a [SmartLink].
  ///
  /// Accepts:
  /// - HTTPS links on the configured domain
  /// - Custom URI scheme links (`myapp://...`)
  ///
  /// Throws [InvalidLinkException] if the URL cannot be parsed.
  SmartLink parse(String rawUrl, {bool isDeferred = false}) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) throw InvalidLinkException(rawUrl);

    if (uri.scheme == config.uriScheme) {
      // Custom scheme: myapp://product/1
      // Uri.parse treats "product" as the host and "/1" as the path.
      // Reconstruct a normalised path: /<host><path>
      final reconstructedPath = uri.host.isNotEmpty
          ? '/${uri.host}${uri.path}'
          : uri.path.isEmpty
              ? '/'
              : uri.path;

      final normalisedUri = uri.replace(
        host: '',
        path: reconstructedPath,
      );
      return SmartLink.fromUri(normalisedUri, isDeferred: isDeferred);
    }

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return SmartLink.fromUri(uri, isDeferred: isDeferred);
    }

    throw InvalidLinkException(rawUrl);
  }

  /// Returns true if [url] looks like a valid smart link for this config.
  bool isValidLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme == config.uriScheme) return true;
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == config.domain) return true;
    return false;
  }
}
