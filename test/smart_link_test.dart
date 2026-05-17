import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_links/flutter_smart_links.dart';
import 'package:flutter_smart_links/src/services/link_generator.dart';
import 'package:flutter_smart_links/src/services/link_parser.dart';

void main() {
  group('SmartLink.fromUri', () {
    test('parses path and query params', () {
      final uri = Uri.parse('https://links.example.com/product/123?ref=USER001');
      final link = SmartLink.fromUri(uri);

      expect(link.path, '/product/123');
      expect(link.queryParams['ref'], 'USER001');
      expect(link.pathSegments, ['product', '123']);
      expect(link.isDeferred, false);
    });

    test('extracts UTM params', () {
      final uri = Uri.parse(
          'https://links.example.com/promo/SALE?utm_source=email&utm_campaign=summer&utm_medium=cpc');
      final link = SmartLink.fromUri(uri);

      expect(link.source, 'email');
      expect(link.campaign, 'summer');
      expect(link.medium, 'cpc');
    });

    test('marks deferred correctly', () {
      final uri = Uri.parse('myapp://product/123');
      final link = SmartLink.fromUri(uri, isDeferred: true);
      expect(link.isDeferred, true);

      final deferred = link.asDeferred();
      expect(deferred.isDeferred, true);
    });

    test('handles root path', () {
      final uri = Uri.parse('https://links.example.com/');
      final link = SmartLink.fromUri(uri);
      expect(link.path, '/');
      expect(link.pathSegments, isEmpty);
    });
  });

  group('RouteDefinition.match', () {
    test('matches simple static path', () {
      const route = const RouteDefinition(name: 'home', pattern: '/home');
      final match = route.match('/home', {});
      expect(match, isNotNull);
      expect(match!.routeName, 'home');
    });

    test('extracts single path param', () {
      const route = const RouteDefinition(name: 'product', pattern: '/product/:id');
      final match = route.match('/product/42', {'ref': 'abc'});
      expect(match, isNotNull);
      expect(match!.pathParams['id'], '42');
      expect(match.queryParams['ref'], 'abc');
    });

    test('extracts multiple path params', () {
      const route = const RouteDefinition(
          name: 'item', pattern: '/category/:slug/item/:id');
      final match = route.match('/category/electronics/item/99', {});
      expect(match!.pathParams['slug'], 'electronics');
      expect(match.pathParams['id'], '99');
    });

    test('returns null for mismatched path', () {
      const route = const RouteDefinition(name: 'product', pattern: '/product/:id');
      expect(route.match('/category/123', {}), isNull);
    });

    test('returns null for different segment count', () {
      const route = const RouteDefinition(name: 'product', pattern: '/product/:id');
      expect(route.match('/product/123/details', {}), isNull);
    });

    test('allParams merges path and query params', () {
      const route = const RouteDefinition(name: 'product', pattern: '/product/:id');
      final match = route.match('/product/7', {'color': 'red'});
      expect(match!.allParams, {'id': '7', 'color': 'red'});
    });
  });

  group('SmartLinkRouter', () {
    late SmartLinkRouter router;

    setUp(() {
      router = SmartLinkRouter();
      router.addRoutes([
        const RouteDefinition(name: 'product', pattern: '/product/:id'),
        const RouteDefinition(name: 'category', pattern: '/category/:slug'),
        const RouteDefinition(name: 'home', pattern: '/home'),
      ]);
    });

    test('matches first applicable route', () {
      final link = SmartLink.fromUri(
          Uri.parse('https://links.example.com/product/55'));
      final match = router.match(link);
      expect(match?.routeName, 'product');
      expect(match?.pathParams['id'], '55');
    });

    test('returns null when no route matches', () {
      final link = SmartLink.fromUri(
          Uri.parse('https://links.example.com/unknown/path'));
      expect(router.match(link), isNull);
    });

    test('removeRoute removes by name', () {
      router.removeRoute('home');
      expect(router.routes.any((r) => r.name == 'home'), false);
    });

    test('clear removes all routes', () {
      router.clear();
      expect(router.routes, isEmpty);
    });
  });

  group('LinkGenerator', () {
    late LinkGenerator generator;

    setUp(() {
      generator = LinkGenerator(const SmartLinksConfig(
        domain: 'links.example.com',
        uriScheme: 'myapp',
        defaultUtmSource: 'app',
      ));
    });

    test('creates HTTPS link with params', () {
      final url = generator.createLink(
        path: '/product/123',
        params: {'ref': 'USER001'},
      );
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'links.example.com');
      expect(uri.path, '/product/123');
      expect(uri.queryParameters['ref'], 'USER001');
      expect(uri.queryParameters['utm_source'], 'app');
    });

    test('creates deep link with custom scheme', () {
      final url = generator.createDeepLink(
        path: '/product/123',
        params: {'ref': 'X'},
      );
      expect(url, startsWith('myapp://'));
      expect(url, contains('product/123'));
    });

    test('creates QR link with utm_medium=qr_code', () {
      final url = generator.createQrLink(path: '/promo/SALE');
      final uri = Uri.parse(url);
      expect(uri.queryParameters['utm_medium'], 'qr_code');
      expect(uri.queryParameters['utm_source'], 'qr');
    });

    test('normalises path without leading slash', () {
      final url = generator.createLink(path: 'product/123');
      expect(Uri.parse(url).path, '/product/123');
    });
  });

  group('LinkParser', () {
    late LinkParser parser;

    setUp(() {
      parser = LinkParser(const SmartLinksConfig(
        domain: 'links.example.com',
        uriScheme: 'myapp',
      ));
    });

    test('parses HTTPS link', () {
      final link = parser.parse('https://links.example.com/product/1');
      expect(link.path, '/product/1');
    });

    test('parses custom scheme link', () {
      final link = parser.parse('myapp://product/1');
      expect(link.path, '/product/1');
    });

    test('throws InvalidLinkException for garbage input', () {
      expect(() => parser.parse('not a url at all !!!'), throwsA(isA<InvalidLinkException>()));
    });

    test('isValidLink returns true for known domain', () {
      expect(
          parser.isValidLink('https://links.example.com/product/1'), isTrue);
    });

    test('isValidLink returns true for custom scheme', () {
      expect(parser.isValidLink('myapp://product/1'), isTrue);
    });

    test('isValidLink returns false for unknown domain', () {
      expect(parser.isValidLink('https://evil.com/product/1'), isFalse);
    });
  });

  group('DeferredLinkData', () {
    test('serialises and deserialises correctly', () {
      final now = DateTime.now();
      final data = DeferredLinkData(
        url: 'https://links.example.com/product/1',
        capturedAt: now,
        installToken: 'tok_abc123',
        referrer: 'https://google.com',
      );

      final json = data.toJson();
      final restored = DeferredLinkData.fromJson(json);

      expect(restored.url, data.url);
      expect(restored.installToken, data.installToken);
      expect(restored.referrer, data.referrer);
      expect(restored.consumed, false);
    });

    test('markConsumed sets consumed to true', () {
      final data = DeferredLinkData(
        url: 'https://links.example.com/x',
        capturedAt: DateTime.now(),
      );
      final consumed = data.markConsumed();
      expect(consumed.consumed, true);
      expect(consumed.url, data.url);
    });
  });

  group('SmartLinksConfig.validate', () {
    test('throws on empty domain', () {
      expect(
        () => const SmartLinksConfig(domain: '', uriScheme: 'myapp').validate(),
        throwsArgumentError,
      );
    });

    test('throws on empty uriScheme', () {
      expect(
        () => const SmartLinksConfig(domain: 'links.example.com', uriScheme: '')
            .validate(),
        throwsArgumentError,
      );
    });

    test('throws when uriScheme contains ://', () {
      expect(
        () => const SmartLinksConfig(
                domain: 'links.example.com', uriScheme: 'myapp://')
            .validate(),
        throwsArgumentError,
      );
    });

    test('passes valid config', () {
      expect(
        () => const SmartLinksConfig(
                domain: 'links.example.com', uriScheme: 'myapp')
            .validate(),
        returnsNormally,
      );
    });
  });
}
