// ===== Thông tin quán (nhóm sửa lại theo quán thật nếu muốn) =====
const String shopName = 'Mộc Cafe & Milk Tea';
const String shopAddress = '123 Nguyễn Văn Linh, Hải Châu, Đà Nẵng';
const String shopPhone = '0905123456';
const String shopOpenHours = '07:00 - 22:00 (Thứ 2 - Chủ nhật)';

// Tọa độ quán để hiển thị trên bản đồ
const double shopLatitude = 16.0605;
const double shopLongitude = 108.2097;

// ===== Size đồ uống =====
// Map: key = tên size, value = giá cộng thêm so với giá gốc
const Map<String, int> sizePrices = {'S': 0, 'M': 6000, 'L': 10000};

// ===== Vai trò người dùng =====
const String roleCustomer = 'customer';
const String roleAdmin = 'admin';

// ===== Người gửi tin nhắn =====
const String senderCustomer = 'customer';
const String senderShop = 'shop';
