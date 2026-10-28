import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Quản lý kết nối SQLite (Module 9 - Local Storage).
// Dùng Singleton: cả app chỉ mở 1 kết nối database duy nhất.
class DatabaseHelper {
  DatabaseHelper._(); // constructor private -> bên ngoài không tạo mới được
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  // Lấy database, nếu chưa mở thì mở (lần đầu sẽ tạo bảng)
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cafe_app.db');
    return openDatabase(
      path,
      // version 2: thêm ảnh món. Máy đã cài bản 1 sẽ chạy onUpgrade, không cần gỡ app
      version: 2,
      // Bật khóa ngoại (SQLite mặc định tắt)
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Ảnh 14 món trong assets/images/products: phần tử thứ i là ảnh của món id = i + 1
  // (cùng thứ tự với danh sách món trong _insertSampleData)
  static const _productImages = [
    'assets/images/products/01_ca-phe-den-da.jpg',
    'assets/images/products/02_ca-phe-sua-da.jpg',
    'assets/images/products/03_bac-xiu.jpg',
    'assets/images/products/04_cappuccino.jpg',
    'assets/images/products/05_tra-sua-tran-chau-duong-den.jpg',
    'assets/images/products/06_tra-sua-truyen-thong.jpg',
    'assets/images/products/07_tra-sua-matcha.jpg',
    'assets/images/products/08_tra-sua-thai-xanh.jpg',
    'assets/images/products/09_tra-dao-cam-sa.jpg',
    'assets/images/products/10_tra-vai.jpg',
    'assets/images/products/11_tra-chanh-day.jpg',
    'assets/images/products/12_cookie-da-xay.jpg',
    'assets/images/products/13_matcha-da-xay.jpg',
    'assets/images/products/14_chocolate-da-xay.jpg',
  ];

  // Chỉ chạy trên máy đã có database cũ (điện thoại đã cài, IndexedDB của Chrome).
  // Chỉ điền ảnh cho món còn trống ảnh; không đụng tài khoản, đơn hàng, tin nhắn,
  // thông báo -> người dùng giữ nguyên dữ liệu.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final batch = db.batch();
      for (var i = 0; i < _productImages.length; i++) {
        batch.update(
          'products',
          {'imageUrl': _productImages[i]},
          where: "id = ? AND (imageUrl IS NULL OR imageUrl = '')",
          whereArgs: [i + 1],
        );
      }
      await batch.commit(noResult: true);
    }
  }

  // Chỉ chạy 1 lần khi cài app: tạo bảng + thêm dữ liệu mẫu
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price INTEGER NOT NULL,
        imageUrl TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE toppings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        customerName TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        note TEXT,
        paymentMethod TEXT NOT NULL,
        isPaid INTEGER NOT NULL,
        totalPrice INTEGER NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        size TEXT NOT NULL,
        toppings TEXT,
        note TEXT,
        quantity INTEGER NOT NULL,
        unitPrice INTEGER NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await _insertSampleData(db);
  }

  // Dữ liệu mẫu: tài khoản demo, danh mục, món, topping
  Future<void> _insertSampleData(Database db) async {
    // Batch: gom nhiều lệnh insert, chạy 1 lần cho nhanh
    final batch = db.batch();

    // --- Tài khoản ---
    batch.insert('users', {
      'name': 'Chủ quán',
      'email': 'admin@cafe.com',
      'password': 'admin123',
      'phone': '0905123456',
      'role': 'admin',
    });
    batch.insert('users', {
      'name': 'Nguyễn Văn A',
      'email': 'khach@gmail.com',
      'password': '123456',
      'phone': '0912345678',
      'role': 'customer',
    });

    // --- Danh mục (id tự tăng: 1, 2, 3, 4) ---
    for (final name in ['Cà phê', 'Trà sữa', 'Trà trái cây', 'Đá xay']) {
      batch.insert('categories', {'name': name});
    }

    // --- Món: [categoryId, tên, mô tả, giá size S] ---
    final products = [
      [1, 'Cà phê đen đá', 'Cà phê phin truyền thống, đậm vị', 25000],
      [1, 'Cà phê sữa đá', 'Cà phê phin pha cùng sữa đặc', 29000],
      [1, 'Bạc xỉu', 'Nhiều sữa, ít cà phê, vị béo nhẹ', 32000],
      [1, 'Cappuccino', 'Espresso với sữa tươi đánh bọt', 45000],
      [2, 'Trà sữa trân châu đường đen', 'Trà sữa béo cùng trân châu đường đen', 39000],
      [2, 'Trà sữa truyền thống', 'Trà đen pha sữa, vị cổ điển', 35000],
      [2, 'Trà sữa matcha', 'Matcha Nhật Bản kết hợp sữa tươi', 42000],
      [2, 'Trà sữa Thái xanh', 'Trà Thái xanh thơm mát', 35000],
      [3, 'Trà đào cam sả', 'Trà đào, cam tươi và sả thơm', 42000],
      [3, 'Trà vải', 'Trà xanh với vải thiều ngọt thanh', 39000],
      [3, 'Trà chanh dây', 'Chanh dây chua ngọt, giải nhiệt', 35000],
      [4, 'Cookie đá xay', 'Bánh cookie xay cùng sữa và kem', 49000],
      [4, 'Matcha đá xay', 'Matcha xay mịn phủ kem tươi', 49000],
      [4, 'Chocolate đá xay', 'Chocolate đậm đà xay cùng đá', 49000],
    ];
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      batch.insert('products', {
        'categoryId': p[0],
        'name': p[1],
        'description': p[2],
        'price': p[3],
        'imageUrl': _productImages[i], // món thứ i có id = i + 1
      });
    }

    // --- Topping ---
    final toppings = {
      'Trân châu đen': 5000,
      'Trân châu trắng': 7000,
      'Thạch trái cây': 5000,
      'Pudding trứng': 8000,
      'Kem cheese': 10000,
    };
    toppings.forEach((name, price) {
      batch.insert('toppings', {'name': name, 'price': price});
    });

    await batch.commit(noResult: true);
  }
}
