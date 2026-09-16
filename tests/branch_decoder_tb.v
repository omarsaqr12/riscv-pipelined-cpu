`timescale 1ns / 1ps
// Run with: iverilog -g2012 -s branch_decoder_tb -o /tmp/branch_tb \
//   tests/branch_decoder_tb.v ArchProject/ArchProject.srcs/sources_1/branchDecoder.v
// vvp /tmp/branch_tb
module branch_decoder_tb;
  reg carryFlag, zeroFlag, overflowFlag, signFlag;
  reg [2:0] func3;
  wire branchOrNot;
  integer checks;
  branchDecoder dut(carryFlag, zeroFlag, overflowFlag, signFlag, func3, branchOrNot);
  task check;
    input [2:0] fn;
    input cf, zf, vf, sf, expected;
    begin
      func3 = fn; carryFlag = cf; zeroFlag = zf;
      overflowFlag = vf; signFlag = sf;
      #1;
      checks = checks + 1;
      if (branchOrNot !== expected) begin
        $display("FAIL branch fn=%b cf=%b zf=%b vf=%b sf=%b got=%b expected=%b",
                 fn, cf, zf, vf, sf, branchOrNot, expected);
        $fatal(1);
      end
    end
  endtask
  initial begin
    checks = 0;
    // Regression: a taken BEQ must become untaken on the next comparison.
    check(3'b000, 1, 1, 0, 0, 1);
    check(3'b000, 1, 0, 0, 0, 0);
    check(3'b001, 1, 0, 0, 0, 1);
    check(3'b001, 1, 1, 0, 0, 0);
    check(3'b100, 1, 0, 0, 1, 1);
    check(3'b100, 1, 0, 1, 1, 0);
    check(3'b101, 1, 0, 1, 1, 1);
    check(3'b101, 1, 0, 0, 1, 0);
    check(3'b110, 0, 0, 0, 0, 1);
    check(3'b110, 1, 0, 0, 0, 0);
    check(3'b111, 1, 0, 0, 0, 1);
    check(3'b111, 0, 0, 0, 0, 0);
    check(3'b010, 1, 1, 0, 0, 0);
    check(3'b011, 1, 1, 0, 0, 0);
    $display("PASS: %0d branch-decoder cases", checks);
    $finish;
  end
endmodule
