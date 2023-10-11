`timescale 1 ps / 1 ps
/*module test_tb;

reg [31:0] din;
reg clk, reset, go;
wire [31:0] dout;
wire drdy;

reg[31:0] mem[0:65536];
integer i, file, file_out;
integer counter =0;

top top_test (din, clk, reset, go, dout, drdy);	



initial
begin 
	$monitor(din);
	$display("display");
	reset =1;
	#5
	reset =0;
	go =1;
	clk = 0;
	forever
	begin
	clk = !clk;
	#5;
	end
end 
initial 
begin 
	file = $fopen("D:/quartus/input.txt","r");
	file_out = $fopen("out302file.txt","w");

	for (i =0;i<65536; i= i+1)
	begin 
		@(posedge clk);
		//$fscanf(file,"%d", mem);
	end
	$fclose(file);
end

always @(posedge clk)
	
	begin 
	if (drdy) 
	begin
		//$fprintf(file_out,"%d",dout);
		counter = counter +1;
	end 
		if(counter == 65536)
		$fclose(file_out);
#10
$stop;
	end
endmodule*/

module test_tb; 
integer i; 
reg clk, reset, go; 
reg[31:0] contentFile [40200:0]; 
reg[31:0] din; 
wire[31:0] dout;
wire [2:0] s;


 


top top_inst(din, clk, reset, go, dout, drdy,s);

 


always #5 clk = ~ clk; 
reg[31:0] N; 
initial 
begin 
reset = 1;
#5
reset = 0;
go = 1; 
clk = 1; 
$readmemh("D:/quartus/input.txt", contentFile); 
@(negedge clk) din = contentFile[0]; N = contentFile[0];
@(negedge clk) din = contentFile[1]; 
@(negedge clk) din = contentFile[2]; 
for (i = 0; i<=((N*N)+N);i=i+1)
    begin
        @(negedge clk) din = contentFile[3 + i]; 
		  $display("CEO of COE");
    end 
#100
$stop; 

end
endmodule