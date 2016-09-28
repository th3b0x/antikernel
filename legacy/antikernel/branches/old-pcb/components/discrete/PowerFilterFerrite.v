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
	@brief Ferrite chip used for power rail filtering
 */
module PowerFilterFerrite(vin, vout);
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// I/O / parameter declarations
	
	(* drc_type = "power_in" *)  input wire vin;
	(* drc_type = "power_out" *) output wire vout;
	
	parameter package			= "SM0402";
	parameter distributor		= "digikey";
	parameter distributor_part	= "";
	parameter impedance			= 0;
	parameter frequency			= 0;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// DRC logic
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Create the black-box cell
	
	generate
	
		case(package)
			
			"SM0402": begin
				SM0402 #(
					.distributor("digikey"),
					.distributor_part(distributor_part),
					.value(impedance)
				) dcell (
					.p2(vout),
					.p1(vin)
				);
			end
			
			"SM0603": begin
				SM0603 #(
					.distributor("digikey"),
					.distributor_part(distributor_part),
					.value(impedance)
				) dcell (
					.p2(vout),
					.p1(vin)
				);
			end
			
			"SM0805": begin
				SM0805 #(
					.distributor("digikey"),
					.distributor_part(distributor_part),
					.value(impedance)
				) dcell (
					.p2(vout),
					.p1(vin)
				);
			end
			
			default: begin
				assert property (1 == 0);
			end
			
		endcase
			
	endgenerate
	
endmodule


