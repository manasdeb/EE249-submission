`include "bm_constants.vh"

module cordic_hyperb (
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


reg [CORDIC_PREC-1:0] atanh_table [0:CORDIC_PREC-1];

initial
begin
atanh_table[0]  = 48'd154615934183448;
atanh_table[1]  = 48'd71892315276369;
atanh_table[2]  = 48'd35369361423710;
atanh_table[3]  = 48'd17615146374006;
atanh_table[4]  = 48'd8798958012631;
atanh_table[5]  = 48'd4398404477483;
atanh_table[6]  = 48'd2199067996433;
atanh_table[7]  = 48'd1099517220233;
atanh_table[8]  = 48'd549756512940;
atanh_table[9]  = 48'd274877994325;
atanh_table[10]  = 48'd137438964395;
atanh_table[11]  = 48'd68719478101;
atanh_table[12]  = 48'd34359738539;
atanh_table[13]  = 48'd17179869205;
atanh_table[14]  = 48'd8589934595;
atanh_table[15]  = 48'd4294967296;
atanh_table[16]  = 48'd2147483648;
atanh_table[17]  = 48'd1073741824;
atanh_table[18]  = 48'd536870912;
atanh_table[19]  = 48'd268435456;
atanh_table[20]  = 48'd134217728;
atanh_table[21]  = 48'd67108864;
atanh_table[22]  = 48'd33554432;
atanh_table[23]  = 48'd16777216;
atanh_table[24]  = 48'd8388608;
atanh_table[25]  = 48'd4194304;
atanh_table[26]  = 48'd2097152;
atanh_table[27]  = 48'd1048576;
atanh_table[28]  = 48'd524288;
atanh_table[29]  = 48'd262144;
atanh_table[30]  = 48'd131072;
atanh_table[31]  = 48'd65536;
atanh_table[32]  = 48'd32768;
atanh_table[33]  = 48'd16384;
atanh_table[34]  = 48'd8192;
atanh_table[35]  = 48'd4096;
atanh_table[36]  = 48'd2048;
atanh_table[37]  = 48'd1024;
atanh_table[38]  = 48'd512;
atanh_table[39]  = 48'd256;
atanh_table[40]  = 48'd128;
atanh_table[41]  = 48'd64;
atanh_table[42]  = 48'd32;
atanh_table[43]  = 48'd16;
atanh_table[44]  = 48'd8;
atanh_table[45]  = 48'd4;
atanh_table[46]  = 48'd2;
atanh_table[47]  = 48'd1;
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
			if (y[0] < 0) begin
				x_temp[0] = fixedpt_add(x[0], (y[0] >>> 1));
				y_temp[0] = fixedpt_add(y[0], (x[0] >>> 1));
				z_temp[0] = fixedpt_sub(z[0], atanh_table[0]);
			end
			else begin
				x_temp[0] = fixedpt_sub(x[0], (y[0] >>> 1));
				y_temp[0] = fixedpt_sub(y[0], (x[0] >>> 1));
				z_temp[0] = fixedpt_add(z[0], atanh_table[0]);
			end

			// 2nd iteration
			if (y_temp[0] < 0) begin
				x[0] = fixedpt_add(x_temp[0], (y_temp[0] >>> 2));
				y[0] = fixedpt_add(y_temp[0], (x_temp[0] >>> 2));
				z[0] = fixedpt_sub(z_temp[0], atanh_table[1]);
			end
			else begin
				x[0] = fixedpt_sub(x_temp[0], (y_temp[0] >>> 2));
				y[0] = fixedpt_sub(y_temp[0], (x_temp[0] >>> 2));
				z[0] = fixedpt_add(z_temp[0], atanh_table[1]);
			end

			// 3rd iteration
			if (y[0] < 0) begin
				x_temp[0] = fixedpt_add(x[0], (y[0] >>> 3));
				y_temp[0] = fixedpt_add(y[0], (x[0] >>> 3));
				z_temp[0] = fixedpt_sub(z[0], atanh_table[2]);
			end
			else begin
				x_temp[0] = fixedpt_sub(x[0], (y[0] >>> 3));
				y_temp[0] = fixedpt_sub(y[0], (x[0] >>> 3));
				z_temp[0] = fixedpt_add(z[0], atanh_table[2]);
			end

			// 4th iteration
			if (y_temp[0] < 0) begin
				x[0] = fixedpt_add(x_temp[0], (y_temp[0] >>> 4));
				y[0] = fixedpt_add(y_temp[0], (x_temp[0] >>> 4));
				z[0] = fixedpt_sub(z_temp[0], atanh_table[3]);
			end
			else begin
				x[0] = fixedpt_sub(x_temp[0], (y_temp[0] >>> 4));
				y[0] = fixedpt_sub(y_temp[0], (x_temp[0] >>> 4));
				z[0] = fixedpt_add(z_temp[0], atanh_table[3]);
			end
		end
	end
end


// 2nd cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 5th iteration
			if (y[1] < 0) begin
				x_temp[1] = fixedpt_add(x[1], (y[1] >>> 4));
				y_temp[1] = fixedpt_add(y[1], (x[1] >>> 4));
				z_temp[1] = fixedpt_sub(z[1], atanh_table[3]);
			end
			else begin
				x_temp[1] = fixedpt_sub(x[1], (y[1] >>> 4));
				y_temp[1] = fixedpt_sub(y[1], (x[1] >>> 4));
				z_temp[1] = fixedpt_add(z[1], atanh_table[3]);
			end

			// 6th iteration
			if (y_temp[1] < 0) begin
				x[1] = fixedpt_add(x_temp[1], (y_temp[1] >>> 5));
				y[1] = fixedpt_add(y_temp[1], (x_temp[1] >>> 5));
				z[1] = fixedpt_sub(z_temp[1], atanh_table[4]);
			end
			else begin
				x[1] = fixedpt_sub(x_temp[1], (y_temp[1] >>> 5));
				y[1] = fixedpt_sub(y_temp[1], (x_temp[1] >>> 5));
				z[1] = fixedpt_add(z_temp[1], atanh_table[4]);
			end

			// 7th iteration
			if (y[1] < 0) begin
				x_temp[1] = fixedpt_add(x[1], (y[1] >>> 6));
				y_temp[1] = fixedpt_add(y[1], (x[1] >>> 6));
				z_temp[1] = fixedpt_sub(z[1], atanh_table[5]);
			end
			else begin
				x_temp[1] = fixedpt_sub(x[1], (y[1] >>> 6));
				y_temp[1] = fixedpt_sub(y[1], (x[1] >>> 6));
				z_temp[1] = fixedpt_add(z[1], atanh_table[5]);
			end

			// 8th iteration
			if (y_temp[1] < 0) begin
				x[1] = fixedpt_add(x_temp[1], (y_temp[1] >>> 7));
				y[1] = fixedpt_add(y_temp[1], (x_temp[1] >>> 7));
				z[1] = fixedpt_sub(z_temp[1], atanh_table[6]);
			end
			else begin
				x[1] = fixedpt_sub(x_temp[1], (y_temp[1] >>> 7));
				y[1] = fixedpt_sub(y_temp[1], (x_temp[1] >>> 7));
				z[1] = fixedpt_add(z_temp[1], atanh_table[6]);
			end
		end
	end
end


// 3rd cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 9th iteration
			if (y[2] < 0) begin
				x_temp[2] = fixedpt_add(x[2], (y[2] >>> 7));
				y_temp[2] = fixedpt_add(y[2], (x[2] >>> 7));
				z_temp[2] = fixedpt_sub(z[2], atanh_table[6]);
			end
			else begin
				x_temp[2] = fixedpt_sub(x[2], (y[2] >>> 7));
				y_temp[2] = fixedpt_sub(y[2], (x[2] >>> 7));
				z_temp[2] = fixedpt_add(z[2], atanh_table[6]);
			end

			// 10th iteration
			if (y_temp[2] < 0) begin
				x[2] = fixedpt_add(x_temp[2], (y_temp[2] >>> 8));
				y[2] = fixedpt_add(y_temp[2], (x_temp[2] >>> 8));
				z[2] = fixedpt_sub(z_temp[2], atanh_table[7]);
			end
			else begin
				x[2] = fixedpt_sub(x_temp[2], (y_temp[2] >>> 8));
				y[2] = fixedpt_sub(y_temp[2], (x_temp[2] >>> 8));
				z[2] = fixedpt_add(z_temp[2], atanh_table[7]);
			end

			// 11th iteration
			if (y[2] < 0) begin
				x_temp[2] = fixedpt_add(x[2], (y[2] >>> 9));
				y_temp[2] = fixedpt_add(y[2], (x[2] >>> 9));
				z_temp[2] = fixedpt_sub(z[2], atanh_table[8]);
			end
			else begin
				x_temp[2] = fixedpt_sub(x[2], (y[2] >>> 9));
				y_temp[2] = fixedpt_sub(y[2], (x[2] >>> 9));
				z_temp[2] = fixedpt_add(z[2], atanh_table[8]);
			end

			// 12th iteration
			if (y_temp[2] < 0) begin
				x[2] = fixedpt_add(x_temp[2], (y_temp[2] >>> 10));
				y[2] = fixedpt_add(y_temp[2], (x_temp[2] >>> 10));
				z[2] = fixedpt_sub(z_temp[2], atanh_table[9]);
			end
			else begin
				x[2] = fixedpt_sub(x_temp[2], (y_temp[2] >>> 10));
				y[2] = fixedpt_sub(y_temp[2], (x_temp[2] >>> 10));
				z[2] = fixedpt_add(z_temp[2], atanh_table[9]);
			end
		end
	end
end


// 4th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 13th iteration
			if (y[3] < 0) begin
				x_temp[3] = fixedpt_add(x[3], (y[3] >>> 10));
				y_temp[3] = fixedpt_add(y[3], (x[3] >>> 10));
				z_temp[3] = fixedpt_sub(z[3], atanh_table[9]);
			end
			else begin
				x_temp[3] = fixedpt_sub(x[3], (y[3] >>> 10));
				y_temp[3] = fixedpt_sub(y[3], (x[3] >>> 10));
				z_temp[3] = fixedpt_add(z[3], atanh_table[9]);
			end

			// 14th iteration
			if (y_temp[3] < 0) begin
				x[3] = fixedpt_add(x_temp[3], (y_temp[3] >>> 11));
				y[3] = fixedpt_add(y_temp[3], (x_temp[3] >>> 11));
				z[3] = fixedpt_sub(z_temp[3], atanh_table[10]);
			end
			else begin
				x[3] = fixedpt_sub(x_temp[3], (y_temp[3] >>> 11));
				y[3] = fixedpt_sub(y_temp[3], (x_temp[3] >>> 11));
				z[3] = fixedpt_add(z_temp[3], atanh_table[10]);
			end

			// 15th iteration
			if (y[3] < 0) begin
				x_temp[3] = fixedpt_add(x[3], (y[3] >>> 12));
				y_temp[3] = fixedpt_add(y[3], (x[3] >>> 12));
				z_temp[3] = fixedpt_sub(z[3], atanh_table[11]);
			end
			else begin
				x_temp[3] = fixedpt_sub(x[3], (y[3] >>> 12));
				y_temp[3] = fixedpt_sub(y[3], (x[3] >>> 12));
				z_temp[3] = fixedpt_add(z[3], atanh_table[11]);
			end

			// 16th iteration
			if (y_temp[3] < 0) begin
				x[3] = fixedpt_add(x_temp[3], (y_temp[3] >>> 13));
				y[3] = fixedpt_add(y_temp[3], (x_temp[3] >>> 13));
				z[3] = fixedpt_sub(z_temp[3], atanh_table[12]);
			end
			else begin
				x[3] = fixedpt_sub(x_temp[3], (y_temp[3] >>> 13));
				y[3] = fixedpt_sub(y_temp[3], (x_temp[3] >>> 13));
				z[3] = fixedpt_add(z_temp[3], atanh_table[12]);
			end
		end
	end
end


// 5th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 17th iteration
			if (y[4] < 0) begin
				x_temp[4] = fixedpt_add(x[4], (y[4] >>> 13));
				y_temp[4] = fixedpt_add(y[4], (x[4] >>> 13));
				z_temp[4] = fixedpt_sub(z[4], atanh_table[12]);
			end
			else begin
				x_temp[4] = fixedpt_sub(x[4], (y[4] >>> 13));
				y_temp[4] = fixedpt_sub(y[4], (x[4] >>> 13));
				z_temp[4] = fixedpt_add(z[4], atanh_table[12]);
			end

			// 18th iteration
			if (y_temp[4] < 0) begin
				x[4] = fixedpt_add(x_temp[4], (y_temp[4] >>> 14));
				y[4] = fixedpt_add(y_temp[4], (x_temp[4] >>> 14));
				z[4] = fixedpt_sub(z_temp[4], atanh_table[13]);
			end
			else begin
				x[4] = fixedpt_sub(x_temp[4], (y_temp[4] >>> 14));
				y[4] = fixedpt_sub(y_temp[4], (x_temp[4] >>> 14));
				z[4] = fixedpt_add(z_temp[4], atanh_table[13]);
			end

			// 19th iteration
			if (y[4] < 0) begin
				x_temp[4] = fixedpt_add(x[4], (y[4] >>> 15));
				y_temp[4] = fixedpt_add(y[4], (x[4] >>> 15));
				z_temp[4] = fixedpt_sub(z[4], atanh_table[14]);
			end
			else begin
				x_temp[4] = fixedpt_sub(x[4], (y[4] >>> 15));
				y_temp[4] = fixedpt_sub(y[4], (x[4] >>> 15));
				z_temp[4] = fixedpt_add(z[4], atanh_table[14]);
			end

			// 20th iteration
			if (y_temp[4] < 0) begin
				x[4] = fixedpt_add(x_temp[4], (y_temp[4] >>> 16));
				y[4] = fixedpt_add(y_temp[4], (x_temp[4] >>> 16));
				z[4] = fixedpt_sub(z_temp[4], atanh_table[15]);
			end
			else begin
				x[4] = fixedpt_sub(x_temp[4], (y_temp[4] >>> 16));
				y[4] = fixedpt_sub(y_temp[4], (x_temp[4] >>> 16));
				z[4] = fixedpt_add(z_temp[4], atanh_table[15]);
			end
		end
	end
end


// 6th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 21st iteration
			if (y[5] < 0) begin
				x_temp[5] = fixedpt_add(x[5], (y[5] >>> 16));
				y_temp[5] = fixedpt_add(y[5], (x[5] >>> 16));
				z_temp[5] = fixedpt_sub(z[5], atanh_table[15]);
			end
			else begin
				x_temp[5] = fixedpt_sub(x[5], (y[5] >>> 16));
				y_temp[5] = fixedpt_sub(y[5], (x[5] >>> 16));
				z_temp[5] = fixedpt_add(z[5], atanh_table[15]);
			end

			// 22nd iteration
			if (y_temp[5] < 0) begin
				x[5] = fixedpt_add(x_temp[5], (y_temp[5] >>> 17));
				y[5] = fixedpt_add(y_temp[5], (x_temp[5] >>> 17));
				z[5] = fixedpt_sub(z_temp[5], atanh_table[16]);
			end
			else begin
				x[5] = fixedpt_sub(x_temp[5], (y_temp[5] >>> 17));
				y[5] = fixedpt_sub(y_temp[5], (x_temp[5] >>> 17));
				z[5] = fixedpt_add(z_temp[5], atanh_table[16]);
			end

			// 23rd iteration
			if (y[5] < 0) begin
				x_temp[5] = fixedpt_add(x[5], (y[5] >>> 18));
				y_temp[5] = fixedpt_add(y[5], (x[5] >>> 18));
				z_temp[5] = fixedpt_sub(z[5], atanh_table[17]);
			end
			else begin
				x_temp[5] = fixedpt_sub(x[5], (y[5] >>> 18));
				y_temp[5] = fixedpt_sub(y[5], (x[5] >>> 18));
				z_temp[5] = fixedpt_add(z[5], atanh_table[17]);
			end

			// 24th iteration
			if (y_temp[5] < 0) begin
				x[5] = fixedpt_add(x_temp[5], (y_temp[5] >>> 19));
				y[5] = fixedpt_add(y_temp[5], (x_temp[5] >>> 19));
				z[5] = fixedpt_sub(z_temp[5], atanh_table[18]);
			end
			else begin
				x[5] = fixedpt_sub(x_temp[5], (y_temp[5] >>> 19));
				y[5] = fixedpt_sub(y_temp[5], (x_temp[5] >>> 19));
				z[5] = fixedpt_add(z_temp[5], atanh_table[18]);
			end
		end
	end
end


// 7th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 25th iteration
			if (y[6] < 0) begin
				x_temp[6] = fixedpt_add(x[6], (y[6] >>> 19));
				y_temp[6] = fixedpt_add(y[6], (x[6] >>> 19));
				z_temp[6] = fixedpt_sub(z[6], atanh_table[18]);
			end
			else begin
				x_temp[6] = fixedpt_sub(x[6], (y[6] >>> 19));
				y_temp[6] = fixedpt_sub(y[6], (x[6] >>> 19));
				z_temp[6] = fixedpt_add(z[6], atanh_table[18]);
			end

			// 26th iteration
			if (y_temp[6] < 0) begin
				x[6] = fixedpt_add(x_temp[6], (y_temp[6] >>> 20));
				y[6] = fixedpt_add(y_temp[6], (x_temp[6] >>> 20));
				z[6] = fixedpt_sub(z_temp[6], atanh_table[19]);
			end
			else begin
				x[6] = fixedpt_sub(x_temp[6], (y_temp[6] >>> 20));
				y[6] = fixedpt_sub(y_temp[6], (x_temp[6] >>> 20));
				z[6] = fixedpt_add(z_temp[6], atanh_table[19]);
			end

			// 27th iteration
			if (y[6] < 0) begin
				x_temp[6] = fixedpt_add(x[6], (y[6] >>> 21));
				y_temp[6] = fixedpt_add(y[6], (x[6] >>> 21));
				z_temp[6] = fixedpt_sub(z[6], atanh_table[20]);
			end
			else begin
				x_temp[6] = fixedpt_sub(x[6], (y[6] >>> 21));
				y_temp[6] = fixedpt_sub(y[6], (x[6] >>> 21));
				z_temp[6] = fixedpt_add(z[6], atanh_table[20]);
			end

			// 28th iteration
			if (y_temp[6] < 0) begin
				x[6] = fixedpt_add(x_temp[6], (y_temp[6] >>> 22));
				y[6] = fixedpt_add(y_temp[6], (x_temp[6] >>> 22));
				z[6] = fixedpt_sub(z_temp[6], atanh_table[21]);
			end
			else begin
				x[6] = fixedpt_sub(x_temp[6], (y_temp[6] >>> 22));
				y[6] = fixedpt_sub(y_temp[6], (x_temp[6] >>> 22));
				z[6] = fixedpt_add(z_temp[6], atanh_table[21]);
			end
		end
	end
end


// 8th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 29th iteration
			if (y[7] < 0) begin
				x_temp[7] = fixedpt_add(x[7], (y[7] >>> 22));
				y_temp[7] = fixedpt_add(y[7], (x[7] >>> 22));
				z_temp[7] = fixedpt_sub(z[7], atanh_table[21]);
			end
			else begin
				x_temp[7] = fixedpt_sub(x[7], (y[7] >>> 22));
				y_temp[7] = fixedpt_sub(y[7], (x[7] >>> 22));
				z_temp[7] = fixedpt_add(z[7], atanh_table[21]);
			end

			// 30th iteration
			if (y_temp[7] < 0) begin
				x[7] = fixedpt_add(x_temp[7], (y_temp[7] >>> 23));
				y[7] = fixedpt_add(y_temp[7], (x_temp[7] >>> 23));
				z[7] = fixedpt_sub(z_temp[7], atanh_table[22]);
			end
			else begin
				x[7] = fixedpt_sub(x_temp[7], (y_temp[7] >>> 23));
				y[7] = fixedpt_sub(y_temp[7], (x_temp[7] >>> 23));
				z[7] = fixedpt_add(z_temp[7], atanh_table[22]);
			end

			// 31st iteration
			if (y[7] < 0) begin
				x_temp[7] = fixedpt_add(x[7], (y[7] >>> 24));
				y_temp[7] = fixedpt_add(y[7], (x[7] >>> 24));
				z_temp[7] = fixedpt_sub(z[7], atanh_table[23]);
			end
			else begin
				x_temp[7] = fixedpt_sub(x[7], (y[7] >>> 24));
				y_temp[7] = fixedpt_sub(y[7], (x[7] >>> 24));
				z_temp[7] = fixedpt_add(z[7], atanh_table[23]);
			end

			// 32nd iteration
			if (y_temp[7] < 0) begin
				x[7] = fixedpt_add(x_temp[7], (y_temp[7] >>> 25));
				y[7] = fixedpt_add(y_temp[7], (x_temp[7] >>> 25));
				z[7] = fixedpt_sub(z_temp[7], atanh_table[24]);
			end
			else begin
				x[7] = fixedpt_sub(x_temp[7], (y_temp[7] >>> 25));
				y[7] = fixedpt_sub(y_temp[7], (x_temp[7] >>> 25));
				z[7] = fixedpt_add(z_temp[7], atanh_table[24]);
			end
		end
	end
end


// 9th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 33rd iteration
			if (y[8] < 0) begin
				x_temp[8] = fixedpt_add(x[8], (y[8] >>> 25));
				y_temp[8] = fixedpt_add(y[8], (x[8] >>> 25));
				z_temp[8] = fixedpt_sub(z[8], atanh_table[24]);
			end
			else begin
				x_temp[8] = fixedpt_sub(x[8], (y[8] >>> 25));
				y_temp[8] = fixedpt_sub(y[8], (x[8] >>> 25));
				z_temp[8] = fixedpt_add(z[8], atanh_table[24]);
			end

			// 34th iteration
			if (y_temp[8] < 0) begin
				x[8] = fixedpt_add(x_temp[8], (y_temp[8] >>> 26));
				y[8] = fixedpt_add(y_temp[8], (x_temp[8] >>> 26));
				z[8] = fixedpt_sub(z_temp[8], atanh_table[25]);
			end
			else begin
				x[8] = fixedpt_sub(x_temp[8], (y_temp[8] >>> 26));
				y[8] = fixedpt_sub(y_temp[8], (x_temp[8] >>> 26));
				z[8] = fixedpt_add(z_temp[8], atanh_table[25]);
			end

			// 35th iteration
			if (y[8] < 0) begin
				x_temp[8] = fixedpt_add(x[8], (y[8] >>> 27));
				y_temp[8] = fixedpt_add(y[8], (x[8] >>> 27));
				z_temp[8] = fixedpt_sub(z[8], atanh_table[26]);
			end
			else begin
				x_temp[8] = fixedpt_sub(x[8], (y[8] >>> 27));
				y_temp[8] = fixedpt_sub(y[8], (x[8] >>> 27));
				z_temp[8] = fixedpt_add(z[8], atanh_table[26]);
			end

			// 36th iteration
			if (y_temp[8] < 0) begin
				x[8] = fixedpt_add(x_temp[8], (y_temp[8] >>> 28));
				y[8] = fixedpt_add(y_temp[8], (x_temp[8] >>> 28));
				z[8] = fixedpt_sub(z_temp[8], atanh_table[27]);
			end
			else begin
				x[8] = fixedpt_sub(x_temp[8], (y_temp[8] >>> 28));
				y[8] = fixedpt_sub(y_temp[8], (x_temp[8] >>> 28));
				z[8] = fixedpt_add(z_temp[8], atanh_table[27]);
			end
		end
	end
end


// 10th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 37th iteration
			if (y[9] < 0) begin
				x_temp[9] = fixedpt_add(x[9], (y[9] >>> 28));
				y_temp[9] = fixedpt_add(y[9], (x[9] >>> 28));
				z_temp[9] = fixedpt_sub(z[9], atanh_table[27]);
			end
			else begin
				x_temp[9] = fixedpt_sub(x[9], (y[9] >>> 28));
				y_temp[9] = fixedpt_sub(y[9], (x[9] >>> 28));
				z_temp[9] = fixedpt_add(z[9], atanh_table[27]);
			end

			// 38th iteration
			if (y_temp[9] < 0) begin
				x[9] = fixedpt_add(x_temp[9], (y_temp[9] >>> 29));
				y[9] = fixedpt_add(y_temp[9], (x_temp[9] >>> 29));
				z[9] = fixedpt_sub(z_temp[9], atanh_table[28]);
			end
			else begin
				x[9] = fixedpt_sub(x_temp[9], (y_temp[9] >>> 29));
				y[9] = fixedpt_sub(y_temp[9], (x_temp[9] >>> 29));
				z[9] = fixedpt_add(z_temp[9], atanh_table[28]);
			end

			// 39th iteration
			if (y[9] < 0) begin
				x_temp[9] = fixedpt_add(x[9], (y[9] >>> 30));
				y_temp[9] = fixedpt_add(y[9], (x[9] >>> 30));
				z_temp[9] = fixedpt_sub(z[9], atanh_table[29]);
			end
			else begin
				x_temp[9] = fixedpt_sub(x[9], (y[9] >>> 30));
				y_temp[9] = fixedpt_sub(y[9], (x[9] >>> 30));
				z_temp[9] = fixedpt_add(z[9], atanh_table[29]);
			end

			// 40th iteration
			if (y_temp[9] < 0) begin
				x[9] = fixedpt_add(x_temp[9], (y_temp[9] >>> 31));
				y[9] = fixedpt_add(y_temp[9], (x_temp[9] >>> 31));
				z[9] = fixedpt_sub(z_temp[9], atanh_table[30]);
			end
			else begin
				x[9] = fixedpt_sub(x_temp[9], (y_temp[9] >>> 31));
				y[9] = fixedpt_sub(y_temp[9], (x_temp[9] >>> 31));
				z[9] = fixedpt_add(z_temp[9], atanh_table[30]);
			end
		end
	end
end


// 11th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 41st iteration
			if (y[10] < 0) begin
				x_temp[10] = fixedpt_add(x[10], (y[10] >>> 31));
				y_temp[10] = fixedpt_add(y[10], (x[10] >>> 31));
				z_temp[10] = fixedpt_sub(z[10], atanh_table[30]);
			end
			else begin
				x_temp[10] = fixedpt_sub(x[10], (y[10] >>> 31));
				y_temp[10] = fixedpt_sub(y[10], (x[10] >>> 31));
				z_temp[10] = fixedpt_add(z[10], atanh_table[30]);
			end

			// 42nd iteration
			if (y_temp[10] < 0) begin
				x[10] = fixedpt_add(x_temp[10], (y_temp[10] >>> 32));
				y[10] = fixedpt_add(y_temp[10], (x_temp[10] >>> 32));
				z[10] = fixedpt_sub(z_temp[10], atanh_table[31]);
			end
			else begin
				x[10] = fixedpt_sub(x_temp[10], (y_temp[10] >>> 32));
				y[10] = fixedpt_sub(y_temp[10], (x_temp[10] >>> 32));
				z[10] = fixedpt_add(z_temp[10], atanh_table[31]);
			end

			// 43rd iteration
			if (y[10] < 0) begin
				x_temp[10] = fixedpt_add(x[10], (y[10] >>> 33));
				y_temp[10] = fixedpt_add(y[10], (x[10] >>> 33));
				z_temp[10] = fixedpt_sub(z[10], atanh_table[32]);
			end
			else begin
				x_temp[10] = fixedpt_sub(x[10], (y[10] >>> 33));
				y_temp[10] = fixedpt_sub(y[10], (x[10] >>> 33));
				z_temp[10] = fixedpt_add(z[10], atanh_table[32]);
			end

			// 44th iteration
			if (y_temp[10] < 0) begin
				x[10] = fixedpt_add(x_temp[10], (y_temp[10] >>> 34));
				y[10] = fixedpt_add(y_temp[10], (x_temp[10] >>> 34));
				z[10] = fixedpt_sub(z_temp[10], atanh_table[33]);
			end
			else begin
				x[10] = fixedpt_sub(x_temp[10], (y_temp[10] >>> 34));
				y[10] = fixedpt_sub(y_temp[10], (x_temp[10] >>> 34));
				z[10] = fixedpt_add(z_temp[10], atanh_table[33]);
			end
		end
	end
end


// 12th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 45th iteration
			if (y[11] < 0) begin
				x_temp[11] = fixedpt_add(x[11], (y[11] >>> 34));
				y_temp[11] = fixedpt_add(y[11], (x[11] >>> 34));
				z_temp[11] = fixedpt_sub(z[11], atanh_table[33]);
			end
			else begin
				x_temp[11] = fixedpt_sub(x[11], (y[11] >>> 34));
				y_temp[11] = fixedpt_sub(y[11], (x[11] >>> 34));
				z_temp[11] = fixedpt_add(z[11], atanh_table[33]);
			end

			// 46th iteration
			if (y_temp[11] < 0) begin
				x[11] = fixedpt_add(x_temp[11], (y_temp[11] >>> 35));
				y[11] = fixedpt_add(y_temp[11], (x_temp[11] >>> 35));
				z[11] = fixedpt_sub(z_temp[11], atanh_table[34]);
			end
			else begin
				x[11] = fixedpt_sub(x_temp[11], (y_temp[11] >>> 35));
				y[11] = fixedpt_sub(y_temp[11], (x_temp[11] >>> 35));
				z[11] = fixedpt_add(z_temp[11], atanh_table[34]);
			end

			// 47th iteration
			if (y[11] < 0) begin
				x_temp[11] = fixedpt_add(x[11], (y[11] >>> 36));
				y_temp[11] = fixedpt_add(y[11], (x[11] >>> 36));
				z_temp[11] = fixedpt_sub(z[11], atanh_table[35]);
			end
			else begin
				x_temp[11] = fixedpt_sub(x[11], (y[11] >>> 36));
				y_temp[11] = fixedpt_sub(y[11], (x[11] >>> 36));
				z_temp[11] = fixedpt_add(z[11], atanh_table[35]);
			end

			// 48th iteration
			if (y_temp[11] < 0) begin
				x[11] = fixedpt_add(x_temp[11], (y_temp[11] >>> 37));
				y[11] = fixedpt_add(y_temp[11], (x_temp[11] >>> 37));
				z[11] = fixedpt_sub(z_temp[11], atanh_table[36]);
			end
			else begin
				x[11] = fixedpt_sub(x_temp[11], (y_temp[11] >>> 37));
				y[11] = fixedpt_sub(y_temp[11], (x_temp[11] >>> 37));
				z[11] = fixedpt_add(z_temp[11], atanh_table[36]);
			end
		end
	end
end


// 13th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 49th iteration
			if (y[12] < 0) begin
				x_temp[12] = fixedpt_add(x[12], (y[12] >>> 37));
				y_temp[12] = fixedpt_add(y[12], (x[12] >>> 37));
				z_temp[12] = fixedpt_sub(z[12], atanh_table[36]);
			end
			else begin
				x_temp[12] = fixedpt_sub(x[12], (y[12] >>> 37));
				y_temp[12] = fixedpt_sub(y[12], (x[12] >>> 37));
				z_temp[12] = fixedpt_add(z[12], atanh_table[36]);
			end

			// 50th iteration
			if (y_temp[12] < 0) begin
				x[12] = fixedpt_add(x_temp[12], (y_temp[12] >>> 38));
				y[12] = fixedpt_add(y_temp[12], (x_temp[12] >>> 38));
				z[12] = fixedpt_sub(z_temp[12], atanh_table[37]);
			end
			else begin
				x[12] = fixedpt_sub(x_temp[12], (y_temp[12] >>> 38));
				y[12] = fixedpt_sub(y_temp[12], (x_temp[12] >>> 38));
				z[12] = fixedpt_add(z_temp[12], atanh_table[37]);
			end

			// 51st iteration
			if (y[12] < 0) begin
				x_temp[12] = fixedpt_add(x[12], (y[12] >>> 39));
				y_temp[12] = fixedpt_add(y[12], (x[12] >>> 39));
				z_temp[12] = fixedpt_sub(z[12], atanh_table[38]);
			end
			else begin
				x_temp[12] = fixedpt_sub(x[12], (y[12] >>> 39));
				y_temp[12] = fixedpt_sub(y[12], (x[12] >>> 39));
				z_temp[12] = fixedpt_add(z[12], atanh_table[38]);
			end

			// 52nd iteration
			if (y_temp[12] < 0) begin
				x[12] = fixedpt_add(x_temp[12], (y_temp[12] >>> 40));
				y[12] = fixedpt_add(y_temp[12], (x_temp[12] >>> 40));
				z[12] = fixedpt_sub(z_temp[12], atanh_table[39]);
			end
			else begin
				x[12] = fixedpt_sub(x_temp[12], (y_temp[12] >>> 40));
				y[12] = fixedpt_sub(y_temp[12], (x_temp[12] >>> 40));
				z[12] = fixedpt_add(z_temp[12], atanh_table[39]);
			end
		end
	end
end


// 14th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 53rd iteration
			if (y[13] < 0) begin
				x_temp[13] = fixedpt_add(x[13], (y[13] >>> 40));
				y_temp[13] = fixedpt_add(y[13], (x[13] >>> 40));
				z_temp[13] = fixedpt_sub(z[13], atanh_table[39]);
			end
			else begin
				x_temp[13] = fixedpt_sub(x[13], (y[13] >>> 40));
				y_temp[13] = fixedpt_sub(y[13], (x[13] >>> 40));
				z_temp[13] = fixedpt_add(z[13], atanh_table[39]);
			end

			// 54th iteration
			if (y_temp[13] < 0) begin
				x[13] = fixedpt_add(x_temp[13], (y_temp[13] >>> 41));
				y[13] = fixedpt_add(y_temp[13], (x_temp[13] >>> 41));
				z[13] = fixedpt_sub(z_temp[13], atanh_table[40]);
			end
			else begin
				x[13] = fixedpt_sub(x_temp[13], (y_temp[13] >>> 41));
				y[13] = fixedpt_sub(y_temp[13], (x_temp[13] >>> 41));
				z[13] = fixedpt_add(z_temp[13], atanh_table[40]);
			end

			// 55th iteration
			if (y[13] < 0) begin
				x_temp[13] = fixedpt_add(x[13], (y[13] >>> 42));
				y_temp[13] = fixedpt_add(y[13], (x[13] >>> 42));
				z_temp[13] = fixedpt_sub(z[13], atanh_table[41]);
			end
			else begin
				x_temp[13] = fixedpt_sub(x[13], (y[13] >>> 42));
				y_temp[13] = fixedpt_sub(y[13], (x[13] >>> 42));
				z_temp[13] = fixedpt_add(z[13], atanh_table[41]);
			end

			// 56th iteration
			if (y_temp[13] < 0) begin
				x[13] = fixedpt_add(x_temp[13], (y_temp[13] >>> 43));
				y[13] = fixedpt_add(y_temp[13], (x_temp[13] >>> 43));
				z[13] = fixedpt_sub(z_temp[13], atanh_table[42]);
			end
			else begin
				x[13] = fixedpt_sub(x_temp[13], (y_temp[13] >>> 43));
				y[13] = fixedpt_sub(y_temp[13], (x_temp[13] >>> 43));
				z[13] = fixedpt_add(z_temp[13], atanh_table[42]);
			end
		end
	end
end


// 15th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 57th iteration
			if (y[14] < 0) begin
				x_temp[14] = fixedpt_add(x[14], (y[14] >>> 43));
				y_temp[14] = fixedpt_add(y[14], (x[14] >>> 43));
				z_temp[14] = fixedpt_sub(z[14], atanh_table[42]);
			end
			else begin
				x_temp[14] = fixedpt_sub(x[14], (y[14] >>> 43));
				y_temp[14] = fixedpt_sub(y[14], (x[14] >>> 43));
				z_temp[14] = fixedpt_add(z[14], atanh_table[42]);
			end

			// 58th iteration
			if (y_temp[14] < 0) begin
				x[14] = fixedpt_add(x_temp[14], (y_temp[14] >>> 44));
				y[14] = fixedpt_add(y_temp[14], (x_temp[14] >>> 44));
				z[14] = fixedpt_sub(z_temp[14], atanh_table[43]);
			end
			else begin
				x[14] = fixedpt_sub(x_temp[14], (y_temp[14] >>> 44));
				y[14] = fixedpt_sub(y_temp[14], (x_temp[14] >>> 44));
				z[14] = fixedpt_add(z_temp[14], atanh_table[43]);
			end

			// 59th iteration
			if (y[14] < 0) begin
				x_temp[14] = fixedpt_add(x[14], (y[14] >>> 45));
				y_temp[14] = fixedpt_add(y[14], (x[14] >>> 45));
				z_temp[14] = fixedpt_sub(z[14], atanh_table[44]);
			end
			else begin
				x_temp[14] = fixedpt_sub(x[14], (y[14] >>> 45));
				y_temp[14] = fixedpt_sub(y[14], (x[14] >>> 45));
				z_temp[14] = fixedpt_add(z[14], atanh_table[44]);
			end

			// 60th iteration
			if (y_temp[14] < 0) begin
				x[14] = fixedpt_add(x_temp[14], (y_temp[14] >>> 46));
				y[14] = fixedpt_add(y_temp[14], (x_temp[14] >>> 46));
				z[14] = fixedpt_sub(z_temp[14], atanh_table[45]);
			end
			else begin
				x[14] = fixedpt_sub(x_temp[14], (y_temp[14] >>> 46));
				y[14] = fixedpt_sub(y_temp[14], (x_temp[14] >>> 46));
				z[14] = fixedpt_add(z_temp[14], atanh_table[45]);
			end
		end
	end
end


// 16th cordic pipeline stage
always @ (posedge clock) begin
	if (!reset) begin
		if (pipe_element_count > 0) begin
			// 61st iteration
			if (y[15] < 0) begin
				x_temp[15] = fixedpt_add(x[15], (y[15] >>> 46));
				y_temp[15] = fixedpt_add(y[15], (x[15] >>> 46));
				z_temp[15] = fixedpt_sub(z[15], atanh_table[45]);
			end
			else begin
				x_temp[15] = fixedpt_sub(x[15], (y[15] >>> 46));
				y_temp[15] = fixedpt_sub(y[15], (x[15] >>> 46));
				z_temp[15] = fixedpt_add(z[15], atanh_table[45]);
			end

			// 62nd iteration
			if (y_temp[15] < 0) begin
				x[15] = fixedpt_add(x_temp[15], (y_temp[15] >>> 47));
				y[15] = fixedpt_add(y_temp[15], (x_temp[15] >>> 47));
				z[15] = fixedpt_sub(z_temp[15], atanh_table[46]);
			end
			else begin
				x[15] = fixedpt_sub(x_temp[15], (y_temp[15] >>> 47));
				y[15] = fixedpt_sub(y_temp[15], (x_temp[15] >>> 47));
				z[15] = fixedpt_add(z_temp[15], atanh_table[46]);
			end

			// 63rd iteration
			if (y[15] < 0) begin
				x_temp[15] = fixedpt_add(x[15], (y[15] >>> 48));
				y_temp[15] = fixedpt_add(y[15], (x[15] >>> 48));
				z_temp[15] = fixedpt_sub(z[15], atanh_table[47]);
			end
			else begin
				x_temp[15] = fixedpt_sub(x[15], (y[15] >>> 48));
				y_temp[15] = fixedpt_sub(y[15], (x[15] >>> 48));
				z_temp[15] = fixedpt_add(z[15], atanh_table[47]);
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



