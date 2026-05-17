/// Base exception for all flutter_smart_links errors.
class SmartLinksException implements Exception {
  final String message;
  final Object? cause;

  const SmartLinksException(this.message, {this.cause});

  @override
  String toString() => cause != null
      ? 'SmartLinksException: $message (caused by: $cause)'
      : 'SmartLinksException: $message';
}

/// Thrown when [SmartLinks.initialize] is called more than once.
class AlreadyInitializedException extends SmartLinksException {
  const AlreadyInitializedException()
      : super('SmartLinks has already been initialized.');
}

/// Thrown when a SmartLinks method is called before [SmartLinks.initialize].
class NotInitializedException extends SmartLinksException {
  const NotInitializedException()
      : super(
            'SmartLinks has not been initialized. Call SmartLinks().initialize() first.');
}

/// Thrown when a link URL cannot be parsed.
class InvalidLinkException extends SmartLinksException {
  final String url;
  const InvalidLinkException(this.url)
      : super('Could not parse link URL: $url');
}

/// Thrown when the platform channel returns an unexpected error.
class PlatformChannelException extends SmartLinksException {
  const PlatformChannelException(super.message, {super.cause});
}
