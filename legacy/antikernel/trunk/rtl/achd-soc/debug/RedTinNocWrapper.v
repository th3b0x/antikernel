`timescale 1ns / 1ps
`default_nettype none
/***********************************************************************************************************************
*                                                                                                                      *
* ANTIKERNEL v0.1                                                                                                      *
*                                                                                                                      *
* Copyright (c) 2012-2016 Andrew D. Zonenberg                                                                          *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

/**
	@file
	@author Andrew D. Zonenberg
	@brief NoC wrapper for RED TIN logic analyzer
	
	WIDTH must be a multiple of 64
 */
module RedTinNocWrapper(
	clk, 
	capture_clk, din,
	rpc_tx_en, rpc_tx_data, rpc_tx_ack, rpc_rx_en, rpc_rx_data, rpc_rx_ack,
	dma_tx_en, dma_tx_data, dma_tx_ack, dma_rx_en, dma_rx_data, dma_rx_ack
    );

	////////////////////////////////////////////////////////////////////////////////////////////////
	// IO / parameter declarations
	
	parameter ROMFILE = "";
	parameter DEPTH = 512;
	parameter WIDTH = 128;		//must be multiple of 64 bits
	
	//Global clock
	input wire clk;
	
	//Data being sniffed
	input wire capture_clk;
	input wire[WIDTH-1:0] din;
	
	//NoC interface
	output wire rpc_tx_en;
	output wire[31:0] rpc_tx_data;
	input wire[1:0] rpc_tx_ack;
	input wire rpc_rx_en;
	input wire[31:0] rpc_rx_data;
	output wire[1:0] rpc_rx_ack;
	
	output wire dma_tx_en;
	output wire[31:0] dma_tx_data;
	input wire dma_tx_ack;
	input wire dma_rx_en;
	input wire[31:0] dma_rx_data;
	output wire dma_rx_ack;
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// NoC transceivers
	
	`include "DMARouter_constants.v"
	`include "RPCv2Router_type_constants.v"	//Pull in autogenerated constant table
	`include "RPCv2Router_ack_constants.v"
	
	parameter NOC_ADDR = 16'h0000;
	
	reg			rpc_fab_tx_en 		= 0;
	reg[15:0]	rpc_fab_tx_dst_addr	= 0;
	reg[7:0]	rpc_fab_tx_callnum	= 0;
	reg[2:0]	rpc_fab_tx_type		= 0;
	reg[20:0]	rpc_fab_tx_d0		= 0;
	reg[31:0]	rpc_fab_tx_d1		= 0;
	reg[31:0]	rpc_fab_tx_d2		= 0;
	wire		rpc_fab_tx_done;
	
	wire		rpc_fab_rx_en;
	wire[15:0]	rpc_fab_rx_src_addr;
	wire[15:0]	rpc_fab_rx_dst_addr;
	wire[7:0]	rpc_fab_rx_callnum;
	wire[2:0]	rpc_fab_rx_type;
	wire[20:0]	rpc_fab_rx_d0;
	wire[31:0]	rpc_fab_rx_d1;
	wire[31:0]	rpc_fab_rx_d2;
	reg			rpc_fab_rx_done		= 0;
	wire		rpc_fab_inbox_full;
	
	RPCv2Transceiver #(
		.LEAF_PORT(1),
		.LEAF_ADDR(NOC_ADDR)
	) txvr(
		.clk(clk),
		
		.rpc_tx_en(rpc_tx_en),
		.rpc_tx_data(rpc_tx_data),
		.rpc_tx_ack(rpc_tx_ack),
		
		.rpc_rx_en(rpc_rx_en),
		.rpc_rx_data(rpc_rx_data),
		.rpc_rx_ack(rpc_rx_ack),
		
		.rpc_fab_tx_en(rpc_fab_tx_en),
		.rpc_fab_tx_src_addr(16'h0000),
		.rpc_fab_tx_dst_addr(rpc_fab_tx_dst_addr),
		.rpc_fab_tx_callnum(rpc_fab_tx_callnum),
		.rpc_fab_tx_type(rpc_fab_tx_type),
		.rpc_fab_tx_d0(rpc_fab_tx_d0),
		.rpc_fab_tx_d1(rpc_fab_tx_d1),
		.rpc_fab_tx_d2(rpc_fab_tx_d2),
		.rpc_fab_tx_done(rpc_fab_tx_done),
		
		.rpc_fab_rx_en(rpc_fab_rx_en),
		.rpc_fab_rx_src_addr(rpc_fab_rx_src_addr),
		.rpc_fab_rx_dst_addr(rpc_fab_rx_dst_addr),
		.rpc_fab_rx_callnum(rpc_fab_rx_callnum),
		.rpc_fab_rx_type(rpc_fab_rx_type),
		.rpc_fab_rx_d0(rpc_fab_rx_d0),
		.rpc_fab_rx_d1(rpc_fab_rx_d1),
		.rpc_fab_rx_d2(rpc_fab_rx_d2),
		.rpc_fab_rx_done(rpc_fab_rx_done),
		.rpc_fab_inbox_full(rpc_fab_inbox_full)
		);
	
	//DMA transmit signals
	wire dtx_busy;
	reg[15:0] dtx_src_addr = 0;
	reg[15:0] dtx_dst_addr = 0;
	reg[1:0] dtx_op = 0;
	reg[9:0] dtx_len = 0;
	reg[31:0] dtx_addr = 0;
	reg dtx_en = 0;
	wire dtx_rd;
	wire[9:0] dtx_raddr;
	reg[31:0] dtx_buf_out = 0;
	
	//DMA receive signals
	wire drx_ready;
	wire drx_en;
	wire[15:0] drx_src_addr;
	wire[15:0] drx_dst_addr;
	wire[1:0] drx_op;
	wire[31:0] drx_addr;
	wire[9:0] drx_len;	
	reg drx_buf_rd = 0;
	reg[8:0] drx_buf_addr = 0;
	wire[31:0] drx_buf_data;
	
	//DMA transceiver
	DMATransceiver #(
		.LEAF_PORT(1),
		.LEAF_ADDR(NOC_ADDR)
	) dma_txvr(
		.clk(clk),
		.dma_tx_en(dma_tx_en), .dma_tx_data(dma_tx_data), .dma_tx_ack(dma_tx_ack),
		.dma_rx_en(dma_rx_en), .dma_rx_data(dma_rx_data), .dma_rx_ack(dma_rx_ack),
		
		.tx_done(),
		.tx_busy(dtx_busy), .tx_src_addr(dtx_src_addr), .tx_dst_addr(dtx_dst_addr), .tx_op(dtx_op), .tx_len(dtx_len),
		.tx_addr(dtx_addr), .tx_en(dtx_en), .tx_rd(dtx_rd), .tx_raddr(dtx_raddr), .tx_buf_out(dtx_buf_out),
		
		.rx_ready(drx_ready), .rx_en(drx_en), .rx_src_addr(drx_src_addr), .rx_dst_addr(drx_dst_addr),
		.rx_op(drx_op), .rx_addr(drx_addr), .rx_len(drx_len),
		.rx_buf_rd(drx_buf_rd), .rx_buf_addr(drx_buf_addr), .rx_buf_data(drx_buf_data), .rx_buf_rdclk(clk)
		);
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Signal name ROM
	
	//Fixed max of 2KB (one DMA packet) for now.
	//TODO: Support deeper and/or eliminate the name ROM entirely and just read the nocgen file
	
	reg[31:0] signal_rom[511:0];
	initial begin
		$readmemh(ROMFILE, signal_rom);
	end
	
	reg[31:0] romdout = 0;
	always @(posedge clk) begin
		if(dtx_rd)
			romdout <= signal_rom[dtx_raddr];
	end
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// The actual logic analyzer
	
	`include "../util/clog2.vh"
	localparam ADDR_BITS = clog2(DEPTH);
	
	localparam WIDTH_BLOCKS 	= WIDTH / 32;
	localparam WIDTH_BITS 		= clog2(WIDTH_BLOCKS);
	localparam WIDTH_BITS_FULL	= WIDTH_BITS + 1;	//add extra bit for timestamp column's address
	
	//Read buffer is WIDTH bits x DEPTH samples
	//One DMA packet is 32 bits x DEPTH samples
	//Use address directly and mux one of the (WIDTH/32) columns by setting la_read_column
	//Columns 0 ... WIDTH_BLOCKS-1 are data, WIDTH_BLOCKS is timestamp
	reg[WIDTH_BITS:0] la_read_column = 0;
	
	wire capture_done;
	reg la_reset = 0;

	wire[WIDTH-1:0] la_read_data;
	wire[31:0] la_read_timestamp;
	
	reg[31:0] dma_read_base = 0;
	wire[ADDR_BITS-1 :0] dma_read_addr = dma_read_base + dtx_raddr;
	
	reg reconfig_finish = 0;
	
	reg drx_buf_rd_buf = 0;
	
	RedTinLogicAnalyzer #(
		.DEPTH(DEPTH),
		.DATA_WIDTH(WIDTH)
	) capture (
		.capture_clk(capture_clk),
		.din(din), 
		.reconfig_clk(clk), 
		.reconfig_din(drx_buf_data), 
		.reconfig_ce(drx_buf_rd_buf),
		.reconfig_finish(reconfig_finish),
		.done(capture_done), 
		.reset(la_reset), 
		.read_clk(clk), 
		.read_en(dtx_rd),
		.read_addr(dma_read_addr[ADDR_BITS-1:0]), 
		.read_data(la_read_data),
		.read_timestamp(la_read_timestamp)
		);
		
	wire capture_done_sync;
	ThreeStageSynchronizer sync_capture_done(
		.clk_in(capture_clk), .din(capture_done),
		.clk_out(clk),	.dout(capture_done_sync));
		
	////////////////////////////////////////////////////////////////////////////////////////////////
	//Mux for DMA transmit data
	
	localparam DMA_TX_SRC_ROM = 0;
	localparam DMA_TX_SRC_LA = 1;
	reg dma_tx_src = DMA_TX_SRC_ROM;
	always @(*) begin
		dtx_buf_out <= 0;
		
		case(dma_tx_src)
			
			//Data comes from signal-name ROM
			DMA_TX_SRC_ROM:	dtx_buf_out <= romdout;
	
			//Data comes from logic analyzer
			DMA_TX_SRC_LA: begin
			
				//max is timestamp
				if(la_read_column == WIDTH_BLOCKS)
					dtx_buf_out <= la_read_timestamp;
					
				//everything else is real data
				else
					dtx_buf_out	<= la_read_data[la_read_column*32 +: 32];
								
			end

		endcase
		
	end
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// NoC interface state machine (TODO)
	
	/**
		Address map
		0x0000 0000 -		start of capture data (read only)
		
							Each column is 4 bytes x DEPTH words.
		
		ADDR_BITS +: WIDTH_BITS_FULL	Column
		ADDR_BITS-1 : 0					Position within column

		0x1000 0000 - signal name buffer    (read only)
		0x2000 0000 - trigger config buffer (write only)
	 */
	
	localparam STATE_IDLE 			= 0;
	localparam STATE_DTX_BUSY 		= 1;
	localparam STATE_RECONFIGURE	= 2;
	localparam STATE_RECONFIGURE_2	= 3;
	localparam STATE_CAPTURE_DONE	= 4;
	reg[7:0] state = STATE_IDLE;
	
	assign drx_ready    = (state == STATE_IDLE);
	
	reg done_sent = 0;
	
	always @(posedge clk) begin
	
		dtx_en <= 0;
		drx_buf_rd <= 0;
		rpc_fab_tx_en <= 0;
		
		la_reset <= 0;
		
		reconfig_finish	<= 0;

		case(state)
			
			//Sit around and wait for commands
			STATE_IDLE: begin
				
				//TODO: handle RPC+DMA arriving at same time
				
				//RPC message came in - process it
				if(rpc_fab_inbox_full) begin
					//TODO: Reset LA
					
					//If it's a function, return fail
					if(rpc_fab_rx_type == RPC_TYPE_CALL) begin
						rpc_fab_tx_type <= RPC_TYPE_RETURN_FAIL;
						rpc_fab_tx_d0 <= 0;
						rpc_fab_tx_d1 <= 0;
						rpc_fab_tx_d2 <= 0;
						rpc_fab_tx_en <= 1;
						
						rpc_fab_rx_done <= 1;
					end
					
					rpc_fab_rx_done <= 1;
				end
				
				//DMA message came in - process it
				else if(drx_en) begin
					
					//Read
					if( drx_op == DMA_OP_READ_REQUEST) begin
			
						//Read from signal name area
						if( drx_addr[31:28] == 4'h1) begin
							dma_tx_src <= DMA_TX_SRC_ROM;
							dtx_op <= DMA_OP_READ_DATA;
							dtx_en <= 1;
							dtx_src_addr <= 16'h0000;
							dtx_dst_addr <= drx_src_addr;
							dtx_addr <= drx_addr;
							dtx_len <= drx_len;
							state <= STATE_DTX_BUSY;
						end
						
						//Read from data area
						else begin
							
							dtx_en <= 1;
							dtx_src_addr <= 16'h0000;
							dtx_dst_addr <= drx_src_addr;
							dtx_len <= drx_len;
							dtx_op <= DMA_OP_READ_DATA;
							dma_tx_src <= DMA_TX_SRC_LA;
							dtx_addr <= drx_addr;
							state <= STATE_DTX_BUSY;
							
							dma_read_base	<= drx_addr[ADDR_BITS+1 : 2];
							la_read_column	<= drx_addr[ADDR_BITS+2 +: WIDTH_BITS_FULL];
						end
						
					end
					
					//Write request to trigger config area
					else if( (drx_op == DMA_OP_WRITE_REQUEST) && (drx_addr[31:28] == 4'h2) ) begin
						state <= STATE_RECONFIGURE;
						drx_buf_addr <= 0;
						drx_buf_rd <= 1;
						
						//Save address of our UI node
						rpc_fab_tx_dst_addr <= drx_src_addr;
						
						//Reset trigger logic
						la_reset <= 1;
						done_sent <= 0;
					end
					
					//ignore all other DMA traffic
					
				end
				
				//Capture done?
				else if(capture_done_sync && !done_sent) begin
					state <= STATE_CAPTURE_DONE;
					done_sent <= 1;
				end
				
			end	//end STATE_IDLE
			
			//Wait for DMA transmit to finish
			STATE_DTX_BUSY: begin
				if(!dtx_busy && !dtx_en)
					state <= STATE_IDLE;
			end	//end STATE_DTX_BUSY
			
			//Prepare to reconfigure the LA
			//Data is shifted in 32 bits at a time.
			//Without major refactoring, we can handle up to a 16kbit bitstream.
			//This is the largest config bitstream that will fit in a single DMA packet.
			//At 32 bits per LUT this is 512 LUTS or 1024 channels.
			STATE_RECONFIGURE: begin
				
				//Bump address and fetch next word unconditionally.
				//If we read off the end, who cares
				drx_buf_addr	<= drx_buf_addr + 9'h1;
				drx_buf_rd		<= 1;
				drx_buf_rd_buf	<= drx_buf_rd;
				
				//Stop if we got to the end (and gate the read status)
				if(drx_buf_addr == WIDTH/2) begin
					state			<= STATE_IDLE;
					reconfig_finish	<= 1;
					drx_buf_rd_buf	<= 0;
				end
				
			end	//end STATE_RECONFIGURE
			
			//Send capture-done notification
			STATE_CAPTURE_DONE: begin

				//TODO: add macro for interrupt ID
				rpc_fab_tx_type <= RPC_TYPE_INTERRUPT;
				rpc_fab_tx_callnum <= 0;
				rpc_fab_tx_d0 <= 0;
				rpc_fab_tx_d1 <= 0;
				rpc_fab_tx_d2 <= 0;
				rpc_fab_tx_en <= 1;
				state <= STATE_IDLE;

			end	//end STATE_CAPTURE_DONE
			
		endcase
		
	end
   
endmodule
