module matrix_multiply(
	output [7:0] data_out,
	output data_rdy,
	input [7:0] data_in,
	input go, reset, clk);

	localparam
		reset_state=0,
		comp_base_br=1,
		loop_r=2,
		loop_c=3,
		loop_k=4,
		comp_addr_b=5,
		load_word_a=6,
		nop_a=11,
		load_word_b=7,
		nop_b=12,
		calc_acc=8,
		store_R_r_c=9,
		done=10,
		N_width=3;

	reg [3:0] ps;

	reg [N_width-1:0] N;
	reg [N_width-1:0] r, c, k;
	reg [7:0] acc;
	reg [7:0] word_a, word_b;


	reg [9:0] address, addr_a, addr_b, addr_r, base_a, base_b, base_r; // 3 X 2^3 X 2^16
	reg [7:0] data;
	reg we;

	wire [7:0] q;

	// memory must hold 3 x 8 x N^2 (A, B, and R)
	single_port_ram matrices(address, clk, data, we, data_rdy, q);

	assign data_rdy = (ps==done);

	always @(posedge clk)
	begin
		if (reset)
		begin
			ps <= reset_state;
			data <= 0; we <= 0; address <= 0;
		end
		else
			case (ps)
        reset_state:
          begin
            if (go) begin
              r <= 0;
							base_a <= 0;
							N <= data_in;
        			ps <= comp_base_br;
            end // if (go)
          end // reset_state
				comp_base_br:
					begin
						base_b <= N*N;
						base_r <= (N*N)<< 1;
						ps <= loop_r;
					end // comp_base_bc
				loop_r:
					begin
						if (r<N)
							begin
								c <= 0;
								ps <= loop_c;
							end // if (r<N)
						else
							begin
							 	ps <= done;
							end // else
					end  // loop_r:

				loop_c:
						begin
							if (c<N)
								begin
									we <= 0; // make sure write is disabled
									acc <= 0;
						      addr_a <= base_a+r*N;
						      addr_b <= base_b+c;
						      k <= 0;
									ps <= loop_k;
								end // if (r<N)
							else
								begin
									r <= r + 1;
									c <= 0;
									ps <= loop_r;
								end // else
						end  // loop_c:

						loop_k:
								begin
									if (k<N)
										begin
											we <= 0;
											address <= addr_a;
											// LOAD(addr_a);
											ps <= nop_a;
										end // if (k<N)
									else
										begin
											c <= c + 1;
											k <= 0;
											addr_r <= base_r + N*r + c;
											ps <= store_R_r_c;
										end // else
								end  // loop_k:

						nop_a:
							begin
								// in this state, address register is ready
								// and in the next edge, q shall be ready
								ps <= load_word_a;
							end // nop_a
						load_word_a:
							begin
								word_a <= q;
								$display("%3t\tword_a <= q (=%d)", $time, q);
								we <= 0;
								address <= addr_b;
								// LOAD(addr_b);
								ps <= nop_b;
							end // load_word_a

							nop_b:
								begin
									ps <= load_word_b;
								end // nop_b

						load_word_b:
							begin
								word_b <= q;
								// $display("%3t\tword_a is %d", $time, word_a);
								$display("%3t\tword_b <= q (=%d)", $time, q);
								ps <= calc_acc;
							end // load_word_a

						calc_acc:
							begin
								// $display("%3t\tword_b is %d", $time, word_b);
								acc <= acc + word_a * word_b;
								$display("acc: @(%t) %d + %d * %d", $time, acc, word_a, word_b);
				        addr_a <= addr_a + 1;
				        addr_b <= addr_b + N;
				        k <= k + 1;
								ps <= loop_k;
							end // calc_acc

						store_R_r_c:
							begin
								we <= 1;
								address <= addr_r;
								data <= acc;
								// STORE(addr_r, acc);
								ps <= loop_c;
							end

						done:
							begin
								// stay here for the rest of the time
							end // done

			endcase
	end // always

	//
	task LOAD(input [9:0] word_address);
	begin
		$display("LOAD: %t\taddress=%d\twe=%d\tq=%d", $time, word_address, we, q);
		we <= 1'b0; // disable write;
		address <= word_address;
		// data is loaded into q in the next clock cycle
	end
	endtask

	task STORE(input [9:0] word_address, input [7:0] data_to_store);
	begin
		$display("STORE: %t\taddress=%d\tdata=%d\twe=%d", $time, word_address, data_to_store, we);
		we <= 1'b1; // enable write;
		address <= word_address;
		data <= data_to_store;
		// data is stored in mem in the next clock cycle
	end
	endtask

endmodule

