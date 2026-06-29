`timescale 1ns / 1ps

module singleMemory(
input clk,
input MemRead,
input MemWrite,
input [2:0] func3,
input [11:0] addr,
input [31:0] data_in,
output [31:0] data_out
    );
    reg [7:0] mem[(4*1024-1):0];


  // Program image: one byte per line (binary), little-endian per 32-bit word.
  // A sample is provided in Test_cases/program.mem (produced by Instruction_generator.py).
  // The path is resolved relative to the simulator's working directory; adjust if needed.
  initial begin
    $readmemb("program.mem", mem);
  end


 
   always @(*) begin
    
    if (clk == 0) 
    begin if (MemWrite) begin
        case (func3)
            3'b000: begin // Byte
                mem[addr] <= data_in[7:0];
            end
            3'b001: begin // Halfword
                mem[addr]     <= data_in[7:0];
                mem[addr + 1] <= data_in[15:8];
            end
            3'b010: begin // Word
                mem[addr]     <= data_in[7:0];
                mem[addr + 1] <= data_in[15:8];
                mem[addr + 2] <= data_in[23:16];
                mem[addr + 3] <= data_in[31:24];
            end
            default: begin
                mem[addr] <= data_in[7:0]; // Defaulting to byte write
            end
        endcase
    end
end
end

 assign data_out = (clk) ? {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]} : // Read Instruction
                                   ((MemRead) ? ((func3 == 3'b000) ? {(mem[addr][7] == 1) ? 24'b111111111111111111111111 : 24'b0, mem[addr]} : //lb
                                   (func3 == 3'b001) ? {(mem[addr+1][7] == 1) ? 16'b1111111111111111 : 16'b0, mem[addr + 1], mem[addr]} : //lh
                                   (func3 == 3'b010) ? {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]} : //lw
                                   (func3 == 3'b100) ? {24'b0, mem[addr]} : //lbu
                                   (func3 == 3'b101) ? {16'b0, mem[addr + 1], mem[addr]} : 32'b0) : 32'bx); //lhu ; 












endmodule
