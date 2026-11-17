`timescale 1ns / 1ps
// Independent counter for one floor containing four parking slots.
module parking2_counter(
    input clk,
    input reset,
    input entry,
    input exit,
    output reg [2:0] occupied,
    output wire [2:0] available,
    output wire full,
    output wire empty
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            occupied <= 3'd0;
        else begin
            // Simultaneous entry and exit cancel each other.
            if (entry && !exit) begin
                if (occupied < 3'd4)
                    occupied <= occupied + 1'b1;
            end
            else if (exit && !entry) begin
                if (occupied > 3'd0)
                    occupied <= occupied - 1'b1;
            end
        end
    end

    assign available = 3'd4 - occupied;
    assign full  = (occupied == 3'd4);
    assign empty = (occupied == 3'd0);
endmodule
