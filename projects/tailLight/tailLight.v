// tailLight.v 汽车尾灯控制模块 - 共阳LED版本
module tailLight(
    input wire clk,            // 板载时钟12MHz
    input wire rst_n,          // 异步复位，低电平有效
    input wire[3:0] state_in,  // 车辆状态输入
    output reg[2:0] led_left,  // 左尾灯RGB输出（低电平有效）
    output reg[2:0] led_right, // 右尾灯RGB输出（低电平有效）
    output reg[7:0] led_flow   // 流水灯显示（低电平有效）
);

// ================== 参数定义 ==================
// 车辆行驶状态编码
parameter STOP   = 4'b0001;  // 停止/故障
parameter GO     = 4'b0010;  // 直行
parameter LEFT   = 4'b0100;  // 左转
parameter RIGHT  = 4'b1000;  // 右转
parameter BACK   = 4'b0110;  // 倒车

// LED颜色定义（共阳，低电平有效）
// RGB: bit2=红色, bit1=绿色, bit0=蓝色
parameter RED    = 3'b011;   // 红色亮：低电平点亮红色，高电平熄灭绿色和蓝色
parameter GREEN  = 3'b101;   // 绿色亮：低电平点亮绿色，高电平熄灭红色和蓝色
parameter BLUE   = 3'b110;   // 蓝色亮：低电平点亮蓝色，高电平熄灭红色和绿色
parameter YELLOW = 3'b001;   // 黄色亮：红+绿，低电平点亮红色和绿色
parameter CYAN   = 3'b010;   // 青色亮：绿+蓝，低电平点亮绿色和蓝色
parameter PURPLE = 3'b100;   // 紫色亮：红+蓝，低电平点亮红色和蓝色
parameter WHITE  = 3'b000;   // 白色亮：低电平点亮所有颜色
parameter OFF    = 3'b111;   // 全灭：高电平所有颜色

// 流水灯定义（低电平有效）
parameter FLOW_ALL_ON  = 8'b0000_0000;  // 所有流水灯亮
parameter FLOW_LEFT_ON = 8'b0000_1111;  // 左侧4个流水灯亮（低电平亮）
parameter FLOW_RIGHT_ON= 8'b1111_0000;  // 右侧4个流水灯亮（低电平亮）
parameter FLOW_ALL_OFF = 8'b1111_1111;  // 所有流水灯灭

// 时钟分频参数 (12MHz时钟)
parameter CLK_FREQ = 12_000_000;   // 12MHz系统时钟
parameter CNT_1HZ_WIDTH = 24;      // 1Hz分频计数器位宽
parameter CNT_1HZ_VALUE = CLK_FREQ;  // 12,000,000 cycles for 1Hz
parameter CNT_1HZ_HALF = CNT_1HZ_VALUE / 2;  // 半周期用于50%占空比

// 流水灯控制参数
parameter FLOW_SPEED = 1_500_000;  // 流水灯速度(8Hz)

// ================== 内部信号定义 ==================
reg [CNT_1HZ_WIDTH-1:0] cnt_1hz;     // 1Hz分频计数器
reg [23:0] cnt_flow;                  // 流水灯分频计数器
reg blink_en;                         // 闪烁使能
reg flow_tick;                        // 流水灯节拍
reg [2:0] blink_signal;               // 闪烁信号（低电平有效）
reg [3:0] current_state;              // 当前状态
reg [3:0] next_state;                 // 下一状态
reg [7:0] flow_reg;                   // 流水灯状态寄存器（低电平有效）

