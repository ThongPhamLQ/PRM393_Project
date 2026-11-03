import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/loyalty.dart';

class LoyaltyRepository {
  LoyaltyRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _account(String userId) =>
      _db.collection(Collections.loyaltyAccounts).doc(userId);

  Stream<LoyaltyAccount> watchAccount(String userId) =>
      _account(userId).snapshots().map((d) => LoyaltyAccount.fromMap(d.data()));

  Future<LoyaltyAccount> getAccount(String userId) async =>
      LoyaltyAccount.fromMap((await _account(userId).get()).data());

  Stream<List<LoyaltyTransactionEntry>> watchTransactions(String userId) =>
      _account(userId)
          .collection(Collections.loyaltyTransactions)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => LoyaltyTransactionEntry.fromMap(d.id, d.data()))
                .toList(),
          );
}
