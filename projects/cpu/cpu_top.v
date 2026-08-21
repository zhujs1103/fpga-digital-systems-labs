module cpu_top (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,      // 数据输入（用于从内存加载）
    output wire [7:0] data_out,    // 数据输出
    output wire [7:0] addr,        // 地址总线
    output wire mem_rd,            // 内存读使能
    output wire mem_wr,            // 内存写使能
    output wire [7:0] reg_out,     // 寄存器输出（用于调试）
    output wire [3:0] flags        // 标志位（用于调试）
);

// 内部信号定义
wire [7:0] instruction;
wire [7:0] alu_result;
wire [7:0] reg_a, reg_b;
wire [7:0] pc_value;
wire [2:0] alu_op;
wire reg_write;
wire [2:0] reg_dst;
wire [2:0] reg_src_a;
wire [2:0] reg_src_b;
wire pc_inc;
wire pc_load;
wire [7:0] pc_load_data;
wire mem_to_reg;
wire alu_src_b;

// 程序计数器实例
program_counter pc (
    .clk(clk),
    .rst_n(rst_n),
    .inc(pc_inc),
    .load(pc_load),
    .load_data(pc_load_data),
    .pc_out(pc_value)
);

// 指令存储器实例
instruction_memory imem (
    .address(pc_value),
    .instruction(instruction)
);

// 寄存器文件实例
register_file reg_file (
    .clk(clk),
    .rst_n(rst_n),
    .write_en(reg_write),
    .write_addr(reg_dst),
    .write_data(alu_result),
    .read_addr_a(reg_src_a),
    .read_addr_b(reg_src_b),
    .read_data_a(reg_a),
    .read_data_b(reg_b),
    .debug_out(reg_out)
);

