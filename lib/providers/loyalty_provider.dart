import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/loyalty.dart';
import '../repositories/loyalty_repository.dart';

class LoyaltyProvider extends ChangeNotifier {
  LoyaltyProvider({FirebaseFirestore? db})
    : _repository = LoyaltyRepository(db: db);

  final LoyaltyRepository _repository;
  final _subscriptions = <StreamSubscription<Object?>>[];
  LoyaltyAccount account = const LoyaltyAccount.empty();
  List<LoyaltyTransactionEntry> transactions = [];

  int maxRedeemablePoints(int subtotal) => LoyaltyPolicy.maxRedeemablePoints(
    subtotal: subtotal,
    balance: account.balance,
  );

  void load(String userId) {
    clear(notify: false);
    _subscriptions.addAll([
      _repository.watchAccount(userId).listen(
        (value) {
          account = value;
          notifyListeners();
        },
        onError: (Object e) => debugPrint('Loyalty account stream failed: $e'),
      ),
      _repository.watchTransactions(userId).listen(
        (value) {
          transactions = value;
          notifyListeners();
        },
        onError: (Object e) => debugPrint('Loyalty history stream failed: $e'),
      ),
    ]);
  }

  void clear({bool notify = true}) {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    account = const LoyaltyAccount.empty();
    transactions = [];
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    clear(notify: false);
    super.dispose();
  }
}
