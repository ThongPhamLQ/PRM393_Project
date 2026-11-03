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
firebase emulators:exec --project demo-prm393 --only firestore "node test/rules/firestore_rules_test.mjs"
flutter build apk --release --dart-define-from-file=.env # build APK release -> build/app/outputs/flutter-apk/app-release.apk
```

- Cần có mạng (Firestore + Firebase Auth). Cấu hình Firebase đã nằm sẵn trong code:
  `android/app/google-services.json` (Android) và `lib/firebase_options.dart` (web), nên clone về là chạy được.
- Android build cần JDK 21 (thư viện MapLibre); có thể dùng JBR của Android Studio. Rules Emulator cũng cần Java 21. Bộ test Flutter hiện có 97 test; bộ test Rules dùng Node 18+ và Firebase CLI, không cần npm dependency bổ sung.
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

- [Phase mới và demo](docs/PHASE_DEMO.md): loyalty, tìm/lọc đơn, đánh giá sau mua, kiểm thử và triển khai Rules.
- [Bằng chứng đóng góp](docs/CONTRIBUTION_EVIDENCE.md): commit, phần việc và cách tính tỷ lệ; 25% công việc là đề xuất để nhóm thống nhất.
- [Phụ lục báo cáo](docs/REPORT_ADDENDUM.md): nội dung cập nhật cho `SampleProjectReport.docx`.

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
| 2 | Menu theo danh mục | `customer/menu_screen` | Lời chào, tìm kiếm **không cần gõ dấu** ("tra sua" ra "Trà sữa"), banner, lọc danh mục (ChoiceChip có icon), lưới ảnh món tự tính số cột theo bề rộng; chủ quán đổi menu là cập nhật ngay. Có đơn đang chạy thì hiện thẻ **"Đơn đang thực hiện"** (trạng thái + thanh tiến độ, đổi ngay khi quán chuyển bước); nút giỏ nổi "Xem giỏ · tổng tiền" |
| 3 | Chi tiết món | `customer/product_detail_screen` | Ảnh bay từ thẻ món sang (Hero). Chọn size (Radio), topping (Checkbox), **mức đường, mức đá** (ChoiceChip, không đổi giá), ghi chú, số lượng. Thêm vào giỏ: rung nhẹ, số trên nút giỏ nảy lên |
| 4 | Giỏ hàng | `customer/cart_screen` | Tăng/giảm, vuốt để xóa, gộp món trùng |
| 5 | Đặt hàng + thanh toán giả lập | `customer/checkout_screen`, `customer/order_success_screen`, `widgets/fake_payment_dialog` | Tiền mặt / MoMo / Thẻ (giả lập 2 giây). Tự điền địa chỉ của đơn gần nhất. Đặt xong sang màn **"Đặt hàng thành công"** có mã đơn + nút "Theo dõi đơn" |
| 6 | Lịch sử đơn hàng | `customer/order_history_screen`, `shared/order_detail_screen` | Chi tiết đơn tự đổi khi quán chuyển bước (timeline có hiệu ứng), hủy đơn khi còn "Chờ xác nhận", **"Đặt lại"** đơn đã xong (theo menu hiện tại, bỏ món ngừng bán) |
| 7 | Thông báo trạng thái đơn | `customer/notifications_screen` | Quán đổi trạng thái trên máy khác → máy khách hiện thông báo hệ thống + badge chưa đọc. **Bấm thông báo mở đúng đơn** đó |
| 8 | Bản đồ vị trí quán | `customer/store_screen` | Bản đồ Goong (maplibre_gl), nút chỉ đường Google Maps, gọi điện |
| 9 | Chat với quán | `shared/chat_screen` | Realtime: tin nhắn hiện ngay trên máy bên kia |
| 10 | Trang quản lý đơn (chủ quán) | `admin/admin_orders_screen` | Đơn mới tự hiện + **thông báo hệ thống "Đơn mới #…"** + badge số đơn chờ trên tab Đơn hàng, lọc theo trạng thái, chuyển trạng thái → khách nhận thông báo |
| + | Tổng quan kinh doanh | `admin/admin_dashboard_screen` | Doanh thu, số đơn, đồ uống bán chạy theo 7 / 30 ngày / tất cả |
| + | Quản lý sản phẩm | `admin/admin_products_screen` | Thêm / sửa món, danh mục, topping, hết hàng / ngừng bán, xóa nhiều món + khôi phục |
| + | Chế độ tối | `customer/profile_screen` | Lưu bằng SharedPreferences |
| + | Chỉnh sửa thông tin cá nhân | `customer/edit_profile_screen` | Sửa họ tên, SĐT; đổi mật khẩu phải nhập đúng mật khẩu cũ (Firebase xác thực lại); email không đổi |
| + | Khách hàng thân thiết | `customer/loyalty_hub_screen` | Yêu thích món realtime; tích 1 điểm/10.000đ đơn hoàn tất; 1 điểm giảm 1.000đ, tối đa 20% đơn; tự hoàn điểm khi hủy |
| + | Tìm/lọc đơn | Lịch sử đơn và quản lý đơn | Mã đơn có/không `#`, nhóm trạng thái; admin tìm thêm tên không dấu và SĐT; nút xóa bộ lọc khi không khớp |
| + | Đánh giá sau mua | Chi tiết đơn và chi tiết món | Khách chấm 1–5 sao, nhận xét tối đa 500 ký tự cho món của đơn hoàn tất; realtime và không ghi trùng |

