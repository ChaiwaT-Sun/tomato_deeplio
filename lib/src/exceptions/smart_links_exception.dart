/// Base exception for all tomato_deeplio errors.
class TomatoDeeplioException implements Exception {
  final String message;
  final Object? cause;

  const TomatoDeeplioException(this.message, {this.cause});

  @override
  String toString() => cause != null
      ? 'TomatoDeeplioException: $message (caused by: $cause)'
      : 'TomatoDeeplioException: $message';
}

/// Thrown when [TomatoDeeplio.initialize] is called more than once.
class AlreadyInitializedException extends TomatoDeeplioException {
  const AlreadyInitializedException()
      : super('TomatoDeeplio has already been initialized.');
}

/// Thrown when a TomatoDeeplio method is called before [TomatoDeeplio.initialize].
class NotInitializedException extends TomatoDeeplioException {
  const NotInitializedException()
      : super(
            'TomatoDeeplio has not been initialized. Call TomatoDeeplio().initialize() first.');
}

/// Thrown when a link URL cannot be parsed.
class InvalidLinkException extends TomatoDeeplioException {
  final String url;
  const InvalidLinkException(this.url)
      : super('Could not parse link URL: $url');
}

/// Thrown when the platform channel returns an unexpected error.
class PlatformChannelException extends TomatoDeeplioException {
  const PlatformChannelException(super.message, {super.cause});
}
