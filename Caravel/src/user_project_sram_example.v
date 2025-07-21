/* Example user project containing a 4096-word DFFRAM */

module user_project_sram_example(
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_cyc_i,
    input wire wbs_stb_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_adr_i,
    input wire [31:0] wbs_dat_i,
    output reg wbs_ack_o,
    output wire [31:0] wbs_dat_o
);

    reg [3:0] dff_we;
    wire dff_en;

    assign dff_en = (wbs_stb_i & wbs_cyc_i);

    always @(*) begin
        dff_we = 4'd0;
        dff_we[0] = (((wbs_sel_i[0] & wbs_we_i) & wbs_stb_i) & wbs_cyc_i);
        dff_we[1] = (((wbs_sel_i[1] & wbs_we_i) & wbs_stb_i) & wbs_cyc_i);
        dff_we[2] = (((wbs_sel_i[2] & wbs_we_i) & wbs_stb_i) & wbs_cyc_i);
        dff_we[3] = (((wbs_sel_i[3] & wbs_we_i) & wbs_stb_i) & wbs_cyc_i);
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
	    wbs_ack_o <= 1'b0;
	end else begin
	    wbs_ack_o <= dff_en & (~wbs_ack_o);
	end
    end

    /* Instantiate a 4096-word RAM */
    RAM4096 RAM4096(
        .A0(wbs_adr_i[13:2]),
        .CLK(wb_clk_i),
        .Di0(wbs_dat_i),
        .EN0(dff_en),
        .WE0(dff_we),
        .Do0(wbs_dat_o)
    );

endmodule;

