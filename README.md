# Mộc Cafe & Milk Tea — App đặt đồ uống (PRM393)

App Flutter cho quán cà phê / trà sữa: khách xem menu, chọn size + topping, đặt hàng, thanh toán giả lập,
theo dõi trạng thái đơn, xem bản đồ quán và chat với quán. Chủ quán có trang riêng để quản lý đơn và trả lời tin nhắn.

## 1. Chạy app

```bash
flutter pub get
flutter run --dart-define-from-file=.env                 # chạy debug trên máy ảo / điện thoại Android
flutter test                                             # chạy unit test + widget test
flutter build apk --release --dart-define-from-file=.env # build APK release -> build/app/outputs/flutter-apk/app-release.apk
```

Bản đồ màn Cửa hàng dùng Goong nên cần key: copy `.env.example` thành `.env`, dán Maptiles key (lấy ở
account.goong.io) vào `GOONG_MAPTILES_KEY=`. File `.env` không commit. Chạy bằng Android Studio thì thêm
`--dart-define-from-file=.env` vào ô *Additional run args* của cấu hình chạy. Thiếu key thì app vẫn chạy, ô bản đồ báo thiếu key.

Tài khoản có sẵn (trên màn Đăng nhập có nút điền nhanh):

| Vai trò   | Email             | Mật khẩu   |
|-----------|-------------------|------------|
| Khách     | khach@gmail.com   | 123456     |
| Chủ quán  | admin@cafe.com    | admin123   |

> Database là SQLite nằm trên máy, nên khách và chủ quán dùng chung 1 máy: đăng nhập khách để đặt hàng / nhắn tin,
> đăng xuất rồi đăng nhập chủ quán để xử lý đơn / trả lời.

### Chạy trên Chrome (web)

```bash
flutter run -d chrome --dart-define-from-file=.env   # cách nhanh nhất: tự build và mở Chrome
flutter build web --release            # hoặc build bản release -> build/web
dart pub global activate dhttpd        # (1 lần) cài web server nhỏ
dhttpd --path build/web --port 8080    # rồi mở http://localhost:8080
```

- `sqflite` không chạy trên web, nên khi `kIsWeb` app dùng `sqflite_common_ffi_web` (SQLite bản WebAssembly,
  dữ liệu lưu trong IndexedDB của trình duyệt) — xem `main.dart`.
- 2 file `web/sqlite3.wasm` và `web/sqflite_sw.js` được tạo bằng `dart run sqflite_common_ffi_web:setup`,
  **phải commit cùng code** thì bản web mới chạy.
- Dữ liệu trên web tách riêng với dữ liệu trên điện thoại.

### Tài liệu (thư mục `docs/`)

- `Technical_Report_MocCafe.docx`: báo cáo kỹ thuật (tiếng Anh, đủ 7 mục theo đề) — điền tên/MSSV rồi xuất PDF để nộp.
- `Phan_cong_cong_viec_nhom.docx`: phân công 4 người (25% mỗi người), file cần đọc, câu hỏi hay gặp, kịch bản demo.
- `On_tap_theo_vai_tro.docx`: ôn tập theo vai trò — kiến thức slide (ghi rõ Module/slide), code tương ứng, câu hỏi + đáp án gợi ý.
- `diagrams/`: mỗi sơ đồ 1 file draw.io, mở bằng draw.io / diagrams.net để sửa hoặc xuất PNG/PDF:
  `1_architecture.drawio`, `2_database_erd.drawio`, `3_order_status.drawio`, `4_ui_flow.drawio`.

## 2. Chức năng

| # | Chức năng | Màn hình | Ghi chú |
|---|-----------|----------|---------|
| 1 | Đăng nhập / Đăng ký | `auth/login_screen`, `auth/register_screen` | Form validation, tự đăng nhập lại khi mở app (Splash) |
| 2 | Menu theo danh mục | `customer/menu_screen` | Lời chào, tìm kiếm, banner, lọc danh mục (ChoiceChip có icon), lưới ảnh món tự tính số cột theo bề rộng |
| 3 | Chi tiết món | `customer/product_detail_screen` | Chọn size (Radio), topping (Checkbox), ghi chú, số lượng |
| 4 | Giỏ hàng | `customer/cart_screen` | Tăng/giảm, vuốt để xóa, gộp món trùng |
| 5 | Đặt hàng + thanh toán giả lập | `customer/checkout_screen`, `widgets/fake_payment_dialog` | Tiền mặt / MoMo / Thẻ (giả lập 2 giây) |
| 6 | Lịch sử đơn hàng | `customer/order_history_screen`, `shared/order_detail_screen` | Xem các bước trạng thái, hủy đơn khi còn "Chờ xác nhận" |
| 7 | Thông báo trạng thái đơn | `customer/notifications_screen` | Thông báo hệ thống (local notification) + lưu lịch sử, badge số chưa đọc |
| 8 | Bản đồ vị trí quán | `customer/store_screen` | Bản đồ Goong (maplibre_gl), nút chỉ đường Google Maps, gọi điện |
| 9 | Chat với quán | `shared/chat_screen` | Khách nhắn, chủ quán trả lời |
| 10 | Trang quản lý đơn (chủ quán) | `admin/admin_orders_screen` | Lọc theo trạng thái, chuyển trạng thái → khách nhận thông báo |
| + | Chế độ tối | `customer/profile_screen` | Lưu bằng SharedPreferences |
| + | Chỉnh sửa thông tin cá nhân | `customer/edit_profile_screen` | Sửa họ tên, SĐT; đổi mật khẩu phải nhập đúng mật khẩu cũ; email không đổi |

