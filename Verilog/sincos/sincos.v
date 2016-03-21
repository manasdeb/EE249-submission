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



module sincos (
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
input signed [IO_BITWIDTH-1:0] arg_in;
output signed [IO_BITWIDTH-1:0] result;
output valid_out;

reg signed [IO_BITWIDTH-1:0] cordic_arg;
reg signed [IO_BITWIDTH-1:0] result;
reg valid_out;

reg valid_in_circ;
wire valid_out_circ;
reg signbit_latch_in, signbit_latch_out;
reg signbit[0:CORDIC_PIPELINE_DEPTH];
reg [4:0] half_pi_angles_latch_in, half_pi_angles_latch_out;
reg [4:0] half_pi_angles[0:CORDIC_PIPELINE_DEPTH];

reg signed [IO_BITWIDTH-1:0] x, y, z;
wire signed [IO_BITWIDTH-1:0] result_x, result_y, result_z;

always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			if (arg_in < 0) begin
				signbit_latch_in = 1;

				if (op_type == `OPTYPE_COS)
					cordic_arg = fixedpt_add(-arg_in, `HALFPI_S7_48);
				else
					cordic_arg = -arg_in;
			end
			else begin
				signbit_latch_in = 0;

				if (op_type == `OPTYPE_COS)
					cordic_arg = fixedpt_add(arg_in, `HALFPI_S7_48);
				else
					cordic_arg = arg_in;
			end

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
	
			signbit[0] <= signbit_latch_in;
			signbit[1] <= signbit[0];
			signbit[2] <= signbit[1];
			signbit[3] <= signbit[2];
			signbit[4] <= signbit[3];
			signbit[5] <= signbit[4];
			signbit[6] <= signbit[5];
			signbit[7] <= signbit[6];
			signbit[8] <= signbit[7];
			signbit[9] <= signbit[8];
			signbit[10] <= signbit[9];
			signbit[11] <= signbit[10];
			signbit[12] <= signbit[11];
			signbit[13] <= signbit[12];
			signbit[14] <= signbit[13];
			signbit[15] <= signbit[14];
			signbit[16] <= signbit[15];
			signbit_latch_out <= signbit[16];
		end
	end
end

always @ (posedge clock) begin
	if (!reset) begin
		if (valid_out_circ) begin
			case (half_pi_angles_latch_out)
				2'd0:
					begin
						result <= signbit_latch_out ? -result_y : result_y;
					end

				2'd1:
					begin
						result <= signbit_latch_out ? -result_x : result_x;
					end

				2'd2:
					begin
						result <= signbit_latch_out ? result_y : -result_y;
					end

				2'd3:
					begin
						result <= signbit_latch_out ? result_x : -result_x;
					end
			endcase

			valid_out <= 1;
		end
	end
end

`include "fixedpt_funcs.vh"

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

