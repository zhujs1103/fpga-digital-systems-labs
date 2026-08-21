module JK_trigger(
    input J, K, clk,
    output reg Q,
    output Qn
);
assign Qn = ~Q;
always@(posedge clk)
case({J,K})
    2'b00: Q <= Q;
    2'b01: Q <= 1'b0;
    2'b10: Q <= 1'b1;
    2'b11: Q <= ~Q;
endcase
endmodule

module dec_cnt(
    input clk, oe,
    output [3:0] dout
);
wire j1, k1, j2, k2, j3, k3;
wire q0, q1, q2, q3, q0n, q1n, q2n, q3n;


assign j1 = q0 & q3n;      // J1 = Q0·Q̅3
assign k1 = q0;            // K1 = Q0
assign j2 = q0 & q1;       // J2 = Q0·Q1
assign k2 = q0 & q1;       // K2 = Q0·Q1
assign j3 = q0 & q1 & q2;  // J3 = Q0·Q1·Q2
assign k3 = q0;            // K3 = Q0


JK_trigger jk0_inst(.J(1'b1), .K(1'b1), .clk(clk), .Q(q0), .Qn(q0n));
JK_trigger jk1_inst(.J(j1), .K(k1), .clk(clk), .Q(q1), .Qn(q1n));
JK_trigger jk2_inst(.J(j2), .K(k2), .clk(clk), .Q(q2), .Qn(q2n));
JK_trigger jk3_inst(.J(j3), .K(k3), .clk(clk), .Q(q3), .Qn(q3n));


reg [3:0] cnt_out;
always @(posedge clk) begin
    cnt_out <= {q3, q2, q1, q0};
    if (cnt_out == 4'b1010) begin
        cnt_out <= 4'b0000;
    end
end

assign dout = oe ? cnt_out : 4'b0000;
endmodule

module clk_divider(
    input clk_in,
    output reg clk_out
);
parameter N = 24'd12_000_000;
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

module decCounterByJK(
    input clk,
    input oe,
    output [3:0] led
);
wire clk_slow;
wire [3:0] cnt_value;

clk_divider cd1(
    .clk_in(clk),
    .clk_out(clk_slow)
);


dec_cnt cnt1(
    .clk(clk_slow),
    .oe(oe),
    .dout(cnt_value)
);


assign led = ~cnt_value;

endmodule