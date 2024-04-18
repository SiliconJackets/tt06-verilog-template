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
    logic mode;
    logic end_OS;

    logic [2:0] PENewOuput;
    logic [3:0] OSOutSel;

    topLevelControl U1(
        .clk(clk),
        .nRST(nRST),
        .readA(readA),
        .readB(readB),
        .PERead(PERead),
        .PEStart(PEStart),
        .filtRead(filtRead),
        .mode(mode),
        .end_OS(end_OS),
        .OSOutSel(OSOutSel)
    );

    //PE Group 0
    //PE 0,0
    logic [9:0] psum_o00;
    logic [7:0] filter_o00;
    logic [7:0] ifmap_o00;

    PE U2(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i({{3{readA[7]}}, readA[6:0]}),
        .filter_i(readB), 
        .ifmap_i(readA), 
        .read_new_filter_val(filtRead[0]),
        .read_new_ifmap_val(PERead[0]),
        .start(PEStart[0]),
        .mode(mode),
		.psum_o(psum_o00), 
        .psum_valid_o(),
		.end_OS(end_OS),
		.filter_o(filter_o00),
		.ifmap_o(ifmap_o00)
    );

    //PE Group 1
    //PE 1,0

    logic [9:0] psum_o10;
    logic [7:0] ifmap_i10;
    logic [7:0] ifmap_o10;
    logic [7:0] filter_o10;
    logic PERead10;

    assign PERead10 = mode ? PERead[1] : PERead[0];
    assign ifmap_i10 = mode ? readA : ifmap_o00;

    PE U3(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i(psum_o00),
        .filter_i(readB), 
        .ifmap_i(ifmap_i10), 
        .read_new_filter_val(filtRead[1]),
        .read_new_ifmap_val(PERead10),
        .start(PEStart[1]),
        .mode(mode),
		.psum_o(psum_o10), 
        .psum_valid_o(),
		.end_OS(end_OS),
		.filter_o(filter_o10),
		.ifmap_o(ifmap_o10)
    );

    //PE 0,1
    logic [9:0] psum_o01;
    logic [7:0] ifmap_o01;
    logic [7:0] filter_i01;
    logic [7:0] filter_o01;

    assign filter_i01 = mode ? readB : filter_o00;

    PE U4(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i({{3{readB[7]}}, readB[6:0]}),
        .filter_i(filter_i01), 
        .ifmap_i(readA), 
        .read_new_filter_val(filtRead[0]),
        .read_new_ifmap_val(PERead[1]),
        .start(PEStart[1]),
        .mode(mode),
		.psum_o(psum_o01), 
        .psum_valid_o(),
		.end_OS(end_OS),
		.filter_o(filter_o01),
		.ifmap_o(ifmap_o01)
    );

    //PE Group 2
    //PE 2,0
    logic [9:0] psum_o20;
    logic [7:0] ifmap_i20;
    logic [7:0] filter_o20;
    logic PERead20;

    assign PERead20 = mode ? PERead[2] : PERead[0];
    assign ifmap_i20 = mode ? readA : ifmap_o10;

    PE U5(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i(psum_o10),
        .filter_i(readB), 
        .ifmap_i(ifmap_i20), 
        .read_new_filter_val(filtRead[2]),
        .read_new_ifmap_val(PERead20),
        .start(PEStart[2]),
        .mode(mode),
		.psum_o(psum_o20), 
        .psum_valid_o(PENewOuput[2]),
		.end_OS(end_OS),
		.filter_o(filter_o20),
		.ifmap_o()
    );

    //PE 1,1
    logic [9:0] psum_o11;
    logic [7:0] ifmap_i11;
    logic [7:0] ifmap_o11;
    logic [7:0] filter_i11;
    logic [7:0] filter_o11;
    logic PERead11;

    assign PERead11 = mode ? PERead[2] : PERead[1];
    assign filter_i11 = mode ? readB : filter_o10;
    assign ifmap_i11 = mode ? readA : ifmap_o01;

    PE U6(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i(psum_o01),
        .filter_i(filter_i11), 
        .ifmap_i(ifmap_i11), 
        .read_new_filter_val(filtRead[1]),
        .read_new_ifmap_val(PERead11),
        .start(PEStart[2]),
        .mode(mode),
		.psum_o(psum_o11), 
        .psum_valid_o(),
		.end_OS(end_OS),
		.filter_o(filter_o11),
		.ifmap_o(ifmap_o11)
    );

    //PE 0,2
    logic [9:0] psum_o02;
    logic [7:0] ifmap_o02;
    logic [7:0] filter_i02;

    assign filter_i02 = mode ? readB : filter_o01;

    PE U7(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i({{3{readB[7]}}, readB[6:0]}),
        .filter_i(filter_i02), 
        .ifmap_i(readA), 
        .read_new_filter_val(filtRead[0]),
        .read_new_ifmap_val(PERead[2]),
        .start(PEStart[2]),
        .mode(mode),
		.psum_o(psum_o02), 
        .psum_valid_o(),
		.end_OS(end_OS),
		.filter_o(),
		.ifmap_o(ifmap_o02)
    );

    //PE Group 3
    //PE 2,1
    logic [9:0] psum_o21;
    logic [7:0] ifmap_i21;
    logic [7:0] filter_i21;
    logic [7:0] filter_o21;
    logic PERead21;

    assign PERead21 = mode ? PERead[3] : PERead[1];
    assign filter_i21 = mode ? readB : filter_o20;
    assign ifmap_i21 = mode ? readA : ifmap_o11;

    PE U8(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i(psum_o11),
        .filter_i(filter_i21), 
        .ifmap_i(ifmap_i21), 
        .read_new_filter_val(filtRead[2]),
        .read_new_ifmap_val(PERead21),
        .start(PEStart[3]),
        .mode(mode),
		.psum_o(psum_o21), 
        .psum_valid_o(PENewOuput[1]),
		.end_OS(end_OS),
		.filter_o(filter_o21),
		.ifmap_o()
    );

    //PE 1,2
    logic [9:0] psum_o12;
    logic [7:0] ifmap_i12;
    logic [7:0] ifmap_o12;
    logic [7:0] filter_i12;
    logic PERead12;
    
    assign PERead12 = mode ? PERead[3] : PERead[2];
    assign filter_i12 = mode ? readB : filter_o11;
    assign ifmap_i12 = mode ? readA : ifmap_o02;

    PE U9(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i(psum_o02),
        .filter_i(filter_i12), 
        .ifmap_i(ifmap_i12), 
        .read_new_filter_val(filtRead[1]),
        .read_new_ifmap_val(PERead12),
        .start(PEStart[3]),
        .mode(mode),
		.psum_o(psum_o12), 
        .psum_valid_o(),
		.end_OS(end_OS),
		.filter_o(),
		.ifmap_o(ifmap_o12)
    );

    //PE Group 4
    //PE 2,2
    logic [9:0] psum_o22;
    logic [7:0] ifmap_i22;
    logic [7:0] filter_i22;
    logic PERead22;

    assign PERead22 = mode ? PERead[4] : PERead[2];
    assign filter_i22 = mode ? readB : filter_o21;
    assign ifmap_i22 = mode ? readB : ifmap_o12;

    PE U10(
        .clk_i(clk), 
        .rstn_i(nRST),
        .psum_i(psum_o12),
        .filter_i(filter_i22), 
        .ifmap_i(ifmap_i22), 
        .read_new_filter_val(filtRead[2]),
        .read_new_ifmap_val(PERead22),
        .start(PEStart[4]),
        .mode(mode),
		.psum_o(psum_o22), 
        .psum_valid_o(PENewOuput[0]),
		.end_OS(end_OS),
		.filter_o(),
		.ifmap_o()
    );

    logic [9:0] writeIntermediate;
    logic [9:0] writeIntermediateRS;
    logic overflowPos;
    logic overflowNeg;

    always_comb begin //select which PE is routed to output
        casez(PENewOuput)
            3'b1??: begin
                writeIntermediateRS = psum_o20;
            end
            3'b01?: begin
                writeIntermediateRS = psum_o21;
            end
            3'b001: begin
                writeIntermediateRS = psum_o22;
            end
            default: begin
                writeIntermediateRS = '0;
            end
        endcase
        case(OSOutSel)
            4'd0: writeIntermediate = writeIntermediateRS;
            4'd1: writeIntermediate = psum_o00;
            4'd2: writeIntermediate = psum_o01;
            4'd3: writeIntermediate = psum_o02;
            4'd4: writeIntermediate = psum_o10;
            4'd5: writeIntermediate = psum_o11;
            4'd6: writeIntermediate = psum_o12;
            4'd7: writeIntermediate = psum_o20;
            4'd8: writeIntermediate = psum_o21;
            4'd9: writeIntermediate = psum_o22;
            default: writeIntermediate = writeIntermediateRS;
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