`include "bm_constants.vh"

`define S0_GENERATOR 32'h128617D1
`define S1_GENERATOR 32'h3A0E8247
`define S2_GENERATOR 32'hC5B9D11A

module tauss (
clock,
reset,
seed_in,
urng_out
);


input clock, reset;
input [`URNG_BITWIDTH-1:0] seed_in;
output [`URNG_BITWIDTH-1:0] urng_out;

reg [`URNG_BITWIDTH-1:0] urng_out;

reg [`URNG_BITWIDTH-1:0] S0;
reg [`URNG_BITWIDTH-1:0] S1;
reg [`URNG_BITWIDTH-1:0] S2;
reg [`URNG_BITWIDTH-1:0] b;


always @ (posedge clock or posedge reset) 
if (reset)
begin
	S0 = seed_in ^ `S0_GENERATOR;
	S1 = seed_in ^ `S1_GENERATOR;
	S2 = seed_in ^ `S2_GENERATOR;
	urng_out = 0;
end
else
begin
	b = ((S0 << 13) ^ S0) >> 19;
	S0 = ((S0 & 32'hFFFFFFFE) << 12) ^ b;


	b = ((S1 << 2) ^ S1) >> 25;
	S1 = ((S1 & 32'hFFFFFFF8) << 4) ^ b;

	b = ((S2 << 3) ^ S2) >> 11;
	S2 = ((S2 & 32'hFFFFFFF0) << 17) ^ b;

	urng_out = S0 ^ S1 ^ S2;
end

endmodule




