import 'package:flutter/material.dart';
import 'package:flutter_smart_links/flutter_smart_links.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Initialise SmartLinks ─────────────────────────────────────────────
  final smartLinks = SmartLinks();

  await smartLinks.initialize(
    config: SmartLinksConfig(
      domain: 'links.example.com',
      uriScheme: 'myapp',
      androidPackageName: 'com.example.myapp',
      iosBundleId: 'com.example.myapp',
      iosAppStoreId: '123456789',
      fallbackUrl: 'https://example.com',
      enableDeferredLinks: true,
      debugMode: true,
    ),
    routes: [
      RouteDefinition(
        name: 'product',
        pattern: '/product/:id',
        handler: (match) {
          debugPrint('→ Product: ${match.pathParams['id']}');
        },
      ),
      RouteDefinition(
        name: 'category',
        pattern: '/category/:slug',
        handler: (match) {
          debugPrint('→ Category: ${match.pathParams['slug']}');
        },
      ),
      RouteDefinition(
        name: 'user_profile',
        pattern: '/user/:username',
        handler: (match) {
          debugPrint('→ User: ${match.pathParams['username']}');
        },
      ),
      RouteDefinition(
        name: 'promo',
        pattern: '/promo/:code',
        handler: (match) {
          debugPrint('→ Promo: ${match.pathParams['code']}');
        },
      ),
    ],
    analyticsAdapters: [
      ConsoleAnalyticsAdapter(verbose: true),
    ],
  );

  runApp(SmartLinksExampleApp(smartLinks: smartLinks));
}

class SmartLinksExampleApp extends StatelessWidget {
  final SmartLinks smartLinks;
  const SmartLinksExampleApp({super.key, required this.smartLinks});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartLinks Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: HomeScreen(smartLinks: smartLinks),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final SmartLinks smartLinks;
  const HomeScreen({super.key, required this.smartLinks});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<SmartLinkResult> _receivedLinks = [];
  String? _generatedUrl;

  @override
  void initState() {
    super.initState();
    // ── 2. Listen for incoming links ───────────────────────────────────────
    widget.smartLinks.resultStream.listen((result) {
      setState(() => _receivedLinks.insert(0, result));
      _showLinkSnackbar(result);
    });
  }

  void _showLinkSnackbar(SmartLinkResult result) {
    if (!mounted) return;
    final route = result.routeMatch;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          route != null
              ? '✅ Route: ${route.routeName} — ${route.allParams}'
              : '🔗 Link: ${result.link.path}',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── 3. Generate a link ───────────────────────────────────────────────────
  void _generateLink() {
    final url = widget.smartLinks.createLink(
      path: '/product/123',
      params: {'ref': 'USER001'},
      utmSource: 'example_app',
      utmCampaign: 'demo',
    );
    setState(() => _generatedUrl = url);
  }

  void _generateQrLink() {
    final url = widget.smartLinks.createQrLink(
      path: '/promo/SUMMER24',
      utmCampaign: 'summer_sale',
    );
    setState(() => _generatedUrl = url);
  }

  // ── 4. Simulate an incoming link (for testing) ───────────────────────────
  Future<void> _simulateLink(String url) async {
    await widget.smartLinks.handleLink(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_smart_links'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Generated URL card ─────────────────────────────────────────
          _SectionCard(
            title: 'Link Generator',
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _generateLink,
                      icon: const Icon(Icons.link),
                      label: const Text('Create Link'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _generateQrLink,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('QR Link'),
                    ),
                  ),
                ],
              ),
              if (_generatedUrl != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _generatedUrl!,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Simulate incoming links ────────────────────────────────────
          _SectionCard(
            title: 'Simulate Incoming Links',
            children: [
              _SimulateButton(
                label: 'Product link',
                url: 'https://links.example.com/product/456?ref=TEST',
                onTap: _simulateLink,
              ),
              _SimulateButton(
                label: 'Category link',
                url: 'https://links.example.com/category/electronics',
                onTap: _simulateLink,
              ),
              _SimulateButton(
                label: 'Custom scheme',
                url: 'myapp://user/johndoe',
                onTap: _simulateLink,
              ),
              _SimulateButton(
                label: 'Unknown route',
                url: 'https://links.example.com/unknown/path',
                onTap: _simulateLink,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Received links log ─────────────────────────────────────────
          _SectionCard(
            title: 'Received Links (${_receivedLinks.length})',
            children: _receivedLinks.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No links received yet.\nTap a simulate button above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  ]
                : _receivedLinks
                    .take(10)
                    .map((r) => _LinkTile(result: r))
                    .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SimulateButton extends StatelessWidget {
  final String label;
  final String url;
  final Future<void> Function(String) onTap;
  const _SimulateButton(
      {required this.label, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () => onTap(url),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(url,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final SmartLinkResult result;
  const _LinkTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final route = result.routeMatch;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            route != null ? Colors.green.shade100 : Colors.orange.shade100,
        child: Icon(
          route != null ? Icons.check : Icons.warning_amber,
          color: route != null ? Colors.green : Colors.orange,
          size: 18,
        ),
      ),
      title: Text(result.link.path,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        route != null
            ? 'Route: ${route.routeName} | ${route.allParams}'
            : 'No route matched',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
