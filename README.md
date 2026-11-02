# Mộc Cafe & Milk Tea — App đặt đồ uống (PRM393)

App Flutter cho quán cà phê / trà sữa: khách xem menu, chọn size + topping, đặt hàng, thanh toán giả lập,
theo dõi trạng thái đơn, xem bản đồ quán và chat với quán. Chủ quán có trang riêng để quản lý đơn, menu,
xem thống kê và trả lời tin nhắn.

Dữ liệu nằm trên **Cloud Firestore** (Firebase project `moc-cafe-prm393`), đăng nhập bằng **Firebase Auth**.
Khách và chủ quán dùng **2 máy khác nhau** (điện thoại + Chrome, hoặc 2 điện thoại): đơn mới, đổi trạng thái,
tin nhắn, menu đều hiện ngay trên máy bên kia (realtime).

## 1. Chạy app

```bash
flutter pub get
flutter run --dart-define-from-file=.env                 # chạy debug trên máy ảo / điện thoại Android
flutter test                                             # chạy unit test + widget test
flutter build apk --release --dart-define-from-file=.env # build APK release -> build/app/outputs/flutter-apk/app-release.apk
```

- Cần có mạng (Firestore + Firebase Auth). Cấu hình Firebase đã nằm sẵn trong code:
  `android/app/google-services.json` (Android) và `lib/firebase_options.dart` (web), nên clone về là chạy được.
- Bản đồ màn Cửa hàng dùng Goong nên cần key: copy `.env.example` thành `.env`, dán Maptiles key (lấy ở
  account.goong.io) vào `GOONG_MAPTILES_KEY=`. File `.env` không commit. Chạy bằng Android Studio thì thêm
  `--dart-define-from-file=.env` vào ô *Additional run args* của cấu hình chạy. Thiếu key thì app vẫn chạy, ô bản đồ báo thiếu key.

Tài khoản có sẵn (trên màn Đăng nhập có nút điền nhanh):

| Vai trò   | Email             | Mật khẩu   |
|-----------|-------------------|------------|
| Khách     | khach@gmail.com   | 123456     |
| Chủ quán  | admin@cafe.com    | admin123   |

Chủ quán là tài khoản `admin@cafe.com` (khai báo ở `lib/utils/constants.dart` và `firestore.rules`).
Mọi tài khoản đăng ký mới đều là khách.

### Firebase (chỉ cần khi dựng lại project)

Project đã được tạo, đã có dữ liệu mẫu và Security Rules. Các lệnh dưới chỉ dùng khi đổi sang project khác
hoặc sửa luật (cần `npm i -g firebase-tools` và `firebase login`):

```bash
firebase deploy --only firestore:rules   # đẩy firestore.rules lên project trong .firebaserc
dart run tool/seed_firestore.dart        # tạo 2 tài khoản demo + menu mẫu (chạy lại không ghi đè dữ liệu đã có)
```

Project mới thì phải bật đăng nhập Email/Password ở Firebase Console (Authentication → Sign-in method) trước khi chạy seed.
Thành viên nhóm muốn xem dữ liệu trên Console: chủ project thêm email vào *Project settings → Users and permissions*.

### Chạy trên Chrome (web)

```bash
flutter run -d chrome --dart-define-from-file=.env   # cách nhanh nhất: tự build và mở Chrome
flutter build web --release            # hoặc build bản release -> build/web
dart pub global activate dhttpd        # (1 lần) cài web server nhỏ
dhttpd --path build/web --port 8080    # rồi mở http://localhost:8080
```

Bản web dùng chung database Firestore với điện thoại, nên có thể mở chủ quán trên Chrome và khách trên điện thoại
để demo realtime.

### Tài liệu (thư mục `docs/`)

- `Technical_Report_MocCafe.docx`: báo cáo kỹ thuật (tiếng Anh, đủ 7 mục theo đề) — điền tên/MSSV rồi xuất PDF để nộp.
  **Chưa cập nhật** phần database theo Firestore (vẫn mô tả SQLite).
- `Phan_cong_cong_viec_nhom.docx`: phân công 4 người (25% mỗi người), file cần đọc, câu hỏi hay gặp, kịch bản demo.
- `On_tap_theo_vai_tro.docx`: ôn tập theo vai trò — kiến thức slide (ghi rõ Module/slide), code tương ứng, câu hỏi + đáp án gợi ý.
- `diagrams/`: mỗi sơ đồ 1 file draw.io, mở bằng draw.io / diagrams.net để sửa hoặc xuất PNG/PDF:
  `1_architecture.drawio`, `2_database_erd.drawio`, `3_order_status.drawio`, `4_ui_flow.drawio`.

## 2. Chức năng

