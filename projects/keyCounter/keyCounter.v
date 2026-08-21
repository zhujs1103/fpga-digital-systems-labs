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

module kcnter(
    input key,
    input clk,
    input rst,
    output reg [7:0] cnt
);
reg key_prev;
always @(posedge clk) begin
    if (rst) begin
        cnt <= 8'b0;
        key_prev <= 1'b0;
    end else begin
        if (!key_prev && key) begin
            if (cnt == 8'h99) begin
                cnt <= 8'h00;
            end else begin
                if (cnt[3:0] == 4'h9) begin
                    cnt <= cnt + 8'h07;
                end else begin
                    cnt <= cnt + 8'h01;
                end
            end
        end
        key_prev <= key;
    end 
end
endmodule

module keyCounter(
    input clk,
    input key,
    input rst,
    output [7:0] seg_tens,
    output [7:0] seg_units
);
wire [7:0] cnt;
wire key_s;
wire rst_s;
Debouncer db1(
    .clk(clk),
    .PB(key),
    .PB_state(key_s)
);
Debouncer db2(
    .clk(clk),
    .PB(rst),
    .PB_state(rst_s)
);
kcnter kct(
    .key(key_s),
    .clk(clk),
    .rst(rst_s),
    .cnt(cnt)
);
segment_decoder seg1(
    .digit_in(cnt[7:4]),
    .seg_out(seg_tens)
);
segment_decoder seg2(
    .digit_in(cnt[3:0]),
    .seg_out(seg_units)
);
endmodule