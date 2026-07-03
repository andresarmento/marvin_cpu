`define HEX_FILES_PATH "C:/Users/andre/Downloads/PROJECTS/marvin_cpu/sw/"

module Marvin_ROM (
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] rdata
);
    reg [31:0] rom [0:255];

    initial $readmemh({`HEX_FILES_PATH, "00_fsm1.hex"}, rom);

    always @(posedge clk)
        rdata <= rom[addr[31:2]]; 
    
endmodule