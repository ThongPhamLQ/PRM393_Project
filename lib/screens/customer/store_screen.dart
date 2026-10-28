import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../shared/chat_screen.dart';

// Tab Cửa hàng: bản đồ vị trí quán + thông tin liên hệ + chat với quán.
// Bản đồ dùng flutter_map + OpenStreetMap (miễn phí, không cần API key).
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
        builder: (_) =>
            ChatScreen(customerId: user.id!, title: shopName, isShop: false),
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
              children: [
                Expanded(child: _buildMap()),
                Expanded(child: _buildInfo(context)),
              ],
            );
          }
          return Column(
            children: [
              SizedBox(height: 280, child: _buildMap()),
              Expanded(child: _buildInfo(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    const shopLocation = LatLng(shopLatitude, shopLongitude);
    return FlutterMap(
      options: const MapOptions(initialCenter: shopLocation, initialZoom: 16),
      children: [
        // Lớp ảnh bản đồ OpenStreetMap.
        // Dùng máy chủ tile.openstreetmap.de (cộng đồng OSM Đức) vì tên miền
        // openstreetmap.org bị chặn DNS trên mạng lúc phát triển (trả về 127.0.0.1).
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.project.shop_app',
        ),
        // Ghim vị trí quán
        const MarkerLayer(
          markers: [
            Marker(
              point: shopLocation,
              width: 50,
              height: 50,
              child: Icon(Icons.location_on, color: Colors.red, size: 50),
            ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.store),
          title: Text(
            shopName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.location_on),
          title: Text(shopAddress),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text(shopPhone),
          trailing: IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: _callShop,
          ),
        ),
        const ListTile(
          leading: Icon(Icons.access_time),
          title: Text(shopOpenHours),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat với quán'),
                  onPressed: () => _openChat(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