// ALU实例
alu alu_unit (
    .a(reg_a),
    .b(alu_src_b ? {5'b00000, instruction[2:0]} : reg_b),  // 立即数扩展
    .op(alu_op),
    .result(alu_result),
    .flags(flags)
);

// 控制器实例
control_unit control (
    .clk(clk),
    .rst_n(rst_n),
    .instruction(instruction),
    .flags(flags),
    .alu_op(alu_op),
    .reg_write(reg_write),
    .reg_dst(reg_dst),
    .reg_src_a(reg_src_a),
    .reg_src_b(reg_src_b),
    .pc_inc(pc_inc),
    .pc_load(pc_load),
    .pc_load_data(pc_load_data),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .mem_to_reg(mem_to_reg),
    .alu_src_b(alu_src_b),
    .addr(addr)
);

// 内存接口
assign data_out = reg_b;

endmodule

// ----------------------------------------------------------------------------
// 程序计数器模块
// ----------------------------------------------------------------------------
module program_counter (
    input wire clk,
    input wire rst_n,
    input wire inc,
    input wire load,
    input wire [7:0] load_data,
    output reg [7:0] pc_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc_out <= 8'h00;
    end
    else begin
        if (load) begin
            pc_out <= load_data;           // 跳转或分支
        end
        else if (inc) begin
            pc_out <= pc_out + 8'd1;       // 顺序执行
        end
    end
end

endmodule

// ----------------------------------------------------------------------------
// 指令存储器模块
// ----------------------------------------------------------------------------
module instruction_memory (
    input wire [7:0] address,
    output reg [7:0] instruction
);

// 指令存储器（256字节）
reg [7:0] memory [0:255];

// 初始化指令存储器
integer i;
initial begin
    // 初始化为NOP指令
    for (i = 0; i < 256; i = i + 1) begin
        memory[i] = 8'b00000000;  // NOP
    end
    
    // 加载测试程序
    // 指令格式: [7:6]=opcode, [5:3]=Rd, [2:0]=Rs
    
    // 程序开始
    memory[0] = 8'b00001001;  // ADD R1, R1  (R1 = R1 + R1 = 0)
    memory[1] = 8'b00010001;  // ADD R2, R1  (R2 = R2 + R1 = 0)
    memory[2] = 8'b00100001;  // ADD R4, R1  (R4 = R4 + R1 = 0)
    
    memory[3] = 8'b00011001;  // ADD R3, R1  (R3 = R3 + R1 = 0)
    memory[4] = 8'b00100100;  // ADD R4, R4  (R4 = R4 + R4 = 0)
    
    // 加载立即数
    memory[5] = 8'b01100000;  // OR R0, #0  (伪立即数指令，实际使用寄存器)
    memory[6] = 8'b00000000;  // NOP
    
    // 算术运算
    memory[7] = 8'b00000001;  // ADD R0, R1
    memory[8] = 8'b00100010;  // ADD R4, R2
    memory[9] = 8'b01000101;  // AND R1, R5
    
    // 跳转测试
    memory[10] = 8'b11100000; // JMP #0   (跳转到地址0)
    memory[11] = 8'b00000000; // 立即数地址(0)
    
    // 填充剩余空间
    for (i = 12; i < 256; i = i + 1) begin
        memory[i] = 8'b00000000;  // NOP
    end
end

// 异步读取
always @(*) begin
    instruction = memory[address];
end

endmodule

// ----------------------------------------------------------------------------
// 寄存器文件模块
// ----------------------------------------------------------------------------
module register_file (
    input wire clk,
    input wire rst_n,
    input wire write_en,
    input wire [2:0] write_addr,
    input wire [7:0] write_data,
    input wire [2:0] read_addr_a,
    input wire [2:0] read_addr_b,
    output reg [7:0] read_data_a,
    output reg [7:0] read_data_b,
    output reg [7:0] debug_out
);

// 8个8位寄存器
reg [7:0] registers [0:7];

// 初始化寄存器
integer i;
initial begin
    for (i = 0; i < 8; i = i + 1) begin
        registers[i] = 8'h00;
    end
end

// 寄存器写操作（同步）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位所有寄存器
        for (i = 0; i < 8; i = i + 1) begin
            registers[i] <= 8'h00;
        end
    end
    else if (write_en) begin
        registers[write_addr] <= write_data;
    end
end

// 寄存器A读操作（组合逻辑）
always @(*) begin
    case (read_addr_a)
        3'd0: read_data_a = registers[0];
        3'd1: read_data_a = registers[1];
        3'd2: read_data_a = registers[2];
        3'd3: read_data_a = registers[3];
        3'd4: read_data_a = registers[4];
        3'd5: read_data_a = registers[5];
        3'd6: read_data_a = registers[6];
        3'd7: read_data_a = registers[7];
        default: read_data_a = 8'h00;
    endcase
end

// 寄存器B读操作（组合逻辑）
always @(*) begin
    case (read_addr_b)
        3'd0: read_data_b = registers[0];
        3'd1: read_data_b = registers[1];
        3'd2: read_data_b = registers[2];
        3'd3: read_data_b = registers[3];
        3'd4: read_data_b = registers[4];
        3'd5: read_data_b = registers[5];
        3'd6: read_data_b = registers[6];
        3'd7: read_data_b = registers[7];
        default: read_data_b = 8'h00;
    endcase
end

// 调试输出（显示寄存器0的值）
always @(*) begin
    debug_out = registers[0];
end

endmodule

// ----------------------------------------------------------------------------
// ALU模块
// ----------------------------------------------------------------------------
module alu (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] op,
    output reg [7:0] result,
    output reg [3:0] flags  // [Z,C,N,V] - 零标志, 进位标志, 负标志, 溢出标志
);

// ALU操作码定义
localparam ALU_ADD = 3'b000;  // 加法
localparam ALU_SUB = 3'b001;  // 减法
localparam ALU_AND = 3'b010;  // 与
localparam ALU_OR  = 3'b011;  // 或
localparam ALU_XOR = 3'b100;  // 异或
localparam ALU_NOT = 3'b101;  // 非
localparam ALU_SHL = 3'b110;  // 左移
localparam ALU_SHR = 3'b111;  // 右移

// 中间信号
wire [8:0] add_result;  // 9位用于检测进位
wire [8:0] sub_result;  // 9位用于检测借位

assign add_result = {1'b0, a} + {1'b0, b};
assign sub_result = {1'b0, a} - {1'b0, b};

// ALU核心逻辑
always @(*) begin
    // 默认值
    result = 8'h00;
    flags = 4'b0000;
    
    case (op)
        ALU_ADD: begin
            result = add_result[7:0];
            flags[1] = add_result[8];  // 进位标志
        end
        
        ALU_SUB: begin
            result = sub_result[7:0];
            flags[1] = sub_result[8];  // 借位标志
        end
        
        ALU_AND: begin
            result = a & b;
        end
        
        ALU_OR: begin
            result = a | b;
        end
        
        ALU_XOR: begin
            result = a ^ b;
        end
        
        ALU_NOT: begin
            result = ~a;
        end
        
        ALU_SHL: begin
            result = a << 1;
            flags[1] = a[7];  // 移出的位作为进位
        end
        
        ALU_SHR: begin
            result = a >> 1;
            flags[1] = a[0];  // 移出的位作为进位
        end
        
        default: begin
            result = 8'h00;
        end
    endcase
    
    // 设置零标志
    flags[0] = (result == 8'h00);
    
    // 设置负标志（最高位）
    flags[2] = result[7];
    
    // 设置溢出标志（有符号运算溢出）
    // 对于加法：如果两个操作数符号相同，但结果符号不同，则溢出
    // 对于减法：转换为加法判断
    if (op == ALU_ADD) begin
        flags[3] = (~(a[7] ^ b[7])) & (a[7] ^ result[7]);
    end
    else if (op == ALU_SUB) begin
        // a - b = a + (-b)，检查-b和a的符号
        flags[3] = (~(a[7] ^ (~b[7]))) & (a[7] ^ result[7]);
    end
    else begin
        flags[3] = 1'b0;
    end
end

endmodule

// ----------------------------------------------------------------------------
// 控制单元模块
// ----------------------------------------------------------------------------
module control_unit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] instruction,
    input wire [3:0] flags,
    output reg [2:0] alu_op,
    output reg reg_write,
    output reg [2:0] reg_dst,
    output reg [2:0] reg_src_a,
    output reg [2:0] reg_src_b,
    output reg pc_inc,
    output reg pc_load,
    output reg [7:0] pc_load_data,
    output reg mem_rd,
    output reg mem_wr,
    output reg mem_to_reg,
    output reg alu_src_b,
    output reg [7:0] addr
);

// 指令解码
wire [1:0] opcode;
wire [2:0] rd_addr;
wire [2:0] rs_addr;

assign opcode = instruction[7:6];  // 操作码
assign rd_addr = instruction[5:3]; // 目标寄存器
assign rs_addr = instruction[2:0]; // 源寄存器/立即数

// 状态定义
localparam STATE_FETCH   = 2'b00;
localparam STATE_DECODE  = 2'b01;
localparam STATE_EXECUTE = 2'b10;
localparam STATE_WRITEBACK = 2'b11;

reg [1:0] state;
reg [1:0] next_state;

// 状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= STATE_FETCH;
    end
    else begin
        state <= next_state;
    end
end

// 状态转移逻辑
always @(*) begin
    case (state)
        STATE_FETCH: begin
            next_state = STATE_DECODE;
        end
        
        STATE_DECODE: begin
            if (opcode == 2'b11) begin  // 跳转指令
                next_state = STATE_FETCH;
            end
            else begin
                next_state = STATE_EXECUTE;
            end
        end
        
        STATE_EXECUTE: begin
            next_state = STATE_WRITEBACK;
        end
        
        STATE_WRITEBACK: begin
            next_state = STATE_FETCH;
        end
        
        default: begin
            next_state = STATE_FETCH;
        end
    endcase
end

// 输出逻辑
always @(*) begin
    // 默认值
    alu_op = 3'b000;
    reg_write = 1'b0;
    reg_dst = 3'b000;
    reg_src_a = 3'b000;
    reg_src_b = 3'b000;
    pc_inc = 1'b0;
    pc_load = 1'b0;
    pc_load_data = 8'h00;
    mem_rd = 1'b0;
    mem_wr = 1'b0;
    mem_to_reg = 1'b0;
    alu_src_b = 1'b0;
    addr = 8'h00;
    
    case (state)
        STATE_FETCH: begin
            pc_inc = 1'b1;  // 递增PC，准备取下一指令
        end
        
        STATE_DECODE: begin
            case (opcode)
                2'b00: begin  // 算术/逻辑运算
                    alu_op = rs_addr;  // 使用rs字段作为ALU操作码
                    reg_src_a = rd_addr;
                    reg_src_b = rs_addr;
                    reg_dst = rd_addr;
                    alu_src_b = 1'b0;  // 使用寄存器值
                end
                
                2'b01: begin  // 立即数运算（简化版）
                    alu_op = 3'b000;  // 默认加法
                    reg_src_a = rd_addr;
                    reg_src_b = 3'b000;  // 不使用寄存器B
                    reg_dst = rd_addr;
                    alu_src_b = 1'b1;  // 使用立即数
                end
                
                2'b10: begin  // 内存操作（简化版）
                    mem_rd = 1'b1;
                    addr = {5'b00000, rs_addr};  // 简化地址
                end
                
                2'b11: begin  // 控制流
                    pc_load = 1'b1;
                    pc_load_data = {2'b00, instruction[5:0]};  // 跳转地址
                end
                
                default: begin
                    // NOP指令，不执行任何操作
                end
            endcase
        end
        
        STATE_EXECUTE: begin
            // 执行阶段，大部分工作在DECODE阶段已完成
            // 这里主要处理需要多周期的操作
        end
        
        STATE_WRITEBACK: begin
            reg_write = 1'b1;  // 允许写回寄存器
        end
    endcase
end

endmodule

// ----------------------------------------------------------------------------
// 测试模块
// ----------------------------------------------------------------------------
module cpu_testbench;

// 测试信号
reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;
wire [7:0] addr;
wire mem_rd, mem_wr;
wire [7:0] reg_out;
wire [3:0] flags;

// 内部信号（用于监控）
wire [7:0] monitor_pc;
wire [7:0] monitor_instruction;
wire [7:0] monitor_reg_a;
wire [7:0] monitor_reg_b;
wire [7:0] monitor_alu_result;
wire monitor_reg_write;
wire [2:0] monitor_reg_dst;

// 实例化CPU
cpu_complete cpu (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out),
    .addr(addr),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .reg_out(reg_out),
    .flags(flags)
);

// 连接到内部信号（用于监控）
assign monitor_pc = cpu.pc_value;
assign monitor_instruction = cpu.instruction;
assign monitor_reg_a = cpu.reg_a;
assign monitor_reg_b = cpu.reg_b;
assign monitor_alu_result = cpu.alu_result;
assign monitor_reg_write = cpu.reg_write;
assign monitor_reg_dst = cpu.reg_dst;

// 时钟生成
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 50MHz时钟（周期20ns）
end

// 测试主程序
initial begin
    // 初始化
    $display("================================================");
    $display("8位RISC CPU测试开始");
    $display("================================================");
    
    rst_n = 0;     // 复位
    data_in = 8'h00;
    #50;           // 等待一段时间
    
    $display("释放复位信号...");
    rst_n = 1;     // 释放复位
    #20;
    
    // 运行测试
    $display("开始执行测试程序...");
    $display("时间\tPC\t指令\t\tR0\tR1\tR2\tR3\t标志位");
    $display("------------------------------------------------");
    
    // 运行100个时钟周期
    #2000;
    
    // 显示最终结果
    $display("\n================================================");
    $display("测试完成");
    $display("寄存器R0的值: %h", reg_out);
    $display("标志位: Z=%b, C=%b, N=%b, V=%b", 
             flags[0], flags[1], flags[2], flags[3]);
    $display("================================================");
    
    #100;
    $finish;
end

// 监控器：每个时钟周期显示状态
always @(posedge clk) begin
    if (rst_n) begin
        $display("%t\t%h\t%b\t%h\t%h\t%h\t%h\t%b",
            $time,
            monitor_pc,
            monitor_instruction,
            cpu.reg_file.registers[0],
            cpu.reg_file.registers[1],
            cpu.reg_file.registers[2],
            cpu.reg_file.registers[3],
            flags);
    end
end

endmodule