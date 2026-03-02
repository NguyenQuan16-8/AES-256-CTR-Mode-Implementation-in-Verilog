# AES-256-CTR-Mode-Implementation-in-Verilog
Dự án thiết kế bộ mã hóa/giải mã AES-256 hoạt động ở chế độ Counter (CTR) bằng ngôn ngữ Verilog. Thiết kế được tối ưu hóa cho phần cứng (FPGA/ASIC) với khả năng xử lý song song và độ trễ thấp.


##  Tính năng chính (Key Features)
* **Algorithm:** AES-256 (Key 256-bit, 14 rounds).
* **Mode:** CTR (Counter Mode).
* **Architecture:** Tối ưu hóa cho hiệu suất
* **Language:** Verilog HDL.

##  Cấu trúc thư mục (Project Structure)
* `src/`: Chứa mã nguồn thiết kế (.v).
* `tb/`: Chứa Testbench và các vector thử nghiệm.
* `docs/`: Tài liệu thiết kế và sơ đồ khối.

##  Hướng dẫn chạy mô phỏng
Sử dụng ModelSim/QuestaSim:
1. Mở terminal tại thư mục dự án.
2. Chạy lệnh:
   ```bash
   vlib work
   vlog src/*.v tb/*.v
   vsim -c tb_aes_ctr -do "run -all; quit"
