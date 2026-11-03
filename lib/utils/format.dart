import 'constants.dart';

// Định dạng tiền VND: 35000 -> "35.000 đ"
String formatVnd(num amount) {
  final s = amount.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return '${buffer.toString()} đ';
}

// Định dạng ngày giờ: "09:05 13/10/2026"
String formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)} ${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

// Mức đường / đá để hiện cho khách và quán, chỉ ghi phần khác mặc định:
// "Đường 70% · Ít đá". Mặc định hoặc đơn cũ chưa có (chuỗi rỗng) -> ''
String formatSugarIce(String sugar, String ice) => [
  if (sugar.isNotEmpty && sugar != defaultSugar) 'Đường $sugar',
  if (ice.isNotEmpty && ice != defaultIce) ice,
].join(' · ');
