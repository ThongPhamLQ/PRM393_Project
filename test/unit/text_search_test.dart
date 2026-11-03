import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/utils/text_search.dart';

void main() {
  group('Tìm kiếm không cần dấu', () {
    test('bỏ dấu và chuyển chữ thường', () {
      expect(foldVietnamese('Trà Sữa Trân Châu'), 'tra sua tran chau');
      expect(foldVietnamese('Đá xay Ổi hồng'), 'da xay oi hong');
      expect(foldVietnamese('Cà phê sữa đá'), 'ca phe sua da');
    });

    test('gõ không dấu vẫn tìm ra món có dấu', () {
      expect(matchesSearch('Trà sữa trân châu', 'tra sua'), isTrue);
      expect(matchesSearch('Cà phê sữa đá', 'PHE SUA'), isTrue);
      expect(matchesSearch('Cà phê sữa đá', 'trà'), isFalse);
    });

    test('chữ gõ dấu rời (dạng NFD) vẫn khớp', () {
      // "trà" gõ thành t + r + a + dấu huyền tổ hợp (U+0300)
      const decomposed = 'trà sữa';
      expect(foldVietnamese(decomposed), 'tra sua');
      expect(matchesSearch('Trà sữa', decomposed), isTrue);
    });

    test('từ khóa rỗng hoặc chỉ có khoảng trắng thì khớp tất cả', () {
      expect(matchesSearch('Trà sữa', ''), isTrue);
      expect(matchesSearch('Trà sữa', '   '), isTrue);
    });
  });
}
