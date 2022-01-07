module CTRL_UNIT(
        clk,
        opcode,
        reset,
        signals
 );

        input clk;
        input [6:0] opcode;
        input reset;
        output reg [22:0]signals;


        always @(posedge clk)
        begin: ctrl_unit_op
                case (opcode)  
                        7'b0010001 :    signals = 23'b01110100000101001100011;
                        7'b0000011 :    signals = 23'b01110101000100001100011;
                        7'b0011001 :    signals = 23'b01100100000101011100011;
                        7'b0011000 :    signals = 23'b01111100000101011100011;
                        7'b1100001 :    signals = 23'b00000000000001110000000;
                        7'b1101000 :    signals = 23'b01100100000001110100000;
                        7'b1100010 :    signals = 23'b01100100000000011100010;
                endcase 
        end // ctrl_unit_op
endmodule // CTRL_UNIT