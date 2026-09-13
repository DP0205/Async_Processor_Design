module hazard_unit (
    input  wire       id_ex_mem_read,
    input  wire [4:0] id_ex_rd,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    input  wire       if_id_use_rs2, // 1 for R-type, SW, BEQ; 0 for I-type (ADDI, LW)

    output reg        pc_write,
    output reg        if_id_write,
    output reg        id_ex_flush
);
    always @(*) begin
        // Default: No stall
        pc_write    = 1'b1;
        if_id_write = 1'b1;
        id_ex_flush = 1'b0;

        // Load-use hazard detection:
        // Triggered only if ID/EX instruction is a Memory Load AND
        // the destination rd is not x0 AND
        // rd matches either rs1 OR (rs2 ONLY IF the current instruction actually reads rs2)
        if (id_ex_mem_read && (id_ex_rd != 5'd0) &&
           ((id_ex_rd == if_id_rs1) || (if_id_use_rs2 && (id_ex_rd == if_id_rs2)))) begin
            pc_write    = 1'b0; // Freeze Program Counter
            if_id_write = 1'b0; // Freeze IF/ID Register
            id_ex_flush = 1'b1; // Insert NOP Bubble into ID/EX Register
        end
    end
endmodule