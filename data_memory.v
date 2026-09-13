/*
module data_memory (
    input         clk,
    input         reset,
    input         mem_read,
    input         mem_write,
    input  [31:0] address,
    input  [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'd0;
        end
        else if (mem_write) begin
            mem[address[9:2]] <= write_data;
        end
    end

    assign read_data = mem_read ? mem[address[9:2]] : 32'd0;
endmodule
*/
module data_memory (
    input  wire        reset,
    input  wire        mem_read,
    input  wire        write_enable, // Derived from: MEM_latch_enable & ex_mem_mem_write
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] mem [0:255];
    integer i;

    // Trigger write on the rising edge of the local handshake write pulse
    always @(posedge write_enable or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'd0;
        end
        else begin
            mem[address[9:2]] <= write_data;
        end
    end

    // Asynchronous read
    assign read_data = mem_read ? mem[address[9:2]] : 32'd0;
endmodule