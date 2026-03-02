module AES256_Encrypt (
    input               clk,
    input               rst_n,
    input               enc_ena,    
    input        [127:0] plaintext,  
    input        [127:0] rk_in,      
    input                rk_valid,   
    input                rk_first, 
    input                rk_final,
    output reg   [127:0] ciphertext,
    output reg           done
);

    // Registers & Internal Signals
    reg [127:0] state;
    reg         busy;

    // 2. Datapath 
    wire [127:0] s_box;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_parallel
            AES_SBOX sbox_inst (.sbox_in(state[i*8 +: 8]), .sbox_out(s_box[i*8 +: 8]));
        end
    endgenerate

    // ShiftRows 
    wire [127:0] s_row;
    assign s_row[127:120] = s_box[127:120]; 
    assign s_row[119:112] = s_box[87:80];
    assign s_row[111:104] = s_box[47:40];  
    assign s_row[103:96]  = s_box[7:0];
    assign s_row[95:88]   = s_box[95:88];   
    assign s_row[87:80]   = s_box[55:48];
    assign s_row[79:72]   = s_box[15:8];    
    assign s_row[71:64]   = s_box[103:96];
    assign s_row[63:56]   = s_box[63:56];   
    assign s_row[55:48]   = s_box[23:16];
    assign s_row[47:40]   = s_box[111:104]; 
    assign s_row[39:32]   = s_box[71:64];
    assign s_row[31:24]   = s_box[31:24];   
    assign s_row[23:16]   = s_box[119:112];
    assign s_row[15:8]    = s_box[79:72];   
    assign s_row[7:0]     = s_box[39:32];

    // MixColumns 
    wire [127:0] m_col;
    generate
        for (i = 0; i < 4; i = i + 1) begin : mix_cols
            AES_Mixcol mc_inst (.col_in(s_row[i*32 +: 32]), .col_out(m_col[i*32 +: 32]));
        end
    endgenerate

    // Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= 128'b0;
            busy            <= 0;
            done            <= 0;
            ciphertext      <= 128'b0;
        end else if (enc_ena) begin
            busy            <= 1;
            done            <= 0;
        end else if (busy && rk_valid) begin
            if (rk_first) begin
                state           <= plaintext ^ rk_in;
            end else if (!rk_final) begin
                // Các vòng 1-13 (Full Round)
                state           <= m_col ^ rk_in;
            end else begin
                // Vòng 14 (Final Round - Không MixColumns)
                ciphertext      <= s_row ^ rk_in;
                busy            <= 0;
                done            <= 1;
            end
        end else begin
            done <= 0;
        end
    end

endmodule