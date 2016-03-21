`include "bm_constants.vh"

module sincos_tb;

reg clock, reset, valid_in;
reg signed [`FIXEDPT_OP_BITWIDTH-1:0] cordic_arg_mem[0:111];
reg signed [`FIXEDPT_OP_BITWIDTH-1:0] cordic_arg;
reg cordic_op;
wire signed [`FIXEDPT_OP_BITWIDTH-1:0] result;
wire valid_out;

reg [7:0] argidx;
reg [7:0] resultidx;
integer handle1;

initial begin
  clock = 0;
  reset = 1;
  valid_in = 0;
  argidx = 0;
  resultidx=0;

  $readmemb("sincos_rtl_in.txt", cordic_arg_mem);
  handle1=$fopen("sin_rtl_out.txt");

  #15 reset = 0; 
end

always @ (posedge clock) begin
	if (!reset) begin
		cordic_arg = cordic_arg_mem[argidx]; cordic_op = `OPTYPE_SIN; valid_in = 1;
		argidx = argidx + 1;
	end
end


always @ (posedge clock) begin
	if (valid_out == 1) begin
		if (resultidx < 112) begin
  			$fdisplay(handle1, "%d", result);
			resultidx = resultidx + 1;
		end

		if (resultidx == 112) begin
			$fclose(handle1);
		end
	end
end

always begin
 #5 clock = !clock;
end


sincos SINCOS (
.clock(clock), 
.reset(reset),
.valid_in(valid_in),
.op_type(cordic_op),
.arg_in(cordic_arg),
.result(result),
.valid_out(valid_out)
);

endmodule
