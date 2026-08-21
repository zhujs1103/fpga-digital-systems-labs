module the_box(
    input clk,
    input rst_n,
    input [3:0] pwd_input,
    input confirm_key,
    input unit_confirm,
    input ten_confirm,
    output reg [7:0] led,
    output reg [8:0] seg_led1,
    output reg [8:0] seg_led2
);

parameter INIT_PWD_TEN = 4'd1;
parameter INIT_PWD_UNIT = 4'd2;
parameter CLK_FREQ = 12_000_000;

parameter [2:0] IDLE      = 3'd0,
                INPUT_PWD = 3'd1,
                CHECK     = 3'd2,
                UNLOCK    = 3'd3,
                MOD_PWD   = 3'd4,
                ERROR     = 3'd5,
                ALARM     = 3'd6;

reg [2:0] current_state, next_state;
reg [1:0] error_cnt;
reg [3:0] unit_pwd, ten_pwd;
reg [3:0] new_unit_pwd, new_ten_pwd;
reg mod_flag;
reg [23:0] counter;
reg alarm_led_state;

wire confirm_d, unit_confirm_d, ten_confirm_d;

debounce #(
    .N(3),
    .CLK_FREQ(CLK_FREQ),
    .DELAY_MS(20)
) debounce_inst (
    .clk(clk),
    .rst(rst_n),
    .key({confirm_key, unit_confirm, ten_confirm}),
    .key_pulse({confirm_d, unit_confirm_d, ten_confirm_d})
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE: begin
            if (unit_confirm_d || ten_confirm_d) 
                next_state = INPUT_PWD;
            else 
                next_state = IDLE;
        end
        
        INPUT_PWD: begin
            if (confirm_d) 
                next_state = CHECK;
            else 
                next_state = INPUT_PWD;
        end
        
        CHECK: begin
            if ((unit_pwd == INIT_PWD_UNIT && ten_pwd == INIT_PWD_TEN) || 
                (mod_flag && unit_pwd == new_unit_pwd && ten_pwd == new_ten_pwd)) begin
                next_state = UNLOCK;
            end else begin
                if (error_cnt >= 2'd2)
                    next_state = ALARM;
                else
                    next_state = ERROR;
            end
        end
        
        UNLOCK: begin
            if (unit_confirm_d || ten_confirm_d) 
                next_state = MOD_PWD;
            else 
                next_state = UNLOCK;
        end
        
        MOD_PWD: begin
            next_state = UNLOCK;
        end
        
        ERROR: begin
            next_state = INPUT_PWD;
        end
        
        ALARM: begin
            next_state = ALARM;
        end
        
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 24'd0;
        alarm_led_state <= 1'b0;
    end else begin
        counter <= counter + 1'b1;
        if (counter == 24'h7FFFFF) begin
            alarm_led_state <= ~alarm_led_state;
            counter <= 24'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        error_cnt <= 2'b00;
        unit_pwd <= 4'b0000;
        ten_pwd <= 4'b0000;
        new_unit_pwd <= INIT_PWD_UNIT;
        new_ten_pwd <= INIT_PWD_TEN;
        mod_flag <= 1'b0;
        led <= 8'b11111111;
    end else begin
        case (current_state)
            IDLE: begin
                led <= 8'b11111111;
            end
            
            INPUT_PWD: begin
                led <= 8'b00000000;
                
                if (ten_confirm_d) begin
                    ten_pwd <= pwd_input;
                end else if (unit_confirm_d) begin
                    unit_pwd <= pwd_input;
                end
            end
            
            CHECK: begin
                if ((unit_pwd == INIT_PWD_UNIT && ten_pwd == INIT_PWD_TEN) || 
                    (mod_flag && unit_pwd == new_unit_pwd && ten_pwd == new_ten_pwd)) begin
                    led <= 8'b00000001;
                    error_cnt <= 2'b00;
                    mod_flag <= 1'b1;
                end else begin
                    led <= 8'b10000000;
                    error_cnt <= error_cnt + 1'b1;
                end
            end
            
            UNLOCK: begin
                led <= 8'b00000001;
                
                if (ten_confirm_d) begin
                    new_ten_pwd <= pwd_input;
                end else if (unit_confirm_d) begin
                    new_unit_pwd <= pwd_input;
                end
            end
            
            ERROR: begin
                led <= 8'b10000000;
            end
            
            ALARM: begin
                if (alarm_led_state) begin
                    led <= 8'b11110000;
                end else begin
                    led <= 8'b00001111;
                end
            end
            
            default: begin
                led <= 8'b11111111;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        seg_led1 <= 9'b00_0111111;
        seg_led2 <= 9'b00_0111111;
    end else begin
        case (unit_pwd)
            4'd0: seg_led1 <= 9'b00_0111111;
            4'd1: seg_led1 <= 9'b00_0000110;
            4'd2: seg_led1 <= 9'b00_1011011;
            4'd3: seg_led1 <= 9'b00_1001111;
            4'd4: seg_led1 <= 9'b00_1100110;
            4'd5: seg_led1 <= 9'b00_1101101;
            4'd6: seg_led1 <= 9'b00_1111101;
            4'd7: seg_led1 <= 9'b00_0000111;
            4'd8: seg_led1 <= 9'b00_1111111;
            4'd9: seg_led1 <= 9'b00_1101111;
            default: seg_led1 <= 9'b00_0111111;
        endcase
        
        case (ten_pwd)
            4'd0: seg_led2 <= 9'b00_0111111;
            4'd1: seg_led2 <= 9'b00_0000110;
            4'd2: seg_led2 <= 9'b00_1011011;
            4'd3: seg_led2 <= 9'b00_1001111;
            4'd4: seg_led2 <= 9'b00_1100110;
            4'd5: seg_led2 <= 9'b00_1101101;
            4'd6: seg_led2 <= 9'b00_1111101;
            4'd7: seg_led2 <= 9'b00_0000111;
            4'd8: seg_led2 <= 9'b00_1111111;
            4'd9: seg_led2 <= 9'b00_1101111;
            default: seg_led2 <= 9'b00_0111111;
        endcase
    end
end

endmodule

module debounce #(
    parameter N = 1,
    parameter CLK_FREQ = 50_000_000,
    parameter DELAY_MS = 20
)(
    input clk,
    input rst,
    input [N-1:0] key,
    output [N-1:0] key_pulse
);

localparam CNT_MAX = (CLK_FREQ * DELAY_MS) / 1000;

reg [N-1:0] key_rst;
reg [N-1:0] key_rst_pre;
reg [19:0] cnt;
reg [N-1:0] key_sec;
reg [N-1:0] key_sec_pre;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        key_rst <= {N{1'b1}};
        key_rst_pre <= {N{1'b1}};
    end else begin
        key_rst <= key;
        key_rst_pre <= key_rst;
    end
end

wire [N-1:0] key_edge = key_rst_pre & (~key_rst);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        cnt <= 20'd0;
    end else if (|key_edge) begin
        cnt <= 20'd0;
    end else if (cnt < CNT_MAX) begin
        cnt <= cnt + 1'b1;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        key_sec <= {N{1'b1}};
    end else if (cnt == CNT_MAX) begin
        key_sec <= key;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        key_sec_pre <= {N{1'b1}};
    end else begin
        key_sec_pre <= key_sec;
    end
end

assign key_pulse = key_sec_pre & (~key_sec);

endmodule