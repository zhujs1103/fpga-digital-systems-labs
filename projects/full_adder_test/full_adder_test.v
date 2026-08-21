module _74LS138(
    input wire G1,
    input wire G2A,
    input wire G2B,
    input wire [2:0] address,
    output reg [7:0] outputs
);
    always @(*) begin
        if (G1 & ~G2A & ~G2B) begin
            case (address)
                3'b000: outputs = 8'b11111110;
                3'b001: outputs = 8'b11111101;
                3'b010: outputs = 8'b11111011;
                3'b011: outputs = 8'b11110111;
                3'b100: outputs = 8'b11101111;
                3'b101: outputs = 8'b11011111;
                3'b110: outputs = 8'b10111111;
                3'b111: outputs = 8'b01111111;
                default: outputs = 8'b11111111;
            endcase
        end else begin
            outputs = 8'b11111111;
        end
    end
endmodule


module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    
    wire [7:0] out;
    
    _74LS138 u1(
        .G1(1'b1),
        .G2A(1'b0),
        .G2B(1'b0),
        .address({a, b, cin}),
        .outputs(out)
    );
    
    assign sum = ~(out[1] & out[2] & out[4] & out[7]);
    assign cout = ~(out[3] & out[5] & out[6] & out[7]);
    
endmodule


module full_adder_test(
    input wire [2:0] sw,
    output wire sum_led,
    output wire cout_led
);
    
    wire a, b, cin;
    wire sum_result, cout_result;
    
    assign a = ~sw[0];
    assign b = ~sw[1]; 
    assign cin = ~sw[2];
    
    full_adder u_full_adder(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum_result),
        .cout(cout_result)
    );
    
    assign sum_led = sum_result;
    assign cout_led = cout_result;
    
endmodule