import 'package:flutter/foundation.dart';

import '../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

/// Loads Dashboard statistics from SQLite. The widget owns this provider.
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardProvider({DashboardRepository? repository})
    : _repository = repository ?? DashboardRepository();

  DashboardStats? stats;
  bool loading = false;
  String? error;
  int days = 7; // 0 means all historical orders.
  int _requestId = 0;
  bool _disposed = false;

  /// The range groups orders by createdAt, NOT the date they were completed.
  Future<void> refresh({int? periodDays}) async {
    if (_disposed) return;
    if (periodDays != null) {
      if (periodDays != 0 && periodDays != 7 && periodDays != 30) {
        throw ArgumentError.value(periodDays, 'periodDays');
      }
      if (days != periodDays)
        stats = null; // Prevent stale previous-period KPIs.
      days = periodDays;
    }

    final requestId = ++_requestId;
    loading = true;
    error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final from = days == 0
          ? null
          : DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: days - 1));
      final result = await _repository.load(from: from);
      if (!_disposed && requestId == _requestId) stats = result;
    } catch (e) {
      if (!_disposed && requestId == _requestId) error = e.toString();
    } finally {
      if (!_disposed && requestId == _requestId) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++; // Invalidate in-flight database requests.
    super.dispose();
  }
}
