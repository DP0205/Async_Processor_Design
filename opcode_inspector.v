module opcode_inspector (
    input  wire        branch,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [3:0]  alu_ctrl,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    output reg  [1:0]  delay_sel
);
    localparam ALU_AND = 4'b0000; 
    localparam ALU_OR  = 4'b0001;

    always @(*) begin
        if (branch || mem_read || mem_write) begin
            delay_sel = 2'b10; // SLOW: Branches and Memory address calc
        end 
        else if ((alu_ctrl == ALU_AND) || (alu_ctrl == ALU_OR)) begin
            delay_sel = 2'b00; // FAST: Bitwise logic
        end 
        else if ((operand_a[31:16] == 16'd0) && (operand_b[31:16] == 16'd0)) begin
            delay_sel = 2'b00; // FAST: Math isolated to lower 16 bits (no high carry)
        end 
        else begin
            delay_sel = 2'b01; // MEDIUM: Standard 32-bit math
        end
    end
endmodule