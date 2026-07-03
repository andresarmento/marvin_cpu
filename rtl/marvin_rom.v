`define HEX_FILES_PATH "C:/Users/andre/Downloads/PROJECTS/marvin_cpu/sw/"

module Marvin_ROM (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    output reg  [31:0] rdata,
    input  wire        valid,
    output reg         ready
);
    reg [31:0] rom [0:255];

    initial $readmemh({`HEX_FILES_PATH, "00_fsm2.hex"}, rom);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
        end else begin
            ready <= valid;
            if (valid) rdata <= rom[addr[31:2]];
        end
    end
    
endmodule