Luồng trạng thái đơn: `Chờ xác nhận → Đã xác nhận → Đang pha chế → Đang giao → Hoàn thành` (hoặc `Đã hủy` khi còn chờ xác nhận).

Mọi danh sách (menu, đơn, thông báo, chat) phân biệt 3 trạng thái: **đang tải** (vòng xoay), **lỗi** (thông báo + nút "Thử lại",
TalkBack tự đọc) và **trống thật**. Logo vẽ bằng code (`widgets/app_logo.dart`) dùng cho splash, đăng nhập, icon app Android
(adaptive + icon thông báo + màn chờ nền nâu) và icon web.

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
| `FavoriteProvider`, `LoyaltyProvider` | Yêu thích realtime, số dư và lịch sử tích/dùng/hoàn điểm |

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
├── unit/                     # giỏ hàng, mức đường/đá, đặt lại, trạng thái + theo dõi đơn, tìm không dấu,
│                             # validators, KPI, quản lý món (Firestore giả lập)
└── widget/                   # màn hình đăng nhập, màn lỗi có "Thử lại", tắt hiệu ứng
tool/seed_firestore.dart      # nạp dữ liệu mẫu lên Firestore
firestore.rules               # Security Rules (phân quyền phía server)
```

## 5. Thiết kế database (Cloud Firestore)

Firestore lưu dạng **collection → document** (giống JSON), không có bảng, JOIN hay AUTOINCREMENT như SQL.

| Collection (document id) | Trường chính | Ghi chú |
|------|-----------|---------|
| `users/{uid}` | name, email, phone, role (`customer`/`admin`) | uid do Firebase Auth cấp; mật khẩu do Firebase Auth giữ, không lưu ở đây |
| `users/{uid}/notifications/{auto}` | title, body, isRead, createdAt, orderId | Subcollection: thông báo của từng người. `orderId` (số, không bắt buộc) để bấm vào mở đúng đơn; thông báo cũ không có thì chỉ đánh dấu đã đọc |
| `categories/{id}` | id, name | id là số (`"1"`, `"2"`…) |
| `products/{id}` | id, categoryId, name, description, price, imageUrl, status (`available`/`soldOut`/`hidden`), deleted, previousStatus, deletedAt | Xóa mềm: `deleted = true`, giữ `previousStatus` để khôi phục |
| `toppings/{id}` | id, name, price | |
| `orders/{id}` | id, userId, customerName, phone, address, note, paymentMethod, isPaid, subtotal, pointsUsed, discountAmount, totalPrice, loyaltyAwarded, pointsRefunded, status, createdAt, **items[]** | Các món nằm luôn trong đơn (mảng `items`: productId, productName, size, toppings, sugar, ice, note, quantity, unitPrice). Field loyalty thiếu trên đơn cũ dùng mặc định an toàn. |
| `chats/{customerUid}` | customerName, lastMessage, lastTime | Danh sách cuộc trò chuyện của chủ quán đọc thẳng collection này (thay JOIN + GROUP BY) |
| `chats/{customerUid}/messages/{auto}` | sender (`customer`/`shop`), content, createdAt | |
| `counters/{name}` | value | Bộ đếm cấp mã đơn `#1, #2…` và id món / danh mục / topping mới, tăng trong transaction |
| `users/{uid}/favorites/{productId}` | productId, createdAt | Món yêu thích của riêng khách |
| `loyaltyAccounts/{uid}` | balance, lifetimeEarned, updatedAt, lastMutationKey, lastOrderId, lastMutationType | Tài khoản điểm; chỉ đổi cùng transaction đơn hàng và ledger |
| `loyaltyAccounts/{uid}/transactions/{orderId_action}` | orderId, type, points, createdAt | Sổ điểm bất biến; `earn`, `redeem`, `refund` |
| `products/{productId}/reviews/{orderId}` | userId, orderId, itemIndex, rating, comment, createdAt | Mua hàng đã hoàn tất; 1 review/món/đơn; số sao 1–5 và nhận xét tối đa 500 ký tự; không sửa/xóa |

- `items` lưu **tên + giá tại thời điểm đặt** → quán đổi giá menu thì lịch sử đơn vẫn đúng.
- Giá size cố định trong code (`utils/constants.dart`): S +0đ, M +6.000đ, L +10.000đ. Mức đường
  (100% / 70% / 50% / 30% / 0%) và mức đá (Bình thường / Ít đá / Không đá) cũng ở đó, không đổi giá.
