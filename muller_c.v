module muller_c (
    input  wire a,
    input  wire b,
    input  wire reset,
    output reg  c
);
    // Muller C-element behavior: 
    // If inputs match, output follows inputs. If they differ, output holds state.
    always @(*) begin
        if (reset) begin
            c = 1'b0;
        end else if (a == b) begin
            c = a;
        end
    end
endmodule