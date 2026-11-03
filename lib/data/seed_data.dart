// Dữ liệu mẫu nạp lên Firestore 1 lần bằng `dart run tool/seed_firestore.dart`
// (trước đây nằm trong DatabaseHelper._insertSampleData của SQLite).
// File chỉ dùng Dart thuần, không import Flutter, để script ngoài app đọc được.

// Tài khoản demo (nút điền nhanh ở màn Đăng nhập dùng đúng 2 tài khoản này)
const demoAccounts = [
  {
    'name': 'Chủ quán',
    'email': 'admin@cafe.com',
    'password': 'admin123',
    'phone': '0905123456',
    'role': 'admin',
  },
  {
    'name': 'Nguyễn Văn A',
    'email': 'khach@gmail.com',
    'password': '123456',
    'phone': '0912345678',
    'role': 'customer',
  },
];

// Danh mục: id = vị trí trong danh sách + 1
const seedCategories = ['Cà phê', 'Trà sữa', 'Trà trái cây', 'Đá xay'];

// Món: [categoryId, tên, mô tả, giá size S, ảnh]. id = vị trí + 1
const seedProducts = [
  [1, 'Cà phê đen đá', 'Cà phê phin truyền thống, đậm vị', 25000, 'assets/images/products/01_ca-phe-den-da.jpg'],
  [1, 'Cà phê sữa đá', 'Cà phê phin pha cùng sữa đặc', 29000, 'assets/images/products/02_ca-phe-sua-da.jpg'],
  [1, 'Bạc xỉu', 'Nhiều sữa, ít cà phê, vị béo nhẹ', 32000, 'assets/images/products/03_bac-xiu.jpg'],
  [1, 'Cappuccino', 'Espresso với sữa tươi đánh bọt', 45000, 'assets/images/products/04_cappuccino.jpg'],
  [2, 'Trà sữa trân châu đường đen', 'Trà sữa béo cùng trân châu đường đen', 39000, 'assets/images/products/05_tra-sua-tran-chau-duong-den.jpg'],
  [2, 'Trà sữa truyền thống', 'Trà đen pha sữa, vị cổ điển', 35000, 'assets/images/products/06_tra-sua-truyen-thong.jpg'],
  [2, 'Trà sữa matcha', 'Matcha Nhật Bản kết hợp sữa tươi', 42000, 'assets/images/products/07_tra-sua-matcha.jpg'],
  [2, 'Trà sữa Thái xanh', 'Trà Thái xanh thơm mát', 35000, 'assets/images/products/08_tra-sua-thai-xanh.jpg'],
  [3, 'Trà đào cam sả', 'Trà đào, cam tươi và sả thơm', 42000, 'assets/images/products/09_tra-dao-cam-sa.jpg'],
  [3, 'Trà vải', 'Trà xanh với vải thiều ngọt thanh', 39000, 'assets/images/products/10_tra-vai.jpg'],
  [3, 'Trà chanh dây', 'Chanh dây chua ngọt, giải nhiệt', 35000, 'assets/images/products/11_tra-chanh-day.jpg'],
  [4, 'Cookie đá xay', 'Bánh cookie xay cùng sữa và kem', 49000, 'assets/images/products/12_cookie-da-xay.jpg'],
  [4, 'Matcha đá xay', 'Matcha xay mịn phủ kem tươi', 49000, 'assets/images/products/13_matcha-da-xay.jpg'],
  [4, 'Chocolate đá xay', 'Chocolate đậm đà xay cùng đá', 49000, 'assets/images/products/14_chocolate-da-xay.jpg'],
];

// Topping: tên -> giá. id = vị trí + 1
const seedToppings = {
  'Trân châu đen': 5000,
  'Trân châu trắng': 7000,
  'Thạch trái cây': 5000,
  'Pudding trứng': 8000,
  'Kem cheese': 10000,
};
