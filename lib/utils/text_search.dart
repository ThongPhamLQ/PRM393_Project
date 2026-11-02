// Tìm kiếm tiếng Việt không cần gõ dấu: "tra sua" vẫn ra "Trà sữa".
// Cách làm: đưa cả tên món và từ khóa về chữ thường không dấu rồi so khớp.

// Mỗi nhóm: chữ gốc + các biến thể có dấu (đã viết sẵn dạng dựng sẵn - NFC)
const _groups = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};

// Bảng tra: chữ có dấu -> chữ gốc
final Map<int, String> _fold = {
  for (final entry in _groups.entries)
    for (final rune in entry.value.runes) rune: entry.key,
};

// Chữ thường, bỏ dấu tiếng Việt. Bỏ luôn dấu tổ hợp U+0300–U+036F để xử lý
// chữ gõ dấu rời (dạng NFD: "a" + dấu huyền) mà một số bàn phím tạo ra.
String foldVietnamese(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    buffer.write(_fold[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

// true nếu text chứa query (không phân biệt hoa thường và dấu). Query rỗng -> khớp hết.
bool matchesSearch(String text, String query) =>
    foldVietnamese(text).contains(foldVietnamese(query.trim()));
