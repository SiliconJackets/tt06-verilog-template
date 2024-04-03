`ifndef TOP
`define TOP
`include "PE_if.svh"
`include "PE_controller_if.svh"

module top(
    input logic clk,
    input logic nRST,
    input logic [7:0] readA,
    input logic [7:0] readB,
    output logic [7:0] write
);

    logic [4:0] PERead;
    logic [4:0] PEStart;
    logic [2:0] filtRead;

    logic [2:0] PENewOuput;

    topLevelControl U1(
        .clk(clk),
        .nRST(nRST),
        .readA(readA),
        .readB(readB),
        .PERead(PERead),
        .PEStart(PEStart),
        .filtRead(filtRead)
    );

    //PE Group 0
    //PE 0,0
    logic [7:0] PE00psum_i;
    assign PE00psum_i = (PERead[4]) ? readA : readB;
    PE_if PED00();
    PE_controller_if PEC0();
    assign PED00.psum_i = PE00psum_i;
    assign PED00.filter_i = readB;
    assign PED00.ifmap_i = readA;

    assign PEC0.read_new_ifmap_val = PERead[0];
    assign PEC0.start_conv = PEStart[0];
    assign PEC0.read_new_filter_val = filtRead[0];

    PE U2(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED00.PE),
        ._controlsDiag(PEC0.PEDiag),
        ._controlsRow(PEC0.PERow)
    );

    //PE Group 1
    //PE 1,0
    PE_if PED10();
    PE_controller_if PEC1();
    assign PED10.psum_i = PED00.psum_o;
    assign PED10.filter_i = readB;
    assign PED10.ifmap_i = readA;

    assign PEC1.read_new_ifmap_val = PERead[1];
    assign PEC1.start_conv = PEStart[1];
    assign PEC1.read_new_filter_val = filtRead[1];

    PE U3(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED10.PE),
        ._controlsDiag(PEC1.PEDiag),
        ._controlsRow(PEC1.PERow)
    );

    //PE 0,1
    PE_if PED01();
    assign PED01.psum_i = readB;
    assign PED01.filter_i = readB;
    assign PED01.ifmap_i = readA;
    PE U4(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED01.PE),
        ._controlsDiag(PEC1.PEDiag),
        ._controlsRow(PEC0.PERow)
    );

    //PE Group 2
    //PE 2,0
    PE_if PED20();
    PE_controller_if PEC2();
    assign PED20.psum_i = PED10.psum_o;
    assign PED20.filter_i = readB;
    assign PED20.ifmap_i = readA;

    assign PEC2.read_new_ifmap_val = PERead[2];
    assign PEC2.start_conv = PEStart[2];
    assign PEC2.read_new_filter_val = filtRead[2];

    PE U5(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED20.PE),
        ._controlsDiag(PEC2.PEDiag),
        ._controlsRow(PEC2.PERow)
    );

    //PE 1,1
    PE_if PED11();
    assign PED11.psum_i = PED01.psum_o;
    assign PED11.filter_i = readB;
    assign PED11.ifmap_i = readA;
    PE U6(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED11.PE),
        ._controlsDiag(PEC2.PEDiag),
        ._controlsRow(PEC1.PERow)
    );

    //PE 0,2
    PE_if PED02();
    assign PED02.psum_i = readB;
    assign PED02.filter_i = readB;
    assign PED02.ifmap_i = readA;
    PE U7(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED02.PE),
        ._controlsDiag(PEC2.PEDiag),
        ._controlsRow(PEC0.PERow)
    );

    //PE Group 3
    //PE 2,1
    PE_if PED21();
    PE_controller_if PEC3();
    assign PED21.psum_i = PED11.psum_o;
    assign PED21.filter_i = readB;
    assign PED21.ifmap_i = readA;

    assign PEC3.read_new_ifmap_val = PERead[3];
    assign PEC3.start_conv = PEStart[3];
    assign PEC3.read_new_filter_val = '0;

    PE U8(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED21.PE),
        ._controlsDiag(PEC3.PEDiag),
        ._controlsRow(PEC2.PERow)
    );

    //PE 1,2
    PE_if PED12();
    assign PED12.psum_i = PED02.psum_o;
    assign PED12.filter_i = readB;
    assign PED12.ifmap_i = readA;
    PE U9(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED12.PE),
        ._controlsDiag(PEC3.PEDiag),
        ._controlsRow(PEC1.PERow)
    );

    //PE Group 4
    //PE 2,2
    PE_if PED22();
    PE_controller_if PEC4();
    assign PED22.psum_i = PED12.psum_o;
    assign PED22.filter_i = readB;
    assign PED22.ifmap_i = readB;

    assign PEC4.read_new_ifmap_val = PERead[4];
    assign PEC4.start_conv = PEStart[4];
    assign PEC4.read_new_filter_val = '0;

    PE U10(
        .clk_i(clk), 
        .rstn_i(nRST),
        ._if(PED22.PE),
        ._controlsDiag(PEC4.PEDiag),
        ._controlsRow(PEC2.PERow)
    );

    logic[9:0] writeIntermediate;
    logic overflowPos;
    logic overflowNeg;

    always_comb begin //select which PE is routed to output
        casez({PED20.psum_valid_o, PED21.psum_valid_o, PED22.psum_valid_o})
            3'b1??: begin
                writeIntermediate = PED20.psum_o;
            end
            3'b01?: begin
                writeIntermediate = PED20.psum_o;
            end
            3'b001: begin
                writeIntermediate = PED20.psum_o;
            end
            default: begin
                writeIntermediate = '0;
            end
        endcase

        write = {writeIntermediate[9], writeIntermediate[6:0]}; //cap output to +/-127 by detecting overflows and writing max value to output in case of overflow
        
        overflowPos = !writeIntermediate[9] & (writeIntermediate[8] | writeIntermediate[7]);
        overflowNeg = writeIntermediate[9] & (!writeIntermediate[8] | !writeIntermediate[7]);

        if(overflowPos) begin
            write[6:0] = '1;
        end
        if(overflowNeg) begin
            write[6:0] = '0;
        end
    end

endmodule
`endif