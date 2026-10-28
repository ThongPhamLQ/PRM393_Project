import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/brand_block.dart';
import '../shared/chat_screen.dart';

// Tab Cửa hàng: bản đồ vị trí quán + thông tin liên hệ + chat với quán.
// Bản đồ Goong (bản đồ Việt Nam, dạng vector) hiển thị qua maplibre_gl, cần Maptiles key.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  // Mở Google Maps để chỉ đường đến quán
  Future<void> _openDirections(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$shopLatitude,$shopLongitude',
    );
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps')),
      );
    }
  }

  // Mở trình gọi điện với số của quán
  Future<void> _callShop() async {
    await launchUrl(Uri.parse('tel:$shopPhone'));
  }

  void _openChat(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          customerId: user.id!,
          title: shopName,
          isShop: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cửa hàng')),
      // LayoutBuilder (Module 6): màn hình rộng thì xếp ngang, hẹp thì xếp dọc
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                    child: _buildMap(context),
                  ),
                ),
                Expanded(child: _buildInfo(context)),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(height: 280, child: _buildMap(context)),
              ),
              Expanded(child: _buildInfo(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Chạy thiếu file .env (hoặc trong test) thì báo thay vì để ô bản đồ trống
    if (goongMaptilesKey.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chưa có Goong Maptiles key.\n'
              'Thêm GOONG_MAPTILES_KEY vào file .env rồi chạy lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    const shopLocation = LatLng(shopLatitude, shopLongitude);
    MapLibreMapController? controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MapLibreMap(
        styleString:
            'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongMaptilesKey',
        initialCameraPosition:
            const CameraPosition(target: shopLocation, zoom: 16),
        onMapCreated: (c) => controller = c,
        // Ghim vị trí quán (chỉ thêm được sau khi style tải xong)
        onStyleLoadedCallback: () => controller?.addCircle(
          CircleOptions(
            geometry: shopLocation,
            circleRadius: 10,
            circleColor: colors.primary.toHexStringRGB(),
            circleStrokeWidth: 3,
            circleStrokeColor: colors.onPrimary.toHexStringRGB(),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thẻ cửa hàng là khối nâu: ListTile / nút bên trong tự lấy màu sáng
        BrandBlock(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront),
                  // textTheme của màn (ngoài khối) -> tự đặt màu sáng
                  title: Text(
                    shopName.toUpperCase(),
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primaryFixed,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text(shopAddress),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text(shopPhone),
                  // Nút đảo màu trên khối đậm: nền sáng, icon nâu. Đặt màu ngay
                  // trên nút vì ListTile ép màu icon của nó lên IconButton bên trong
                  trailing: IconButton.filled(
                    tooltip: 'Gọi cho quán',
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primaryFixed,
                      foregroundColor: colors.onPrimaryFixedVariant,
                    ),
                    icon: const Icon(Icons.call),
                    onPressed: _callShop,
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text(shopOpenHours),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Chỉ đường'),
                onPressed: () => _openDirections(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Chat với quán'),
                onPressed: () => _openChat(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
