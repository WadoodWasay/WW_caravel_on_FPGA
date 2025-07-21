`default_nettype none
/*
 *  SPDX-FileCopyrightText: 2015 Clifford Wolf
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *  SPDX-License-Identifier: ISC
 */

/* This version of simpleuart taken from picosoc (picorv32) and modified
 * for operation as a module sitting between the FTDI chip on the Arty A7
 * board and the Caravel housekeeping SPI, translating from UART protocol
 * to SPI and vice versa, because the Arty A7 board does not connect pins
 * from the FTDI other than UART Tx and Rx, making a direct connection to
 * SPI impossible.
 */

`timescale 1 ns / 1 ps

`include "uart_to_spi.v"

module uart_to_spi_tb ();

    // Stimulus inputs

    reg clock;
    reg resetn;

    reg we;
    reg re;
    reg [31:0] di;
    reg ser_rx;
    reg spi_sdo;

    reg [7:0] tbdata;

    // Stimulus outputs

    wire [31:0] do;
    wire ser_tx;
    wire spi_sdi, spi_csb, spi_sck;

    integer i;

    // Define tasks for UART functions
    // Run UART data at 1Mbps (actually 1.002 MHz)

    task write_byte;
	input [7:0] odata;
	begin
	    ser_rx <= 1'b0;	// start bit
	    #1002;
	    for (i = 0; i < 8; i++) begin
		ser_rx <= odata[i];
		#1002;
	    end
	    ser_rx <= 1'b1;	// stop bit
	    #1002;
	end
    endtask

    task read_byte;
	output [7:0] idata;
	begin
	    ser_rx <= 1'b0;	// start bit
	    #1002;
	    for (i = 0; i < 8; i++) begin
		ser_rx <= 1'b0;
		idata[i] = ser_tx;
		#1002;
	    end
	    ser_rx <= 1'b1;	// stop bit
	    #1002;
	end
    endtask

    // At 1ns tick, this is the Arty A7 board's 100MHz clock
    always #5 clock <= (clock === 1'b0);

    // Just keep the SDO toggling so we can see return data.
    always #2500 spi_sdo <= (spi_sdo === 1'b0);

    initial begin
	clock <= 0;
 	ser_rx <= 1'b1;
	resetn <= 1'b0;
	spi_sdo <= 1'b0;
	#5000;
	resetn <= 1'b1;		// bring out of reset
	#5000;
	write_byte(8'h40);
	write_byte(8'h03);
	read_byte(tbdata);
	#37500;
	$finish;
    end

    initial begin
	$dumpfile("uart_to_spi_tb.vcd");
	$dumpvars(0, uart_to_spi_tb);
    end

    // Instantiate the uart_to_spi

    uart_to_spi uart (
	.clk(clock),
	.resetn(resetn),

	.ser_tx(ser_tx),
	.ser_rx(ser_rx),

	.spi_sck(spi_sck),
	.spi_csb(spi_csb),
	.spi_sdo(spi_sdo),
	.spi_sdi(spi_sdi)
    );

endmodule
`default_nettype wire
