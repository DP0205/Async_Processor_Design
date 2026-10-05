module async_pipeline_controller (
    input  wire rst,
    input  wire req_in,
    output wire ack_out,
    output wire req_out,
    input  wire ack_in,
    output wire latch_enable
);
    wire c_out;
    
    // The C-element synchronizes the incoming request with the downstream acknowledgment
    muller_c c_elem (
        .a(req_in),
        .b(~ack_in),
        .reset(rst),
        .c(c_out)
    );
    
    assign req_out      = c_out;
    assign ack_out      = c_out;
    assign latch_enable = c_out;
    
endmodule