import 'package:flutter/material.dart';

import '../models/product_review.dart';
import '../repositories/review_repository.dart';

class ProductReviews extends StatefulWidget {
  const ProductReviews({super.key, required this.productId, this.repository});
  final int productId;
  final ReviewRepository? repository;
  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  late Stream<List<ProductReview>> _stream;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() => _stream = (widget.repository ?? ReviewRepository())
      .watchProduct(widget.productId);
  @override
  void didUpdateWidget(covariant ProductReviews oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        oldWidget.repository != widget.repository) {
      _listen();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ProductReview>>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(_listen),
          child: const Text('Không tải được đánh giá. Thử lại'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ReviewList(reviews: snapshot.data!);
    },
  );
}

class ReviewList extends StatelessWidget {
  const ReviewList({super.key, required this.reviews});
  final List<ProductReview> reviews;
  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có đánh giá'),
      );
    }
    final average =
        reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        reviews.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '★ ${average.toStringAsFixed(1)}/5 · ${reviews.length} đánh giá',
          ),
        ),
        for (final review in reviews)
          ListTile(
            title: Text('${review.rating}/5 ★'),
            subtitle: review.comment.isEmpty ? null : Text(review.comment),
          ),
      ],
    );
  }
}

class OrderReviewButton extends StatefulWidget {
  const OrderReviewButton({
    super.key,
    required this.productId,
    required this.orderId,
    required this.userId,
    required this.productName,
    this.repository,
  });
  final int productId;
  final int orderId;
  final String userId;
  final String productName;
  final ReviewRepository? repository;
  @override
  State<OrderReviewButton> createState() => _OrderReviewButtonState();
}

class _OrderReviewButtonState extends State<OrderReviewButton> {
  late ReviewRepository _repo;
  late Stream<bool> _stream;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _repo = widget.repository ?? ReviewRepository();
    _stream = _repo.watchReviewed(widget.productId, widget.orderId);
  }

  @override
  void didUpdateWidget(covariant OrderReviewButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        oldWidget.orderId != widget.orderId ||
        oldWidget.repository != widget.repository) {
      _listen();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(_listen),
          child: const Text('Không tải được trạng thái đánh giá. Thử lại'),
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      if (snapshot.data!) return Text('${widget.productName}: Đã đánh giá');
      return TextButton.icon(
        icon: const Icon(Icons.star_outline),
        label: Text('Đánh giá ${widget.productName}'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _ReviewDialog(widget: widget, repository: _repo),
        ),
      );
    },
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.widget, required this.repository});
  final OrderReviewButton widget;
  final ReviewRepository repository;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final target = widget.widget;
      await widget.repository.submit(
        userId: target.userId,
        orderId: target.orderId,
        productId: target.productId,
        rating: _rating,
        comment: _comment.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Không gửi được. Món có thể đã được đánh giá; hãy đóng và thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text('Đánh giá ${widget.widget.productName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star sao',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_outline,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _comment,
              maxLength: 500,
              maxLines: 3,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (tùy chọn)',
              ),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Đang gửi…' : 'Gửi đánh giá'),
        ),
      ],
    ),
  );
}
