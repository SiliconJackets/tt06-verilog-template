module topLevelControl (
    input logic clk,
    input logic nRST,
    input logic [7:0] readA,
    input logic [7:0] readB,
    output logic [4:0] PERead,
    output logic [4:0] PEStart,
    output logic [2:0] filtRead,
    output logic mode,
    output logic end_OS,
    output logic [3:0] OSOutSel
);

typedef enum logic [2:0] {
    idle,
    loadInit,
    loadSingle,
    reload,
    beginOS,
    runOS,
    endOS,
    outOS
} state_t;

state_t state, nextState;

logic [4:0] PEReadNaive;

logic [2:0] countPE, nextCountPE;
logic [7:0] countRow, nextCountRow;
logic [6:0] countTile, nextCountTile;

logic [7:0] rowLen, nextRowLen;
logic [6:0] colTiles, nextColTiles;
logic [1:0] PEStartEN, nextPEStartEN;

assign mode = (colTiles == 7'd0) ? 1'b0 : 1'b1;

always_ff @(posedge clk, negedge nRST) begin
    if(nRST == '0) begin
        state <= idle;
        countPE <= '0;
        countRow <= '0;
        countTile <= '0;
        rowLen <= '0;
        colTiles <= '0;
        PEStartEN <= '0;
    end
    else begin
        state <= nextState;
        countPE <= nextCountPE;
        countRow <= nextCountRow;
        countTile <= nextCountTile;
        rowLen <= nextRowLen;
        colTiles <= nextColTiles;
        PEStartEN <= nextPEStartEN;
    end
end

always_comb begin
    nextState = state;
    nextCountPE = countPE;
    nextCountRow = countRow;
    nextCountTile = countTile;

    nextRowLen = rowLen;
    nextColTiles = colTiles;

    PEReadNaive = '0;

    PERead = '0;
    PEStart = '0;
    filtRead = '0;

    end_OS = '0;

    nextPEStartEN = PEStartEN;

    OSOutSel = '0;

    case(countPE)
        3'd1: PEReadNaive[0] = 1'b1;
        3'd2: PEReadNaive[1] = 1'b1;
        3'd3: PEReadNaive[2] = 1'b1;
        3'd4: PEReadNaive[3] = 1'b1;
        3'd5: PEReadNaive[4] = 1'b1;
        default:PEReadNaive = '0;
    endcase

    case(state)
        idle: begin
            nextCountPE = '0;
            nextCountRow = '0;
            nextCountTile = '0;
            if(readA[7]) begin
                nextRowLen = {readA[6:0], readB[7]};
                nextColTiles = readB[6:0];
                nextCountPE = 3'd1;
                if(readB[6:0] == '0) begin
                    nextState = beginOS;
                end
                else begin
                    nextState = loadInit;
                end
                end_OS = 1'b1;
            end
        end
        loadInit: begin
            PERead = {PEReadNaive[3], PEReadNaive[3:0]};
            filtRead = PEReadNaive[2:0];
            nextCountPE = countPE + 3'd1;
            if(countPE == 3'd4) begin
                nextCountPE = 3'd1;
                nextCountRow = countRow + 8'd1;
            end
            if(countRow == 8'd2) begin
                PEStart = PEReadNaive;
            end
            if(countRow == 8'd3) begin
                nextCountPE = 3'd1;
                PEStart[4] = 1'b1;
                filtRead = '0;
                PERead = '0;
                nextState = loadSingle;
                nextCountRow = 8'd1;
            end
        end
        loadSingle: begin
            PEStart = PEReadNaive;
            PERead = PEReadNaive;
            nextCountPE = countPE + 3'd1;
            if(countPE == 3'd5) begin
                nextCountPE = 3'd1;
                nextCountRow = countRow + 8'd1;
                if(countRow == rowLen) begin
                    nextState = reload;
                    nextCountTile = countTile + 7'd1;
                    nextCountRow = '0;
                end
            end
        end
        reload: begin
            PERead = {PEReadNaive[3], PEReadNaive[3:0]};
            nextCountPE = countPE + 3'd1;
            if(countPE == 3'd4) begin
                nextCountPE = 3'd1;
                nextCountRow = countRow + 8'd1;
            end
            if(countRow == 8'd2) begin
                PEStart = PEReadNaive;
            end
            if(countRow == 8'd3) begin
                nextCountPE = 3'd1;
                PEStart[4] = 1'b1;
                filtRead = '0;
                PERead = '0;
                nextState = loadSingle;
                nextCountRow = 8'd1;
            end
            if(countTile == colTiles) begin
                nextState = idle;
                PERead = '0;
            end
        end
        beginOS: begin
            nextCountPE = countPE + 3'd1;
            PERead[0] = PEReadNaive[0] | PEReadNaive[1];
            filtRead[0] = PEReadNaive[0] | PEReadNaive[1];
            PERead[1] = PEReadNaive[2];
            filtRead[1] = PEReadNaive[2];
            PEStart[0] = PEReadNaive[0] | PEReadNaive[2];
            PEStart[1] = PEReadNaive[2];
            if(countPE == 3'd3) begin
                nextCountPE = 3'd1;
                nextCountRow = 8'd1;
                nextState = runOS;
            end
        end
        runOS: begin
            nextCountPE = countPE + 3'd1;
            PERead = PEReadNaive;
            filtRead = PEReadNaive[2:0];
            if(countPE == 3'd3) begin
                nextCountPE = 3'd1;
                nextCountRow = countRow + 8'd1;
                PEStart[2:0] = '1;
                PEStart[4:3] = PEStartEN;
                nextPEStartEN[0] = 1'b1;
                nextPEStartEN[1] = PEStartEN[0];
                if(countRow == rowLen) begin
                    nextState = endOS;
                end
            end
        end
        endOS: begin
            nextCountPE = countPE + 3'd1;
            PERead[1] = PEReadNaive[0];
            filtRead[1] = PEReadNaive[0];
            PEStart[1] = PEReadNaive[1];
            PERead[2] = PEReadNaive[1] | PEReadNaive[2];
            filtRead[2] = PEReadNaive[1] | PEReadNaive[2];
            PEStart[2] = PEReadNaive[1] | PEReadNaive[2];
            nextPEStartEN[0] = PEReadNaive[0] | PEReadNaive[1] | PEReadNaive[2];
            nextPEStartEN[1] = PEStartEN[0];
            PEStart[4:3] = PEStartEN;
            if(countPE == 3'd1) begin
                PEStart = '0;
            end
            if(countPE == 3'd5) begin
                nextState = outOS;
                nextCountTile = 8'd1;
            end
        end
        outOS: begin
            nextCountTile = countTile + 7'd1;
            OSOutSel = countTile[3:0];
            if(countTile == 8'd9) begin
                nextState = idle;
            end
        end
    endcase
end
    
endmodule