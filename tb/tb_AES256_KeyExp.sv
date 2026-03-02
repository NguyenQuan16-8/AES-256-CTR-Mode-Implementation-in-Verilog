`timescale 1ns/1ps

module tb_AES256_KeyExp();

    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] key_in;
    
    wire [127:0] rk_out;
    wire rk_valid;
    wire done;

    //  Khởi tạo Clock (100MHz) 
    initial clk = 0;
    always #5 clk = ~clk;

    //  Instantiate Unit Under Test (UUT) 
    AES256_KeyExp uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key_in(key_in),
        .rk_out(rk_out),
        .rk_valid(rk_valid),
        .done(done)
    );

    integer rk_count = 0;

    initial begin
        // Khởi tạo
        rst_n = 0;
        start = 0;
        key_in = 256'b0;
        
        #20 rst_n = 1;
        #10;

        //  VECTOR TEST 1: NIST FIPS-197 Example 
        // Key: 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
        $display("\n TEST START: NIST VECTOR ");
        key_in = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
        start = 1;
        #10 start = 0; // Tín hiệu Start chỉ cần 1 chu kỳ

        wait(done);
        #20;
        $display(" TEST FINISHED \n");
        
        $stop; 
    end

    // Monitor 
    always @(posedge clk) begin
        if (rk_valid) begin
            $display("Time=%0t | RoundKey[%0d] = %h", $time, rk_count, rk_out);
            rk_count <= rk_count + 1;
        end
        if (done) begin
            rk_count <= 0;
        end
    end

endmodule