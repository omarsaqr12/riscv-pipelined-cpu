`timescale 1ns / 1ps

// Interpret the subtraction flags supplied by prv32_ALU for RV32I branches.
// The carry flag is 1 when unsigned subtraction requires no borrow.
module branchDecoder(
    input carryFlag,
    input zeroFlag,
    input overflowFlag,
    input signFlag,
    input [2:0] func3,
    output reg branchOrNot
);
    always @* begin
        // A default is essential: BEQ not taken must clear the preceding
        // decision instead of inferring a latch.
        branchOrNot = 1'b0;
        case (func3)
            3'b000: branchOrNot = zeroFlag;                    // BEQ
            3'b001: branchOrNot = !zeroFlag;                   // BNE
            3'b100: branchOrNot = (signFlag != overflowFlag);  // BLT
            3'b101: branchOrNot = (signFlag == overflowFlag);  // BGE
            3'b110: branchOrNot = !carryFlag;                  // BLTU
            3'b111: branchOrNot = carryFlag;                   // BGEU
            default: branchOrNot = 1'b0;
        endcase
    end
endmodule
