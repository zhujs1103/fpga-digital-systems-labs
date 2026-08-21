module ssd(in, seg_led);
    input [3:0] in;
    output reg [7:0] seg_led;
    always @(*) begin
        case (in)
            4'h0: seg_led = 8'h3f;
            4'h1: seg_led = 8'h06;
            4'h2: seg_led = 8'h5b;
            4'h3: seg_led = 8'h4f;
            4'h4: seg_led = 8'h66;
            4'h5: seg_led = 8'h6d;
            4'h6: seg_led = 8'h7d;
            4'h7: seg_led = 8'h07;
            4'h8: seg_led = 8'h7f;
            4'h9: seg_led = 8'h6f;
            default: seg_led = 8'h80;
        endcase
    end
endmodule

module seven_segment_decoder(
    input [3:0] bcd,
    output [7:0] ssd
);
    ssd ssd1 (
        .in(bcd),
        .seg_led(ssd)
    );
endmodule

