# Bằng chứng đóng góp — Vương Minh Quân (DE190747)

Ngày đối chiếu: 03/11/2026. Nhánh nộp: `master`. Git author hiện tại: `Ashleybemy <quanvuong22122005@gmail.com>`. Không đổi tác giả hoặc viết lại lịch sử của thành viên khác. Các chức năng nền tảng, Firebase migration, admin sản phẩm và test từ remote giữ nguyên ghi nhận của tác giả gốc.

## Phần việc mới và commit

| Commit | Phần việc có thể kiểm chứng |
| --- | --- |
| `9ca0d76` | Model điểm, các transaction redeem/earn/refund, account/ledger, favorite data/provider và test policy/repository/dashboard |
| `01ee5c9` | Hub thành viên, nút tim trên menu, checkout dùng điểm, dashboard giảm điểm, đăng xuất và xử lý lỗi yêu thích |
| `ad583e9` | Backend review xác minh đơn/món, Rules bảo vệ review và loyalty, request test Emulator |
| `aeb83b7` | Tìm/lọc đơn khách và admin, tìm tên không dấu/SĐT, empty state, test |
| `460173a` | Gửi review từ đơn completed, giao diện chọn sao/nhận xét, cập nhật review realtime và widget test |
| `c3dc037` | Review/điểm trung bình và nút tim trên màn chi tiết món, test tích hợp màn desktop |
| `a2a5186` | Giảm bộ nhớ và worker Gradle, tương thích Dart SDK và API Flutter, sửa cảnh báo analyzer |
| Commit chứa tài liệu này (`docs: record phase validation and contribution evidence`) | Schema, demo, phụ lục báo cáo, bằng chứng đóng góp và công cụ smoke web bằng Chrome headless |

Commit `f25669a` là merge đồng bộ code mới, xử lý conflict menu/lockfile và giữ các test mới của nhóm. Không tính merge đó như một chức năng. Các thay đổi có hỗ trợ AI; cần hiểu code và tự trình bày, demo phần việc nhận phụ trách.

## Tỷ lệ Git sau commit tài liệu cuối

Sau khi tích hợp `origin/master` tại `658ae9c` và hoàn thành 8 commit nội dung ở trên:

- Có tính merge: 10/39 commit thuộc email của Quân = **25,64%** (bao gồm 2 merge, không gọi chúng là 2 chức năng).
- Không tính merge: 8/27 commit = **29,63%**.
- Đây là tỷ lệ trong lịch sử reachable từ local `master`, chưa phải xác nhận biểu đồ GitHub. Remote có commit mới hoặc GitHub lọc cách khác thì tỷ lệ cần tính lại. GitHub còn cần email được liên kết đúng tài khoản.

Kiểm tra lại bằng:

```sh
git rev-list --count HEAD
git shortlog -sne HEAD
git rev-list --count --no-merges HEAD
git shortlog -sne --no-merges HEAD
```

## Đóng góp trong báo cáo

Đề xuất ghi Quân phụ trách Loyalty, Customer Feedback, tìm đơn, Rules/test/tài liệu tương ứng ở mức **25% công việc**, chờ nhóm thống nhất. Đây không phải mức tự suy ra từ số commit. Không tự thay các tỷ lệ của ba người còn lại hoặc các topic phân tích/thiết kế khi chưa đánh giá lại. Nội dung bổ sung cho báo cáo nằm trong `REPORT_ADDENDUM.md`; file Word gốc được giữ nguyên để nhóm duyệt phụ lục trước khi ghép.

## Nghiệm thu thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| Dart analyzer | No issues found sau merge |
| Flutter unit/widget | 97/97 pass sau merge, bao gồm test mới từ nhóm |
| Firestore Emulator requests | Pass: ownership, review đồng thời, validation, ledger bất biến, đổi/tích/hoàn nguyên tử, chống lặp, account mới, đơn cũ |
| Web release | Build thành công sau merge, CanvasKit cục bộ |
| Chrome headless smoke | Pass: app render đăng nhập, submit trống hiển thị cả 2 lỗi, không lỗi runtime/tài nguyên; ảnh `build/web-smoke.png` |
| Android debug | Gradle assembleDebug thành công; không chạy máy ảo Android |
| Bộ widget trên `--platform chrome` | Chưa pass do lỗi đường dẫn/CanvasKit của SDK Windows; không nhập chung với kết quả smoke release |
| Hai tài khoản trên Firebase thật / deploy Rules | Chưa thực hiện; cần người quản lý Firebase duyệt deploy và nghiệm thu |

Hướng dẫn chạy lại và kịch bản trình bày: `PHASE_DEMO.md`. Không lưu khóa/tệp `.env`, dữ liệu khách thật hoặc nhật ký hệ thống vào commit.
