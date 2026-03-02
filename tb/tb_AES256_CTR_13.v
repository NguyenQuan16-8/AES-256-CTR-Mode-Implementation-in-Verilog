`timescale 1ns/1ps

module tb_AES256_CTR_13();

    // --- 1. Signals ---
    reg                 clk;
    reg                 rst_n;
    reg                 enable;
    reg                 valid_in;
    reg  [1663:0]       plaintext;
    reg  [127:0]        nonce;
    reg  [255:0]        key;
    
    wire [1679:0]       ciphertext; 
    wire                valid_out;
    wire                done_out;

    reg [1663:0]        orig_p;
    reg [1679:0]        saved_c;

    integer i; 

    // --- 2. Instantiate DUT ---
    AES256_CTR_13 dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .enable(enable), 
        .valid_in(valid_in),
        .plaintext(plaintext), 
        .nonce(nonce), 
        .key(key),
        .ciphertext(ciphertext), 
        .valid_out(valid_out), 
        .done_out(done_out)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    // --- 3. Helper Task ---
    task drive_input(input [255:0] i_key, input [127:0] i_nonce, input [1663:0] i_p);
    begin
        @(posedge clk);
        enable   <= 1;
        valid_in <= 1;
        key      <= i_key;
        nonce    <= i_nonce;
        plaintext<= i_p;
        @(posedge clk);
        valid_in <= 0;
    end
    endtask

    // --- 4. Main Test Sequence ---
    initial begin
        // Khởi tạo
        clk = 0; rst_n = 0; enable = 0; valid_in = 0;
        plaintext = 0; nonce = 0; key = 0;
        orig_p = 0; saved_c = 0;
        
        #20 rst_n = 1; #20;

        // [TC-02] COUNTER ROLLOVER TEST
        $display("\n[TC-02] COUNTER ROLLOVER TEST");
        drive_input(
            256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4, 
            128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFE, 
            {13{128'h0}} 
        );
        wait(done_out);
        #10;
        $display(">> Done at %t. Check block rollover in Waveform.", $time);
        $display(">> Ciphertext Block 2 (Nonce 0): %h", ciphertext[383:256]);


        // [TC-03] ROUND-TRIP (ENC -> DEC) TEST
        $display("\n[TC-03] ROUND-TRIP (ENC -> DEC) TEST");
        
        // Sửa lỗi: Khai báo i đã đưa ra ngoài, ở đây chỉ sử dụng
        for (i = 0; i < 52; i = i + 1) begin
            orig_p[i*32 +: 32] = $random;
        end

        drive_input(256'hABC123456789, 128'h5555AAAA5555AAAA, orig_p);
        
        @(posedge clk); 
        wait(done_out);
        saved_c = ciphertext; 
        
        #100;
        $display(">> Re-feeding ciphertext for decryption...");
        drive_input(256'hABC123456789, 128'h5555AAAA5555AAAA, saved_c[1663:0]); 
        
        @(posedge clk);
        wait(done_out);
        
        #10;
        if (ciphertext[1663:0] === orig_p)
            $display(">> PASS: 13 Blocks Recovered Successfully!");
        else begin
            $display(">> FAIL: Data mismatch!");
            $display(">> Sent: %h", orig_p[127:0]);
            $display(">> Got : %h", ciphertext[127:0]);
        end


        // [TC-04] RESET DURING OPERATION TEST
        $display("\n[TC-04] RESET DURING OPERATION TEST");
        drive_input(256'hFFFF, 128'hEEEE, {13{128'h1234}});
        #50; 
        rst_n = 0;
        #20 rst_n = 1;
        
        #5;
        if (done_out == 0)
            $display(">> PASS: Reset successful during operation.");
        else
            $display(">> FAIL: System state not cleared.");

        #100 $display("\n--- ALL TESTS COMPLETED ---");
        $finish;
    end

endmodule