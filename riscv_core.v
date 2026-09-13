/*

module riscv_core (
    input wire clk,
    input wire reset
);

    // ============================================================
    // PIPELINE INTERCONNECT & FORWARD DECLARATIONS
    // ============================================================
    wire        branch_taken;
    wire [31:0] branch_target;
    wire        pc_write;
    wire        if_id_write;
    wire        id_ex_flush;
    
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_immediate;
    wire        id_ex_mem_read;
    wire [4:0]  id_ex_rd;
    wire        ex_mem_reg_write;
    wire [4:0]  ex_mem_rd;
    wire [31:0] ex_mem_alu_result;
    wire        mem_wb_reg_write;
    wire [4:0]  mem_wb_rd;
    wire [31:0] wb_write_data;

    // ============================================================
    // IF STAGE
    // ============================================================
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] instruction;
    wire [31:0] pc_plus4 = pc + 32'd4;

    pc pc_unit (
        .clk(clk),
        .reset(reset),
        .enable(pc_write),            // Controlled by hazard unit
        .next_pc(next_pc),
        .current_pc(pc)
    );

    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );

    assign branch_target = id_ex_pc + id_ex_immediate;
    assign next_pc       = branch_taken ? branch_target : pc_plus4;

    // ============================================================
    // IF/ID PIPELINE REGISTER
    // ============================================================
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_instruction;

    if_id if_id_reg (
        .clk(clk),
        .reset(reset),
        .enable(if_id_write),
        .flush(branch_taken),
        .pc_in(pc),
        .pc_plus4_in(pc_plus4),
        .instruction_in(instruction),
        .pc_out(if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .instruction_out(if_id_instruction)
    );

    // ============================================================
    // ID STAGE
    // ============================================================
    wire [6:0] id_opcode = if_id_instruction[6:0];
    wire [4:0] id_rs1    = if_id_instruction[19:15];
    wire [4:0] id_rs2    = if_id_instruction[24:20];
    wire [4:0] id_rd     = if_id_instruction[11:7];
    wire [2:0] id_funct3 = if_id_instruction[14:12];
    wire [6:0] id_funct7 = if_id_instruction[31:25];

    wire id_reg_write;
    wire id_mem_read;
    wire id_mem_write;
    wire id_mem_to_reg;
    wire id_alu_src;
    wire id_branch;
    wire [1:0] id_alu_op;

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_immediate;
    wire [3:0]  id_alu_ctrl;

    // Flag to check if current instruction in ID actually reads rs2
    wire id_use_rs2 = (id_opcode == 7'b0110011) || // R-type
                      (id_opcode == 7'b0100011) || // SW
                      (id_opcode == 7'b1100011);   // BEQ

    control_unit control (
        .opcode(id_opcode),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .alu_src(id_alu_src),
        .branch(id_branch),
        .alu_op(id_alu_op)
    );

    immediate_generator imm_gen (
        .instruction(if_id_instruction),
        .immediate(id_immediate)
    );

    alu_control alu_ctrl_unit (
        .alu_op(id_alu_op),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .alu_ctrl(id_alu_ctrl)
    );

    register_file regs (
        .clk(clk),
        .reset(reset),
        .reg_write(mem_wb_reg_write),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(mem_wb_rd),
        .write_data(wb_write_data),
        .read_data1(id_rs1_data),
        .read_data2(id_rs2_data)
    );

    // ============================================================
    // HAZARD UNIT
    // ============================================================
    hazard_unit hazard (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .if_id_use_rs2(id_use_rs2),    // Fixed: Prevents false stalls on I-types
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .id_ex_flush(id_ex_flush)
    );

    // ============================================================
    // ID/EX PIPELINE REGISTER
    // ============================================================
    wire        id_ex_reg_write;
    wire        id_ex_mem_write;
    wire        id_ex_mem_to_reg;
    wire        id_ex_alu_src;
    wire        id_ex_branch;
    wire [3:0]  id_ex_alu_ctrl;

    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [4:0]  id_ex_rs1;
    wire [4:0]  id_ex_rs2;

    id_ex id_ex_reg (
        .clk(clk),
        .reset(reset),
        .flush(id_ex_flush || branch_taken), // Flushed on load-use stall or taken branch

        .reg_write_in(id_reg_write),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .mem_to_reg_in(id_mem_to_reg),
        .alu_src_in(id_alu_src),
        .branch_in(id_branch),
        .alu_ctrl_in(id_alu_ctrl),

        .pc_in(if_id_pc),
        .rs1_data_in(id_rs1_data),
        .rs2_data_in(id_rs2_data),
        .immediate_in(id_immediate),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),

        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .alu_src_out(id_ex_alu_src),
        .branch_out(id_ex_branch),
        .alu_ctrl_out(id_ex_alu_ctrl),

        .pc_out(id_ex_pc),
        .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data),
        .immediate_out(id_ex_immediate),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd)
    );

    // ============================================================
    // EX STAGE
    // ============================================================
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    wire [31:0] ex_forward_a;
    wire [31:0] ex_forward_b;
    wire [31:0] ex_alu_b;
    wire [31:0] ex_alu_result;
    wire        ex_zero;

    wire [31:0] ex_mem_forward_value = ex_mem_alu_result;
    wire [31:0] mem_wb_forward_value = wb_write_data;

    forwarding_unit forwarding (
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    assign ex_forward_a =
        (forward_a == 2'b10) ? ex_mem_forward_value :
        (forward_a == 2'b01) ? mem_wb_forward_value :
                               id_ex_rs1_data;

    assign ex_forward_b =
        (forward_b == 2'b10) ? ex_mem_forward_value :
        (forward_b == 2'b01) ? mem_wb_forward_value :
                               id_ex_rs2_data;

    assign ex_alu_b = id_ex_alu_src ? id_ex_immediate : ex_forward_b;

    alu alu_unit (
        .a(ex_forward_a),
        .b(ex_alu_b),
        .alu_ctrl(id_ex_alu_ctrl),
        .result(ex_alu_result),
        .zero(ex_zero)
    );

    branch_unit branch (
        .branch(id_ex_branch),
        .zero(ex_zero),
        .branch_taken(branch_taken)
    );

    // ============================================================
    // EX/MEM PIPELINE REGISTER
    // ============================================================
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_mem_to_reg;
    wire [31:0] ex_mem_store_data;

    ex_mem ex_mem_reg (
        .clk(clk),
        .reset(reset),

        .reg_write_in(id_ex_reg_write),
        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),
        .mem_to_reg_in(id_ex_mem_to_reg),

        .alu_result_in(ex_alu_result),
        .store_data_in(ex_forward_b),
        .rd_in(id_ex_rd),

        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),
        .alu_result_out(ex_mem_alu_result),
        .store_data_out(ex_mem_store_data),
        .rd_out(ex_mem_rd)
    );

    // ============================================================
    // MEM STAGE
    // ============================================================
    wire [31:0] mem_read_data;

    data_memory dmem (
        .clk(clk),
        .reset(reset),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_store_data),
        .read_data(mem_read_data)
    );

    // ============================================================
    // MEM/WB PIPELINE REGISTER
    // ============================================================
    wire        mem_wb_mem_to_reg;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;

    mem_wb mem_wb_reg (
        .clk(clk),
        .reset(reset),

        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),

        .alu_result_in(ex_mem_alu_result),
        .mem_data_in(mem_read_data),
        .rd_in(ex_mem_rd),

        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),
        .alu_result_out(mem_wb_alu_result),
        .mem_data_out(mem_wb_mem_data),
        .rd_out(mem_wb_rd)
    );

    // ============================================================
    // WB STAGE
    // ============================================================
    assign wb_write_data =
        mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

endmodule

*/

