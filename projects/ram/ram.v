module ram256x8(
input clk, // 时钟
input we, // 写使能
input [7:0] addr, // 地址总线输入
input [7:0] data_in, // 数据输入
output [7:0] data_out // 数据输出
);
reg [7:0] ram[255:0]; // 256 * 8存储矩阵
always @(posedge clk)
if (we) ram[addr] <= data_in; // 写使能有效，数据写入存储单元
assign data_out = ram[addr]; // 读操作，data_out输出addr单元的值
endmodule

module ram(
    input [1:0] ad,
    input [1:0] data,
    input we_n,
    input clk,
    output [7:0] led_n
);
wire we;
assign we = ~we_n;
wire [7:0] led;
assign led_n = ~led;
ram256x8 u_ram256x8 (
    .clk(clk),
    .we(we),
    .addr({6'b0, ad}), // 地址扩展为8位
    .data_in({6'b0, data}), // 数据扩展为8位
    .data_out(led)
);
endmodule