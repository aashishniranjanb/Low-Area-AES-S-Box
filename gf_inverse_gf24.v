// =========================================================================
// SUBMODULE: 8-bit Composite Field Inverse
// =========================================================================
module gf_inverse_gf24 (
    input  wire [7:0] in,
    output wire [7:0] out
);
    wire [3:0] ah, al;
    wire [3:0] ah_sq_scale, al_sq, ah_al_mult;
    wire [3:0] inv_in, inv_out;
    wire [3:0] out_ah, out_al;

    // Split the 8-bit input into two 4-bit nibbles
    assign ah = in[7:4];
    assign al = in[3:0];

    // 1. GF(2^4) Squaring and Scaling of the upper nibble
    assign ah_sq_scale[3] = ah[3] ^ ah[2] ^ ah[1];
    assign ah_sq_scale[2] = ah[3] ^ ah[0];
    assign ah_sq_scale[1] = ah[3] ^ ah[2];
    assign ah_sq_scale[0] = ah[2] ^ ah[1] ^ ah[0];

    // 2. GF(2^4) Squaring of the lower nibble
    assign al_sq[3] = al[3] ^ al[1];
    assign al_sq[2] = al[2] ^ al[0];
    assign al_sq[1] = al[3] ^ al[2];
    assign al_sq[0] = al[1] ^ al[0];

    // 3. GF(2^4) Multiplication of ah and al
    gf_mult_gf24 u_mult1 (.a(ah), .b(al), .c(ah_al_mult));

    // 4. Summation to create the input for the 4-bit inverse
    assign inv_in = ah_sq_scale ^ al_sq ^ ah_al_mult;

    // 5. GF(2^4) Inversion (The core math)
    gf_inv_4bit u_inv4 (.in(inv_in), .out(inv_out));

    // 6. Final GF(2^4) Multiplications to generate the 8-bit output
    gf_mult_gf24 u_mult2 (.a(ah), .b(inv_out), .c(out_ah));
    
    wire [3:0] ah_al_xor = ah ^ al;
    gf_mult_gf24 u_mult3 (.a(ah_al_xor), .b(inv_out), .c(out_al));

    assign out = {out_ah, out_al};

endmodule

// =========================================================================
// SUBMODULE: GF(2^4) Multiplier
// =========================================================================
module gf_mult_gf24 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] c
);
    wire a3b3 = a[3] & b[3];
    wire a2b2 = a[2] & b[2];
    wire a1b1 = a[1] & b[1];
    wire a0b0 = a[0] & b[0];

    assign c[3] = a[3]&b[0] ^ a[2]&b[1] ^ a[1]&b[2] ^ a[0]&b[3] ^ a3b3 ^ a2b2;
    assign c[2] = a[2]&b[0] ^ a[1]&b[1] ^ a[0]&b[2] ^ a[3]&b[3] ^ a[3]&b[2] ^ a[2]&b[3];
    assign c[1] = a[1]&b[0] ^ a[0]&b[1] ^ a[3]&b[2] ^ a[2]&b[3] ^ a3b3 ^ a2b2;
    assign c[0] = a0b0 ^ a[3]&b[1] ^ a[1]&b[3] ^ a[2]&b[2] ^ a[3]&b[2] ^ a[2]&b[3];
endmodule

// =========================================================================
// SUBMODULE: GF(2^4) Multiplicative Inverse
// =========================================================================
module gf_inv_4bit (
    input  wire [3:0] in,
    output wire [3:0] out
);
    wire a = in[3];
    wire b = in[2];
    wire c = in[1];
    wire d = in[0];

    // Highly optimized boolean logic for 4-bit inversion
    assign out[3] = a & b & c | a & b & d | a & c & d | b & c & d | a & b | a & c | b & c | a | b | c;
    assign out[2] = a & b & c | a & b & d | a & c & d | b & c & d | a & d | b & d | c & d | a | b | d;
    assign out[1] = a & b & d | a & c & d | b & c & d | a & b | a & c | a & d | b & c | b & d | c & d | a | c | d;
    assign out[0] = a & b & c | a & c & d | b & c & d | a & b | a & d | b & c | b & d | c & d | b | c | d;
endmodule
