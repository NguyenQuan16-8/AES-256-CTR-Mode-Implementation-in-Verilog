module AES_Mixcol(
  input  wire [31:0] col_in,
  output wire [31:0] col_out
);
  wire [7:0] s0 = col_in[31:24];
  wire [7:0] s1 = col_in[23:16];
  wire [7:0] s2 = col_in[15:8];
  wire [7:0] s3 = col_in[7:0];

  wire [7:0] s0_2, s1_2, s2_2, s3_2;
  mul2 u0 (.mul2_in(s0), .mul2_out(s0_2));
  mul2 u1 (.mul2_in(s1), .mul2_out(s1_2));
  mul2 u2 (.mul2_in(s2), .mul2_out(s2_2));
  mul2 u3 (.mul2_in(s3), .mul2_out(s3_2));

  wire [7:0] s0_3 = s0_2 ^ s0;
  wire [7:0] s1_3 = s1_2 ^ s1;
  wire [7:0] s2_3 = s2_2 ^ s2;
  wire [7:0] s3_3 = s3_2 ^ s3;

  wire [7:0] o0 = (s0_2 ^ s1_3) ^ (s2 ^ s3);    // 2so + 3s1 + s2 + s3
  wire [7:0] o1 = (s0 ^ s1_2) ^ (s2_3 ^ s3);    // s0 + 2s1 + 3s2 + s3
  wire [7:0] o2 = (s0 ^ s1)   ^ (s2_2 ^ s3_3);  // s0 + s1 + 2s2 + 3s3
  wire [7:0] o3 = (s0_3 ^ s1) ^ (s2 ^ s3_2);    // 3s0 + s1 + s2 + 2s3

  assign col_out = {o0, o1, o2, o3};
endmodule
