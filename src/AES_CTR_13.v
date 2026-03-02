module AES256_CTR_13 (
    input                       clk,
    input                       rst_n,
    input                       enable,
    input                       valid_in,
    input        [1663:0]       plaintext,
    input        [127:0]        nonce,
    input        [255:0]        key,
    output reg   [1679:0]       ciphertext,
    output reg                  valid_out,
    output reg                  done_out
);

    // Registers nội bộ
    reg [255:0] key_reg;
    reg [127:0] nonce_reg;
    reg         ena_sub;
    reg         is_processing;

    //
    reg [127:0] p_block0,  p_block1,  p_block2,  p_block3;
    reg [127:0] p_block4,  p_block5,  p_block6,  p_block7;
    reg [127:0] p_block8,  p_block9,  p_block10, p_block11;
    reg [127:0] p_block12;

    // Logic chốt dữ liệu 
    wire trigger = enable && valid_in && !is_processing;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_reg       <= 256'b0;
            nonce_reg     <= 128'b0;
            ena_sub       <= 1'b0;
            is_processing <= 1'b0;
            // Reset 13 blocks
            p_block0 <= 0; p_block1 <= 0; p_block2 <= 0; p_block3 <= 0;
            p_block4 <= 0; p_block5 <= 0; p_block6 <= 0; p_block7 <= 0;
            p_block8 <= 0; p_block9 <= 0; p_block10<= 0; p_block11<= 0;
            p_block12<= 0;
        end else if (trigger) begin
            key_reg       <= key;
            nonce_reg     <= nonce;
            ena_sub       <= 1'b1;
            is_processing <= 1'b1;
            // Chốt 1664 bit plaintext 
            p_block0  <= plaintext[127:0];
            p_block1  <= plaintext[255:128];
            p_block2  <= plaintext[383:256];
            p_block3  <= plaintext[511:384];
            p_block4  <= plaintext[639:512];
            p_block5  <= plaintext[767:640];
            p_block6  <= plaintext[895:768];
            p_block7  <= plaintext[1023:896];
            p_block8  <= plaintext[1151:1024];
            p_block9  <= plaintext[1279:1152];
            p_block10 <= plaintext[1407:1280];
            p_block11 <= plaintext[1535:1408];
            p_block12 <= plaintext[1663:1536];
        end else begin
            ena_sub <= 1'b0;
            if (done_out) is_processing <= 1'b0;
        end
    end

    // Key Expansion 
    wire [127:0] rk_bus;
    wire         rk_valid;
    wire         rk_first;
    wire         rk_final;

    AES256_KeyExp key_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .keyex_ena(ena_sub),
        .key_in(key_reg),
        .rk_out(rk_bus),
        .rk_valid(rk_valid),
        .done(), 
        .rk_first(rk_first),
        .rk_final(rk_final)
    );

    // 13 Submodules AES-256
    wire [127:0] keystream [0:12];
    wire [12:0]  aes_done_bus;
    
    genvar i;
    generate
        for (i = 0; i < 13; i = i + 1) begin : aes_parallel
            AES256_Encrypt aes_inst (
                .clk(clk),
                .rst_n(rst_n),
                .enc_ena(ena_sub),
                .plaintext(nonce_reg + i), 
                .rk_in(rk_bus),
                .rk_valid(rk_valid),
                .rk_first(rk_first),   
                .rk_final(rk_final),   
                .ciphertext(keystream[i]), 
                .done(aes_done_bus[i])
            );
        end
    endgenerate

    // Logic XOR và Ghép kết quả đầu ra
    wire all_done = aes_done_bus[0]; 
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ciphertext <= 1680'b0;
            valid_out  <= 1'b0;
            done_out   <= 1'b0;
        end else if (all_done && is_processing) begin
            // XOR Plaintext_i với Keystream_i 
            ciphertext[127:0]     <= p_block0  ^ keystream[0];
            ciphertext[255:128]   <= p_block1  ^ keystream[1];
            ciphertext[383:256]   <= p_block2  ^ keystream[2];
            ciphertext[511:384]   <= p_block3  ^ keystream[3];
            ciphertext[639:512]   <= p_block4  ^ keystream[4];
            ciphertext[767:640]   <= p_block5  ^ keystream[5];
            ciphertext[895:768]   <= p_block6  ^ keystream[6];
            ciphertext[1023:896]  <= p_block7  ^ keystream[7];
            ciphertext[1151:1024] <= p_block8  ^ keystream[8];
            ciphertext[1279:1152] <= p_block9  ^ keystream[9];
            ciphertext[1407:1280] <= p_block10 ^ keystream[10];
            ciphertext[1535:1408] <= p_block11 ^ keystream[11];
            ciphertext[1663:1536] <= p_block12 ^ keystream[12];
            
            // Append 16-bit 0 (Padding)
            ciphertext[1679:1664] <= 16'h0000;
            
            valid_out <= 1'b1;
            done_out  <= 1'b1;
        end else begin
            valid_out <= 1'b0;
            done_out  <= 1'b0;
        end
    end

endmodule