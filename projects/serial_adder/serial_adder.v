module serial_adder(
    input clk_12M,          
    input [3:0] switches,  
    input [3:0] buttons,    
    output reg [4:0] led   
);

    reg [3:0] a_reg, b_reg; 
    wire cin;               
    wire [3:0] sum;         
    wire cout;              
    wire [3:0] button_debounced; 
    wire load_a, load_b, yes, rst;    
    
    debounce deb0(.clk(clk_12M), .button_in(buttons[0]), .button_out(button_debounced[0]));
    debounce deb1(.clk(clk_12M), .button_in(buttons[1]), .button_out(button_debounced[1]));
    debounce deb2(.clk(clk_12M), .button_in(buttons[2]), .button_out(button_debounced[2]));
    debounce deb3(.clk(clk_12M), .button_in(buttons[3]), .button_out(button_debounced[3]));
    
    assign load_a = ~button_debounced[0]; 
    assign load_b = ~button_debounced[1]; 
    assign yes = ~button_debounced[2];    
    assign rst = ~button_debounced[3];    
    
    assign cin = 1'b0; 
    
    serial_adder_4bit adder(
        .a(a_reg),
        .b(b_reg), 
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );
    
    always @(posedge clk_12M) begin
        if (rst) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
            led <= 5'b11111;
        end else begin
            if (load_a) 
                a_reg <= switches; 
            if (load_b) 
                b_reg <= switches; 
            if (yes) begin
                led[3:0] <= ~sum;
                led[4] <= ~cout;
            end
        end
    end

endmodule

module serial_adder_4bit(
    input [3:0] a,
    input [3:0] b, 
    input cin,
    output [3:0] sum,
    output cout
);
    
    wire [2:0] c; 
    
    full_adder fa0(.a(a[0]), .b(b[0]), .cin(cin),  .sum(sum[0]), .cout(c[0]));
    full_adder fa1(.a(a[1]), .b(b[1]), .cin(c[0]), .sum(sum[1]), .cout(c[1]));
    full_adder fa2(.a(a[2]), .b(b[2]), .cin(c[1]), .sum(sum[2]), .cout(c[2]));
    full_adder fa3(.a(a[3]), .b(b[3]), .cin(c[2]), .sum(sum[3]), .cout(cout));
    
endmodule

module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
    
endmodule

module debounce(
    input clk,
    input button_in,
    output reg button_out
);
    
    reg [19:0] count;
    reg button_sync;
    
    always @(posedge clk) begin
        button_sync <= button_in;
        
        if (button_sync == button_out) begin
            count <= 0;
        end else begin
            count <= count + 1;
            if (count == 20'd240000) begin 
                button_out <= button_sync;
                count <= 0;
            end
        end
    end
    
endmodule
