`timescale 1ns / 1ps
module parking2_tb;
    reg clk;
    reg [15:0] sw;
    reg [3:0] btn;
    wire [15:0] led;
    wire [7:0] D0_SEG;
    wire [3:0] D0_AN;

    top2 DUT(.clk(clk), .sw(sw), .btn(btn), .led(led),
             .D0_SEG(D0_SEG), .D0_AN(D0_AN));

    always #5 clk = ~clk;

    task pulse_entry;
        begin
            @(negedge clk); sw[0] = 1'b1;
            @(negedge clk); sw[0] = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    task pulse_exit;
        begin
            @(negedge clk); sw[1] = 1'b1;
            @(negedge clk); sw[1] = 1'b0;
            repeat (2) @(negedge clk);
        end
    endtask

    initial begin
        clk = 0; sw = 16'd0; btn = 4'b0001;
        repeat (3) @(negedge clk);
        btn[0] = 1'b0;

        // Ground floor: fill four slots; fifth entry must be ignored.
        sw[3:2] = 2'b00;
        repeat (4) pulse_entry();
        if (DUT.occ0 !== 3'd4) $fatal(1, "Ground floor should be full");
        pulse_entry();
        if (DUT.occ0 !== 3'd4) $fatal(1, "Ground floor overflow");

        // First floor: two entries, then one exit.
        sw[3:2] = 2'b01;
        repeat (2) pulse_entry();
        if (DUT.occ1 !== 3'd2) $fatal(1, "First floor count incorrect");
        pulse_exit();
        if (DUT.occ1 !== 3'd1) $fatal(1, "First floor exit failed");

        // Second floor: one entry.
        sw[3:2] = 2'b10;
        pulse_entry();
        if (DUT.occ2 !== 3'd1) $fatal(1, "Second floor count incorrect");

        // Whole-facility totals should be 6 occupied and 6 available.
        sw[4] = 1'b1;
        #20;
        if (DUT.total_occupied !== 5'd6 ||
            DUT.total_available !== 5'd6)
            $fatal(1, "Facility totals incorrect");

        // Exit all six vehicles and verify available indication.
        sw[3:2] = 2'b00;
        repeat (4) pulse_exit();
        sw[3:2] = 2'b01;
        pulse_exit();
        sw[3:2] = 2'b10;
        pulse_exit();
        if (DUT.total_occupied !== 5'd0)
            $fatal(1, "All exits should clear facility");
        if (led[0] !== 1'b0 || led[1] !== 1'b1)
            $fatal(1, "LED indication incorrect when spaces are available");

        $display("PASS: three-floor parking test completed.");
        $finish;
    end
endmodule
