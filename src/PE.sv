module PE
    (
        input logic clk_i, rstn_i,
        input logic signed [7:0] filter_i, 
        input logic signed [7:0] ifmap_i, 
        input logic read_new_filter_val,
        input logic read_new_ifmap_val,
        output logic signed [9:0] psum_o, 

        input logic mode, // 1 = RS, 0 = OS.
        // If RSmode, then start = start_conv.
        // If OSmode, then start = do_MAC.
        input logic start,

        // Row Stationary Signals
        input logic signed [9:0] psum_i,
        output logic psum_valid_o,

        // Output Stationary Signals
        input logic end_OS,
        output logic signed [7:0] filter_o, ifmap_o
    );

    //Scratchpad regs
    logic signed [7:0] filter_spad [0:2];
    logic signed [7:0] ifmap_spad [0:2];
    logic signed [9:0] psum_spad;
    
    //psum buffer reg
    logic signed [9:0] psum_buffer;

    //datapath wires
    logic signed [7:0] filter_intermediate, ifmap_intermediate;
    logic signed [15:0] mult_out_raw; //full multiplication result
    logic signed [9:0] mult_out_trunc;
    logic signed [9:0] adder_input, adder_output, psum_spad_input; // result of multiplexor. chooses either result of MAC or the psum from above PE to go to adder

    //counter reg and wires
    logic [1:0] counter; //Tells which regs to use in scratchpad
    logic [1:0] next_counter; // 1 + index
    logic acc_psum;

    //state reg and wire
    logic next_calculating_RS;
    logic calculating_RS;

    logic do_MAC, nextDoMac;
    logic start_conv;

    always_comb begin
        //============= Time to accumulate psum? ===============
        acc_psum = (counter == 2'd3);

        //============= Next State ==================
        nextDoMac = !mode & start; //mode == 0 means OS.
        start_conv = mode & start; //mode == 1 means RS.
        if ((!calculating_RS && start_conv) || (calculating_RS && !acc_psum)) next_calculating_RS = '1;
        else next_calculating_RS = '0;

        //============= Next Counter =================
        next_counter = calculating_RS ? counter + 1 : '0;

        //============= Multiplication ===============
        filter_intermediate = filter_spad[counter];
        ifmap_intermediate = ifmap_spad[counter];
        mult_out_raw = filter_intermediate * ifmap_intermediate;
        mult_out_trunc = mult_out_raw[15:6]; //truncate to 10 bits

        //============= Accumulation ================
        adder_input = acc_psum ? psum_i : mult_out_trunc;
        adder_output = adder_input + psum_spad;
            //if (currently calculating RS and not yet done) or (OS mode) then feed MAC result into scratchpad
        psum_spad_input = (calculating_RS && !acc_psum) || (mode == 1'b0 && !end_OS) ? adder_output : '0;

        //============= Set Output =================
        psum_o = psum_buffer;

        //============= Propogate OS signals ==========
        filter_o = filter_intermediate;
        ifmap_o = ifmap_intermediate;
    end

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            //============ set all the registers to 0 =========
            counter <= '0;
            for (int i = 0; i < 3; i++) begin
                filter_spad[i] <= '0;
                ifmap_spad[i] <= '0;
            end
            psum_spad <= '0;
            psum_buffer <= '0;
            calculating_RS <= '0;
            do_MAC <= '0;
            psum_valid_o <= '0;

        end else begin
            //==========   update state ===========
            calculating_RS <= next_calculating_RS;
            do_MAC <= nextDoMac;

            //==========  update counter  =============
            counter <= next_counter;

            //==========  update filter scratchpad  =============
            if (read_new_filter_val) begin
                for (int i = 2; i > 0; i--) begin
                    filter_spad[i] <= filter_spad[i-1];
                end
                filter_spad[0] <= filter_i;
            end

            //==========  update ifmap scratchpad  =============
            if (read_new_ifmap_val) begin
                for (int i = 2; i > 0; i--) begin
                    ifmap_spad[i] <= ifmap_spad[i-1];
                end
                ifmap_spad[0] <= ifmap_i;
            end

            //========= update psum buffer ==========
            if (acc_psum || do_MAC) psum_buffer <= adder_output;

            //========= update psum scratchpad ======
            if (mode || do_MAC || end_OS) psum_spad <= psum_spad_input;

            //============= valid bit ===================
            psum_valid_o <= acc_psum;
        end
    end

endmodule