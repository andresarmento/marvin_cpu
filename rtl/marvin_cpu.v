module Marvin_CPU (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] mem_addr,
    input  wire [31:0] mem_rdata,
    output wire        mem_valid,
    input  wire        mem_ready,
    output wire [31:0] dbg_IR
);

// Registers
reg [31:0] PC;
reg [31:0] IR;
reg [31:0] regFile [0:31];

// Init and assignments
integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) regFile[i] = 32'b0;
end
assign mem_addr = PC;
assign mem_valid = state[S_FETCH_bit] | state[S_WAIT_bit];
assign dbg_IR   = IR;

// FSM
localparam S_FETCH   = 3'b001,
           S_WAIT    = 3'b010,
           S_EXECUTE = 3'b100;

localparam S_FETCH_bit   = 0,
           S_WAIT_bit    = 1,
           S_EXECUTE_bit = 2;
reg [2:0] state;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_FETCH;
        PC <= 32'b0;
        IR <= 32'b0;
    end else begin
        case (1'b1)
            state[S_FETCH_bit]: begin          // Presents mem_addr = PC
                state <= S_WAIT;     
            end
            
            state[S_WAIT_bit]: begin
                if (mem_ready) begin
                    IR <= mem_rdata;    // Now mem_rdata is stable (1 cycle memory latency)
                    state <= S_EXECUTE;
                end
            end

            state[S_EXECUTE_bit]: begin
                PC <= PC + 4;
                state <= S_FETCH;
            end

            default: state <= S_FETCH;
        endcase
    end
end
endmodule