Luồng trạng thái đơn: `Chờ xác nhận → Đã xác nhận → Đang pha chế → Đang giao → Hoàn thành` (hoặc `Đã hủy` khi còn chờ xác nhận).

## 3. Kiến trúc (Provider)

```
UI (screens, widgets)
   │  context.watch / context.read / Selector
   ▼
Provider (ChangeNotifier) ── giữ state, gọi notifyListeners() để UI vẽ lại
   │
   ▼
Repository ── chỉ lo đọc/ghi dữ liệu (SQL)
   │
   ▼
DatabaseHelper (SQLite - sqflite)      SharedPreferences (phiên đăng nhập, dark mode)
```

| Provider | Nhiệm vụ |
|----------|----------|
| `AuthProvider` | Đăng nhập, đăng ký, auto-login, đăng xuất |
| `MenuProvider` | Danh mục, món, topping, lọc + tìm kiếm |
| `CartProvider` | Giỏ hàng (trong bộ nhớ), tính tổng tiền |
| `OrderProvider` | Đặt hàng, lịch sử đơn, đổi trạng thái + gửi thông báo |
| `NotificationProvider` | Danh sách thông báo, số chưa đọc |
| `ChatProvider` | Tin nhắn, danh sách cuộc trò chuyện (chủ quán) |
| `ThemeProvider` | Sáng / tối |

## 4. Cấu trúc thư mục

```
lib/
├── main.dart                 # MultiProvider + MaterialApp + named routes
├── data/database_helper.dart # tạo bảng SQLite + dữ liệu mẫu
├── models/                   # User, Product, CartItem, Order, ChatMessage, AppNotification
├── repositories/             # truy vấn SQLite cho từng bảng
├── providers/                # state management
├── services/notification_service.dart  # local notification
├── screens/
│   ├── splash_screen.dart
│   ├── auth/                 # đăng nhập, đăng ký
│   ├── customer/             # các màn hình của khách
│   ├── admin/                # các màn hình của chủ quán
│   └── shared/               # chi tiết đơn, chat (dùng chung)
├── widgets/                  # widget tách nhỏ, dùng lại nhiều nơi
└── utils/                    # constants, format tiền/ngày, validators, logout
test/
├── unit/                     # test logic giỏ hàng, trạng thái đơn, validators
└── widget/                   # test màn hình đăng nhập
```

## 5. Thiết kế database (SQLite)

| Bảng | Cột chính | Quan hệ |
|------|-----------|---------|
| `users` | id, name, email (unique), password, phone, role (`customer`/`admin`) | |
| `categories` | id, name | 1 - N `products` |
| `products` | id, categoryId, name, description, price, imageUrl | N - 1 `categories` |
| `toppings` | id, name, price | |
| `orders` | id, userId, customerName, phone, address, note, paymentMethod, isPaid, totalPrice, status, createdAt | N - 1 `users`, 1 - N `order_items` |
| `order_items` | id, orderId, productName, size, toppings, note, quantity, unitPrice | N - 1 `orders` |
| `messages` | id, customerId, sender (`customer`/`shop`), content, createdAt | N - 1 `users` |
| `notifications` | id, userId, title, body, isRead, createdAt | N - 1 `users` |

- `order_items` lưu **tên + giá tại thời điểm đặt** → quán đổi giá menu thì lịch sử đơn vẫn đúng.
- Giá size cố định trong code (`utils/constants.dart`): S +0đ, M +6.000đ, L +10.000đ.
- Ảnh món nằm ở `assets/images/products/` (khai báo trong `pubspec.yaml`), cột `imageUrl` lưu đường dẫn
  `assets/...` (hoặc link `http...`); thiếu file / lỗi tải thì app hiện icon theo danh mục.
- Database đang ở **version 2**: máy đã cài bản 1 (kể cả IndexedDB trên Chrome) tự chạy `onUpgrade`, chỉ điền
  `products.imageUrl`, không đụng tài khoản / đơn hàng / tin nhắn / thông báo → không cần gỡ app.
  Sửa dữ liệu mẫu khác thì vẫn phải gỡ app cài lại vì `onCreate` chỉ chạy 1 lần.

## 6. Kiến thức trong slide đã áp dụng

