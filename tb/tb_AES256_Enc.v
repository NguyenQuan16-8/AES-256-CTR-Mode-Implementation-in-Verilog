`timescale 1ns / 1ps

module tb_AES256_Enc;
    // Clock & Reset
    reg clk;
    reg rst_n;

    // Inputs
    reg [255:0] key_in;
    reg [127:0] plaintext;
    reg         start;

    // Internal Wires (Kết nối 2 module)
    wire [127:0] rk_bus;
    wire         rk_vld;
    wire         c_first, c_final;
    wire [127:0] ciphertext;
    wire         done;

    // Golden Reference (AES-256)
    // Key: 603deb10...dff4 | PT: 00112233...eeff
    reg [127:0] golden_ref = 128'h8ea2b7ca516745bfeafc49904b496089;

    // ---------------------------------------------------------
    // 1. Instantiate Key Expansion
    // ---------------------------------------------------------
    AES256_KeyExp key_gen (
        .clk(clk),
        .rst_n(rst_n),
        .keyex_ena(start),
        .key_in(key_in),
        .rk_out(rk_bus),
        .rk_valid(rk_vld),
        .done(),             // Không dùng ở mức top
        .ctrl_first(c_first),
        .ctrl_final(c_final)
    );

    // ---------------------------------------------------------
    // 2. Instantiate Encrypt Core
    // ---------------------------------------------------------
    AES256_Encrypt encrypt_core (
        .clk(clk),
        .rst_n(rst_n),
        .enc_ena(start),
        .plaintext(plaintext),
        .rk_in(rk_bus),
        .rk_valid(rk_vld),
        .ctrl_first(c_first),
        .ctrl_final(c_final),
        .ciphertext(ciphertext),
        .done(done)
    );

    // Clock generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // Test Procedure
    // ---------------------------------------------------------
    initial begin
        // Init signals
        clk = 0;
        rst_n = 0;
        start = 0;
        key_in = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        plaintext = 128'h00112233445566778899aabbccddeeff;

        // Reset
        #20 rst_n = 1;
        #20;

        // Trigger Encryption
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Chờ module Encrypt báo Done
        wait(done);
        
        #10;
        $display("\n==================================================");
        $display("AES-256 TEST RESULT:");
        $display("Plaintext : %h", plaintext);
        $display("Key       : %h", key_in);
        $display("Ciphertext: %h", ciphertext);
        $display("Golden    : %h", golden_ref);
        
        if (ciphertext === golden_ref) begin
            $display(">>> STATUS: PASSED! <<<");
        end else begin
            $display(">>> STATUS: FAILED! <<<");
        end
        $display("==================================================\n");

        #50 $finish;
    end

    // Monitor (Optional) - Để xem từng Round Key chạy qua
    
    always @(posedge clk) begin
        if (rk_vld) 
            $display("Time %t | RK: %h | First: %b | Final: %b", $time, rk_bus, c_first, c_final);
    end
    

endmodule