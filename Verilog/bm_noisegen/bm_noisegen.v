`include "bm_constants.vh"


module bm_noisegen (
clock,
reset,
seed_in1,
seed_in2,
awgn_out
);


input clock, reset;
input [`URNG_BITWIDTH-1:0] seed_in1, seed_in2;
output [`AWGN_BITWIDTH-1:0] awgn_out;

reg valid_in_sin, valid_in_cos, valid_in_log, valid_in_sqrt;
reg sin_op, cos_op, log_op, sqrt_op;
reg [47:0] log_arg;
reg [30:0] sqrt_arg;
wire [`URNG_BITWIDTH-1:0] urng_out1, urng_out2;
wire valid_out_sin, valid_out_cos, valid_out_log, valid_out_sqrt;

always @ (posedge reset) begin
	valid_in_sincos = 0;
end

always @ (posedge clock) begin
	if (! reset) begin
		valid_in_sin <= 1;
		valid_in_cos <= 1;
		sin_op <= `OPTYPE_SIN;
		cos_op <= `OPTYPE_COS;
		sin_arg <= urng_out1;
		cos_arg <= urng_out2;


	end
end


always @ (posedge clock) begin
	if (! reset) begin
		if (valid_out_sin) begin
		end
	end
end


always @ (posedge clock) begin
	if (! reset) begin
		if (valid_out_cos) begin
		end
	end
end







tauss TAUSS1 (
.clock(clock), 
.reset(reset),
.seed_in(seed_in1),
.urng_out(urng_out1)
);

tauss TAUSS2 (
.clock(clock), 
.reset(reset),
.seed_in(seed_in2),
.urng_out(urng_out2)
);

sincos SINCOS1 (
.clock(clock), 
.reset(reset),
.valid_in(valid_in_sin),
.op_type(sin_op),
.arg_in(sin_arg),
.result(sin_result),
.valid_out(sin_valid_out)
);

sincos SINCOS2 (
.clock(clock), 
.reset(reset),
.valid_in(valid_in_cos),
.op_type(cos_op),
.arg_in(cos_arg),
.result(cos_result),
.valid_out(cos_valid_out)
);

logsqrt LOGSQRT1 (
.clock(clock), 
.reset(reset),
.valid_in(log_valid_in),
.op_type(log_op),
.arg_in(log_arg),
.result(log_result),
.valid_out(log_valid_out)
);

logsqrt LOGSQRT2 (
.clock(clock), 
.reset(reset),
.valid_in(sqrt_valid_in),
.op_type(sqrt_op),
.arg_in(sqrt_arg),
.result(sqrt_result),
.valid_out(sqrt_valid_out)
);



endmodule
