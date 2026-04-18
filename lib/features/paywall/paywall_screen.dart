import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/premium_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-luk skærmen hvis premium allerede er aktivt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPremium = ref.read(premiumProvider).valueOrNull ?? false;
      if (isPremium && mounted) context.pop();
    });
  }

  Future<void> _purchase() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await purchasePremium();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await restorePurchases();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-luk når køb bekræftes via purchaseStream
    ref.listen(premiumProvider, (_, next) {
      if ((next.valueOrNull ?? false) && mounted) context.pop();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lås op'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.lock_open_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Fangstguide Premium',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ét engangsbeløb — ingen abonnement.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            const _FeatureList(),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _purchase,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lås op — 39 kr.'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _loading ? null : _restore,
                child: const Text('Gendan tidligere køb'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.set_meal, 'Alle 29 fiskearter — ikke kun de gratis'),
      (Icons.calendar_month, 'Fuld 12-måneders fredningstidskalender'),
      (Icons.straighten, 'Mål-tjek for alle arter'),
      (Icons.wifi_off, 'Offline-adgang — ingen internet nødvendig'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(f.$1, color: const Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(f.$2,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
