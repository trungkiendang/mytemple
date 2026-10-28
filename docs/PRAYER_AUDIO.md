# Thêm bản thu âm (giọng thiền sư, giọng tụng) cho bài khấn

Ứng dụng có chế độ **Bản thu**: phát một file âm thanh và chạy chữ karaoke theo vị trí phát. Chế độ chỉ xuất hiện với bài khấn có khai báo `audio`.

## Lưu ý bản quyền
Các bản tụng/đọc của các thiền sư (Plum Village, Thích Trí Quảng, … ) là sản phẩm có bản quyền; app **không đi kèm** bản thu nào và không nên tự tải về để đóng gói. Chỉ dùng:
- bản thu bạn tự thu, hoặc được chủ sở hữu **cho phép bằng văn bản** (nên lưu lại thư/giấy phép);
- bản thu giấy phép mở (CC BY / CC0 / public domain) – ghi rõ nguồn và giấy phép trong `audioCredit`.

## Cách thêm
1. Đặt file (mp3/m4a, nên < 3 MB) vào `assets/audio/prayers/`, ví dụ `khan-ram.mp3`.
2. Trong `assets/data/prayers.json`, thêm vào bài tương ứng:
   ```json
   "audio": "audio/prayers/khan-ram.mp3",
   "audioCredit": "Giọng đọc: Tên người đọc – giấy phép / nguồn"
   ```
3. Chạy lại app: trong màn chọn bài sẽ có nút **Bản thu**.

Chữ chạy được chia theo độ dài từng câu trên tổng thời lượng file (`lineEndsMs`), nên bản thu nên đọc đều và đúng thứ tự các câu của bài; câu để người dùng tự xưng (họ tên, địa chỉ) tính như một khoảng dừng.
