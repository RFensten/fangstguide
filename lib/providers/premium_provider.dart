import 'package:flutter_riverpod/flutter_riverpod.dart';

// RevenueCat ikke konfigureret endnu — alle er gratis-tier
final premiumProvider = StreamProvider<bool>((_) => Stream.value(false));

Future<bool> restorePurchases() async => false;