| # | Chức năng | Màn hình | Ghi chú |
|---|-----------|----------|---------|
| 1 | Đăng nhập / Đăng ký | `auth/login_screen`, `auth/register_screen` | Firebase Auth, form validation, tự đăng nhập lại khi mở app (Splash) |
| 2 | Menu theo danh mục | `customer/menu_screen` | Lời chào, tìm kiếm, banner, lọc danh mục (ChoiceChip có icon), lưới ảnh món tự tính số cột theo bề rộng; chủ quán đổi menu là cập nhật ngay |
| 3 | Chi tiết món | `customer/product_detail_screen` | Chọn size (Radio), topping (Checkbox), ghi chú, số lượng |
| 4 | Giỏ hàng | `customer/cart_screen` | Tăng/giảm, vuốt để xóa, gộp món trùng |
| 5 | Đặt hàng + thanh toán giả lập | `customer/checkout_screen`, `widgets/fake_payment_dialog` | Tiền mặt / MoMo / Thẻ (giả lập 2 giây) |
| 6 | Lịch sử đơn hàng | `customer/order_history_screen`, `shared/order_detail_screen` | Trạng thái tự cập nhật khi quán đổi, hủy đơn khi còn "Chờ xác nhận" |
| 7 | Thông báo trạng thái đơn | `customer/notifications_screen` | Quán đổi trạng thái trên máy khác → máy khách hiện thông báo hệ thống + badge chưa đọc |
| 8 | Bản đồ vị trí quán | `customer/store_screen` | Bản đồ Goong (maplibre_gl), nút chỉ đường Google Maps, gọi điện |
| 9 | Chat với quán | `shared/chat_screen` | Realtime: tin nhắn hiện ngay trên máy bên kia |
| 10 | Trang quản lý đơn (chủ quán) | `admin/admin_orders_screen` | Đơn mới tự hiện, lọc theo trạng thái, chuyển trạng thái → khách nhận thông báo |
| + | Tổng quan kinh doanh | `admin/admin_dashboard_screen` | Doanh thu, số đơn, đồ uống bán chạy theo 7 / 30 ngày / tất cả |
| + | Quản lý sản phẩm | `admin/admin_products_screen` | Thêm / sửa món, danh mục, topping, hết hàng / ngừng bán, xóa nhiều món + khôi phục |
| + | Chế độ tối | `customer/profile_screen` | Lưu bằng SharedPreferences |
| + | Chỉnh sửa thông tin cá nhân | `customer/edit_profile_screen` | Sửa họ tên, SĐT; đổi mật khẩu phải nhập đúng mật khẩu cũ (Firebase xác thực lại); email không đổi |

Luồng trạng thái đơn: `Chờ xác nhận → Đã xác nhận → Đang pha chế → Đang giao → Hoàn thành` (hoặc `Đã hủy` khi còn chờ xác nhận).

## 3. Kiến trúc (Provider)

```
UI (screens, widgets)
   │  context.watch / context.read / Selector
   ▼
Provider (ChangeNotifier) ── giữ state, nghe Stream từ Firestore, gọi notifyListeners() để UI vẽ lại
   │
   ▼
Repository ── chỉ lo đọc/ghi dữ liệu (Firestore query, snapshots(), transaction)
   │
   ▼
Cloud Firestore + Firebase Auth (cloud)      SharedPreferences (dark mode, trên máy)
```

| Provider | Nhiệm vụ |
|----------|----------|
| `AuthProvider` | Đăng nhập, đăng ký, đổi mật khẩu (Firebase Auth), hồ sơ `users/{uid}`, auto-login, đăng xuất |
| `MenuProvider` | Nghe danh mục, món, topping; lọc + tìm kiếm |
| `CartProvider` | Giỏ hàng (trong bộ nhớ), tính tổng tiền |
| `OrderProvider` | Đặt hàng, nghe danh sách đơn, đổi trạng thái + ghi thông báo |
| `NotificationProvider` | Nghe thông báo, số chưa đọc, bật thông báo hệ thống khi có thông báo mới |
| `ChatProvider` | Nghe tin nhắn và danh sách cuộc trò chuyện (chủ quán) |
| `ThemeProvider` | Sáng / tối |
| `DashboardProvider`, `ProductManagementProvider` | Thống kê và quản lý menu (chỉ ở màn chủ quán) |

"Nghe" = `stream.listen(...)` trên `snapshots()` của Firestore. Provider hủy nghe khi đăng xuất (`clear()`),
trước khi Firebase Auth đăng xuất, để Security Rules không báo lỗi thiếu quyền.

## 4. Cấu trúc thư mục

