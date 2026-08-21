module breathingLED (
    input wire clk,
    input wire rst_n,
    output wire [2:0] rgb_n
);

wire rst;
assign rst = ~rst_n;
wire [2:0] rgb;
assign rgb_n = ~rgb;  

rainbow_breathe b(
    .clk(clk),
    .rst(rst),
    .rgb(rgb)
);

endmodule

// pwm.v PWM模块，占空比可调（0-255）
module pwm (
    input wire clk,
    input wire rst,
    // 占空比
    input wire [7:0] duty_cycle,
    output reg pwm_out
);
    
    reg [7:0] cnt;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 8'd0;
            pwm_out <= 0;
        end
        else begin
            cnt <= cnt + 1;
            // 若cnt小于duty_cycle，则输出高电平，否则输出低电平
            pwm_out <= (cnt < duty_cycle) ? 1'b1 : 1'b0;
        end
    end
    
endmodule

// rainbow_breathe.v 彩虹呼吸灯模块
module rainbow_breathe (
    // 时钟信号
    input wire clk,
    // 复位信号
    input wire rst,
    // RGB LED输出
    output wire [2:0] rgb
);
    
    // 三个通道的亮度值
    reg [7:0] brightness_r, brightness_g, brightness_b;
    // 三个通道的亮度变化方向
    reg direction_r, direction_g, direction_b;
    
    wire clk_d;
    
    // 时钟分频，控制呼吸速度
    divide #(.WIDTH(16), .N(20000)) d(  // 修改分频系数
        .clk(clk),
        .rst_n(~rst),  // 注意：divide模块使用rst_n
        .clkout(clk_d)
    );
    
    // 实例化3个PWM模块，分别用于控制RGB三个通道
    pwm pwm_r (
        .clk(clk),
        .rst(rst),
        .duty_cycle(brightness_r),
        .pwm_out(rgb[0])  // 红色通道
    );
    
    pwm pwm_g (
        .clk(clk),
        .rst(rst),
        .duty_cycle(brightness_g),
        .pwm_out(rgb[1])  // 绿色通道
    );
    
    pwm pwm_b (
        .clk(clk),
        .rst(rst),
        .duty_cycle(brightness_b),
        .pwm_out(rgb[2])  // 蓝色通道
    );
    
    // 红色通道亮度控制
    always @(posedge clk_d or posedge rst) begin
        if (rst) begin
            brightness_r <= 8'd0;
            direction_r <= 1'b0;
        end
        else begin
            if (direction_r == 1'b0) begin
                // 递增阶段
                if (brightness_r == 8'd255) begin
                    direction_r <= 1'b1;
                    brightness_r <= 8'd254;
                end
                else begin
                    brightness_r <= brightness_r + 8'd1;
                end
            end
            else begin
                // 递减阶段
                if (brightness_r == 8'd0) begin
                    direction_r <= 1'b0;
                    brightness_r <= 8'd1;
                end
                else begin
                    brightness_r <= brightness_r - 8'd1;
                end
            end
        end
    end
    
    // 绿色通道亮度控制（相位偏移85）
    always @(posedge clk_d or posedge rst) begin
        if (rst) begin
            brightness_g <= 8'd85;  // 初始相位偏移
            direction_g <= 1'b0;
        end
        else begin
            if (direction_g == 1'b0) begin
                // 递增阶段
                if (brightness_g == 8'd255) begin
                    direction_g <= 1'b1;
                    brightness_g <= 8'd254;
                end
                else begin
                    brightness_g <= brightness_g + 8'd1;
                end
            end
            else begin
                // 递减阶段
                if (brightness_g == 8'd0) begin
                    direction_g <= 1'b0;
                    brightness_g <= 8'd1;
                end
                else begin
                    brightness_g <= brightness_g - 8'd1;
                end
            end
        end
    end
    
    // 蓝色通道亮度控制（相位偏移170）
    always @(posedge clk_d or posedge rst) begin
        if (rst) begin
            brightness_b <= 8'd170;  // 初始相位偏移
            direction_b <= 1'b0;
        end
        else begin
            if (direction_b == 1'b0) begin
                // 递增阶段
                if (brightness_b == 8'd255) begin
                    direction_b <= 1'b1;
                    brightness_b <= 8'd254;
                end
                else begin
                    brightness_b <= brightness_b + 8'd1;
                end
            end
            else begin
                // 递减阶段
                if (brightness_b == 8'd0) begin
                    direction_b <= 1'b0;
                    brightness_b <= 8'd1;
                end
                else begin
                    brightness_b <= brightness_b - 8'd1;
                end
            end
        end
    end
    
endmodule

// divide.v 时钟分频模块
module divide #(
    parameter WIDTH = 24,
    parameter N = 12_000_000
)(
    input clk,
    input rst_n,
    output clkout
);
    
    reg [WIDTH-1:0] cnt_p, cnt_n;
    reg clk_p, clk_n;
    wire clk1, clk2, clk3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_p <= {WIDTH{1'b0}};
        end
        else if (cnt_p == (N-1)) begin
            cnt_p <= {WIDTH{1'b0}};
        end
        else begin
            cnt_p <= cnt_p + 1'b1;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_p <= 1'b0;
        end
        else if (cnt_p < (N >> 1)) begin
            clk_p <= 1'b0;
        end
        else begin
            clk_p <= 1'b1;
        end
    end
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_n <= {WIDTH{1'b0}};
        end
        else if (cnt_n == (N-1)) begin
            cnt_n <= {WIDTH{1'b0}};
        end
        else begin
            cnt_n <= cnt_n + 1'b1;
        end
    end
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_n <= 1'b0;
        end
        else if (cnt_n < (N >> 1)) begin
            clk_n <= 1'b0;
        end
        else begin
            clk_n <= 1'b1;
        end
    end
    
    assign clk1 = clk;
    assign clk2 = clk_p;
    assign clk3 = clk_p & clk_n;
    
    assign clkout = (N == 1) ? clk1 : (N[0] ? clk3 : clk2);
    
endmodule