/*
module register_file (
    input         clk,
    input         reset,
    input         reg_write,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end
        else if (reg_write && (rd != 5'd0)) begin
            regs[rd] <= write_data;
        end
    end

   // Optional: Write-first internal bypass
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 :
                    ((rs1 == rd) && reg_write) ? write_data : regs[rs1];

    assign read_data2 = (rs2 == 5'd0) ? 32'd0 :
                    ((rs2 == rd) && reg_write) ? write_data : regs[rs2];
endmodule
*/

module register_file (
    input  wire        reset,
    input  wire        write_enable, // Derived from: WB_latch_enable & mem_wb_reg_write
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] regs [0:31];
    integer i;

    // Trigger write on the rising edge of the local handshake write pulse
    always @(posedge write_enable or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end
        else if (rd != 5'd0) begin
            regs[rd] <= write_data;
        end
    end

    // Asynchronous reads with internal write-bypass to prevent same-cycle read/write races
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 :
                        ((rs1 == rd) && write_enable) ? write_data : regs[rs1];

    assign read_data2 = (rs2 == 5'd0) ? 32'd0 :
                        ((rs2 == rd) && write_enable) ? write_data : regs[rs2];
endmodule