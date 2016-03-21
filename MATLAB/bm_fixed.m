function x=bm_fixed()

N=10000;
TWO_PI=1768559438007110;
MINUS_TWO=-562949953421312;

x0_array=zeros(1, N);
x1_array=zeros(1, N);

urnd1_array=tauss(hex2dec('9A61C8B2'), N);
urnd2_array=tauss(hex2dec('F26C2A1E'), N);


for i=1:N
	urnd1=urnd1_array(i);
	urnd2=urnd2_array(i);

	upper_urnd2=uint16(bitshift(bitand(urnd2, hex2dec('FFFF0000'), 'uint32'), -16));
	lower_urnd2=uint16(bitand(urnd2, hex2dec('0000FFFF'), 'uint32'));

	u0_int=uint64(bitor(bitshift(uint64(urnd1), 16, 'uint64'), uint64(upper_urnd2), 'uint64'));
	u1_int=lower_urnd2;

	u0=double(u0_int);
	u1=double(u1_int);

	logval=cordic_fixedpt('log', u0, 'fixed');
	e=fixed_mul(MINUS_TWO, logval, 48);

	f=cordic_fixedpt('sqrt', fix(e), 'fixed');

	angle_arg=bitshift(u1, 32);
	sincos_arg=fixed_mul(TWO_PI, angle_arg, 48);
	g0=cordic_fixedpt('sin', sincos_arg, 'fixed');
	g1=cordic_fixedpt('cos', sincos_arg, 'fixed');

	x0=fixed_mul(f, g0, 48);
	x1=fixed_mul(f, g1, 48);

	x0_array(i)=x0;
	x1_array(i)=x1;
end

x=[x0_array; x1_array];
x=x(:);




% -----------------------------------------
% fixed point addition
% -----------------------------------------
function val=fixed_add(op1, op2, n_bits)

if (n_bits == 16)
	max_val=hex2dec('1FFFFF');  % S4.16
elseif (n_bits == 32)
	max_val=hex2dec('1FFFFFFFFF');  % S4.32
else
	max_val=hex2dec('3FFFFFFFFFFFFF');  % S6.48
end

val=op1+op2;

% Saturation check
if (val > max_val)
	disp(sprintf('fixed_add_bm saturated: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
	val = max_val;
end


% -----------------------------------------
% fixed point subtraction
% -----------------------------------------
function val=fixed_sub(op1, op2, n_bits)

if (n_bits == 16)
	min_val=-1*hex2dec('200000');  % S4.16
elseif (n_bits == 32)
	min_val=-1*hex2dec('2000000000');  % S4.32
else
	min_val=-1*hex2dec('40000000000000');  % S6.48
end

val=op1-op2;

% Saturation check
if (val < min_val)
	disp(sprintf('fixed_sub_bm saturated: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
	val = min_val;
end


% -----------------------------------------
% fixed point multiplication
% -----------------------------------------
function val=fixed_mul(op1, op2, n_bits)

if (n_bits == 16)
	% S4.16
	max_val=hex2dec('1FFFFF');
	min_val=-1*hex2dec('200000');
elseif (n_bits == 32)
	% S4.32
	max_val=hex2dec('1FFFFFFFFF');
	min_val=-1*hex2dec('2000000000');
else
	% S6.48
	max_val=hex2dec('3FFFFFFFFFFFFF');
	min_val=-1*hex2dec('40000000000000');
end

val=op1*op2;

% Round to nearest integer
if (n_bits == 16)
	val_adjust=fix(val/(2^15));
elseif (n_bits == 32)
	val_adjust=fix(val/(2^31));
else
	val_adjust=fix(val/(2^47));
end

val_adjust=val_adjust + 1;
val=fix(val_adjust/2);

% Saturation check
if (val > max_val)
	disp(sprintf('fixed_mul_bm saturated at max_val: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
	val = max_val;
elseif (val < min_val)
	disp(sprintf('fixed_mul_bm saturated at min_val: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
	val = min_val;
end


% -----------------------------------------------
% fixed point division (only 16 bit operands)
% -----------------------------------------------
function val=fixed_div(op1, op2, n_bits)

% S4.16
max_val=hex2dec('1FFFFFFFFF');
min_val=-1*hex2dec('4000000000');

% Scale the numerator
op1=op1*(2^17);

% Saturation check
if (op1 > max_val)
	disp(sprintf('fixed_div_bm saturated at max_val: op1=%d', op1)); 
	op1 = max_val;
elseif (op1 < min_val)
	disp(sprintf('fixed_div_bm saturated at min_val: op1=%d', op1)); 
	op1 = min_val;
end

val=op1/op2;

% Round to nearest integer
val_adjust=val + 1;
val=fix(val_adjust/2)
