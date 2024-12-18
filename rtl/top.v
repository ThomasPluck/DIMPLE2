module top (
    input  wire        sys_clk,    // FPGA system clock
    input  wire        rst_n,      // Active low reset
    input  wire [3:0]  sw,         // Switches for input control
    input  wire [3:0]  btn,        // Push buttons
    output wire [3:0]  led         // LEDs for output display
);

    // Internal signals
    wire        din;
    wire        sin;
    wire [11:0] weight;
    wire        async_dout;
    wire        sync_dout;
    
    // Use switches/buttons for control
    assign din = sw[0];           // Input data on switch 0
    assign sin = sw[1];           // Selection input on switch 1
    assign weight = {8'h00, sw};  // Use switches to set a small test weight
    
    // Instantiate async countdown
    async_countdown #(
        .WIDTH(12),
        .RING_LENGTH(5),
        .GATE_DELAY(0.3)  // Note: This delay only affects simulation
    ) async_count (
        .din(din),
        .sin(sin),
        .weight(weight),
        .dout(async_dout)
    );
    
    // Instantiate sync countdown
    clocked_countdown #(
        .WIDTH(12),
        .RING_LENGTH(5),
        .GATE_DELAY(0.3)  // Note: This delay only affects simulation
    ) sync_count (
        .din(din),
        .sin(sin),
        .weight(weight),
        .clk(sys_clk),
        .dout(sync_dout)
    );
    
    // Output mapping
    assign led[0] = din;          // Input data
    assign led[1] = sin;          // Selection input
    assign led[2] = async_dout;   // Async circuit output
    assign led[3] = sync_dout;    // Sync circuit output

endmodule