`include "bm_constants.vh"


module bm_noisegen (
clock,
reset,
seed_in1,
seed_in2,
awgn_out1,
awgn_out2
);

localparam URNG_PIPELINE_DEPTH = 16;

input clock, reset;
input [`URNG_BITWIDTH-1:0] seed_in1, seed_in2;
output [`AWGN_BITWIDTH-1:0] awgn_out1, awgn_out2;

reg signed [`AWGN_BITWIDTH-1:0] awgn_out1, awgn_out2;

reg valid_in_sin, valid_in_cos, valid_in_log, valid_in_sqrt;
reg sin_op, cos_op;

reg [15:0] sin_arg;
reg [15:0] cos_arg;
reg [47:0] log_arg;
reg [30:0] sqrt_arg;

reg [15:0] urng_pipeline_latch_in, urng_pipeline_latch_out;
reg [15:0] urng_pipeline[0:URNG_PIPELINE_DEPTH];

reg signed [18:0] f_reg, g0_reg, g1_reg;

wire [`URNG_BITWIDTH-1:0] urng_out1, urng_out2;
wire valid_out_sin, valid_out_cos, valid_out_log, valid_out_sqrt;
wire signed [15:0] sin_result;
wire signed [15:0] cos_result;
wire [30:0] log_result;
wire [16:0] sqrt_result;

always @ (posedge reset) begin
	valid_in_sin = 0;
	valid_in_cos = 0;
	valid_in_log = 0;
	valid_in_sqrt = 0;
	sin_op = `OPTYPE_SIN;
	cos_op = `OPTYPE_COS;
end


always @ (posedge clock) begin
	if (! reset) begin
		urng_pipeline_latch_in <= urng_out1[15:0];
		log_arg <= {urng_out2, urng_out1[31:16]};
		valid_in_log <= 1;
	end
end

// Move the URNG pipeline forward
// This is a synchronization pipeline to align the start
// and end of the sqrt and sin/cosine computation
always @ (posedge clock) begin
	if (! reset) begin
		urng_pipeline[0] <= urng_pipeline_latch_in;
		urng_pipeline[1] <= urng_pipeline[0];
		urng_pipeline[2] <= urng_pipeline[1];
		urng_pipeline[3] <= urng_pipeline[2];
		urng_pipeline[4] <= urng_pipeline[3];
		urng_pipeline[5] <= urng_pipeline[4];
		urng_pipeline[6] <= urng_pipeline[5];
		urng_pipeline[7] <= urng_pipeline[6];
		urng_pipeline[8] <= urng_pipeline[7];
		urng_pipeline[9] <= urng_pipeline[8];
		urng_pipeline[10] <= urng_pipeline[9];
		urng_pipeline[11] <= urng_pipeline[10];
		urng_pipeline[12] <= urng_pipeline[11];
		urng_pipeline[13] <= urng_pipeline[12];
		urng_pipeline[14] <= urng_pipeline[13];
		urng_pipeline[15] <= urng_pipeline[14];
		urng_pipeline[16] <= urng_pipeline[15];
		urng_pipeline_latch_out <= urng_pipeline[16];
	end
end


always @ (posedge clock) begin
	if (! reset) begin
		if (valid_out_log) begin
			sqrt_arg <= log_result;
			valid_in_sqrt <= 1;

			sin_arg <= urng_pipeline_latch_out;
			cos_arg <= urng_pipeline_latch_out;
			valid_in_sin <= 1;
			valid_in_cos <= 1;
		end
	end
end


always @ (posedge clock) begin
	if (! reset) begin
		if (valid_out_sqrt) begin
			f_reg = sqrt_result; 
			f_reg = f_reg <<< 2;

			g0_reg = sin_result;
			g1_reg = cos_result;

			awgn_out1 = fixedpt_mul(f_reg, g0_reg);
			awgn_out2 = fixedpt_mul(f_reg, g1_reg);
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

sincos SINUNIT (
.clock(clock), 
.reset(reset),
.valid_in(valid_in_sin),
.op_type(sin_op),
.arg_in(sin_arg),
.result(sin_result),
.valid_out(valid_out_sin)
);

sincos COSUNIT (
.clock(clock), 
.reset(reset),
.valid_in(valid_in_cos),
.op_type(cos_op),
.arg_in(cos_arg),
.result(cos_result),
.valid_out(valid_out_cos)
);

logunit LOGUNIT (
.clock(clock), 
.reset(reset),
.valid_in(valid_in_log),
.arg_in(log_arg),
.result(log_result),
.valid_out(valid_out_log)
);

sqrtunit SQRTUNIT (
.clock(clock), 
.reset(reset),
.valid_in(valid_in_sqrt),
.arg_in(sqrt_arg),
.result(sqrt_result),
.valid_out(valid_out_sqrt)
);

function signed [15:0] fixedpt_mul;
input signed [18:0] op1;
input signed [18:0] op2;
reg signed [37:0] prodval;
begin
	prodval = op1 * op2;
	prodval = prodval >>> 14;
	if (prodval[0] == 1)
		prodval = prodval + 1;

	prodval = prodval >>> 1;

	if (prodval > 524288)
		fixedpt_mul = 524288;
	else if (prodval < -524288)
		fixedpt_mul = -524288;
	else begin
		prodval = prodval >>> 3;
		if (prodval[1] == 1)
			prodval = prodval + 1;

		prodval = prodval >>> 1;
		fixedpt_mul = prodval[16:0];
	end
end
endfunction


endmodule
