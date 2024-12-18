module top (
    input  wire       clk,        // 100MHz system clock
    input  wire       btnC,       // Center button for reset
    input  wire [3:0] sw,         // Switches for inputs
    output wire [3:0] led         // LEDs for outputs
);

    // Test pattern generator signals
    reg [25:0] slow_counter = 0;  // Divides 100MHz clock for visible changes
    reg test_din = 0;
    reg test_sin = 0;

    // Counter for test pattern generation
    always @(posedge clk) begin
        slow_counter <= slow_counter + 1;
        if (slow_counter == 0) begin
            // Change pattern every ~0.67 seconds (100MHz/2^26)
            test_din <= ~test_din;
            if (test_din == 1)
                test_sin <= ~test_sin;
        end
    end

    // Internal signals to monitor
    wire        din;
    wire        sin;
    wire [11:0] weight;
    wire        async_dout;
    wire        sync_dout;
    wire        ring_osc;
    wire [11:0] async_counter;
    wire [11:0] sync_counter;
    
    // Map controls - use either switches or test pattern based on btnC
    assign din = btnC ? sw[0] : test_din;
    assign sin = btnC ? sw[1] : test_sin;
    assign weight = {8'h0A, sw};  // Keep weight constant for testing
    
    // Get internal signals from async countdown
    async_countdown #(
        .WIDTH(12),
        .RING_LENGTH(5)
    ) async_count (
        .din(din),
        .sin(sin),
        .weight(weight),
        .dout(async_dout)
    );
    
    // Get internal signals from sync countdown
    clocked_countdown #(
        .WIDTH(12)
    ) sync_count (
        .din(din),
        .sin(sin),
        .weight(weight),
        .clk(clk),
        .dout(sync_dout)
    );
    
    // Map outputs to LEDs
    assign led[0] = din;
    assign led[1] = sin;
    assign led[2] = async_dout;
    assign led[3] = sync_dout;

    // Instantiate ILA core
    ila_0 debug_logic (
        .clk(clk),
        .probe0(din),           // 1-bit
        .probe1(sin),           // 1-bit
        .probe2(weight),        // 12-bit
        .probe3(async_dout),    // 1-bit
        .probe4(sync_dout),     // 1-bit
        .probe5(ring_osc)       // 1-bit to monitor oscillator
    );

endmodule