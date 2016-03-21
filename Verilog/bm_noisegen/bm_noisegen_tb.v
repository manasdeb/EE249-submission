`include "bm_constants.vh"

`define SEED_1    32'h9A61CBB2
`define SEED_2    32'hF26C2A1E

module bm_noisegen_tb;

reg clock, reset;
reg [`URNG_BITWIDTH-1:0] seed_1, seed_2;
wire signed [`AWGN_BITWIDTH-1:0] awgn_samp1, awgn_samp2;

integer file_hndl;
integer sample_index;

initial begin
  clock = 0;
  reset = 1;
  seed_1 = `SEED_1;
  seed_2 = `SEED_2;

  file_hndl=$fopen("awgn_rtl_out.txt");
  sample_index=0;

  #10 reset = 0;
end

always @ (posedge clock) begin
	$display("At time %d awgn samp1 = %d, samp2 = %d", $time, awgn_samp1, awgn_samp2);

	if (sample_index < 10100)
  		$fdisplay(file_hndl, "%d %d", awgn_samp1, awgn_samp2);

	sample_index = sample_index + 1;

	if (sample_index == 10100)
		$fclose(file_hndl);
end

always begin
 #5 clock = !clock;
end

bm_noisegen BM_NOISEGEN (
.clock(clock),
.reset(reset),
.seed_in1(seed_1),
.seed_in2(seed_2),
.awgn_out1(awgn_samp1),
.awgn_out2(awgn_samp2)
);

endmodule


