`timescale 1 ps / 1 ps
module top(input [31:0] din, input clk, reset, go, output [31:0] dout, output drdy, output [2:0] s);

	localparam S0=0, S1=1, S2=2, S3=3, S4=4, S5=5, S6=6, S7=7, S8=8; 
	reg [3:0] state;
	
	reg	[15:0]  address_x;
	wire	[31:0]  q;
	
	reg [31:0] ite_reg, reg_x, reg_thresh, reg_sum, diagonal;
	reg [7:0] reg_n;
	wire [31:0] useless, L7, L4, add32inst2, add32inst6, mult16inst1, mult16inst2, mult32inst1, mult32inst2, LS, next_row, NN, 
		reg_line, x_new, ram_in, mux_input, L5, downout;
	wire [15:0] c_sig, address_ram, L3;
	wire [7:0] N, inc, i;
	wire en_i /*to enable the counte of i*/, wr, sel_1, value, x_greater_y, thresh_comp, coff/*MUST BE Defined*/, 
		terminate /*threshold*/, terminatee /*iterations*/, enc1, row_c;

	
	ram	ram_inst (
	.address ( address_ram ),
	.clock ( clk ),
	.data ( ram_in ),
	.wren ( wr ),
	.q ( q )
	);
	
	add32	add32_inst1 (
	.dataa ( 32'b1 ),
	.datab ( ~L4 ),
	.result ( L5 )
	);
	
	add32	add32_inst2 (
	.dataa ( {24'b000000000000000000000000,i} ),
	.datab ( {16'b00000000000000,c_sig} ),
	.result ( add32inst2 )
	);
	
	add32	add32_inst3 (
	.dataa ( {24'b000000000000000000000000,i} ),
	.datab ( mult16inst1 ),
	.result ( LS ) 
	);
	
	add32	add32_inst4 (
	.dataa ( {24'b000000000000000000000000,N} ),
	.datab ( mult16inst2 ),
	.result ( next_row )
	);
	
	add32	add32_inst5 (
	.dataa ( {24'b000000000000000000000000,N} ),
	.datab ( mult32inst1 ),
	.result ( NN )
	);
	
	add32	add32_inst6 (
	.dataa ( mult32inst2 ),
	.datab ( reg_sum ),
	.result ( add32inst6)
	);
	
	sub32	sub32_inst1 (
	.dataa ( x_new ),
	.datab ( q ),
	.result ( L4 )
	);
	
	mult16	mult16_inst1 (
	.dataa ( {8'b00000000,i} ),
	.datab ( {8'b00000000,N} ),
	.result ( mult16inst1 )
	);
	
	mult16	mult16_inst2 (
	.dataa ( {8'b00000000,inc} ),
	.datab ( {8'b00000000,N} ),
	.result ( mult16inst2 )
	);
	
	mult32	mult32_inst1 (
	.dataa ( {24'b000000000000000000000000,N} ),
	.datab ( {24'b000000000000000000000000,N} ),
	.result ( mult32inst1 )
	);
	
	mult32	mult32_inst2 (
	.dataa ( {q [31:3],3'b000} ),
	.datab ( {reg_line [31:3],3'b000} ),
	.result ( mult32inst2 )
	);
	
	div32	div32_inst1(
	.denom ( {add32inst6[31:16],16'b0000000000000000} ),
	.numer ( diagonal ),
	.quotient (L7),
	.remain (useless)
	);
	
	count8	count8_inst ( /*i counter*/
	.clock ( clk ),
	.cnt_en ( en_i ),
	.q ( i )
	);
	
	count8	count8_inst2 ( /*i counter*/
	.clock ( clk ),
	.cnt_en ( /*row_c*/ (state==S6) ),
	.q ( inc )
	);
	
	count32	count32_inst (
	.clock ( clk ),
	.cnt_en ( new_ite ),
	.data ( 0 ), // revise -----
	.sload ( ite ),
	.q ( downout )
	);
	
	counter16clr	counter16clr_inst (
	.clock ( clk ),
	.cnt_en ( enc ),
	.sclr ( enc1 ),
	.q ( c_sig )
	);

	assign address_ram = sel_1? address_x: c_sig;
	assign ram_in = value? x_new: din;
	assign x_greater_y = (reg_x - q > 0)?1:0; //TO BE REVISED
	assign thresh_comp = (x_greater_y)? L4:L5;
	assign terminate = (reg_thresh > thresh_comp)?1:0; // TO BE REVISED
	assign reg_line = (coff)?diagonal:0; // Make sure to define coff
	assign coff = (L3 == c_sig)?1:0; 
	assign enc = go || enc1;
	assign row_c = ({16'b0,c_sig} == next_row);
	assign fin = (downout == 0);
	assign enc1 = (N*N == c_sig);
	assign drdy = (state==S8);
	assign s = state;
	assign dout = L7;
	assign sel_1 = (state == S7);
	assign wr = (state == S3)||(state == S7);
	assign value = 0;
	assign N =  reg_n;
	
	always @(posedge clk) 
		begin 
		if (reset) state <= S0;
		else 
		begin 
		case(state) 
		S0: begin if(go) 
						begin 
						 reg_n <= din; 
						 state <= S1; 
						end /*go*/
						else state <= S0; 
			 end /*S0*/
		S1: begin 
				ite_reg <= din; 
				state <= S2;
			 end /*S1*/
		S2: begin 
				reg_thresh <= din; 
				state <= S3; 
			 end /*S2*/
		S3: begin 
				state <= S4; 
			 end	
			
		S4: begin 
				state <= S5; 
			 
			 end /*S4*/
			 
		S5: begin 
			if (terminate)
				state <= S8; 
			else 
				begin
					if(row_c)
					begin 
						reg_sum <= add32inst6; 
						reg_x <= L7;
						state <= S6;
					end /*row_c*/
					else
						begin 
						state <= S5;
						$display("wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww");
						end 
				end /*else Terminate*/
			end /*S5*/
		S6: 
		begin 
			address_x <= add32inst2; 
			state <= S7; 
		end /*S6*/
		
		S7: 
		begin 
			if (fin) state <= S0;  /*fin*/ 
			else 
			begin 
				if (terminatee) 
					begin
						state <= S8; 
					end /*terminatee*/
				else 
					begin 
						state <= S5; 
					end /*else terminatee*/
			end /*else fin*/ 
		end /*S7*/
		
		S8: 
		begin 
			state <= S0; 
		end /*S8*/
		
		default: state <= S0; // Default case, force it to zero
		endcase 
		
	end /*end for the very first else*/
	end /*end for the always block*/
	
endmodule
