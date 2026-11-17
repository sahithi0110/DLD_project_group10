`timescale 1ns / 1ps
// LED status logic for the selected floor or the whole facility.
module parking2_status(
    input full,
    input empty,
    output red_led,
    output green_led
);
    assign red_led   = full;
    assign green_led = ~full;
endmodule
