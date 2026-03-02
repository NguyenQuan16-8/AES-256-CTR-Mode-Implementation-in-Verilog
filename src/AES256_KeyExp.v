module AES256_KeyExp (
    input               clk,
    input               rst_n,
    input               keyex_ena,     
    input        [255:0] key_in,
    output reg   [127:0] rk_out,
    output reg           rk_valid,
    output reg           done,
    output reg          rk_first, 
    output reg          rk_final
);

    // Registers
    reg [31:0] w0, w1, w2, w3, w4, w5, w6, w7;
    reg [7:0]  rcon;
    reg        phase; 
    reg        busy;
    reg        is_rk1; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rk_first <= 0;
        end else begin
            rk_first <= keyex_ena; 
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rk_final <= 0;
        end else if (keyex_ena) begin
        rk_final <= 0;
        end else begin
        rk_final <= (~phase & rcon[6]); 
        end
    end
    // Datapath 
    wire [31:0] last_w   = w7;
    wire [31:0] sbox_in  = phase ? last_w : {last_w[23:0], last_w[31:24]};
    wire [31:0] sbox_out;

    AES_SBOX sb0(.sbox_in(sbox_in[31:24]), .sbox_out(sbox_out[31:24]));
    AES_SBOX sb1(.sbox_in(sbox_in[23:16]), .sbox_out(sbox_out[23:16]));
    AES_SBOX sb2(.sbox_in(sbox_in[15:8]),  .sbox_out(sbox_out[15:8]));
    AES_SBOX sb3(.sbox_in(sbox_in[7:0]),   .sbox_out(sbox_out[7:0]));

    wire [31:0] sub_func = phase ? sbox_out : (sbox_out ^ {rcon, 24'b0});
    
    wire [31:0] n_w0 = w0 ^ sub_func;
    wire [31:0] n_w1 = w1 ^ n_w0;
    wire [31:0] n_w2 = w2 ^ n_w1;
    wire [31:0] n_w3 = w3 ^ n_w2;

    // Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy   <= 0;
            done   <= 0;
            is_rk1 <= 0;
        end else if (keyex_ena) begin
            busy   <= 1;
            done   <= 0;
            is_rk1 <= 1; 
        end else if (busy) begin
            is_rk1 <= 0; 
            if (rk_final) begin 
                busy <= 0;
                done <= 1;
            end
        end else begin
            done <= 0;
        end
    end

    // RCON và Phase
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rcon  <= 8'h01;
            phase <= 0;
        end else if (keyex_ena) begin
            rcon  <= 8'h01;
            phase <= 0;
        end else if (busy && ~is_rk1) begin
            if (phase) 
                rcon <= {rcon[6:0], 1'b0};
            phase <= ~phase;
        end
    end

    // Khối Cập nhật thanh ghi 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {w0, w1, w2, w3, w4, w5, w6, w7} <= 256'b0;
        end else if (keyex_ena) begin
            {w0,w1,w2,w3,w4,w5,w6,w7} <= key_in;
        end else if (busy && !is_rk1) begin
            w0 <= w4;   
            w1 <= w5;   
            w2 <= w6;   
            w3 <= w7;
            w4 <= n_w0; 
            w5 <= n_w1; 
            w6 <= n_w2; 
            w7 <= n_w3;
        end
    end

    // Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rk_out   <= 128'b0;
            rk_valid <= 0;
        end else if (keyex_ena) begin
            rk_out   <= key_in[255:128]; 
            rk_valid <= 1;
        end else if (busy) begin
            rk_valid <= 1;
            if (is_rk1) 
                rk_out <= {w4, w5, w6, w7}; 
            else 
                rk_out <= {n_w0, n_w1, n_w2, n_w3}; 
        end else begin
            rk_valid <= 0;
        end
    end

endmodule