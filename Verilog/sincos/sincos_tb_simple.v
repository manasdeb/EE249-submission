`include "bm_constants.vh"

module sincos_tb;

reg clock, reset, valid_in;
reg signed [`FIXEDPT_OP_BITWIDTH-1:0] cordic_arg;
reg cordic_op;
wire signed [`FIXEDPT_OP_BITWIDTH-1:0] result;
wire valid_out;

reg [4:0] state;

initial begin
  clock = 0;
  reset = 1;
  valid_in = 0;

  #15 reset = 0; cordic_arg = -56'sd154811237190861; cordic_op = `OPTYPE_SIN; valid_in = 1; // -0.55
  #10 reset = 0; cordic_arg = 56'sd168884986026394; cordic_op = `OPTYPE_SIN; valid_in = 1; // 0.6
  #10 reset = 0; cordic_arg = 56'sd253327479039590; cordic_op = `OPTYPE_SIN; valid_in = 1; // 0.9
  #10 reset = 0; cordic_arg = 56'sd197032483697459 ; cordic_op = `OPTYPE_SIN; valid_in = 1; // 0.7
  #10 reset = 0; cordic_arg = 56'sd154811237190861; cordic_op = `OPTYPE_SIN; valid_in = 1; // 0.55
  #10 reset = 0; cordic_arg = 56'sd717761190612173; cordic_op = `OPTYPE_SIN; valid_in = 1; // 2.55
  #10 reset = 0; cordic_arg = 56'sd1345450388676936; cordic_op = `OPTYPE_SIN; valid_in = 1; // 4.78
end

always @ (posedge clock) begin
	if (valid_out) begin
		$display("At time %d sin result = %d", $time, result);
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
