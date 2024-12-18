module async_countdown #(
    parameter WIDTH = 12,
    parameter RING_LENGTH = 5,
    parameter GATE_DELAY = 0.3  // 100ps gate delay
)(
    input wire din,
    input wire sin,
    input reg [WIDTH-1:0] weight,
    output reg dout
);
        
    // Ring oscillator signals
    (* KEEP = "TRUE" *)
    (* ALLOW_COMBINATORIAL_LOOPS = "TRUE" *)
    wire [RING_LENGTH-1:0] inv_chain;
    wire osc_enable;
    wire ring_osc;

    // First inverter with enable
    assign inv_chain[0] = ~inv_chain[RING_LENGTH-1] & osc_enable;
    
    // Generate the rest of the inverter chain with delays
    genvar i;
    generate
        for (i = 1; i < RING_LENGTH; i = i + 1) begin : ring_osc_gen
            (* KEEP = "TRUE" *)
            assign #GATE_DELAY inv_chain[i] = ~inv_chain[i-1];
        end
    endgenerate
    
    assign ring_osc = inv_chain[RING_LENGTH-1];

    // Counter register
    reg [WIDTH-1:0] counter = 0;

    // Enable logic if a wavefront has arrived
    assign osc_enable = (din ^ sin) & (din ^ dout);

    always @(posedge ring_osc) begin

        if (counter == 0) begin
            counter <= weight;
        end else if (counter != 0) begin
            counter <= counter - 1;
            if (counter == 1) begin // Will be zero next
                dout <= din;
            end
        end
    end

endmodule

module clocked_countdown #(
    parameter WIDTH = 12,
    parameter RING_LENGTH = 5,
    parameter GATE_DELAY = 0.3  // 100ps gate delay
)(
    input wire din,
    input wire sin,
    input reg [WIDTH-1:0] weight,
    input wire clk,
    output reg dout
);

    reg [WIDTH-1:1] counter <= 0;

    always @(posedge clk) begin
        if ((din ^ sin) & (din ^ dout)) begin
            counter <= weight;
        end else if (counter != 0) begin
            counter <= counter - 1;
            if (counter == 0) begin
                dout <= din;
            end
        end
    end

endmodule