| Module | Áp dụng ở đâu |
|--------|---------------|
| M2-M3 Dart, OOP, async | Model + `factory fromMap`, enum `OrderStatus`, `Future`/`async`/`await`, Singleton `DatabaseHelper`, Repository pattern |
| M4 UI Widgets | Scaffold, Card, ListTile, CustomScrollView + SliverGrid, NavigationBar / NavigationRail, RadioListTile, CheckboxListTile, SwitchListTile, Badge, ThemeData (component theme gom ở `main.dart`) + Dark mode |
| M5 Navigation & State | Named routes, `push` / `pushReplacementNamed` / `pushNamedAndRemoveUntil`, Provider (`context.watch` / `read` / `select`, `Selector`) |
| M6 Responsive | `LayoutBuilder`: mốc 600/1024px chọn NavigationBar / NavigationRail / Rail mở rộng (`widgets/adaptive_shell.dart`), số cột lưới Menu theo bề rộng (thẻ ≤ 280px), màn Cửa hàng; `MediaQuery` (cỡ chữ, mật độ điểm ảnh); nội dung rộng tối đa 1200px (`MaxWidthBox`), `SafeArea`, `Expanded`, `Wrap` |
| M7 Forms | `Form` + `GlobalKey<FormState>`, validator, xác nhận mật khẩu, `AutovalidateMode.onUserInteraction`, ẩn/hiện mật khẩu, ẩn bàn phím |
| M8 JSON / Service layer | `toMap()` / `fromMap()`, `FutureBuilder` (chi tiết đơn), xử lý loading / rỗng / lỗi |
| M9 Local storage | SQLite (sqflite) CRUD + transaction + JOIN/GROUP BY, SharedPreferences (phiên đăng nhập, dark mode), `Dismissible` |
| M10 Auth & Notification | AuthService/Provider giả lập server, Splash → auto-login, logout, local notification |
| M11 Testing | Unit test (`test/unit`), Widget test (`test/widget`), dùng `Key` để tìm widget |
| M12 Performance & Deploy | `const`, tách widget, `Selector`/`context.select`, `ListView.builder`, `ValueKey`, build APK release |

## 7. Kiến thức ngoài slide (ghi vào báo cáo mục "new technologies")

| Thư viện / kỹ thuật | Dùng để | Lý do chọn |
|---------------------|---------|------------|
| `maplibre_gl` + Goong Maptiles | Hiển thị bản đồ Goong (bản đồ vector của Việt Nam) + ghim vị trí quán | Dữ liệu địa chỉ Việt Nam chi tiết; key đọc từ `.env` qua `--dart-define-from-file`, không nằm trong code |
| `url_launcher` | Mở Google Maps chỉ đường, mở trình gọi điện | Gọi app khác của điện thoại bằng URL |
| `RadioGroup` | Quản lý nhóm Radio (size, phương thức thanh toán) | Flutter 3.32+ bỏ `groupValue`/`onChanged` trên từng Radio |
| Enum có thuộc tính (enhanced enum) | `OrderStatus('Chờ xác nhận', ...)`, `PaymentMethod` | Gom nhãn + mô tả vào 1 chỗ, có getter `next` |
| SQLite transaction | Lưu đơn + các món cùng lúc | Lỗi giữa chừng thì không lưu dở dang |
| `sqflite_common_ffi_web` | Chạy database SQLite trên Chrome (bản web) | `sqflite` không hỗ trợ web; gói này chạy SQLite dạng WebAssembly |

## 8. Kịch bản demo gợi ý (15 phút)

1. Mở app → Splash → Login. Đăng ký tài khoản mới (thử nhập sai để thấy validate).
2. Đăng nhập khách → Menu: lọc danh mục, tìm kiếm → chọn món, chọn size L + 2 topping → thêm giỏ.
3. Giỏ hàng: tăng/giảm, vuốt xóa → Đặt hàng → chọn MoMo → thanh toán giả lập → thông báo hiện lên.
4. Tab Cửa hàng: bản đồ, chỉ đường → Chat với quán: gửi tin nhắn.
5. Đăng xuất → đăng nhập chủ quán → thấy đơn mới → chuyển trạng thái từng bước → trả lời chat.
6. Đăng xuất → đăng nhập lại khách → tab Thông báo (badge) + tab Đơn hàng thấy trạng thái mới.
7. Bật chế độ tối, tắt app mở lại → vẫn giữ đăng nhập + chế độ tối.
8. Chạy `flutter test`, mở APK release trên máy.

## 9. Hạn chế & hướng phát triển

- Database nằm trên máy → khách và chủ quán phải dùng chung 1 máy. Hướng phát triển: chuyển sang Firebase Firestore
  hoặc REST API để nhiều máy dùng chung, chat realtime, push notification (FCM).
- Mật khẩu đang lưu dạng chữ thường (chỉ phục vụ học tập) → thực tế phải mã hóa (hash) ở server.
- Thanh toán chỉ là giả lập → có thể tích hợp SDK MoMo / VNPay.
- Chủ quán chưa thêm/sửa món được trên app; chưa có thống kê doanh thu.
