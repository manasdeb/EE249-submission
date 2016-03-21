// Include file containing fixed point math functions 

`ifndef _fixedpt_funcs_vh_
`define _fixedpt_funcs_vh_


function signed [`FIXEDPT_OP_BITWIDTH-1:0] fixedpt_add;
input signed [`FIXEDPT_OP_BITWIDTH-1:0] op1;
input signed [`FIXEDPT_OP_BITWIDTH-1:0] op2;
reg signed [`FIXEDPT_OP_BITWIDTH-1:0] sumval;
begin
	sumval = op1 + op2;

	if (sumval > `MAX_FIXEDPT_VAL)
		fixedpt_add = `MAX_FIXEDPT_VAL;
	else
		fixedpt_add = sumval;
end
endfunction
	
function signed [`FIXEDPT_OP_BITWIDTH-1:0] fixedpt_sub;
input signed [`FIXEDPT_OP_BITWIDTH-1:0] op1;
input signed [`FIXEDPT_OP_BITWIDTH-1:0] op2;
reg signed [`FIXEDPT_OP_BITWIDTH-1:0] subval;
begin
	subval = op1 - op2;

	if (subval < `MIN_FIXEDPT_VAL)
		fixedpt_sub = `MIN_FIXEDPT_VAL;
	else
		fixedpt_sub = subval;
end
endfunction

function signed [`FIXEDPT_OP_BITWIDTH-1:0] fixedpt_mul;
input signed [`FIXEDPT_OP_BITWIDTH-1:0] op1;
input signed [`FIXEDPT_OP_BITWIDTH-1:0] op2;
reg signed [`FIXEDPT_PROD_BITWIDTH-1:0] prodval;
begin
	prodval = op1 * op2;
	prodval = prodval >>> `FIXEDPT_PROD_SHIFTVAL;
	if (prodval[0] == 1)
		prodval = prodval + 1;

	prodval = prodval >>> 1;

	if (prodval > `MAX_FIXEDPT_VAL)
		fixedpt_mul = `MAX_FIXEDPT_VAL;
	else if (prodval < `MIN_FIXEDPT_VAL)
		fixedpt_mul = `MIN_FIXEDPT_VAL;
	else
		fixedpt_mul = prodval[`FIXEDPT_OP_BITWIDTH-1:0];
end
endfunction


`endif // _fixedpt_funcs_vh_



