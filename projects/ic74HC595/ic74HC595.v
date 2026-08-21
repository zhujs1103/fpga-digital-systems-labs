module HC595(
    input sclr_n, si, sck, rck, g_n,
    output qh, qg, qf, qe, qd, qc, qb, qa, qh_qout
);
    reg [7:0] shift_dffs;
    reg [7:0] storge_dffs;
    
    always @(posedge sck or negedge sclr_n) begin
        if (~sclr_n) 
            shift_dffs[7:0] <= 8'h00;
        else 
            shift_dffs[7:0] <= {shift_dffs[6:0], si};
    end
    
    always @(posedge rck) begin
        storge_dffs[7:0] <= shift_dffs[7:0];
    end
    
    assign qh_qout = shift_dffs[7];
    assign {qh,qg,qf,qe,qd,qc,qb,qa} = g_n ? 8'bzzzzzzzz : storge_dffs[7:0];
endmodule

module SSD (
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
            default: seg_out = 8'b1000_0000;
        endcase
    end
endmodule

module clk_divider(
    input clk_in,
    output reg clk_out
);
    parameter N = 12000000;
    reg [23:0] counter;
    
    always @(posedge clk_in) begin
        if (counter == (N - 1))
            counter <= 0;
        else
            counter <= counter + 1;
    end
    
    always @(posedge clk_in) begin
        if (counter == (N - 1))
            clk_out <= ~clk_out;
    end
endmodule

module ic74HC595(
    input clk,
    input data,
    input catch,
    output [7:0] led,
    output ledg,
    output [7:0] seg0,
    output [7:0] seg1
);
    wire clk_slow;
    wire [7:0] dout;
    wire ledgn;
    
    clk_divider cd(
        .clk_in(clk), 
        .clk_out(clk_slow)
    );
    
    
    HC595 IC1(
        .sclr_n(1'b1),
        .si(data),
        .sck(clk_slow),
        .rck(catch),
        .g_n(1'b0),
        .qa(dout[0]),
        .qb(dout[1]),
        .qc(dout[2]),
        .qd(dout[3]),
        .qe(dout[4]),
        .qf(dout[5]),
        .qg(dout[6]),
        .qh(dout[7]),
        .qh_qout(ledgn)
    );
    
    SSD ssd0(
        .digit_in(dout[3:0]),
        .seg_out(seg0)
    );
    
    SSD ssd1(
        .digit_in(dout[7:4]),
        .seg_out(seg1)
    );
    
    assign led = ~dout;
    assign ledg = ~ledgn;
endmodule