`ifndef SIZE_PKG
`define SIZE_PKG

package sizes;

    parameter DATA_SIZE = 8; //in bits
    parameter BIGGER_DATA_SIZE = 10;
    parameter BIGGEST_FILTER_ROW_WIDTH = 3; //controls size of scratchpads in PEs
    parameter counter_bits = 2; //floor(log_2(BIGGEST_FILTER_ROW_WIDTH))

endpackage
`endif