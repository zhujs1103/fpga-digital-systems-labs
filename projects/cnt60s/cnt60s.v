module cnt60s(
    input clk,
    input rst,
    input go,
    output [7:0] seg1,
    output [7:0] seg2
);

wire clk_sec;
wire debounced_rst;
reg [7:0] counter;
reg running;

always @(posedge clk)begin
if (debounced_rst)begin
running <= 1'b0;
end
else begin
running <= go;
end
end

always @(posedge clk_sec) begin
if (debounced_rst)
counter <= 8'h00;
else if (running) begin
if (counter[3:0] == 4'd9) begin
counter[3:0] <= 4'd0;
if (counter[7:4] == 4'd5)
counter[7:4] <= 4'd0;
else
counter[7:4] <= counter[7:4] + 1'b1;
end else
counter[3:0] <= counter[3:0] + 1'b1;
end 
else
counter <= counter;
end


clk_divider cd1(
    .clk_in(clk),
    .clk_out(clk_sec)
);

Debouncer db_rst(
    .clk(clk),
    .PB(rst),
    .PB_state(debounced_rst)
);

segment_decoder seg_decoder_units(
    .digit_in(counter[3:0]),
    .seg_out(seg2)
);

segment_decoder seg_decoder_tens(
    .digit_in(counter[7:4]),
    .seg_out(seg1)
);

endmodule

module clk_divider(
    input clk_in,
    output reg clk_out
);
parameter N = 24'd6_000_000;
reg [23:0] counter;

always @(posedge clk_in) begin
    if (counter == (N - 1))
        counter <= 24'd0;
    else
        counter <= counter + 1'b1;
end

always @(posedge clk_in) begin
    if (counter == (N - 1))
        clk_out <= ~clk_out;
end
endmodule

module Debouncer(
    input clk,
    input PB,
    output reg PB_state
);
reg PB_sync_0;
always @(posedge clk) PB_sync_0 <= ~PB;
reg PB_sync_1;
always @(posedge clk) PB_sync_1 <= PB_sync_0;
reg [17:0] PB_cnt;
wire PB_idle = (PB_state == PB_sync_1);
wire PB_cnt_max = &PB_cnt;
always @(posedge clk) begin
    if (PB_idle)
        PB_cnt <= 18'b0;
    else begin
        PB_cnt <= PB_cnt + 18'd1;
        if (PB_cnt_max)
            PB_state <= ~PB_state;
    end
end
endmodule

module segment_decoder (
    input [3:0] digit_in,
    output reg [7:0] seg_out
);
always @(digit_in) begin
    case (digit_in)
        4'b0000: seg_out = 8'b0011_1111;
        4'b0001: seg_out = 8'b0000_0110;
        4'b0010: seg_out = 8'b0101_1011;
        4'b0011: seg_out = 8'b0100_1111;
        4'b0100: seg_out = 8'b0110_0110;
        4'b0101: seg_out = 8'b0110_1101;
        4'b0110: seg_out = 8'b0111_1101;
        4'b0111: seg_out = 8'b0000_0111;
        4'b1000: seg_out = 8'b0111_1111;
        4'b1001: seg_out = 8'b0110_1111;
        4'b1010: seg_out = 8'b0111_0111;
        4'b1011: seg_out = 8'b0111_1100;
        4'b1100: seg_out = 8'b0011_1001;
        4'b1101: seg_out = 8'b0101_1110;
        4'b1110: seg_out = 8'b0111_1001;
        4'b1111: seg_out = 8'b0111_0001;
        default: seg_out = 8'b0000_0000;
    endcase
end
endmodule