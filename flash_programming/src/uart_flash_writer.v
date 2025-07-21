`default_nettype none
`timescale 1ns/1ns
`define USE_RESET_BTN

`ifdef USE_RESET_BTN
	`define HRESETn_PORT .HRESETn(HRESETn)
`else
	`define HRESETn_PORT .HRESETn(HRESETn)
`endif

module uart_flash_writer (

    input wire HCLK, 
    input wire RST,
    input wire UART_MASTER_RX,
    output wire UART_MASTER_TX,
	
    inout  wire [3: 0] 	fdio,
    output wire [0: 0] 	fsclk,
    output wire [0: 0] 	fcen
 );

    
    wire HREADY;
    wire [31: 0] HADDR;
    wire [31: 0] HWDATA;
    wire HWRITE;
    wire [1: 0] HTRANS;
    wire [2:0] HSIZE;

    wire [31: 0] HRDATA;
    
    wire [3:0] fdi;
    wire [3:0] fdo;
    wire [3:0] fdoe;
    
    wire HRESETn;
    `ifdef USE_RESET_BTN
	reset_sync rst_sync (.clk(HCLK), .rst_n(~RST), .rst_sync_n(HRESETn));
    `endif

    AHB_UART_MASTER UM (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HREADY(HREADY),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA),
        .HSIZE(HSIZE),
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        .HADDR(HADDR),
        .RX(UART_MASTER_RX),
        .TX(UART_MASTER_TX)
    );

    wire [3:0] fdoen = {{~fdoe}}; // invert enable 

    gpio_bidir #(
        .WIDTH(4)
    ) flash_bidir (
        .dio_buf(fdio),
        .din_i(fdo),
        .dout_o(fdi),
        .in_not_out_i(fdoen) 
    );

    AHB_FLASH_WRITER FW (
	.HCLK(HCLK),
        .HRESETn(HRESETn),
	    
	// AHB-Lite Slave Interface
	.HSEL(1'b1),
	.HREADYOUT(HREADY),
	.HREADY(HREADY), 
	.HWDATA(HWDATA),
	.HRDATA(HRDATA),
	.HSIZE(HSIZE),
	.HWRITE(HWRITE),
	.HTRANS(HTRANS),
	.HADDR(HADDR),
		
	.fm_sck(fsclk),
	.fm_ce_n(fcen),
	.fm_din(fdi),
	.fm_dout(fdo),
	.fm_douten(fdoe)
    );

endmodule
