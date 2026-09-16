/*
module mem_wb (
    input         clk,
    input         reset,

    input         reg_write_in,
    input         mem_to_reg_in,

    input  [31:0] alu_result_in,
    input  [31:0] mem_data_in,
    input  [4:0]  rd_in,

    output reg       reg_write_out,
    output reg       mem_to_reg_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_data_out,
    output reg [4:0]  rd_out
);
    always @(posedge clk) begin
        if (reset) begin
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_result_out <= 32'd0;
            mem_data_out   <= 32'd0;
            rd_out         <= 5'd0;
        end
        else begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            rd_out         <= rd_in;
        end
    end
endmodule
*/

module mem_wb (
    input  wire        reset,
    input  wire        latch_enable,

    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,

    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_data_in,
    input  wire [4:0]  rd_in,

    output wire        reg_write_out,
    output wire        mem_to_reg_out,
    
    output wire [31:0] alu_result_out,
    output wire [31:0] mem_data_out,
    output wire [4:0]  rd_out
);

    wire [1:0] ctrl_in = {reg_write_in, mem_to_reg_in};
    wire [1:0] ctrl_out;
    assign {reg_write_out, mem_to_reg_out} = ctrl_out;

    async_pipeline_latch #(.WIDTH(2)) latch_ctrl (
        .latch_enable(latch_enable), .reset(reset), .flush(1'b0),
        .data_in(ctrl_in), .data_out(ctrl_out)
    );

    async_pipeline_latch #(.WIDTH(32)) latch_alu_result (
        .latch_enable(latch_enable), .reset(reset), .flush(1'b0),
        .data_in(alu_result_in), .data_out(alu_result_out)
    );

    async_pipeline_latch #(.WIDTH(32)) latch_mem_data (
        .latch_enable(latch_enable), .reset(reset), .flush(1'b0),
        .data_in(mem_data_in), .data_out(mem_data_out)
    );

    async_pipeline_latch #(.WIDTH(5)) latch_rd (
        .latch_enable(latch_enable), .reset(reset), .flush(1'b0),
        .data_in(rd_in), .data_out(rd_out)
    );

endmodule