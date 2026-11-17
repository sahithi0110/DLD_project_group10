`timescale 1ns / 1ps
// Four-digit active-LOW seven-segment multiplexing driver.
// digit3 is leftmost; digit0 is rightmost.
// seg[0:6] map to A,B,C,D,E,F,G.
module seven_segment2(
    input clk,
    input reset,
    input [3:0] digit3,
    input [3:0] digit2,
    input [3:0] digit1,
    input [3:0] digit0,
    output reg [6:0] seg,
    output reg [3:0] an
);
    reg [16:0] refresh_count;
    reg [3:0] current_digit;

    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_count <= 17'd0;
        else
            refresh_count <= refresh_count + 1'b1;
    end

    always @(*) begin
        case (refresh_count[16:15])
            2'b00: begin an = 4'b1110; current_digit = digit0; end
            2'b01: begin an = 4'b1101; current_digit = digit1; end
            2'b10: begin an = 4'b1011; current_digit = digit2; end
            default: begin an = 4'b0111; current_digit = digit3; end
        endcase

        // Active-LOW segment patterns, bit order A through G.
        case (current_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
