`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/17/2026 02:27:40 PM
// Design Name: 
// Module Name: top2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



// Boolean board top-level.
// SW0 = Entry
// SW1 = Exit
// SW2:SW3 = Floor selection
// SW4 = Display mode
// BTN0 = Reset

module top2(
    input clk,
    input [15:0] sw,
    input [3:0] btn,
    output [1:0] led,
    output [7:0] D0_SEG,
    output [3:0] D0_AN
);

    wire reset = btn[0];
    wire entry = sw[0];
    wire exit = sw[1];
    wire [1:0] floor_sel = sw[3:2];
    wire display_mode = sw[4];

    wire red_led, green_led;
    wire [6:0] seg;
    wire [3:0] an;

    reg entry_prev, exit_prev;
    reg entry_pulse, exit_pulse;

    wire [2:0] occ0, occ1, occ2;
    wire [2:0] avail0, avail1, avail2;
    wire full0, full1, full2;
    wire empty0, empty1, empty2;

    wire e0 = entry_pulse && (floor_sel == 2'b00);
    wire e1 = entry_pulse && (floor_sel == 2'b01);
    wire e2 = entry_pulse && (floor_sel == 2'b10);

    wire x0 = exit_pulse && (floor_sel == 2'b00);
    wire x1 = exit_pulse && (floor_sel == 2'b01);
    wire x2 = exit_pulse && (floor_sel == 2'b10);

    // Rising-edge event detection
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            entry_prev <= 1'b0;
            exit_prev <= 1'b0;
            entry_pulse <= 1'b0;
            exit_pulse <= 1'b0;
        end
        else begin
            entry_pulse <= entry && !entry_prev;
            exit_pulse <= exit && !exit_prev;

            entry_prev <= entry;
            exit_prev <= exit;
        end
    end

    // Floor 1
    parking2_counter floor0(
        .clk(clk),
        .reset(reset),
        .entry(e0),
        .exit(x0),
        .occupied(occ0),
        .available(avail0),
        .full(full0),
        .empty(empty0)
    );

    // Floor 2
    parking2_counter floor1(
        .clk(clk),
        .reset(reset),
        .entry(e1),
        .exit(x1),
        .occupied(occ1),
        .available(avail1),
        .full(full1),
        .empty(empty1)
    );

    // Floor 3
    parking2_counter floor2(
        .clk(clk),
        .reset(reset),
        .entry(e2),
        .exit(x2),
        .occupied(occ2),
        .available(avail2),
        .full(full2),
        .empty(empty2)
    );

    reg [3:0] digit3, digit2, digit1, digit0;
    reg [4:0] total_occupied, total_available;
    

    reg selected_full, selected_empty;
    reg facility_full, facility_empty;

    reg [2:0] selected_occupied;
    reg [2:0] selected_available;
    reg [1:0] status_value;

    always @(*) begin

        total_occupied =
            {2'b00, occ0} +
            {2'b00, occ1} +
            {2'b00, occ2};

        total_available = 5'd12 - total_occupied;

        selected_occupied = 3'd0;
        selected_available = 3'd4;
        selected_full = 1'b0;
        selected_empty = 1'b1;

        case (floor_sel)

            2'b00: begin
                selected_occupied = occ0;
                selected_available = avail0;
                selected_full = full0;
                selected_empty = empty0;
            end

            2'b01: begin
                selected_occupied = occ1;
                selected_available = avail1;
                selected_full = full1;
                selected_empty = empty1;
            end

            2'b10: begin
                selected_occupied = occ2;
                selected_available = avail2;
                selected_full = full2;
                selected_empty = empty2;
            end

            default: begin
                selected_occupied = 3'd0;
                selected_available = 3'd0;
                selected_full = 1'b0;
                selected_empty = 1'b1;
            end

        endcase

        facility_full = (total_occupied == 5'd12);
        facility_empty = (total_occupied == 5'd0);

        if (!display_mode) begin

            // Floor display mode
            digit3 = {1'b0, selected_occupied};
            digit2 = {1'b0, selected_available};
            digit1 = 4'd4;

            if (selected_full)
                status_value = 2'd2;
            else if (selected_empty)
                status_value = 2'd0;
            else
                status_value = 2'd1;

            digit0 = {2'b00, status_value};

        end
        else begin

            // Total parking display mode
            digit3 = total_occupied / 10;
            digit2 = total_occupied % 10;

            digit1 = total_available / 10;
            digit0 = total_available % 10;

            status_value = 2'd0;

        end

    end

    // Parking status LEDs
    parking2_status status_leds(
        .full(display_mode ? facility_full : selected_full),
        .empty(display_mode ? facility_empty : selected_empty),
        .red_led(red_led),
        .green_led(green_led)
    );

    // Seven-segment display
    seven_segment2 display(
        .clk(clk),
        .reset(reset),
        .digit3(digit3),
        .digit2(digit2),
        .digit1(digit1),
        .digit0(digit0),
        .seg(seg),
        .an(an)
    );

    // LED0 = Red LED
    // LED1 = Green LED
    assign led[0] = red_led;
    assign led[1] = green_led;

    // Decimal point inactive HIGH
    assign D0_SEG = {1'b1, seg};

    assign D0_AN = an;

endmodule
