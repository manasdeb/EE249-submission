`include "bm_constants.vh"

`define A_CIRC_S7_48                     56'sd170926505739102
`define A_HYPERB_S7_48                   56'd339890743935231
`define ONE_S7_48                        56'sd281474976710656 
`define TWO_S7_48                        56'sd562949953421312
`define QUARTER_S7_48                    56'sd70368744177664
`define HALFPI_S7_48                     56'sd442139859501778
`define LOG_2_S7_48                      56'sd195103586505167
`define LOG_LIMIT_S7_48                  56'sd42221246506598
`define SQRT_LOWER_LIMIT_S7_48           56'sd8444249301320
`define SQRT_UPPER_LIMIT_S7_48           56'sd562949953421312


module logsqrt (
clock, 
reset,
valid_in,
op_type,
arg_in,
result,
valid_out
);

localparam IO_BITWIDTH = 56;
localparam CORDIC_PIPELINE_DEPTH = 16;

input clock, reset, valid_in;
input op_type;
input [IO_BITWIDTH-1:0] arg_in;
output [IO_BITWIDTH-1:0] result;
output valid_out;

reg signed [IO_BITWIDTH-1:0] cordic_arg;
reg signed [IO_BITWIDTH-1:0] result;
reg valid_out;

reg signed [IO_BITWIDTH-1:0] scalefactor[0:CORDIC_PIPELINE_DEPTH];
reg cordic_op[0:CORDIC_PIPELINE_DEPTH];
reg signed [IO_BITWIDTH-1:0] scalefactor_latch_in, scalefactor_latch_out;
reg cordic_op_latch_in, cordic_op_latch_out;
reg mod_two;
reg signed [IO_BITWIDTH-1:0] temp_result, adjust_val;

reg valid_in_hyperb;
wire valid_out_hyperb;
reg signed [IO_BITWIDTH-1:0] x, y, z;
wire signed [IO_BITWIDTH-1:0] result_x, result_y, result_z;



always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			cordic_op_latch_in = op_type;
			scalefactor_latch_in = 0;
			cordic_arg = arg_in;

			if (op_type == `OPTYPE_LOG) begin
				// Range scale the LOG argument to the range [0.15, 10]
				repeat(48) begin
					if (cordic_arg <= `LOG_LIMIT_S7_48) begin
						cordic_arg = cordic_arg << 1;
						scalefactor_latch_in = scalefactor_latch_in + 1;
					end
				end

				x = fixedpt_add(cordic_arg, `ONE_S7_48);
				y = fixedpt_sub(cordic_arg, `ONE_S7_48);
				z = 0;
	
				valid_in_hyperb = 1;
			end // log
			else begin
				mod_two = 0;

				// Range scale the SQRT argument to the range [0.03, 2]
				repeat(48) begin
					if (cordic_arg < `SQRT_LOWER_LIMIT_S7_48)
					begin
						cordic_arg = cordic_arg << 1;
						scalefactor_latch_in = scalefactor_latch_in - 1;
						mod_two = ~mod_two;
					end
					else if (cordic_arg > `SQRT_UPPER_LIMIT_S7_48)
					begin
						cordic_arg = cordic_arg >> 1;
						scalefactor_latch_in = scalefactor_latch_in + 1;
						mod_two = ~mod_two;
					end
				end

				if (mod_two == 1) begin
					if (scalefactor_latch_in < 0) begin
						cordic_arg = cordic_arg << 1;
						scalefactor_latch_in = scalefactor_latch_in - 1;
						mod_two = ~mod_two;
					end
					else if (scalefactor_latch_in > 0) begin
						cordic_arg = cordic_arg >> 1;
						scalefactor_latch_in = scalefactor_latch_in + 1;
						mod_two = ~mod_two;
					end
				end

				x = fixedpt_add(cordic_arg, `QUARTER_S7_48);
				y = fixedpt_sub(cordic_arg, `QUARTER_S7_48);
				z = 0;

				valid_in_hyperb = 1;
			end // sqrt
		end // valid_in
	end // !reset
end // always


// Move the pipeline forward
always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			scalefactor[0] <= scalefactor_latch_in;
			scalefactor[1] <= scalefactor[0];
			scalefactor[2] <= scalefactor[1];
			scalefactor[3] <= scalefactor[2];
			scalefactor[4] <= scalefactor[3];
			scalefactor[5] <= scalefactor[4];
			scalefactor[6] <= scalefactor[5];
			scalefactor[7] <= scalefactor[6];
			scalefactor[8] <= scalefactor[7];
			scalefactor[9] <= scalefactor[8];
			scalefactor[10] <= scalefactor[9];
			scalefactor[11] <= scalefactor[10];
			scalefactor[12] <= scalefactor[11];
			scalefactor[13] <= scalefactor[12];
			scalefactor[14] <= scalefactor[13];
			scalefactor[15] <= scalefactor[14];
			scalefactor[16] <= scalefactor[15];
			scalefactor_latch_out <= scalefactor[16];

			cordic_op[0] <= cordic_op_latch_in;
			cordic_op[1] <= cordic_op[0];
			cordic_op[2] <= cordic_op[1];
			cordic_op[3] <= cordic_op[2];
			cordic_op[4] <= cordic_op[3];
			cordic_op[5] <= cordic_op[4];
			cordic_op[6] <= cordic_op[5];
			cordic_op[7] <= cordic_op[6];
			cordic_op[8] <= cordic_op[7];
			cordic_op[9] <= cordic_op[8];
			cordic_op[10] <= cordic_op[9];
			cordic_op[11] <= cordic_op[10];
			cordic_op[12] <= cordic_op[11];
			cordic_op[13] <= cordic_op[12];
			cordic_op[14] <= cordic_op[13];
			cordic_op[15] <= cordic_op[14];
			cordic_op[16] <= cordic_op[15];
			cordic_op_latch_out <= cordic_op[16];
		end
	end
end



always @ (posedge clock) begin
	if (!reset) begin
		if (valid_out_hyperb) begin

			if (cordic_op_latch_out == `OPTYPE_LOG) begin
				temp_result = fixedpt_mul(result_z, `TWO_S7_48);

				if (scalefactor_latch_out != 0) begin
					scalefactor_latch_out = scalefactor_latch_out << 48;
					adjust_val = fixedpt_mul(scalefactor_latch_out, `LOG_2_S7_48);
					result = fixedpt_sub(temp_result, adjust_val);
				end
				else begin
					result = temp_result;
				end
			end
			else begin
				temp_result = fixedpt_mul(result_x, `A_HYPERB_S7_48);
				if (scalefactor_latch_out != 0) begin
					scalefactor_latch_out = scalefactor_latch_out >>> 1;

					if (scalefactor_latch_out < 0)
						result = temp_result >>> -scalefactor_latch_out;
					else if (scalefactor_latch_out > 0)
						result = temp_result <<< scalefactor_latch_out;
				end
				else begin
					result = temp_result;
				end
			end

			valid_out = 1;
		end
	end
end



`include "fixedpt_funcs.vh"


cordic_hyperb CORDIC_HYPERB(
.clock (clock),
.reset(reset),
.valid_in(valid_in_hyperb),
.x_in(x),
.y_in(y),
.z_in(z),
.x_out(result_x),
.y_out(result_y),
.z_out(result_z),
.valid_out(valid_out_hyperb)
);

endmodule



