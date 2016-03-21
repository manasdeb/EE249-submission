`include "bm_constants.vh"

module tauss_tb;

reg clock, reset;

reg [`URNG_BITWIDTH-1:0] seed_in;
wire [`URNG_BITWIDTH-1:0] result;

initial begin
  clock = 0;
  reset = 1;
  seed_in = 32'h9A61C8B2; // F26C2A1E 

  #15 reset = 0; 
end

always @ (posedge clock) begin
	$display("At time %d tauss result = %d", $time, result);
end

always begin
 #5 clock = !clock;
end


tauss TAUSS (
.clock(clock), 
.reset(reset),
.seed_in(seed_in),
.urng_out(result)
);

endmodule
