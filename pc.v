/*
module pc (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,      // Connects to pc_write from hazard_unit
    input  wire [31:0] next_pc,
    output reg  [31:0] current_pc
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_pc <= 32'd0;
        end else if (enable) begin
            current_pc <= next_pc;  // Update PC only when enable (pc_write) is active
        end
        // If enable is low, current_pc holds its previous value (stalled)
    end

endmodule
*/

module pc (
    input  wire        reset,
    input  wire        latch_enable, // Driven by IF stage controller
    input  wire [31:0] next_pc,
    output reg  [31:0] current_pc
);
    always @(*) begin
        if (reset) begin
            current_pc = 32'd0;
        end else if (latch_enable) begin
            current_pc = next_pc;
        end
    end
endmodule