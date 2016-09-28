`timescale 1ns / 1ps
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
	@brief Unidirectional pipeline stage for RPCv2
 */
module RPCv2PipelineStage(
	clk,
	rpc_en, rpc_ack, rpc_data,
	rpc_en_buf, rpc_ack_buf, rpc_data_buf
	);
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// I/O declarations
	
	input wire clk;
	
	input wire rpc_en;
	input wire[1:0] rpc_ack;
	input wire[31:0] rpc_data;
	
	parameter STAGES = 1;
	
	output wire rpc_en_buf;
	output wire[1:0] rpc_ack_buf;
	output wire[31:0] rpc_data_buf;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Pipelining
	
	generate
		
		//No pipelining - just pass through
		if(STAGES == 0) begin
			assign rpc_en_buf = rpc_en;
			assign rpc_ack_buf = rpc_ack;
			assign rpc_data_buf = rpc_data;
		end
		
		//Single pipeline stage
		else if(STAGES == 1) begin
			(* KEEP="yes" *) reg rpc_en_ff = 0;
			(* KEEP="yes" *) reg[1:0] rpc_ack_ff = 0;
			(* KEEP="yes" *) reg[31:0] rpc_data_ff = 0;
			
			always @(posedge clk) begin
				rpc_en_ff <= rpc_en;
				rpc_ack_ff <= rpc_ack;
				rpc_data_ff <= rpc_data;
			end
			
			assign rpc_en_buf = rpc_en_ff;
			assign rpc_ack_buf = rpc_ack_ff;
			assign rpc_data_buf = rpc_data_ff;
			
		end
		
		//Multiple pipeline stages not implemented yet
		else begin
		
			initial begin
				$display("ERROR: Only 0/1 pipeline stages supported in RPCv2PipelineStage for now");
				$finish;
			end
		end
	
	endgenerate

endmodule
