module alu_control (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg [3:0] alu_ctrl
);
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_SLT = 4'b0100;

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD; // ADDI/LW/SW
            2'b01: alu_ctrl = ALU_SUB; // BEQ comparison

            2'b10: begin                // R-type
                case (funct3)
                    3'b000:
                        alu_ctrl = (funct7 == 7'b0100000) ?
                                   ALU_SUB : ALU_ADD;
                    3'b111: alu_ctrl = ALU_AND;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b010: alu_ctrl = ALU_SLT;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: alu_ctrl = ALU_ADD;
        endcase
    end
endmodule
