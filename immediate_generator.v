module immediate_generator (
    input  wire [31:0] instruction,
    output reg  [31:0] immediate
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011, // I-type: ADDI
            7'b0000011: // I-type: LW
                immediate = {{20{instruction[31]}}, instruction[31:20]};

            7'b0100011: // S-type: SW
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            7'b1100011: // B-type: BEQ
                immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            default:
                immediate = 32'd0;
        endcase
    end
endmodule