```
lib/
├── main.dart                 # Firebase.initializeApp + MultiProvider + MaterialApp + named routes
├── firebase_options.dart     # cấu hình Firebase cho bản web
├── data/
│   ├── firestore_db.dart     # tên collection, bộ đếm mã số (nextId), đổi Timestamp -> DateTime
│   └── seed_data.dart        # tài khoản demo + menu mẫu (tool/seed_firestore.dart dùng)
├── models/                   # User, Product, CartItem, Order, ChatMessage, AppNotification, DashboardStats
├── repositories/             # truy vấn Firestore cho từng collection
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
├── unit/                     # giỏ hàng, trạng thái đơn, validators, KPI, quản lý món (Firestore giả lập)
└── widget/                   # test màn hình đăng nhập
tool/seed_firestore.dart      # nạp dữ liệu mẫu lên Firestore
firestore.rules               # Security Rules (phân quyền phía server)
```

## 5. Thiết kế database (Cloud Firestore)

Firestore lưu dạng **collection → document** (giống JSON), không có bảng, JOIN hay AUTOINCREMENT như SQL.

| Collection (document id) | Trường chính | Ghi chú |
|------|-----------|---------|
| `users/{uid}` | name, email, phone, role (`customer`/`admin`) | uid do Firebase Auth cấp; mật khẩu do Firebase Auth giữ, không lưu ở đây |
| `users/{uid}/notifications/{auto}` | title, body, isRead, createdAt | Subcollection: thông báo của từng người |
| `categories/{id}` | id, name | id là số (`"1"`, `"2"`…) |
| `products/{id}` | id, categoryId, name, description, price, imageUrl, status (`available`/`soldOut`/`hidden`), deleted, previousStatus, deletedAt | Xóa mềm: `deleted = true`, giữ `previousStatus` để khôi phục |
| `toppings/{id}` | id, name, price | |
| `orders/{id}` | id, userId, customerName, phone, address, note, paymentMethod, isPaid, totalPrice, status, createdAt, **items[]** | Các món nằm luôn trong đơn (mảng `items`: productName, size, toppings, note, quantity, unitPrice) thay cho bảng order_items |
| `chats/{customerUid}` | customerName, lastMessage, lastTime | Danh sách cuộc trò chuyện của chủ quán đọc thẳng collection này (thay JOIN + GROUP BY) |
| `chats/{customerUid}/messages/{auto}` | sender (`customer`/`shop`), content, createdAt | |
| `counters/{name}` | value | Bộ đếm cấp mã đơn `#1, #2…` và id món / danh mục / topping mới, tăng trong transaction |

- `items` lưu **tên + giá tại thời điểm đặt** → quán đổi giá menu thì lịch sử đơn vẫn đúng.
- Giá size cố định trong code (`utils/constants.dart`): S +0đ, M +6.000đ, L +10.000đ.
- Ảnh món nằm ở `assets/images/products/` (khai báo trong `pubspec.yaml`), trường `imageUrl` lưu đường dẫn
  `assets/...` (hoặc link `http...`); thiếu file / lỗi tải thì app hiện icon theo danh mục.
- Đặt đơn, đổi trạng thái, xóa / khôi phục món chạy trong **transaction**: đọc lại dữ liệu mới nhất rồi mới ghi,
  máy khác vừa đổi thì báo lỗi thay vì ghi đè.
- **Security Rules** (`firestore.rules`) kiểm tra trên server: khách chỉ đọc đơn / thông báo / chat của mình,
  chỉ được hủy đơn đang chờ; chỉ chủ quán sửa menu và đổi trạng thái đơn; không ai tự nâng vai trò thành admin.
- Firestore trên Android tự lưu cache: mất mạng vẫn xem được dữ liệu đã tải; đặt đơn (transaction) thì cần mạng.

## 6. Kiến thức trong slide đã áp dụng

| Module | Áp dụng ở đâu |
|--------|---------------|
| M2-M3 Dart, OOP, async | Model + `factory fromMap`, enum `OrderStatus`, `Future`/`async`/`await`, **Stream** + `listen` (snapshots), Repository pattern |
| M4 UI Widgets | Scaffold, Card, ListTile, CustomScrollView + SliverGrid, NavigationBar / NavigationRail, RadioListTile, CheckboxListTile, SwitchListTile, Badge, ThemeData (component theme gom ở `main.dart`) + Dark mode |
| M5 Navigation & State | Named routes, `push` / `pushReplacementNamed` / `pushNamedAndRemoveUntil`, Provider (`context.watch` / `read` / `select`, `Selector`) |
| M6 Responsive | `LayoutBuilder`: mốc 600/1024px chọn NavigationBar / NavigationRail / Rail mở rộng (`widgets/adaptive_shell.dart`), số cột lưới Menu theo bề rộng (thẻ ≤ 280px), màn Cửa hàng; `MediaQuery` (cỡ chữ, mật độ điểm ảnh); nội dung rộng tối đa 1200px (`MaxWidthBox`), `SafeArea`, `Expanded`, `Wrap` |
| M7 Forms | `Form` + `GlobalKey<FormState>`, validator, xác nhận mật khẩu, `AutovalidateMode.onUserInteraction`, ẩn/hiện mật khẩu, ẩn bàn phím |
| M8 JSON / Service layer | `toMap()` / `fromMap()` cho document Firestore, `FutureBuilder` (chi tiết đơn), xử lý loading / rỗng / lỗi |
| M9 Storage | Cloud Firestore (remote database) CRUD + transaction + batch, SharedPreferences (dark mode), `Dismissible` |
| M10 Auth & Notification | Firebase Auth (email/password, đổi mật khẩu có xác thực lại), Splash → auto-login, logout, local notification |
| M11 Testing | Unit test (`test/unit`, có Firestore giả lập `fake_cloud_firestore`), Widget test (`test/widget`), dùng `Key` để tìm widget |
| M12 Performance & Deploy | `const`, tách widget, `Selector`/`context.select`, `ListView.builder`, `ValueKey`, build APK release |

