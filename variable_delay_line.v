module variable_delay_line (
    input  wire       req_in,
    input  wire [1:0] delay_sel,
    output wire       req_out
);
    // Number of logic blocks per path (Tune based on Vivado timing analysis)
    localparam FAST_TAPS = 2;
    localparam MED_TAPS  = 8;
    localparam SLOW_TAPS = 20;

    (* DONT_TOUCH = "TRUE" *) wire [SLOW_TAPS:0] chain;
    
    assign chain[0] = req_in;

    genvar i;
    generate
        for (i = 0; i < SLOW_TAPS; i = i + 1) begin : delay_elements
            // Xilinx LUT1 primitive: Correct input port is I0 (not I)
            (* DONT_TOUCH = "TRUE" *) LUT1 #(
                .INIT(2'b10) // Buffer function (O = I0)
            ) dly (
                .O(chain[i+1]),
                .I0(chain[i])  // <--- FIXED: Changed .I(...) to .I0(...)
            );
        end
    endgenerate

    // Dynamic Tap Selection Multiplexer
    assign req_out = (delay_sel == 2'b00) ? chain[FAST_TAPS] :
                     (delay_sel == 2'b01) ? chain[MED_TAPS]  :
                                            chain[SLOW_TAPS];
endmodule