// ================== 1Hz分频器 (50%占空比) ==================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_1hz <= {CNT_1HZ_WIDTH{1'b0}};
        blink_en <= 1'b0;
    end
    else begin
        if (cnt_1hz >= CNT_1HZ_VALUE - 1) begin
            cnt_1hz <= {CNT_1HZ_WIDTH{1'b0}};
        end
        else begin
            cnt_1hz <= cnt_1hz + 1'b1;
        end
        
        // 生成50%占空比的1Hz信号blink_en
        if (cnt_1hz < CNT_1HZ_HALF) begin
            blink_en <= 1'b1;
        end
        else begin
            blink_en <= 1'b0;
        end
    end
end

// ================== 流水灯分频器 ==================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_flow <= 24'd0;
        flow_tick <= 1'b0;
    end
    else begin
        if (cnt_flow >= FLOW_SPEED - 1) begin
            cnt_flow <= 24'd0;
            flow_tick <= 1'b1;
        end
        else begin
            cnt_flow <= cnt_flow + 1'b1;
            flow_tick <= 1'b0;
        end
    end
end
// flow_tick在每FLOW_SPEED个时钟周期产生一个高脉冲，用于控制流水灯移动速度

// ================== 闪烁信号生成 ==================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        blink_signal <= OFF;  // 复位时LED灭
    end
    else begin
        // 闪烁时在红色和关闭之间切换 (1Hz)
        if (blink_en) begin
            blink_signal <= RED;  // 亮红灯
        end
        else begin
            blink_signal <= OFF;  // 熄灭
        end
    end
end

// ================== 状态机 ==================
// 状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= STOP;
    end
    else begin
        current_state <= next_state;
    end
end

// 状态转移逻辑 - 直接使用输入作为下一状态
always @(*) begin
    case (state_in)
        4'b0001: next_state = STOP;
        4'b0010: next_state = GO;
        4'b0100: next_state = LEFT;
        4'b1000: next_state = RIGHT;
        4'b0110: next_state = BACK;
        default: next_state = STOP;  // 默认停止状态
    endcase
end

// ================== 流水灯状态寄存器控制 ==================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flow_reg <= 8'b1111_1110;  // 初始状态：最右侧灯亮（低电平有效，0表示亮）
    end
    else begin
        case (current_state)
            GO: begin  // 直行状态：流水灯向前流动（从右向左）
                if (flow_tick) begin
                    // 向前流动：向右循环移位（0向左移动）
                    // 例如：11111110 -> 11111101 -> 11111011 -> ...
                    flow_reg <= {flow_reg[0], flow_reg[7:1]};
                end
            end
            
            BACK: begin  // 倒车状态：流水灯向后流动（从左向右）
                if (flow_tick) begin
                    // 向后流动：向左循环移位（0向右移动）
                    // 例如：11111110 -> 11111101? 不对，应该是 01111111 -> 10111111 -> ...
                    // 修正：对于低电平有效，亮灯位置应该从右向左移动表示向前
                    // 向后流动应该是亮灯位置从左向右移动
                    flow_reg <= {flow_reg[6:0], flow_reg[7]};
                end
            end
            
            // 其他状态：流水灯保持固定模式
            default: begin
                // 保持不变，不需要额外操作
            end
        endcase
    end
end
// flow_reg寄存器控制流水灯的移动模式

// ================== 主输出逻辑 ==================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位状态：两侧红灯闪烁
        led_left <= OFF;           // 初始状态灭
        led_right <= OFF;          // 初始状态灭
        led_flow <= FLOW_ALL_OFF;  // 所有流水灯灭
    end
    else begin
        // 根据当前状态控制输出
        case (current_state)
            STOP: begin  // 停车/故障：两侧红灯同时闪烁，流水灯全亮
                led_left <= blink_signal;   // 红灯闪烁
                led_right <= blink_signal;  // 红灯闪烁
                led_flow <= FLOW_ALL_ON;    // 所有流水灯亮（低电平）
            end
            
            GO: begin  // 直行：尾灯不亮，流水灯向前流动
                led_left <= OFF;      // 尾灯灭
                led_right <= OFF;     // 尾灯灭
                led_flow <= flow_reg; // 使用流水灯状态寄存器
            end
            
            LEFT: begin  // 左转：左侧红灯闪烁，右侧不亮，左侧流水灯亮
                led_left <= blink_signal;      // 左侧红灯闪烁
                led_right <= OFF;              // 右侧尾灯灭
                led_flow <= FLOW_LEFT_ON;      // 左侧4个流水灯亮（低电平）
            end
            
            RIGHT: begin  // 右转：右侧红灯闪烁，左侧不亮，右侧流水灯亮
                led_left <= OFF;               // 左侧尾灯灭
                led_right <= blink_signal;     // 右侧红灯闪烁
                led_flow <= FLOW_RIGHT_ON;     // 右侧4个流水灯亮（低电平）
            end
            
            BACK: begin  // 倒车：白灯常亮，流水灯向后流动
                led_left <= WHITE;    // 白色常亮（低电平点亮所有颜色）
                led_right <= WHITE;   // 白色常亮（低电平点亮所有颜色）
                led_flow <= flow_reg; // 使用流水灯状态寄存器
            end
            
            default: begin  // 默认：同STOP状态
                led_left <= blink_signal;
                led_right <= blink_signal;
                led_flow <= FLOW_ALL_ON;
            end
        endcase
    end
end

endmodule