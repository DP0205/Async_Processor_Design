`timescale 1ns/1ps

module tb_riscv_core;

    reg clk;
    reg reset;

    riscv_core dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        #20;
        reset = 1'b0;

        // Run long enough for the test program to pass through WB.
        #250;

        $display("==========================================");
        $display("Simulation finished");
        $display("x1  = %0d", dut.regs.regs[1]);
        $display("x2  = %0d", dut.regs.regs[2]);
        $display("x3  = %0d", dut.regs.regs[3]);
        $display("x4  = %0d", dut.regs.regs[4]);
        $display("x5  = %0d", dut.regs.regs[5]);
        $display("mem[0] = %0d", dut.dmem.mem[0]);
        $display("==========================================");

        $finish;
    end

endmodule