module riscv_core (
    input  wire reset,
    
    // Asynchronous Handshake Interface (Replaces Global Clock)
    input  wire req_in,       // Triggers the Instruction Fetch stage
    output wire ack_out,      // Acknowledges the fetch request
    output wire req_out,      // Signals Writeback completion
    input  wire ack_in        // Acknowledges Writeback completion
);

    // ============================================================
    // PIPELINE INTERCONNECT & FORWARD DECLARATIONS
    // ============================================================
    wire        branch_taken;
    wire [31:0] branch_target;
    wire        pc_write;
    wire        if_id_write;
    wire        id_ex_flush;
    
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_immediate;
    wire        id_ex_mem_read;
    wire [4:0]  id_ex_rd;
    wire        ex_mem_reg_write;
    wire [4:0]  ex_mem_rd;
    wire [31:0] ex_mem_alu_result;
    wire        mem_wb_reg_write;
    wire [4:0]  mem_wb_rd;
    wire [31:0] wb_write_data;

    // ============================================================
    // MULLER C-ELEMENT HANDSHAKE CONTROLLERS
    // ============================================================
    wire req_if_id,  ack_id_if,  le_if;
    wire req_id_ex,  ack_ex_id,  le_id;
    wire req_ex_mem, ack_mem_ex, le_ex;
    wire req_mem_wb, ack_wb_mem, le_mem;
    wire le_wb;

    // Asynchronous Scoreboarding: Gate IF's Ack if Hazard Unit stalls
    wire ack_id_if_gated = if_id_write ? ack_id_if : 1'b0;

    async_pipeline_controller ctrl_if (
        .rst(reset), .req_in(req_in), .ack_out(ack_out),
        .req_out(req_if_id), .ack_in(ack_id_if_gated), .latch_enable(le_if)
    );

    async_pipeline_controller ctrl_id (
        .rst(reset), .req_in(req_if_id), .ack_out(ack_id_if),
        .req_out(req_id_ex), .ack_in(ack_ex_id), .latch_enable(le_id)
    );

    async_pipeline_controller ctrl_ex (
        .rst(reset), .req_in(req_id_ex), .ack_out(ack_ex_id),
        .req_out(req_ex_mem), .ack_in(ack_mem_ex), .latch_enable(le_ex)
    );

    async_pipeline_controller ctrl_mem (
        .rst(reset), .req_in(req_ex_mem), .ack_out(ack_mem_ex),
        .req_out(req_mem_wb), .ack_in(ack_wb_mem), .latch_enable(le_mem)
    );

    async_pipeline_controller ctrl_wb (
        .rst(reset), .req_in(req_mem_wb), .ack_out(ack_wb_mem),
        .req_out(req_out), .ack_in(ack_in), .latch_enable(le_wb)
    );

    // ============================================================
    // IF STAGE
    // ============================================================
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] instruction;
    wire [31:0] pc_plus4 = pc + 32'd4;

    pc pc_unit (
        .reset(reset),
        .latch_enable(le_if),
        .next_pc(next_pc),
        .current_pc(pc)
    );

    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );

    assign branch_target = id_ex_pc + id_ex_immediate;
    assign next_pc       = branch_taken ? branch_target : pc_plus4;

    // ============================================================
    // IF/ID PIPELINE REGISTER (Asynchronous)
    // ============================================================
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_instruction;

    if_id if_id_reg (
        .reset(reset),
        .latch_enable(le_if),
        .flush(branch_taken),
        .pc_in(pc),
        .pc_plus4_in(pc_plus4),
        .instruction_in(instruction),
        .pc_out(if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .instruction_out(if_id_instruction)
    );

    // ============================================================
    // ID STAGE
    // ============================================================
    wire [6:0] id_opcode = if_id_instruction[6:0];
    wire [4:0] id_rs1    = if_id_instruction[19:15];
    wire [4:0] id_rs2    = if_id_instruction[24:20];
    wire [4:0] id_rd     = if_id_instruction[11:7];
    wire [2:0] id_funct3 = if_id_instruction[14:12];
    wire [6:0] id_funct7 = if_id_instruction[31:25];

    wire id_reg_write, id_mem_read, id_mem_write, id_mem_to_reg, id_alu_src, id_branch;
    wire [1:0] id_alu_op;
    wire [31:0] id_rs1_data, id_rs2_data, id_immediate;
    wire [3:0]  id_alu_ctrl;

    wire id_use_rs2 = (id_opcode == 7'b0110011) || (id_opcode == 7'b0100011) || (id_opcode == 7'b1100011);

    control_unit control (
        .opcode(id_opcode), .reg_write(id_reg_write), .mem_read(id_mem_read),
        .mem_write(id_mem_write), .mem_to_reg(id_mem_to_reg), .alu_src(id_alu_src),
        .branch(id_branch), .alu_op(id_alu_op)
    );

    immediate_generator imm_gen (
        .instruction(if_id_instruction), .immediate(id_immediate)
    );

    alu_control alu_ctrl_unit (
        .alu_op(id_alu_op), .funct3(id_funct3), .funct7(id_funct7), .alu_ctrl(id_alu_ctrl)
    );

    wire reg_write_pulse = le_wb & mem_wb_reg_write;
    register_file regs (
        .reset(reset),
        .write_enable(reg_write_pulse),
        .rs1(id_rs1), .rs2(id_rs2), .rd(mem_wb_rd),
        .write_data(wb_write_data),
        .read_data1(id_rs1_data), .read_data2(id_rs2_data)
    );

    hazard_unit hazard (
        .id_ex_mem_read(id_ex_mem_read), .id_ex_rd(id_ex_rd),
        .if_id_rs1(id_rs1), .if_id_rs2(id_rs2), .if_id_use_rs2(id_use_rs2),
        .pc_write(pc_write), .if_id_write(if_id_write), .id_ex_flush(id_ex_flush)
    );

    // ============================================================
    // ID/EX PIPELINE REGISTER (Asynchronous)
    // ============================================================
    wire        id_ex_reg_write, id_ex_mem_write, id_ex_mem_to_reg, id_ex_alu_src, id_ex_branch;
    wire [3:0]  id_ex_alu_ctrl;
    wire [31:0] id_ex_rs1_data, id_ex_rs2_data;
    wire [4:0]  id_ex_rs1, id_ex_rs2;

    id_ex id_ex_reg (
        .reset(reset),
        .latch_enable(le_id),
        .flush(id_ex_flush || branch_taken),
        .reg_write_in(id_reg_write), .mem_read_in(id_mem_read), .mem_write_in(id_mem_write),
        .mem_to_reg_in(id_mem_to_reg), .alu_src_in(id_alu_src), .branch_in(id_branch),
        .alu_ctrl_in(id_alu_ctrl), .pc_in(if_id_pc), .rs1_data_in(id_rs1_data),
        .rs2_data_in(id_rs2_data), .immediate_in(id_immediate), .rs1_in(id_rs1),
        .rs2_in(id_rs2), .rd_in(id_rd),
        .reg_write_out(id_ex_reg_write), .mem_read_out(id_ex_mem_read), .mem_write_out(id_ex_mem_write),
        .mem_to_reg_out(id_ex_mem_to_reg), .alu_src_out(id_ex_alu_src), .branch_out(id_ex_branch),
        .alu_ctrl_out(id_ex_alu_ctrl), .pc_out(id_ex_pc), .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data), .immediate_out(id_ex_immediate), .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2), .rd_out(id_ex_rd)
    );

    // ============================================================
    // EX STAGE
    // ============================================================
    wire [1:0] forward_a, forward_b;
    wire [31:0] ex_forward_a, ex_forward_b, ex_alu_b, ex_alu_result;
    wire ex_zero;

    wire [31:0] ex_mem_forward_value = ex_mem_alu_result;
    wire [31:0] mem_wb_forward_value = wb_write_data;

    forwarding_unit forwarding (
        .ex_mem_reg_write(ex_mem_reg_write), .ex_mem_rd(ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write), .mem_wb_rd(mem_wb_rd),
        .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    assign ex_forward_a = (forward_a == 2'b10) ? ex_mem_forward_value :
                          (forward_a == 2'b01) ? mem_wb_forward_value : id_ex_rs1_data;

    assign ex_forward_b = (forward_b == 2'b10) ? ex_mem_forward_value :
                          (forward_b == 2'b01) ? mem_wb_forward_value : id_ex_rs2_data;

    assign ex_alu_b = id_ex_alu_src ? id_ex_immediate : ex_forward_b;

    alu alu_unit (
        .a(ex_forward_a), .b(ex_alu_b), .alu_ctrl(id_ex_alu_ctrl),
        .result(ex_alu_result), .zero(ex_zero)
    );

    branch_unit branch (
        .branch(id_ex_branch), .zero(ex_zero), .branch_taken(branch_taken)
    );

    // ============================================================
    // EX/MEM PIPELINE REGISTER (Asynchronous)
    // ============================================================
    wire        ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_to_reg;
    wire [31:0] ex_mem_store_data;

    ex_mem ex_mem_reg (
        .reset(reset),
        .latch_enable(le_ex),
        .reg_write_in(id_ex_reg_write), .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write), .mem_to_reg_in(id_ex_mem_to_reg),
        .alu_result_in(ex_alu_result), .store_data_in(ex_forward_b), .rd_in(id_ex_rd),
        .reg_write_out(ex_mem_reg_write), .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write), .mem_to_reg_out(ex_mem_mem_to_reg),
        .alu_result_out(ex_mem_alu_result), .store_data_out(ex_mem_store_data), .rd_out(ex_mem_rd)
    );

    // ============================================================
    // MEM STAGE
    // ============================================================
    wire [31:0] mem_read_data;
    wire dmem_write_pulse = le_mem & ex_mem_mem_write;

    data_memory dmem (
        .reset(reset),
        .mem_read(ex_mem_mem_read),
        .write_enable(dmem_write_pulse),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_store_data),
        .read_data(mem_read_data)
    );

    // ============================================================
    // MEM/WB PIPELINE REGISTER (Asynchronous)
    // ============================================================
    wire        mem_wb_mem_to_reg;
    wire [31:0] mem_wb_alu_result, mem_wb_mem_data;

    mem_wb mem_wb_reg (
        .reset(reset),
        .latch_enable(le_mem),
        .reg_write_in(ex_mem_reg_write), .mem_to_reg_in(ex_mem_mem_to_reg),
        .alu_result_in(ex_mem_alu_result), .mem_data_in(mem_read_data), .rd_in(ex_mem_rd),
        .reg_write_out(mem_wb_reg_write), .mem_to_reg_out(mem_wb_mem_to_reg),
        .alu_result_out(mem_wb_alu_result), .mem_data_out(mem_wb_mem_data), .rd_out(mem_wb_rd)
    );

    // ============================================================
    // WB STAGE
    // ============================================================
    assign wb_write_data = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

endmodule