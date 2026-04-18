import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _kProductId = 'fangstguide_premium';
const _kPremiumKey = 'premium_unlocked';

final premiumProvider = StreamProvider<bool>((ref) {
  final box = Hive.box('settings');
  final controller = StreamController<bool>();

  final alreadyPremium = box.get(_kPremiumKey, defaultValue: false) as bool;
  controller.add(alreadyPremium);

  if (!alreadyPremium) {
    final sub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          if (purchase.productID != _kProductId) continue;
          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            await InAppPurchase.instance.completePurchase(purchase);
            await box.put(_kPremiumKey, true);
            if (!controller.isClosed) controller.add(true);
          }
        }
      },
    );
    ref.onDispose(() {
      sub.cancel();
      controller.close();
    });
  } else {
    ref.onDispose(controller.close);
  }

  return controller.stream;
});

Future<void> purchasePremium() async {
  final available = await InAppPurchase.instance.isAvailable();
  if (!available) throw Exception('Køb ikke tilgængeligt på denne enhed');

  final response =
      await InAppPurchase.instance.queryProductDetails({_kProductId});
  if (response.productDetails.isEmpty) {
    throw Exception('Produktet blev ikke fundet. Prøv igen senere.');
  }

  final param =
      PurchaseParam(productDetails: response.productDetails.first);
  await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
}

Future<void> restorePurchases() async {
  await InAppPurchase.instance.restorePurchases();
}