- Đơn cũ vẫn đọc được; bản app có loyalty và đánh giá cần deploy `firestore.rules` mới trước khi nghiệm thu trên Firebase thật.
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
| Animation ngầm: `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedContainer`, `AnimatedScale` | Nhãn trạng thái, timeline, thanh tiến độ, dấu tích màn thành công, nút giỏ nổi (`utils/motion.dart`) | Trạng thái đổi có chuyển tiếp ngắn (~200 ms, chỉ mờ + phóng) thay vì nhảy cụt |
| `AnimationController` + `TweenSequence` | Số trên nút giỏ nảy 1 nhịp khi thêm món (`widgets/cart_button.dart`) | Phản hồi rõ "đã thêm vào giỏ" |
| `Hero` | Ảnh món bay từ thẻ Menu sang màn chi tiết | Giữ mạch nhìn khi chuyển màn |
| `MediaQuery.disableAnimationsOf` | Người dùng bật "Tắt hiệu ứng" trong Cài đặt → mọi hiệu ứng trên = 0 ms | Hỗ trợ người dễ chóng mặt |
| `Semantics(liveRegion: true)` | Màn lỗi có "Thử lại" được TalkBack đọc ngay | Trợ năng |
| `HapticFeedback.lightImpact` | Rung nhẹ khi thêm vào giỏ | Cảm giác bấm thật |
| `CustomPainter` + xuất PNG | Logo vẽ bằng code, xuất thành icon app Android / web | Không cần phần mềm đồ họa, một nguồn cho mọi cỡ |
| Adaptive icon, icon thông báo, màn chờ Android 12 | `res/mipmap-anydpi-v26`, `drawable-*/ic_stat_cafe`, `values-v31` | Icon đúng chuẩn Android (thông báo phải là hình trắng trong suốt) |
| Chuẩn hóa chữ tiếng Việt (bỏ dấu, cả dạng NFD) | Tìm món không cần gõ dấu (`utils/text_search.dart`) | Người Việt hay gõ không dấu |
| Dart 3: record, `firstOrNull`, `'k': ?v` (null-aware element) | `cartItemsFromOrder` trả record; field không bắt buộc chỉ ghi khi có giá trị | Code ngắn, không ghi field null lên Firestore |

## 8. Kịch bản demo gợi ý (15 phút)

Chuẩn bị 2 máy: máy A (điện thoại / máy ảo) đăng nhập khách, máy B (Chrome hoặc điện thoại khác) đăng nhập chủ quán.

1. Mở app → Splash (logo Mộc Cafe) → Login. Đăng ký tài khoản mới (thử nhập sai để thấy validate).
2. Máy A (khách) → Menu: lọc danh mục, gõ "tra sua" (không dấu) → bấm món (ảnh bay sang) → size L, 2 topping,
   **đường 70%, ít đá** → Thêm vào giỏ (rung nhẹ, số trên nút giỏ nảy, nút "Xem giỏ · …" hiện ở góc).
3. Máy B (chủ quán) → Quản lý sản phẩm: báo "Hết hàng" 1 món → máy A thấy món biến mất khỏi menu.
4. Máy A: Xem giỏ → Đặt hàng (địa chỉ tự điền từ đơn trước) → MoMo → màn **"Đặt hàng thành công"** có mã đơn.
   Máy B: hiện thông báo "Đơn mới #…" và badge trên tab Đơn hàng.
5. Máy A bấm **"Theo dõi đơn"**. Máy B chuyển trạng thái từng bước → timeline máy A đổi ngay có hiệu ứng;
   quay về Menu thấy thẻ "Đơn đang thực hiện" chạy theo.
6. Máy A → tab Thông báo → **bấm 1 thông báo → mở đúng đơn đó**. Đơn hoàn thành → **"Đặt lại"** → giỏ có lại đúng các món.
7. Chat: máy A nhắn quán → máy B trả lời → tin hiện ngay hai bên.
8. Máy B: Tổng quan kinh doanh (doanh thu, món bán chạy).
9. Tắt app mở lại → vẫn giữ đăng nhập (Firebase Auth) + chế độ tối. Chạy `flutter test`, mở APK release trên máy.

## 9. Hạn chế & hướng phát triển

- Thông báo chỉ hiện khi app khách đang mở (hoặc chạy nền); muốn báo cả khi đã tắt app thì cần
  Firebase Cloud Messaging + Cloud Functions (phải lên gói Blaze trả phí).
- Ảnh món dùng ảnh có sẵn trong app hoặc link http; tải ảnh từ điện thoại lên cần Cloud Storage (gói Blaze).
- Thống kê đọc mọi đơn trong khoảng thời gian rồi cộng trên máy chủ quán; nhiều đơn thì nên dùng aggregate query.
- Chủ quán xác định bằng 1 email cố định; nhiều nhân viên thì nên dùng custom claims của Firebase Auth.
- Thanh toán chỉ là giả lập → có thể tích hợp SDK MoMo / VNPay.
- Không dùng Cloud Functions: Security Rules bảo vệ quan hệ điểm–đơn và giới hạn giảm; việc đối chiếu toàn bộ giá từng item với menu vẫn được repository kiểm tra phía client.
