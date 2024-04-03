`ifndef PE_IF
`define PE_IF

import sizes::*;

interface PE_if;

    //Non-control
    logic signed [BIGGER_DATA_SIZE-1:0] psum_i;
    logic signed [BIGGER_DATA_SIZE-1:0] psum_o;
    logic psum_valid_o;
    //logic psum_valid_i; //not needed

    //from memory
    logic signed [DATA_SIZE-1:0] filter_i;
    logic signed [DATA_SIZE-1:0] ifmap_i;

    modport PE (
        input psum_i, filter_i, ifmap_i, 
        output psum_o, psum_valid_o
    );

    modport in (
        output psum_i
    );

    modport out (
        input psum_o, psum_valid_o
    );

    modport memory (
        input psum_valid_o, psum_o,
        output filter_i, ifmap_i
    );

endinterface;

`endif