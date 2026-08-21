module shift_reg(
    input din, clk, rst,
    output s_out,
    output reg [7:0] p_out
);
assign s_out = p_out[7];
always @(posedge clk) begin
    if(rst) p_out <= 8'h00;
    else begin
        p_out <= {p_out[6:0], din};
    end
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
 reg [17:0]PB_cnt;
wire PB_idle=(PB_state == PB_sync_1);
wire PB_cnt_max = &PB_cnt;
always @(posedge clk)
 if (PB_idle)
 PB_cnt <= 18'b0;
else
 begin
 PB_cnt <= PB_cnt + 18'd1;
if (PB_cnt_max)
 PB_state <= ~PB_state;
end
 endmodule

module shiftRegister(
    input data_botton, rst_switch, clk,
    output [7:0] led, 
    output led_g
);
wire data_debounced;
wire [7:0] ledd;
wire ledg;
assign led_g = ~ledg;
assign led = ~ledd;
Debouncer d1(
    .clk(clk),
    .PB(data_botton),
    .PB_state(data_debounced)
);
shift_reg reg1(
    .din(data_debounced),
    .clk(clk),
    .rst(rst_switch),
    .p_out(ledd),
    .s_out(ledg)
);
endmodule