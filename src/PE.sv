`ifndef PE
`define PE
`include "PE_if.svh"
`include "PE_controller_if.svh"
import sizes::*;

//Start MAC the cycle AFTER the start signal.
// MAC1, MAC2, MAC3, AC4 and validout high, shift in new ifmap

module PE
    (
        input logic clk_i, rstn_i,
        PE_if.PE _if,
        PE_controller_if.PEDiag _controlsDiag,
        PE_controller_if.PERow _controlsRow
    );

    //Scratchpad regs
    logic signed [DATA_SIZE-1:0] filter_spad [0:BIGGEST_FILTER_ROW_WIDTH-1];
    logic signed [DATA_SIZE-1:0] ifmap_spad [0:BIGGEST_FILTER_ROW_WIDTH-1];
    logic signed [BIGGER_DATA_SIZE-1:0] psum_spad;
    
    //psum buffer reg
    logic signed [BIGGER_DATA_SIZE-1:0] psum_buffer;

    //datapath wires
    // logic signed [DATA_SIZE-1:0] mult_input_filter, mult_input_ifmap; //wires between regs and multiplier
    logic signed [2*DATA_SIZE-1:0] mult_out_raw; //full multiplication result
    logic signed [BIGGER_DATA_SIZE-1:0] mult_out_trunc;
    logic signed [BIGGER_DATA_SIZE-1:0] adder_input, adder_output, psum_spad_input; // result of multiplexor. chooses either result of MAC or the psum from above PE to go to adder

    //counter reg and wires
    logic [counter_bits - 1:0] counter; //Tells which regs to use in scratchpad
    logic [counter_bits - 1:0] next_counter; // 1 + index
    logic acc_psum;

    //state reg and wire
    logic next_calculating;
    logic calculating;


    always_comb begin
        //============= Time to accumulate psum? ===============
        acc_psum = (counter == BIGGEST_FILTER_ROW_WIDTH);

        //============= Next State ==================
        if ((!calculating && _controlsDiag.start_conv) || (calculating && !acc_psum)) next_calculating = '1;
        else next_calculating = '0;

        //============= Next Counter =================
        next_counter = calculating ? counter + 1 : '0;

        //============= Multiplication ===============
        mult_out_raw = filter_spad[counter] * ifmap_spad[counter];
        mult_out_trunc = mult_out_raw[2*DATA_SIZE-1:DATA_SIZE-2]; //truncate to 10 bits

        //============= Accumulation ================
        adder_input = acc_psum ? _if.psum_i : mult_out_trunc;
        adder_output = adder_input + psum_spad;
        psum_spad_input = (calculating && !acc_psum) ? adder_output : '0;

        //============= Set Output =================
        _if.psum_o = psum_buffer;
    end

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            //============ set all the registers to 0 =========
            counter <= '0;
            for (int i = 0; i < BIGGEST_FILTER_ROW_WIDTH; i++) begin
                filter_spad[i] <= '0;
                ifmap_spad[i] <= '0;
            end
            psum_spad <= '0;
            psum_buffer <= '0;
            calculating <= '0;
            _if.psum_valid_o <= '0;

        end else begin
            //==========   update state ===========
            calculating <= next_calculating;

            //==========  update counter  =============
            counter <= next_counter;

            //==========  update filter scratchpad  =============
            if (_controlsRow.read_new_filter_val) begin
                for (int i = 0; i < BIGGEST_FILTER_ROW_WIDTH - 1; i++) begin
                    filter_spad[i] <= filter_spad[i+1];
                end
                filter_spad[BIGGEST_FILTER_ROW_WIDTH - 1] <= _if.filter_i;
            end

            //==========  update ifmap scratchpad  =============
            if (_controlsDiag.read_new_ifmap_val) begin
                for (int i = 0; i < BIGGEST_FILTER_ROW_WIDTH - 1; i++) begin
                    ifmap_spad[i] <= ifmap_spad[i+1];
                end
                ifmap_spad[BIGGEST_FILTER_ROW_WIDTH - 1] <= _if.ifmap_i;
            end

            //========= update psum buffer ==========
            if (acc_psum) psum_buffer <= adder_output;

            //========= update psum scratchpad ======
            psum_spad <= psum_spad_input;

            //============= valid bit ===================
            _if.psum_valid_o <= acc_psum;
        end
    end

endmodule
`endif