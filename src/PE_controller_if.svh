`ifndef PE_TOP_IF
`define PE_TOP_IF


//import sizes::*;

interface PE_controller_if;

    //control
    logic read_new_ifmap_val, read_new_filter_val, start_conv;

    modport PEDiag (
        input read_new_ifmap_val, start_conv
    );
    modport PERow (
        input read_new_filter_val
    );

    modport controller (
        output read_new_ifmap_val, read_new_filter_val, start_conv
    );

endinterface

`endif