module aes_sbox_low_area (
    input  wire [7:0] data_in,
    output wire [7:0] data_out
);

    wire [7:0] mapped_data;
    wire [7:0] inverse_data;
    wire [7:0] unmapped_data;

    // 1. Isomorphic Mapping GF(2^8) -> GF(2^4)
    // Pure XOR logic
    assign mapped_data[7] = data_in[7] ^ data_in[5];
    assign mapped_data[6] = data_in[7] ^ data_in[6] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1];
    assign mapped_data[5] = data_in[7] ^ data_in[5] ^ data_in[3] ^ data_in[2];
    assign mapped_data[4] = data_in[7] ^ data_in[5] ^ data_in[3] ^ data_in[2] ^ data_in[1];
    assign mapped_data[3] = data_in[7] ^ data_in[6] ^ data_in[2] ^ data_in[1];
    assign mapped_data[2] = data_in[7] ^ data_in[4] ^ data_in[3] ^ data_in[2] ^ data_in[1];
    assign mapped_data[1] = data_in[6] ^ data_in[4] ^ data_in[1];
    assign mapped_data[0] = data_in[6] ^ data_in[1] ^ data_in[0];

    // 2. Multiplicative Inverse in GF(2^4)
    // (You will instantiate the inverse boolean logic here)
    gf_inverse_gf24 u_inv (
        .in(mapped_data),
        .out(inverse_data)
    );

    // 3. Inverse Isomorphic Mapping GF(2^4) -> GF(2^8)
    assign unmapped_data[7] = inverse_data[7] ^ inverse_data[6] ^ inverse_data[5] ^ inverse_data[1];
    assign unmapped_data[6] = inverse_data[6] ^ inverse_data[2];
    assign unmapped_data[5] = inverse_data[6] ^ inverse_data[5] ^ inverse_data[1];
    assign unmapped_data[4] = inverse_data[6] ^ inverse_data[5] ^ inverse_data[4] ^ inverse_data[2] ^ inverse_data[1];
    assign unmapped_data[3] = inverse_data[5] ^ inverse_data[4] ^ inverse_data[3] ^ inverse_data[2] ^ inverse_data[1];
    assign unmapped_data[2] = inverse_data[7] ^ inverse_data[4] ^ inverse_data[3] ^ inverse_data[2] ^ inverse_data[1];
    assign unmapped_data[1] = inverse_data[5] ^ inverse_data[4];
    assign unmapped_data[0] = inverse_data[6] ^ inverse_data[5] ^ inverse_data[4] ^ inverse_data[2] ^ inverse_data[0];

    // 4. Affine Transformation (NIST Standard)
    assign data_out[0] = ~ (unmapped_data[0] ^ unmapped_data[4] ^ unmapped_data[5] ^ unmapped_data[6] ^ unmapped_data[7]);
    assign data_out[1] = ~ (unmapped_data[0] ^ unmapped_data[1] ^ unmapped_data[5] ^ unmapped_data[6] ^ unmapped_data[7]);
    assign data_out[2] =   (unmapped_data[0] ^ unmapped_data[1] ^ unmapped_data[2] ^ unmapped_data[6] ^ unmapped_data[7]);
    assign data_out[3] =   (unmapped_data[0] ^ unmapped_data[1] ^ unmapped_data[2] ^ unmapped_data[3] ^ unmapped_data[7]);
    assign data_out[4] =   (unmapped_data[0] ^ unmapped_data[1] ^ unmapped_data[2] ^ unmapped_data[3] ^ unmapped_data[4]);
    assign data_out[5] = ~ (unmapped_data[1] ^ unmapped_data[2] ^ unmapped_data[3] ^ unmapped_data[4] ^ unmapped_data[5]);
    assign data_out[6] = ~ (unmapped_data[2] ^ unmapped_data[3] ^ unmapped_data[4] ^ unmapped_data[5] ^ unmapped_data[6]);
    assign data_out[7] =   (unmapped_data[3] ^ unmapped_data[4] ^ unmapped_data[5] ^ unmapped_data[6] ^ unmapped_data[7]);

endmodule
