import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorite_provider.dart';

Future<void> toggleFavorite(BuildContext context, int productId) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<FavoriteProvider>().toggle(productId);
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không cập nhật được yêu thích. Vui lòng thử lại.'),
        ),
      );
    }
  }
}