module matrix_multiply_tb;

	wire [7:0] data_out;
	wire data_rdy;
	reg [7:0] data_in;
	reg go, reset, clk;

	matrix_multiply mm(data_out, data_rdy, data_in, go, reset, clk);

	always #1 clk = ~clk;

	initial
	begin
    $dumpfile("dump.vcd"); $dumpvars;
		#20;
		//$display("Starting main tb\n");
		#1;
		go=0; reset=0; clk=1; data_in=0;
		@(negedge clk) reset=1;
		@(negedge clk) reset=0; go=1; data_in=3;
		@(negedge clk) go=0;
		@(negedge clk);
		#2000;
		$finish();
	end
endmodule

module single_port_ram
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=10)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk,
	input [(DATA_WIDTH-1):0] data,
	input we,
	input data_rdy,
	output reg [(DATA_WIDTH-1):0] q
);
	localparam  base_a=0, base_b=9, base_r = 18;
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	reg [ADDR_WIDTH-1:0] ptr;

	initial begin
		// $readmemh("init.txt", ram, 0, 17);
		ram[0]=0; ram[1]=1; ram[2]=2;
		ram[3]=3; ram[4]=4; ram[5]=5;
		ram[6]=6; ram[7]=7; ram[8]=8;

		ram[9 ]=0; ram[10]=1; ram[11]=2;
		ram[12]=3; ram[13]=4; ram[14]=5;
		ram[15]=6; ram[16]=7; ram[17]=8;


		#1;
		//$display("Address\tWord");
		for (ptr=0; ptr<18; ptr=ptr+1)
		begin
			// ram[ptr] = ptr;
			//$display("%d\t%d", ptr, ram[ptr]);
		end
		$display("time\taddr\twe\tdata\tq");
		$monitor("%3t\t%3d\t%2d\t%3d\t%3d", $time, addr, we, data, q);
	end

	integer i;
	initial
	begin
		@(posedge data_rdy)
			begin
				$display("Content of matrix A:");
				$display("[ %5d%5d%5d", ram[base_a+0], ram[base_a+1], ram[base_a+2]);
				$display("  %5d%5d%5d", ram[base_a+3], ram[base_a+4], ram[base_a+5]);
				$display("  %5d%5d%5d ]", ram[base_a+6], ram[base_a+7], ram[base_a+8]);

				$display("Content of matrix B:");
				$display("[ %5d%5d%5d", ram[base_b+0], ram[base_b+1], ram[base_b+2]);
				$display("  %5d%5d%5d", ram[base_b+3], ram[base_b+4], ram[base_b+5]);
				$display("  %5d%5d%5d ]", ram[base_b+6], ram[base_b+7], ram[base_b+8]);

				$display("Content of matrix R (=AxB):");
				$display("[ %5d%5d%5d", ram[base_r+0], ram[base_r+1], ram[base_r+2]);
				$display("  %5d%5d%5d", ram[base_r+3], ram[base_r+4], ram[base_r+5]);
				$display("  %5d%5d%5d ]", ram[base_r+6], ram[base_r+7], ram[base_r+8]);
			end // negedge
	end // initial



	// initial begin
	// 	$monitor("%t\t%d\t%d\n"$time, addr_reg, ram[addr_reg]);
	// end


	// Variable to hold the registered read address
	// reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (posedge clk)
	begin
		// Write
		if (we) begin
			ram[addr] <= data;
			q <= data; // load the new data when writing
		end
		else
			q <= ram[addr];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.
//	assign q = ram[addr_reg];

endmodule


// The $readmemb and $readmemh system tasks load the contents of a 2-D
// array variable from a text file.  Quartus Prime supports these system tasks in
// initial blocks.  They may be used to initialized the contents of inferred
// RAMs or ROMs.  They may also be used to specify the power-up value for
// a 2-D array of registers.
//
// Usage:
//
// ("file_name", memory_name [, start_addr [, end_addr]]);
// ("file_name", memory_name [, start_addr [, end_addr]]);
//
// File Format:
//
// The text file can contain Verilog whitespace characters, comments,
// and binary ($readmemb) or hexadecimal ($readmemh) data values.  Both
// types of data values can contain x or X, z or Z, and the underscore
// character.
//
// The data values are assigned to memory words from left to right,
// beginning at start_addr or the left array bound (the default).  The
// next address to load may be specified in the file itself using @hhhhhh,
// where h is a hexadecimal character.  Spaces between the @ and the address
// character are not allowed.  It shall be an error if there are too many
// words in the file or if an address is outside the bounds of the array.
//
// Example:
//
// reg [7:0] ram[0:2];
//
// initial
// begin
//     $readmemb("init.txt", rom);
// end
//
// <init.txt>
//
// 11110000      // Loads at address 0 by default
// 10101111
// @2 00001111
