// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`ifndef FPGA
`default_nettype none
`else
`default_nettype wire
`endif

/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a simple user project.
 *
 * This project generates an integer count, accessible from
 * a memory-mapped location on the wishbone bus.  This is
 * used, for example, with the "dhrystone" testbench, to
 * track CPU cycles since program start.
 *
 * Added:  Cycle and instruction counts from the CPU have
 * been passed through to the user project.  This is a
 * blatant hack because it's easier to figure out how to
 * do than to figure out how to configure the LiteX/Migen
 * VexRISC to enable the RISC-V CSR registers internally.
 *
 * Memory-mapped addressing is as follows:
 *	30000000 = user project counter
 *	30000004 = CPU cycle count (low 32 bits)
 *	30000008 = CPU cycle count (high 32 bits)
 *	3000000c = CPU instruction count (low 32 bits)
 *	30000010 = CPU instruction count (high 32 bits)
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq,

    // Hack to pass cycle and instruction counts to the user project
    input [63:0] user_mcycle,
    input [63:0] user_minstret
);

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;

    // IO (diagnostic)
    // assign io_out = count[`MPRJ_IO_PADS-1:0];
    assign io_out[31:0] = count;
    assign io_out[`MPRJ_IO_PADS-1:32] = 0;
    assign io_oeb = {(`MPRJ_IO_PADS-1){wb_rst_i}};

    // IRQ
    assign irq = 3'b000;	// Unused

    counter #(
        .BITS(BITS)
    ) counter(
        .clk(wb_clk_i),
        .reset(wb_rst_i),
        .ready(wbs_ack_o),
        .valid(valid),
        .rdata(rdata),
	.addr(wbs_adr_i[4:2]),
        .wdata(wbs_dat_i),
        .wstrb(wstrb),
        .count(count),
	.mcycle(user_mcycle),
	.minstret(user_minstret)
    );

endmodule

module counter #(
    parameter BITS = 32
)(
    input clk,
    input reset,
    input valid,
    input [3:0] wstrb,
    input [BITS-1:0] wdata,
    input [2:0] addr,
    output ready,
    output [BITS-1:0] rdata,
    output [BITS-1:0] count,
    input [63:0] mcycle,
    input [63:0] minstret
);
    reg ready;
    reg [BITS-1:0] count;
    reg [BITS-1:0] rdata;

    wire cycle_low_sel, cycle_high_sel;
    wire instr_low_sel, instr_high_sel;

    /* Wishbone address select indicators */
    assign cycle_low_sel = (addr == 3'h1);
    assign cycle_high_sel = (addr == 3'h2);
    assign instr_low_sel = (addr == 3'h3);
    assign instr_high_sel = (addr == 3'h4);

    /* Reading register 0 reads the count, writing it resets	*/
    /* the count to the value written.				*/
    /* All other registers are read-only */

    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            ready <= 0;
        end else begin
            ready <= 1'b0;
	    /* Always count on every clock cycle */
            count <= count + 1;
            if (valid && !ready) begin
                ready <= 1'b1;
		if (cycle_low_sel) begin
		    rdata <= mcycle[31:0];
		end else if (cycle_high_sel) begin
		    rdata <= mcycle[63:32];
		end else if (instr_low_sel) begin
		    rdata <= minstret[31:0];
		end else if (instr_high_sel) begin
		    rdata <= minstret[63:32];
		end else begin
		    rdata <= count;
		end
                if (wstrb[0]) count[7:0]   <= wdata[7:0];
                if (wstrb[1]) count[15:8]  <= wdata[15:8];
                if (wstrb[2]) count[23:16] <= wdata[23:16];
                if (wstrb[3]) count[31:24] <= wdata[31:24];
            end
        end
    end

endmodule
`default_nettype wire
