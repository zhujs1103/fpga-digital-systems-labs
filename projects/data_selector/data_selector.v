module mux8to1 (
    input [7:0] data_in,
    input [2:0] sel,
    output reg data_out
);
    always@(*) begin
        case(sel)
            3'b000: data_out = data_in[0];
            3'b001: data_out = data_in[1];
            3'b010: data_out = data_in[2];
            3'b011: data_out = data_in[3];
            3'b100: data_out = data_in[4];
            3'b101: data_out = data_in[5];
            3'b110: data_out = data_in[6];
            3'b111: data_out = data_in[7];
            default: data_out = 1'b0;
        endcase
    end
endmodule

module data_selector (
    input [3:0] in,
    input [1:0] sel,
    output led
);
    mux8to1 mux1(
        .data_in({4'b0000, in}),
        .sel({1'b0, sel}),
        .data_out(led)
    );
endmodule