## 7. Kiến thức ngoài slide (ghi vào báo cáo mục "new technologies")

| Thư viện / kỹ thuật | Dùng để | Lý do chọn |
|---------------------|---------|------------|
| `cloud_firestore` (realtime `snapshots()`) | Database trên cloud dùng chung cho mọi máy | Khách và chủ quán ở 2 máy khác nhau; dữ liệu đổi là máy kia thấy ngay, không cần tự viết server |
| Firestore Security Rules | Phân quyền đọc/ghi chạy trên server | App chỉ là client, sửa code app cũng không vượt được quyền |
| Firestore transaction + bộ đếm | Cấp mã đơn tăng dần, đổi trạng thái không ghi đè nhau | Firestore không có AUTOINCREMENT; 2 máy ghi cùng lúc vẫn đúng |
| `fake_cloud_firestore` | Unit test repository không cần mạng | Chạy `flutter test` nhanh, không đụng dữ liệu thật |
| `maplibre_gl` + Goong Maptiles | Hiển thị bản đồ Goong (bản đồ vector của Việt Nam) + ghim vị trí quán | Dữ liệu địa chỉ Việt Nam chi tiết; key đọc từ `.env` qua `--dart-define-from-file`, không nằm trong code |
| `url_launcher` | Mở Google Maps chỉ đường, mở trình gọi điện | Gọi app khác của điện thoại bằng URL |
| `RadioGroup` | Quản lý nhóm Radio (size, phương thức thanh toán) | Flutter 3.32+ bỏ `groupValue`/`onChanged` trên từng Radio |
| Enum có thuộc tính (enhanced enum) | `OrderStatus('Chờ xác nhận', ...)`, `PaymentMethod` | Gom nhãn + mô tả vào 1 chỗ, có getter `next` |

## 8. Kịch bản demo gợi ý (15 phút)

Chuẩn bị 2 máy: máy A (điện thoại / máy ảo) đăng nhập khách, máy B (Chrome hoặc điện thoại khác) đăng nhập chủ quán.

1. Mở app → Splash → Login. Đăng ký tài khoản mới (thử nhập sai để thấy validate).
2. Máy A (khách) → Menu: lọc danh mục, tìm kiếm → chọn món, chọn size L + 2 topping → thêm giỏ.
3. Máy B (chủ quán) → Quản lý sản phẩm: báo "Hết hàng" 1 món → máy A thấy món biến mất khỏi menu.
4. Máy A: giỏ hàng → Đặt hàng → chọn MoMo → thanh toán giả lập → máy B thấy đơn mới hiện ngay.
5. Máy B chuyển trạng thái từng bước → máy A hiện thông báo hệ thống, badge tăng, tab Đơn hàng đổi trạng thái.
6. Chat: máy A nhắn quán → máy B trả lời → tin hiện ngay hai bên.
7. Máy B: Tổng quan kinh doanh (doanh thu, món bán chạy).
8. Tắt app mở lại → vẫn giữ đăng nhập (Firebase Auth) + chế độ tối. Chạy `flutter test`, mở APK release trên máy.

## 9. Hạn chế & hướng phát triển

- Thông báo chỉ hiện khi app khách đang mở (hoặc chạy nền); muốn báo cả khi đã tắt app thì cần
  Firebase Cloud Messaging + Cloud Functions (phải lên gói Blaze trả phí).
- Ảnh món dùng ảnh có sẵn trong app hoặc link http; tải ảnh từ điện thoại lên cần Cloud Storage (gói Blaze).
- Thống kê đọc mọi đơn trong khoảng thời gian rồi cộng trên máy chủ quán; nhiều đơn thì nên dùng aggregate query.
- Chủ quán xác định bằng 1 email cố định; nhiều nhân viên thì nên dùng custom claims của Firebase Auth.
- Thanh toán chỉ là giả lập → có thể tích hợp SDK MoMo / VNPay.
