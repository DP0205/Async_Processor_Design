/*
module id_ex (
    input  wire        clk,
    input  wire        reset,
    input  wire        flush,

    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        alu_src_in,
    input  wire        branch_in,
    input  wire [3:0]  alu_ctrl_in,

    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] immediate_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,

    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         alu_src_out,
    output reg         branch_out,
    output reg  [3:0]  alu_ctrl_out,

    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] immediate_out,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out
);
    always @(posedge clk) begin
        if (reset || flush) begin
            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_src_out    <= 1'b0;
            branch_out     <= 1'b0;
            alu_ctrl_out   <= 4'd0;
            pc_out         <= 32'd0;
            rs1_data_out   <= 32'd0;
            rs2_data_out   <= 32'd0;
            immediate_out  <= 32'd0;
            rs1_out        <= 5'd0;
            rs2_out        <= 5'd0;
            rd_out         <= 5'd0;
        end
        else begin
            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_src_out    <= alu_src_in;
            branch_out     <= branch_in;
            alu_ctrl_out   <= alu_ctrl_in;
            pc_out         <= pc_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            immediate_out  <= immediate_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
        end
    end
endmodule

*/

module id_ex (
    input  wire        reset,
    input  wire        latch_enable,
    input  wire        flush,

    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        alu_src_in,
    input  wire        branch_in,
    input  wire [3:0]  alu_ctrl_in,

    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] immediate_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,

    output wire        reg_write_out,
    output wire        mem_read_out,
    output wire        mem_write_out,
    output wire        mem_to_reg_out,
    output wire        alu_src_out,
    output wire        branch_out,
    output wire [3:0]  alu_ctrl_out,

    output wire [31:0] pc_out,
    output wire [31:0] rs1_data_out,
    output wire [31:0] rs2_data_out,
    output wire [31:0] immediate_out,
    output wire [4:0]  rs1_out,
    output wire [4:0]  rs2_out,
    output wire [4:0]  rd_out
);

    // Bundle 1-bit control flags
    wire [5:0] ctrl_in  = {reg_write_in, mem_read_in, mem_write_in, mem_to_reg_in, alu_src_in, branch_in};
    wire [5:0] ctrl_out;
    assign {reg_write_out, mem_read_out, mem_write_out, mem_to_reg_out, alu_src_out, branch_out} = ctrl_out;

    async_pipeline_latch #(.WIDTH(6)) latch_ctrl (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in(ctrl_in), .data_out(ctrl_out)
    );

    async_pipeline_latch #(.WIDTH(4)) latch_alu_ctrl (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in(alu_ctrl_in), .data_out(alu_ctrl_out)
    );

    async_pipeline_latch #(.WIDTH(32)) latch_pc (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in(pc_in), .data_out(pc_out)
    );

    async_pipeline_latch #(.WIDTH(32)) latch_rs1_data (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in(rs1_data_in), .data_out(rs1_data_out)
    );

    async_pipeline_latch #(.WIDTH(32)) latch_rs2_data (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in(rs2_data_in), .data_out(rs2_data_out)
    );

    async_pipeline_latch #(.WIDTH(32)) latch_imm (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in(immediate_in), .data_out(immediate_out)
    );

    async_pipeline_latch #(.WIDTH(15)) latch_regs (
        .latch_enable(latch_enable), .reset(reset), .flush(flush),
        .data_in({rs1_in, rs2_in, rd_in}), .data_out({rs1_out, rs2_out, rd_out})
    );

endmodule