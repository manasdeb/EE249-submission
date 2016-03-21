`include "bm_constants.vh"

`define A_CIRC_S7_48                     56'sd170926505739102
`define A_HYPERB_S7_48                   56'd339890743935231
`define ONE_S7_48                        56'sd281474976710656 
`define TWO_S7_48                        56'sd562949953421312
`define QUARTER_S7_48                    56'sd70368744177664
`define HALFPI_S7_48                     56'sd442139859501778
`define TWO_PI_S7_48                     56'sd1768559438007110
`define LOG_2_S7_48                      56'sd195103586505167
`define LOG_LIMIT_S7_48                  56'sd42221246506598
`define SQRT_LOWER_LIMIT_S7_48           56'sd8444249301320
`define SQRT_UPPER_LIMIT_S7_48           56'sd562949953421312
`define MAX_OUTPUTVAL                    56'sd281474976710655
`define MIN_OUTPUTVAL                    -56'sd281474976710656



module sincos (
clock, 
reset,
valid_in,
op_type,
arg_in,
result,
valid_out
);

`include "fixedpt_funcs.vh"

localparam IO_BITWIDTH = 16;
localparam CORDIC_BITWIDTH = 56;
localparam CORDIC_PIPELINE_DEPTH = 16;

input clock, reset, valid_in;
input op_type;
input [IO_BITWIDTH-1:0] arg_in;
output signed [IO_BITWIDTH-1:0] result;
output valid_out;

reg signed [CORDIC_BITWIDTH-1:0] cordic_arg;
reg signed [CORDIC_BITWIDTH-1:0] temp_arg;
reg signed [IO_BITWIDTH-1:0] result;
reg signed [CORDIC_BITWIDTH-1:0] temp_result;
reg valid_out;

reg valid_in_circ;
wire valid_out_circ;
reg [4:0] half_pi_angles_latch_in, half_pi_angles_latch_out;
reg [4:0] half_pi_angles[0:CORDIC_PIPELINE_DEPTH];

reg signed [CORDIC_BITWIDTH-1:0] x, y, z;
wire signed [CORDIC_BITWIDTH-1:0] result_x, result_y, result_z;

always @ (posedge reset) begin
	valid_out = 0;
	valid_in_circ = 0;
	result = 0;
end

always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			// The input argument is 16-bits wide. However, the CORDIC uses 48 bits
			// internally
			temp_arg = arg_in;
			temp_arg = temp_arg <<< 32;

			// Multiply the input argument by 2*pi
			temp_arg = fixedpt_mul(temp_arg, `TWO_PI_S7_48);

			if (op_type == `OPTYPE_COS)
				cordic_arg = fixedpt_add(temp_arg, `HALFPI_S7_48);
			else
				cordic_arg = temp_arg;

			half_pi_angles_latch_in = 0;

			// Range scale the angle argument to a value between [-pi/4, pi/4]
			repeat(4) begin
				if (cordic_arg >= `HALFPI_S7_48) begin
					cordic_arg = fixedpt_sub(cordic_arg, `HALFPI_S7_48);
					half_pi_angles_latch_in = half_pi_angles_latch_in + 1;
				end
			end

			if (half_pi_angles_latch_in == 4)
				half_pi_angles_latch_in = 0;

			x = `A_CIRC_S7_48;
			y = 0;
			z = cordic_arg;

			valid_in_circ = 1;
		end
	end
end



always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			half_pi_angles[0] <= half_pi_angles_latch_in;
			half_pi_angles[1] <= half_pi_angles[0];
			half_pi_angles[2] <= half_pi_angles[1];
			half_pi_angles[3] <= half_pi_angles[2];
			half_pi_angles[4] <= half_pi_angles[3];
			half_pi_angles[5] <= half_pi_angles[4];
			half_pi_angles[6] <= half_pi_angles[5];
			half_pi_angles[7] <= half_pi_angles[6];
			half_pi_angles[8] <= half_pi_angles[7];
			half_pi_angles[9] <= half_pi_angles[8];
			half_pi_angles[10] <= half_pi_angles[9];
			half_pi_angles[11] <= half_pi_angles[10];
			half_pi_angles[12] <= half_pi_angles[11];
			half_pi_angles[13] <= half_pi_angles[12];
			half_pi_angles[14] <= half_pi_angles[13];
			half_pi_angles[15] <= half_pi_angles[14];
			half_pi_angles[16] <= half_pi_angles[15];
			half_pi_angles_latch_out <= half_pi_angles[16];
		end
	end
end

always @ (posedge clock) begin
	if (!reset) begin
		if (valid_out_circ) begin
			case (half_pi_angles_latch_out)
				2'd0:
					begin
						 temp_result = result_y;	

					end

				2'd1:
					begin
						temp_result = result_x;	
					end

				2'd2:
					begin
						temp_result = -result_y;
					end

				2'd3:
					begin
						temp_result = -result_x;
					end
			endcase

			if (temp_result > `MAX_OUTPUTVAL)
				temp_result = `MAX_OUTPUTVAL;
			else if (temp_result < `MIN_OUTPUTVAL)
				temp_result = `MIN_OUTPUTVAL;

			temp_result = temp_result >>> 32;
			if (temp_result[0] == 1)
					temp_result = temp_result + 1;
			temp_result = temp_result >>> 1;

			result = temp_result[15:0];
			valid_out <= 1;
		end
	end
end


cordic_circular CORDIC_CIRC(
.clock (clock),
.reset(reset),
.valid_in(valid_in_circ),
.x_in(x),
.y_in(y),
.z_in(z),
.x_out(result_x),
.y_out(result_y),
.z_out(result_z),
.valid_out(valid_out_circ)
);


endmodule

