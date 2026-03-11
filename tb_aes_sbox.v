module tb_aes_sbox();

    reg  [7:0] test_in;
    wire [7:0] test_out;
    reg  [7:0] nist_golden [0:255]; // The NIST Standard Array
    integer i, errors;

    // Instantiate DUT
    aes_sbox_low_area dut (
        .data_in(test_in),
        .data_out(test_out)
    );

    initial begin
        errors = 0;
        
        // Load the 256-byte NIST standard hex file
        $readmemh("nist_sbox.hex", nist_golden);

        $display("Starting Exhaustive S-Box Verification...");
        
        // Exhaustive 8-bit input-to-output mapping
        for (i = 0; i < 256; i = i + 1) begin
            test_in = i;
            #1; // Wait 1 time unit for combinational logic to settle
            
            if (test_out !== nist_golden[i]) begin
                $display("FAIL: Input %02X | Expected: %02X | Got: %02X", i, nist_golden[i], test_out);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("SUCCESS: All 256 values mapped perfectly against NIST standard.");
        else
            $display("FAILED with %0d errors.", errors);
            
        $finish;
    end
endmodule
