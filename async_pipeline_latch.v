module async_pipeline_latch #(
    parameter WIDTH = 32,
    parameter RESET_VAL = 32'd0 // Allows overriding default reset value (e.g., NOP)
) (
    input  wire             latch_enable,
    input  wire             reset,
    input  wire             flush,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    // Level-sensitive latch inference
    always @(*) begin
        if (reset || flush) begin
            data_out = RESET_VAL;
        end else if (latch_enable) begin
            data_out = data_in;
        end
        // If enable is 0 and no reset/flush, data_out implicitly holds its state
    end
endmodule