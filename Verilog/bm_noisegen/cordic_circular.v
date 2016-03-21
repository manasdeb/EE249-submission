`include "bm_constants.vh"

module cordic_circular (
clock, 
reset,
valid_in,
x_in,
y_in,
z_in,
x_out,
y_out,
z_out,
valid_out
);

localparam CORDIC_PREC = 48;
localparam CORDIC_PIPELINE_DEPTH = 16;
localparam CORDIC_BITWIDTH = 56;

input clock, reset, valid_in;
input signed [CORDIC_BITWIDTH-1:0] x_in, y_in, z_in;
output signed [CORDIC_BITWIDTH-1:0] x_out, y_out, z_out;
output valid_out;

reg signed [CORDIC_BITWIDTH-1:0] x_out, y_out, z_out;
reg valid_out;

reg signed [CORDIC_BITWIDTH-1:0] x_in_latch, y_in_latch, z_in_latch;
reg[5:0] pipe_element_count;

reg signed [CORDIC_BITWIDTH-1:0] x [0:CORDIC_PIPELINE_DEPTH-1];
reg signed [CORDIC_BITWIDTH-1:0] y [0:CORDIC_PIPELINE_DEPTH-1];
reg signed [CORDIC_BITWIDTH-1:0] z [0:CORDIC_PIPELINE_DEPTH-1];

reg signed [CORDIC_BITWIDTH-1:0] x_temp [0:CORDIC_PIPELINE_DEPTH-1];
reg signed [CORDIC_BITWIDTH-1:0] y_temp [0:CORDIC_PIPELINE_DEPTH-1];
reg signed [CORDIC_BITWIDTH-1:0] z_temp [0:CORDIC_PIPELINE_DEPTH-1];

reg [CORDIC_PREC-1:0] atan_table [0:CORDIC_PREC-1];


initial
begin
	atan_table[0]  = 48'd221069929750889;
	atan_table[1]  = 48'd130505199945453;
	atan_table[2]  = 48'd68955363498242;
	atan_table[3]  = 48'd35002819193903;
	atan_table[4]  = 48'd17569333089919;
	atan_table[5]  = 48'd8793231387230;
	atan_table[6]  = 48'd4397688649582;
	atan_table[7]  = 48'd2198978517948;
	atan_table[8]  = 48'd1099506035422;
	atan_table[9]  = 48'd549755114839;
	atan_table[10] = 48'd274877819563;
	atan_table[11] = 48'd137438942549;
	atan_table[12] = 48'd68719475371;
	atan_table[13] = 48'd34359738197;
	atan_table[14] = 48'd17179869163;
	atan_table[15] = 48'd8589934589;
	atan_table[16] = 48'd4294967296;
	atan_table[17] = 48'd2147483648;
	atan_table[18] = 48'd1073741824;
	atan_table[19] = 48'd536870912;
	atan_table[20] = 48'd268435456;
	atan_table[21] = 48'd134217728;
	atan_table[22] = 48'd67108864;
	atan_table[23] = 48'd33554432;
	atan_table[24] = 48'd16777216;
	atan_table[25] = 48'd8388608;
	atan_table[26] = 48'd4194304;
	atan_table[27] = 48'd2097152;
	atan_table[28] = 48'd1048576;
	atan_table[29] = 48'd524288;
	atan_table[30] = 48'd262144;
	atan_table[31] = 48'd131072;
	atan_table[32] = 48'd65536;
	atan_table[33] = 48'd32768;
	atan_table[34] = 48'd16384;
	atan_table[35] = 48'd8192;
	atan_table[36] = 48'd4096;
	atan_table[37] = 48'd2048;
	atan_table[38] = 48'd1024;
	atan_table[39] = 48'd512;
	atan_table[40] = 48'd256;
	atan_table[41] = 48'd128;
	atan_table[42] = 48'd64;
	atan_table[43] = 48'd32;
	atan_table[44] = 48'd16;
	atan_table[45] = 48'd8;
	atan_table[46] = 48'd4;
	atan_table[47] = 48'd2;
end

always @ (posedge reset) begin
	valid_out = 0;
	pipe_element_count = 0;
	x_in_latch = 0;
	y_in_latch = 0;
	z_in_latch = 0;
	x_out = 0;
	y_out = 0;
	z_out = 0;
end

// Pipeline input stage
always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			x_in_latch = x_in;
			y_in_latch = y_in;
			z_in_latch = z_in;
		end
	end
end


// 1st cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 1st iteration
			if (z[0] >= 0) begin
				x_temp[0] = fixedpt_sub(x[0], y[0]);
				y_temp[0] = fixedpt_add(y[0], x[0]);
				z_temp[0] = fixedpt_sub(z[0], atan_table[0]);
			end
			else begin
				x_temp[0] = fixedpt_add(x[0], y[0]);
				y_temp[0] = fixedpt_sub(y[0], x[0]);
				z_temp[0] = fixedpt_add(z[0], atan_table[0]);
			end

			// 2nd iteration
			if (z_temp[0] >= 0) begin
				x[0] = fixedpt_sub(x_temp[0], (y_temp[0] >>> 1));
				y[0] = fixedpt_add(y_temp[0], (x_temp[0] >>> 1));
				z[0] = fixedpt_sub(z_temp[0], atan_table[1]);
			end
			else begin
				x[0] = fixedpt_add(x_temp[0], (y_temp[0] >>> 1));
				y[0] = fixedpt_sub(y_temp[0], (x_temp[0] >>> 1));
				z[0] = fixedpt_add(z_temp[0], atan_table[1]);
			end

			// 3rd iteration
			if (z[0] >= 0) begin
				x_temp[0] = fixedpt_sub(x[0], (y[0] >>> 2));
				y_temp[0] = fixedpt_add(y[0], (x[0] >>> 2));
				z_temp[0] = fixedpt_sub(z[0], atan_table[2]);
			end
			else begin
				x_temp[0] = fixedpt_add(x[0], (y[0] >>> 2));
				y_temp[0] = fixedpt_sub(y[0], (x[0] >>> 2));
				z_temp[0] = fixedpt_add(z[0], atan_table[2]);
			end

			x[0] = x_temp[0];
			y[0] = y_temp[0];
			z[0] = z_temp[0];
		end
	end
end


// 2nd cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 4th iteration
			if (z[1] >= 0) begin
				x_temp[1] = fixedpt_sub(x[1], (y[1] >>> 3));
				y_temp[1] = fixedpt_add(y[1], (x[1] >>> 3));
				z_temp[1] = fixedpt_sub(z[1], atan_table[3]);
			end
			else begin
				x_temp[1] = fixedpt_add(x[1], (y[1] >> 3));
				y_temp[1] = fixedpt_sub(y[1], (x[1] >> 3));
				z_temp[1] = fixedpt_add(z[1], atan_table[3]);
			end

			// 5th iteration
			if (z_temp[1] >= 0) begin
				x[1] = fixedpt_sub(x_temp[1], (y_temp[1] >>> 4));
				y[1] = fixedpt_add(y_temp[1], (x_temp[1] >>> 4));
				z[1] = fixedpt_sub(z_temp[1], atan_table[4]);
			end
			else begin
				x[1] = fixedpt_add(x_temp[1], (y_temp[1] >>> 4));
				y[1] = fixedpt_sub(y_temp[1], (x_temp[1] >>> 4));
				z[1] = fixedpt_add(z_temp[1], atan_table[4]);
			end

			// 6th iteration
			if (z[1] >= 0) begin
				x_temp[1] = fixedpt_sub(x[1], (y[1] >>> 5));
				y_temp[1] = fixedpt_add(y[1], (x[1] >>> 5));
				z_temp[1] = fixedpt_sub(z[1], atan_table[5]);
			end
			else begin
				x_temp[1] = fixedpt_add(x[1], (y[1] >>> 5));
				y_temp[1] = fixedpt_sub(y[1], (x[1] >>> 5));
				z_temp[1] = fixedpt_add(z[1], atan_table[5]);
			end

			x[1] = x_temp[1];
			y[1] = y_temp[1];
			z[1] = z_temp[1];
		end
	end
end


// 3rd pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 7th iteration
			if (z[2] >= 0) begin
				x_temp[2] = fixedpt_sub(x[2], (y[2] >>> 6));
				y_temp[2] = fixedpt_add(y[2], (x[2] >>> 6));
				z_temp[2] = fixedpt_sub(z[2], atan_table[6]);
			end
			else begin
				x_temp[2] = fixedpt_add(x[2], (y[2] >> 6));
				y_temp[2] = fixedpt_sub(y[2], (x[2] >> 6));
				z_temp[2] = fixedpt_add(z[2], atan_table[6]);
			end

			// 8th iteration
			if (z_temp[2] >= 0) begin
				x[2] = fixedpt_sub(x_temp[2], (y_temp[2] >>> 7));
				y[2] = fixedpt_add(y_temp[2], (x_temp[2] >>> 7));
				z[2] = fixedpt_sub(z_temp[2], atan_table[7]);
			end
			else begin
				x[2] = fixedpt_add(x_temp[2], (y_temp[2] >>> 7));
				y[2] = fixedpt_sub(y_temp[2], (x_temp[2] >>> 7));
				z[2] = fixedpt_add(z_temp[2], atan_table[7]);
			end

			// 9th iteration
			if (z[2] >= 0) begin
				x_temp[2] = fixedpt_sub(x[2], (y[2] >>> 8));
				y_temp[2] = fixedpt_add(y[2], (x[2] >>> 8));
				z_temp[2] = fixedpt_sub(z[2], atan_table[8]);
			end
			else begin
				x_temp[2] = fixedpt_add(x[2], (y[2] >>> 8));
				y_temp[2] = fixedpt_sub(y[2], (x[2] >>> 8));
				z_temp[2] = fixedpt_add(z[2], atan_table[8]);
			end

			x[2] = x_temp[2];
			y[2] = y_temp[2];
			z[2] = z_temp[2];
		end
	end
end


// 4th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 10th iteration
			if (z[3] >= 0) begin
				x_temp[3] = fixedpt_sub(x[3], (y[3] >>> 9));
				y_temp[3] = fixedpt_add(y[3], (x[3] >>> 9));
				z_temp[3] = fixedpt_sub(z[3], atan_table[9]);
			end
			else begin
				x_temp[3] = fixedpt_add(x[3], (y[3] >> 9));
				y_temp[3] = fixedpt_sub(y[3], (x[3] >> 9));
				z_temp[3] = fixedpt_add(z[3], atan_table[9]);
			end

			// 11th iteration
			if (z_temp[3] >= 0) begin
				x[3] = fixedpt_sub(x_temp[3], (y_temp[3] >>> 10));
				y[3] = fixedpt_add(y_temp[3], (x_temp[3] >>> 10));
				z[3] = fixedpt_sub(z_temp[3], atan_table[10]);
			end
			else begin
				x[3] = fixedpt_add(x_temp[3], (y_temp[3] >>> 10));
				y[3] = fixedpt_sub(y_temp[3], (x_temp[3] >>> 10));
				z[3] = fixedpt_add(z_temp[3], atan_table[10]);
			end

			// 12th iteration
			if (z[3] >= 0) begin
				x_temp[3] = fixedpt_sub(x[3], (y[3] >>> 11));
				y_temp[3] = fixedpt_add(y[3], (x[3] >>> 11));
				z_temp[3] = fixedpt_sub(z[3], atan_table[11]);
			end
			else begin
				x_temp[3] = fixedpt_add(x[3], (y[3] >>> 11));
				y_temp[3] = fixedpt_sub(y[3], (x[3] >>> 11));
				z_temp[3] = fixedpt_add(z[3], atan_table[11]);
			end

			x[3] = x_temp[3];
			y[3] = y_temp[3];
			z[3] = z_temp[3];
		end
	end
end


// 5th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 13th iteration
			if (z[4] >= 0) begin
				x_temp[4] = fixedpt_sub(x[4], (y[4] >>> 12));
				y_temp[4] = fixedpt_add(y[4], (x[4] >>> 12));
				z_temp[4] = fixedpt_sub(z[4], atan_table[12]);
			end
			else begin
				x_temp[4] = fixedpt_add(x[4], (y[4] >> 12));
				y_temp[4] = fixedpt_sub(y[4], (x[4] >> 12));
				z_temp[4] = fixedpt_add(z[4], atan_table[12]);
			end

			// 14th iteration
			if (z_temp[4] >= 0) begin
				x[4] = fixedpt_sub(x_temp[4], (y_temp[4] >>> 13));
				y[4] = fixedpt_add(y_temp[4], (x_temp[4] >>> 13));
				z[4] = fixedpt_sub(z_temp[4], atan_table[13]);
			end
			else begin
				x[4] = fixedpt_add(x_temp[4], (y_temp[4] >>> 13));
				y[4] = fixedpt_sub(y_temp[4], (x_temp[4] >>> 13));
				z[4] = fixedpt_add(z_temp[4], atan_table[13]);
			end

			// 15th iteration
			if (z[4] >= 0) begin
				x_temp[4] = fixedpt_sub(x[4], (y[4] >>> 14));
				y_temp[4] = fixedpt_add(y[4], (x[4] >>> 14));
				z_temp[4] = fixedpt_sub(z[4], atan_table[14]);
			end
			else begin
				x_temp[4] = fixedpt_add(x[4], (y[4] >>> 14));
				y_temp[4] = fixedpt_sub(y[4], (x[4] >>> 14));
				z_temp[4] = fixedpt_add(z[4], atan_table[14]);
			end

			x[4] = x_temp[4];
			y[4] = y_temp[4];
			z[4] = z_temp[4];
		end
	end
end


// 6th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 16th iteration
			if (z[5] >= 0) begin
				x_temp[5] = fixedpt_sub(x[5], (y[5] >>> 15));
				y_temp[5] = fixedpt_add(y[5], (x[5] >>> 15));
				z_temp[5] = fixedpt_sub(z[5], atan_table[15]);
			end
			else begin
				x_temp[5] = fixedpt_add(x[5], (y[5] >> 15));
				y_temp[5] = fixedpt_sub(y[5], (x[5] >> 15));
				z_temp[5] = fixedpt_add(z[5], atan_table[15]);
			end

			// 17th iteration
			if (z_temp[5] >= 0) begin
				x[5] = fixedpt_sub(x_temp[5], (y_temp[5] >>> 16));
				y[5] = fixedpt_add(y_temp[5], (x_temp[5] >>> 16));
				z[5] = fixedpt_sub(z_temp[5], atan_table[16]);
			end
			else begin
				x[5] = fixedpt_add(x_temp[5], (y_temp[5] >>> 16));
				y[5] = fixedpt_sub(y_temp[5], (x_temp[5] >>> 16));
				z[5] = fixedpt_add(z_temp[5], atan_table[16]);
			end

			// 18th iteration
			if (z[5] >= 0) begin
				x_temp[5] = fixedpt_sub(x[5], (y[5] >>> 17));
				y_temp[5] = fixedpt_add(y[5], (x[5] >>> 17));
				z_temp[5] = fixedpt_sub(z[5], atan_table[17]);
			end
			else begin
				x_temp[5] = fixedpt_add(x[5], (y[5] >>> 17));
				y_temp[5] = fixedpt_sub(y[5], (x[5] >>> 17));
				z_temp[5] = fixedpt_add(z[5], atan_table[17]);
			end

			x[5] = x_temp[5];
			y[5] = y_temp[5];
			z[5] = z_temp[5];
		end
	end
end



// 7th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 19th iteration
			if (z[6] >= 0) begin
				x_temp[6] = fixedpt_sub(x[6], (y[6] >>> 18));
				y_temp[6] = fixedpt_add(y[6], (x[6] >>> 18));
				z_temp[6] = fixedpt_sub(z[6], atan_table[18]);
			end
			else begin
				x_temp[6] = fixedpt_add(x[6], (y[6] >> 18));
				y_temp[6] = fixedpt_sub(y[6], (x[6] >> 18));
				z_temp[6] = fixedpt_add(z[6], atan_table[18]);
			end

			// 20th iteration
			if (z_temp[6] >= 0) begin
				x[6] = fixedpt_sub(x_temp[6], (y_temp[6] >>> 19));
				y[6] = fixedpt_add(y_temp[6], (x_temp[6] >>> 19));
				z[6] = fixedpt_sub(z_temp[6], atan_table[19]);
			end
			else begin
				x[6] = fixedpt_add(x_temp[6], (y_temp[6] >>> 19));
				y[6] = fixedpt_sub(y_temp[6], (x_temp[6] >>> 19));
				z[6] = fixedpt_add(z_temp[6], atan_table[19]);
			end

			// 21st iteration
			if (z[6] >= 0) begin
				x_temp[6] = fixedpt_sub(x[6], (y[6] >>> 20));
				y_temp[6] = fixedpt_add(y[6], (x[6] >>> 20));
				z_temp[6] = fixedpt_sub(z[6], atan_table[20]);
			end
			else begin
				x_temp[6] = fixedpt_add(x[6], (y[6] >>> 20));
				y_temp[6] = fixedpt_sub(y[6], (x[6] >>> 20));
				z_temp[6] = fixedpt_add(z[6], atan_table[20]);
			end

			x[6] = x_temp[6];
			y[6] = y_temp[6];
			z[6] = z_temp[6];
		end
	end
end


// 8th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 22nd iteration
			if (z[7] >= 0) begin
				x_temp[7] = fixedpt_sub(x[7], (y[7] >>> 21));
				y_temp[7] = fixedpt_add(y[7], (x[7] >>> 21));
				z_temp[7] = fixedpt_sub(z[7], atan_table[21]);
			end
			else begin
				x_temp[7] = fixedpt_add(x[7], (y[7] >> 21));
				y_temp[7] = fixedpt_sub(y[7], (x[7] >> 21));
				z_temp[7] = fixedpt_add(z[7], atan_table[21]);
			end

			// 23rd iteration
			if (z_temp[7] >= 0) begin
				x[7] = fixedpt_sub(x_temp[7], (y_temp[7] >>> 22));
				y[7] = fixedpt_add(y_temp[7], (x_temp[7] >>> 22));
				z[7] = fixedpt_sub(z_temp[7], atan_table[22]);
			end
			else begin
				x[7] = fixedpt_add(x_temp[7], (y_temp[7] >>> 22));
				y[7] = fixedpt_sub(y_temp[7], (x_temp[7] >>> 22));
				z[7] = fixedpt_add(z_temp[7], atan_table[22]);
			end

			// 24th iteration
			if (z[7] >= 0) begin
				x_temp[7] = fixedpt_sub(x[7], (y[7] >>> 23));
				y_temp[7] = fixedpt_add(y[7], (x[7] >>> 23));
				z_temp[7] = fixedpt_sub(z[7], atan_table[23]);
			end
			else begin
				x_temp[7] = fixedpt_add(x[7], (y[7] >>> 23));
				y_temp[7] = fixedpt_sub(y[7], (x[7] >>> 23));
				z_temp[7] = fixedpt_add(z[7], atan_table[23]);
			end

			x[7] = x_temp[7];
			y[7] = y_temp[7];
			z[7] = z_temp[7];
		end
	end
end


// 9th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 25th iteration
			if (z[8] >= 0) begin
				x_temp[8] = fixedpt_sub(x[8], (y[8] >>> 24));
				y_temp[8] = fixedpt_add(y[8], (x[8] >>> 24));
				z_temp[8] = fixedpt_sub(z[8], atan_table[24]);
			end
			else begin
				x_temp[8] = fixedpt_add(x[8], (y[8] >> 24));
				y_temp[8] = fixedpt_sub(y[8], (x[8] >> 24));
				z_temp[8] = fixedpt_add(z[8], atan_table[24]);
			end

			// 26th iteration
			if (z_temp[8] >= 0) begin
				x[8] = fixedpt_sub(x_temp[8], (y_temp[8] >>> 25));
				y[8] = fixedpt_add(y_temp[8], (x_temp[8] >>> 25));
				z[8] = fixedpt_sub(z_temp[8], atan_table[25]);
			end
			else begin
				x[8] = fixedpt_add(x_temp[8], (y_temp[8] >>> 25));
				y[8] = fixedpt_sub(y_temp[8], (x_temp[8] >>> 25));
				z[8] = fixedpt_add(z_temp[8], atan_table[25]);
			end

			// 27th iteration
			if (z[8] >= 0) begin
				x_temp[8] = fixedpt_sub(x[8], (y[8] >>> 26));
				y_temp[8] = fixedpt_add(y[8], (x[8] >>> 26));
				z_temp[8] = fixedpt_sub(z[8], atan_table[26]);
			end
			else begin
				x_temp[8] = fixedpt_add(x[8], (y[8] >>> 26));
				y_temp[8] = fixedpt_sub(y[8], (x[8] >>> 26));
				z_temp[8] = fixedpt_add(z[8], atan_table[26]);
			end

			x[8] = x_temp[8];
			y[8] = y_temp[8];
			z[8] = z_temp[8];
		end
	end
end


// 10th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 28th iteration
			if (z[9] >= 0) begin
				x_temp[9] = fixedpt_sub(x[9], (y[9] >>> 27));
				y_temp[9] = fixedpt_add(y[9], (x[9] >>> 27));
				z_temp[9] = fixedpt_sub(z[9], atan_table[27]);
			end
			else begin
				x_temp[9] = fixedpt_add(x[9], (y[9] >> 27));
				y_temp[9] = fixedpt_sub(y[9], (x[9] >> 27));
				z_temp[9] = fixedpt_add(z[9], atan_table[27]);
			end

			// 29th iteration
			if (z_temp[9] >= 0) begin
				x[9] = fixedpt_sub(x_temp[9], (y_temp[9] >>> 28));
				y[9] = fixedpt_add(y_temp[9], (x_temp[9] >>> 28));
				z[9] = fixedpt_sub(z_temp[9], atan_table[28]);
			end
			else begin
				x[9] = fixedpt_add(x_temp[9], (y_temp[9] >>> 28));
				y[9] = fixedpt_sub(y_temp[9], (x_temp[9] >>> 28));
				z[9] = fixedpt_add(z_temp[9], atan_table[28]);
			end

			// 30th iteration
			if (z[9] >= 0) begin
				x_temp[9] = fixedpt_sub(x[9], (y[9] >>> 29));
				y_temp[9] = fixedpt_add(y[9], (x[9] >>> 29));
				z_temp[9] = fixedpt_sub(z[9], atan_table[29]);
			end
			else begin
				x_temp[9] = fixedpt_add(x[9], (y[9] >>> 29));
				y_temp[9] = fixedpt_sub(y[9], (x[9] >>> 29));
				z_temp[9] = fixedpt_add(z[9], atan_table[29]);
			end

			x[9] = x_temp[9];
			y[9] = y_temp[9];
			z[9] = z_temp[9];
		end
	end
end


// 11th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 31st iteration
			if (z[10] >= 0) begin
				x_temp[10] = fixedpt_sub(x[10], (y[10] >>> 30));
				y_temp[10] = fixedpt_add(y[10], (x[10] >>> 30));
				z_temp[10] = fixedpt_sub(z[10], atan_table[30]);
			end
			else begin
				x_temp[10] = fixedpt_add(x[10], (y[10] >> 30));
				y_temp[10] = fixedpt_sub(y[10], (x[10] >> 30));
				z_temp[10] = fixedpt_add(z[10], atan_table[30]);
			end

			// 32nd iteration
			if (z_temp[10] >= 0) begin
				x[10] = fixedpt_sub(x_temp[10], (y_temp[10] >>> 31));
				y[10] = fixedpt_add(y_temp[10], (x_temp[10] >>> 31));
				z[10] = fixedpt_sub(z_temp[10], atan_table[31]);
			end
			else begin
				x[10] = fixedpt_add(x_temp[10], (y_temp[10] >>> 31));
				y[10] = fixedpt_sub(y_temp[10], (x_temp[10] >>> 31));
				z[10] = fixedpt_add(z_temp[10], atan_table[31]);
			end

			// 33rd iteration
			if (z[10] >= 0) begin
				x_temp[10] = fixedpt_sub(x[10], (y[10] >>> 32));
				y_temp[10] = fixedpt_add(y[10], (x[10] >>> 32));
				z_temp[10] = fixedpt_sub(z[10], atan_table[32]);
			end
			else begin
				x_temp[10] = fixedpt_add(x[10], (y[10] >>> 32));
				y_temp[10] = fixedpt_sub(y[10], (x[10] >>> 32));
				z_temp[10] = fixedpt_add(z[10], atan_table[32]);
			end

			x[10] = x_temp[10];
			y[10] = y_temp[10];
			z[10] = z_temp[10];
		end
	end
end


// 12th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 34th iteration
			if (z[11] >= 0) begin
				x_temp[11] = fixedpt_sub(x[11], (y[11] >>> 33));
				y_temp[11] = fixedpt_add(y[11], (x[11] >>> 33));
				z_temp[11] = fixedpt_sub(z[11], atan_table[33]);
			end
			else begin
				x_temp[11] = fixedpt_add(x[11], (y[11] >> 33));
				y_temp[11] = fixedpt_sub(y[11], (x[11] >> 33));
				z_temp[11] = fixedpt_add(z[11], atan_table[33]);
			end

			// 35th iteration
			if (z_temp[11] >= 0) begin
				x[11] = fixedpt_sub(x_temp[11], (y_temp[11] >>> 34));
				y[11] = fixedpt_add(y_temp[11], (x_temp[11] >>> 34));
				z[11] = fixedpt_sub(z_temp[11], atan_table[34]);
			end
			else begin
				x[11] = fixedpt_add(x_temp[11], (y_temp[11] >>> 34));
				y[11] = fixedpt_sub(y_temp[11], (x_temp[11] >>> 34));
				z[11] = fixedpt_add(z_temp[11], atan_table[34]);
			end

			// 36th iteration
			if (z[11] >= 0) begin
				x_temp[11] = fixedpt_sub(x[11], (y[11] >>> 35));
				y_temp[11] = fixedpt_add(y[11], (x[11] >>> 35));
				z_temp[11] = fixedpt_sub(z[11], atan_table[35]);
			end
			else begin
				x_temp[11] = fixedpt_add(x[11], (y[11] >>> 35));
				y_temp[11] = fixedpt_sub(y[11], (x[11] >>> 35));
				z_temp[11] = fixedpt_add(z[11], atan_table[35]);
			end

			x[11] = x_temp[11];
			y[11] = y_temp[11];
			z[11] = z_temp[11];
		end
	end
end


// 13th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 37th iteration
			if (z[12] >= 0) begin
				x_temp[12] = fixedpt_sub(x[12], (y[12] >>> 36));
				y_temp[12] = fixedpt_add(y[12], (x[12] >>> 36));
				z_temp[12] = fixedpt_sub(z[12], atan_table[36]);
			end
			else begin
				x_temp[12] = fixedpt_add(x[12], (y[12] >> 36));
				y_temp[12] = fixedpt_sub(y[12], (x[12] >> 36));
				z_temp[12] = fixedpt_add(z[12], atan_table[36]);
			end

			// 38th iteration
			if (z_temp[12] >= 0) begin
				x[12] = fixedpt_sub(x_temp[12], (y_temp[12] >>> 37));
				y[12] = fixedpt_add(y_temp[12], (x_temp[12] >>> 37));
				z[12] = fixedpt_sub(z_temp[12], atan_table[37]);
			end
			else begin
				x[12] = fixedpt_add(x_temp[12], (y_temp[12] >>> 37));
				y[12] = fixedpt_sub(y_temp[12], (x_temp[12] >>> 37));
				z[12] = fixedpt_add(z_temp[12], atan_table[37]);
			end

			// 39th iteration
			if (z[12] >= 0) begin
				x_temp[12] = fixedpt_sub(x[12], (y[12] >>> 38));
				y_temp[12] = fixedpt_add(y[12], (x[12] >>> 38));
				z_temp[12] = fixedpt_sub(z[12], atan_table[38]);
			end
			else begin
				x_temp[12] = fixedpt_add(x[12], (y[12] >>> 38));
				y_temp[12] = fixedpt_sub(y[12], (x[12] >>> 38));
				z_temp[12] = fixedpt_add(z[12], atan_table[38]);
			end

			x[12] = x_temp[12];
			y[12] = y_temp[12];
			z[12] = z_temp[12];
		end
	end
end


// 14th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 40th iteration
			if (z[13] >= 0) begin
				x_temp[13] = fixedpt_sub(x[13], (y[13] >>> 39));
				y_temp[13] = fixedpt_add(y[13], (x[13] >>> 39));
				z_temp[13] = fixedpt_sub(z[13], atan_table[39]);
			end
			else begin
				x_temp[13] = fixedpt_add(x[13], (y[13] >> 39));
				y_temp[13] = fixedpt_sub(y[13], (x[13] >> 39));
				z_temp[13] = fixedpt_add(z[13], atan_table[39]);
			end

			// 41st iteration
			if (z_temp[13] >= 0) begin
				x[13] = fixedpt_sub(x_temp[13], (y_temp[13] >>> 40));
				y[13] = fixedpt_add(y_temp[13], (x_temp[13] >>> 40));
				z[13] = fixedpt_sub(z_temp[13], atan_table[40]);
			end
			else begin
				x[13] = fixedpt_add(x_temp[13], (y_temp[13] >>> 40));
				y[13] = fixedpt_sub(y_temp[13], (x_temp[13] >>> 40));
				z[13] = fixedpt_add(z_temp[13], atan_table[40]);
			end

			// 42nd iteration
			if (z[13] >= 0) begin
				x_temp[13] = fixedpt_sub(x[13], (y[13] >>> 41));
				y_temp[13] = fixedpt_add(y[13], (x[13] >>> 41));
				z_temp[13] = fixedpt_sub(z[13], atan_table[41]);
			end
			else begin
				x_temp[13] = fixedpt_add(x[13], (y[13] >>> 41));
				y_temp[13] = fixedpt_sub(y[13], (x[13] >>> 41));
				z_temp[13] = fixedpt_add(z[13], atan_table[41]);
			end

			x[13] = x_temp[13];
			y[13] = y_temp[13];
			z[13] = z_temp[13];
		end
	end
end


// 15th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 43rd iteration
			if (z[14] >= 0) begin
				x_temp[14] = fixedpt_sub(x[14], (y[14] >>> 42));
				y_temp[14] = fixedpt_add(y[14], (x[14] >>> 42));
				z_temp[14] = fixedpt_sub(z[14], atan_table[42]);
			end
			else begin
				x_temp[14] = fixedpt_add(x[14], (y[14] >> 42));
				y_temp[14] = fixedpt_sub(y[14], (x[14] >> 42));
				z_temp[14] = fixedpt_add(z[14], atan_table[42]);
			end

			// 44th iteration
			if (z_temp[14] >= 0) begin
				x[14] = fixedpt_sub(x_temp[14], (y_temp[14] >>> 43));
				y[14] = fixedpt_add(y_temp[14], (x_temp[14] >>> 43));
				z[14] = fixedpt_sub(z_temp[14], atan_table[43]);
			end
			else begin
				x[14] = fixedpt_add(x_temp[14], (y_temp[14] >>> 43));
				y[14] = fixedpt_sub(y_temp[14], (x_temp[14] >>> 43));
				z[14] = fixedpt_add(z_temp[14], atan_table[43]);
			end

			// 45th iteration
			if (z[14] >= 0) begin
				x_temp[14] = fixedpt_sub(x[14], (y[14] >>> 44));
				y_temp[14] = fixedpt_add(y[14], (x[14] >>> 44));
				z_temp[14] = fixedpt_sub(z[14], atan_table[44]);
			end
			else begin
				x_temp[14] = fixedpt_add(x[14], (y[14] >>> 44));
				y_temp[14] = fixedpt_sub(y[14], (x[14] >>> 44));
				z_temp[14] = fixedpt_add(z[14], atan_table[44]);
			end

			x[14] = x_temp[14];
			y[14] = y_temp[14];
			z[14] = z_temp[14];
		end
	end
end


// 16th pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 46th iteration
			if (z[15] >= 0) begin
				x_temp[15] = fixedpt_sub(x[15], (y[15] >>> 45));
				y_temp[15] = fixedpt_add(y[15], (x[15] >>> 45));
				z_temp[15] = fixedpt_sub(z[15], atan_table[45]);
			end
			else begin
				x_temp[15] = fixedpt_add(x[15], (y[15] >> 45));
				y_temp[15] = fixedpt_sub(y[15], (x[15] >> 45));
				z_temp[15] = fixedpt_add(z[15], atan_table[45]);
			end

			// 47th iteration
			if (z_temp[15] >= 0) begin
				x[15] = fixedpt_sub(x_temp[15], (y_temp[15] >>> 46));
				y[15] = fixedpt_add(y_temp[15], (x_temp[15] >>> 46));
				z[15] = fixedpt_sub(z_temp[15], atan_table[46]);
			end
			else begin
				x[15] = fixedpt_add(x_temp[15], (y_temp[15] >>> 46));
				y[15] = fixedpt_sub(y_temp[15], (x_temp[15] >>> 46));
				z[15] = fixedpt_add(z_temp[15], atan_table[46]);
			end

			// 48th iteration
			if (z[15] >= 0) begin
				x_temp[15] = fixedpt_sub(x[15], (y[15] >>> 47));
				y_temp[15] = fixedpt_add(y[15], (x[15] >>> 47));
				z_temp[15] = fixedpt_sub(z[15], atan_table[47]);
			end
			else begin
				x_temp[15] = fixedpt_add(x[15], (y[15] >>> 47));
				y_temp[15] = fixedpt_sub(y[15], (x[15] >>> 47));
				z_temp[15] = fixedpt_add(z[15], atan_table[47]);
			end

			x[15] = x_temp[15];
			y[15] = y_temp[15];
			z[15] = z_temp[15];
		end
	end
end


// Move the pipeline forward
always @ (posedge clock) begin
	if (!reset) begin
		if (valid_in) begin
			x[0]  <= x_in_latch;
			x[1]  <= x[0];
			x[2]  <= x[1];
			x[3]  <= x[2];
			x[4]  <= x[3];
			x[5]  <= x[4];
			x[6]  <= x[5];
			x[7]  <= x[6];
			x[8]  <= x[7];
			x[9]  <= x[8];
			x[10] <= x[9];
			x[11] <= x[10];
			x[12] <= x[11];
			x[13] <= x[12];
			x[14] <= x[13];
			x[15] <= x[14];
		
			y[0]  <= y_in_latch;
			y[1]  <= y[0];
			y[2]  <= y[1];
			y[3]  <= y[2];
			y[4]  <= y[3];
			y[5]  <= y[4];
			y[6]  <= y[5];
			y[7]  <= y[6];
			y[8]  <= y[7];
			y[9]  <= y[8];
			y[10] <= y[9];
			y[11] <= y[10];
			y[12] <= y[11];
			y[13] <= y[12];
			y[14] <= y[13];
			y[15] <= y[14];
		
			z[0]  <= z_in_latch;
			z[1]  <= z[0];
			z[2]  <= z[1];
			z[3]  <= z[2];
			z[4]  <= z[3];
			z[5]  <= z[4];
			z[6]  <= z[5];
			z[7]  <= z[6];
			z[8]  <= z[7];
			z[9]  <= z[8];
			z[10] <= z[9];
			z[11] <= z[10];
			z[12] <= z[11];
			z[13] <= z[12];
			z[14] <= z[13];
			z[15] <= z[14];
		
			x_out <= x[15];
			y_out <= y[15];
			z_out <= z[15];
		
			if (pipe_element_count < CORDIC_PIPELINE_DEPTH)
				pipe_element_count <= pipe_element_count + 1;

			if (pipe_element_count > 0) begin
				if (pipe_element_count == CORDIC_PIPELINE_DEPTH) begin
					valid_out <= 1;
				end
			end
			else
				valid_out <= 0;
		end
		else begin
			if (pipe_element_count > 0)
				pipe_element_count <= pipe_element_count - 1;
		end
	end
end


`include "fixedpt_funcs.vh"

endmodule



