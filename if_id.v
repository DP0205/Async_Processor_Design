/* 
module if_id (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] instruction_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] instruction_out
);
    always @(posedge clk) begin
        if (reset || flush) begin
            pc_out          <= 32'd0;
            pc_plus4_out    <= 32'd0;
            instruction_out <= 32'h00000013; // RISC-V NOP (addi x0, x0, 0)
        end
        else if (enable) begin
            pc_out          <= pc_in;
            pc_plus4_out    <= pc_plus4_in;
            instruction_out <= instruction_in;
        end
        // If enable == 0 and flush == 0, hold current values (stall)
    end
endmodule

*/
module if_id (
    input  wire        reset,
    input  wire        latch_enable, // Replaces clk and enable
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] instruction_in,
    
    output wire [31:0] pc_out,
    output wire [31:0] pc_plus4_out,
    output wire [31:0] instruction_out
);

    // Latch for Program Counter
    async_pipeline_latch #(
        .WIDTH(32),
        .RESET_VAL(32'd0)
    ) latch_pc (
        .latch_enable(latch_enable),
        .reset(reset),
        .flush(flush),
        .data_in(pc_in),
        .data_out(pc_out)
    );

    // Latch for PC+4
    async_pipeline_latch #(
        .WIDTH(32),
        .RESET_VAL(32'd0)
    ) latch_pc_plus4 (
        .latch_enable(latch_enable),
        .reset(reset),
        .flush(flush),
        .data_in(pc_plus4_in),
        .data_out(pc_plus4_out)
    );

    // Latch for Instruction (Flushes to RISC-V NOP: addi x0, x0, 0)
    async_pipeline_latch #(
        .WIDTH(32),
        .RESET_VAL(32'h00000013) 
    ) latch_instruction (
        .latch_enable(latch_enable),
        .reset(reset),
        .flush(flush),
        .data_in(instruction_in),
        .data_out(instruction_out)
    );

endmodule