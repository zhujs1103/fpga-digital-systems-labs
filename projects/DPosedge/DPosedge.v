module DFlipFlop (
    input clk,
    input d,
    input rst,
    output reg q
);
always@(posedge clk) begin
    if (rst) q <= 1'b0;
    else q <= d;
end
endmodule

module DPosedge (
    input clk,
    input d,
    input rst,
    output led
);
wire q;
assign led = ~q;
DFlipFlop dff(
    .clk (clk),
    .d (d),
    .rst (rst),
    .q (q)
);
endmodule