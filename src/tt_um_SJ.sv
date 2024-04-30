module tt_um_SJ(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    /*assign uio_oe  = 0;
    assign uio_out  = 0;

    top DUT(
        .clk(clk),
        .nRST(rst_n),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .write(uo_out)
    );*/

    PE U2(
        .clk_i(clk), 
        .rstn_i(rst_n),
        .psum_i({{3{ui_in[7]}}, ui_in[6:0]}),
        .filter_i(uio_in), 
        .ifmap_i(ui_in), 
        .read_new_filter_val(ui_in[0]),
        .read_new_ifmap_val(uio_in[0]),
        .start(ui_in[1]),
        .mode(uio_in[2]),
		.psum_o(uo_out), 
        .psum_valid_o(),
		.end_OS(uio_in[1]),
		.filter_o(uio_out),
		.ifmap_o(uio_oe)
    );

endmodule