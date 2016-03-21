function val=cordic_fixedpt(funcname, funcarg, argtype)

if (~exist('argtype', 'var'))
	argtype='float';
end

% Number of precision bits and number of iterations
N_BITS_PREC=48;

atan_table_fixedpt=[ ...
         221069929750889;          130505199945453;           68955363498242;           35002819193903; ...
          17569333089919;            8793231387230;            4397688649582;            2198978517948; ...
           1099506035422;             549755114839;             274877819563;             137438942549; ...
             68719475371;              34359738197;              17179869163;               8589934589; ...
              4294967296;               2147483648;               1073741824;                536870912; ...
               268435456;                134217728;                 67108864;                 33554432; ...
                16777216;                  8388608;                  4194304;                  2097152; ...
                 1048576;                   524288;                   262144;                   131072; ...
                   65536;                    32768;                    16384;                     8192; ...
                    4096;                     2048;                     1024;                      512; ...
                     256;                      128;                       64;                       32; ...
                      16;                        8;                        4;                        2; ...
];

atanh_table_fixedpt=[ ...
         154615934183448;           71892315276369;           35369361423710;           17615146374006; ...
           8798958012631;            4398404477483;            2199067996433;            1099517220233; ...
            549756512940;             274877994325;             137438964395;              68719478101; ...
             34359738539;              17179869205;               8589934595;               4294967296; ...
              2147483648;               1073741824;                536870912;                268435456; ...
               134217728;                 67108864;                 33554432;                 16777216; ...
                 8388608;                  4194304;                  2097152;                  1048576; ...
                  524288;                   262144;                   131072;                    65536; ...
                   32768;                    16384;                     8192;                     4096; ...
                    2048;                     1024;                      512;                      256; ...
                     128;                       64;                       32;                       16; ...
                       8;                        4;                        2;                        1; ...
];


A_CIRC=170926505739102;                % round(0.6072529350088815558450*(2^48))
A_HYPERB=339890743935231;              % round(1.20753449527637446437 * (2^48))

HALFPI=442139859501778;                % round((pi/2)*(2^48))
LOG_2=195103586505167;                 % round(log(2)*(2^48))
LOG_LIMIT=42221246506598;              % round(0.15*(2^48))
SQRT_LOWER_LIMIT=8444249301320;        % round(0.03*(2^48))
SQRT_UPPER_LIMIT=562949953421312;      % round(2*(2^48))

switch lower(funcname)
	case {'sin', 'cos'}
		if (strcmpi(argtype, 'fixed'))
			arg_sign=sign(funcarg);
			angle_arg=abs(funcarg);
		else
			arg_sign=sign(funcarg);
			funcarg=abs(funcarg);
	
			% Convert from floating point to S6.48 fixed point
			angle_arg=round(funcarg*(2^N_BITS_PREC));
		end

		% cos(theta)=sin(theta + pi/2)
		if (strcmpi(funcname, 'cos') == 1)
			angle_arg=fixed_add(angle_arg, HALFPI, 48);
			arg_sign=1;
		end

		% Reduce the angle argument to a value between [-pi/4, pi/4]
		n_halfpi_angles=0;
		while (angle_arg >= HALFPI)
			angle_arg=fixed_sub(angle_arg, HALFPI, 48);
			n_halfpi_angles=n_halfpi_angles+1;
		end

		% Get the quadrant where the angle lies
		quad_id=mod(n_halfpi_angles, 4); 

		x=A_CIRC;
		y=0;
		z=angle_arg;
		[x_ret, y_ret, z_ret]=cordic_circular(x, y, z, N_BITS_PREC, atan_table_fixedpt);

		% Modify the output of the cordic based on the sign of the argument and the
		% quadrant of the angle argument
		switch (quad_id)
			case 0
				if (strcmpi(argtype, 'fixed'))
					val=arg_sign*y_ret;
				else
					val=arg_sign*(y_ret/(2^N_BITS_PREC));
				end

			case 1
				if (strcmpi(argtype, 'fixed'))
					val=arg_sign*x_ret;
				else
					val=arg_sign*(x_ret/(2^N_BITS_PREC));
				end

			case 2
				if (strcmpi(argtype, 'fixed'))
					val=arg_sign * -1 * y_ret;
				else
					val=arg_sign*(-1 * y_ret/(2^N_BITS_PREC));
				end

			case 3
				if (strcmpi(argtype, 'fixed'))
					val=arg_sign * -1 * x_ret;
				else
					val=arg_sign*(-1 * x_ret/(2^N_BITS_PREC));
				end
		end

	case 'log'
		if (strcmpi(argtype, 'fixed') ~= 1)
			% Convert from floating point to fixed point
			funcarg=round(funcarg*(2^N_BITS_PREC));
		end

		% The CORDIC log function's lower limit is 0.15
		% Scale the function argument to bring it above this limit 
		scalefactor=0;
		while (funcarg < LOG_LIMIT)
			funcarg=funcarg*2;
			scalefactor=scalefactor+1;
		end

		x=fixed_add(funcarg, 281474976710656, 48);   % funcarg+round(1 * (2^48))
		y=fixed_sub(funcarg, 281474976710656, 48);   % funcarg-round(1 * (2^48))
		z=0;
		[x_ret, y_ret, z_ret]=cordic_hyperbolic(x, y, z, N_BITS_PREC, atanh_table_fixedpt);
		val=fixed_mul(562949953421312, z_ret, 48);   % round(2 * (2^48))*z_ret

		if (scalefactor)
			adjust_val=fixed_mul(scalefactor*(2^48), LOG_2, 48);
			val=fixed_sub(val, adjust_val, 48);
		end

		if (strcmpi(argtype, 'fixed') ~= 1)
			% return floating point value
			val=val/(2^N_BITS_PREC);
		end

	case 'sqrt'
		if (strcmpi(argtype, 'fixed') ~= 1)
			% Convert from floating point to fixed point
			funcarg=round(funcarg*(2^N_BITS_PREC));
		end

		% Scale the function argument to fall in the range [0.03, 2]
		scalefactor=0;
		if (funcarg < SQRT_LOWER_LIMIT)
			while (funcarg < SQRT_LOWER_LIMIT)
				funcarg=bitshift(funcarg, 1);
				scalefactor=scalefactor+1;
			end

			if (mod(scalefactor, 2) ~= 0)
				funcarg=bitshift(funcarg, 1);
				scalefactor=scalefactor+1;
			end

			scalefactor=-1*scalefactor;
		elseif (funcarg > SQRT_UPPER_LIMIT)
			while (funcarg > SQRT_UPPER_LIMIT)
				funcarg=bitshift(funcarg, -1);
				scalefactor=scalefactor+1;
			end

			if (mod(scalefactor, 2) ~= 0)
				funcarg=bitshift(funcarg, -1);
				scalefactor=scalefactor+1;
			end
		end

		x=fixed_add(funcarg, 70368744177664, 48);   % funcarg + round(0.25 * (2^48))
		y=fixed_sub(funcarg, 70368744177664, 48);   % funcarg - round(0.25 * (2^48))
		z=0;
		[x_ret, y_ret, z_ret]=cordic_hyperbolic(x, y, z, N_BITS_PREC, atanh_table_fixedpt);
		val=fixed_mul(x_ret, A_HYPERB, 48);

		% Compensate for the scaling
		val=bitshift(val, scalefactor/2, 'uint64');

		if (strcmpi(argtype, 'fixed') ~= 1)
			% return floating point value
			val=val/(2^N_BITS_PREC);
		end

	otherwise
		val = 0;
		disp(sprintf('Unsupported CORDIC function %s', funcname));
end


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
	disp(sprintf('fixed_add saturated: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
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
	disp(sprintf('fixed_sub saturated: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
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
	disp(sprintf('fixed_mul saturated at max_val: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
	val = max_val;
elseif (val < min_val)
	disp(sprintf('fixed_mul saturated at min_val: op1=%d, op2=%d, val=%d (0x%s)', op1, op2, val, dec2hex(val))); 
	val = min_val;
end



% ----------------------------------------------------
% Circular Cordic
% ----------------------------------------------------
function [x_final, y_final, z_final]=cordic_circular(x, y, z, N, atan_table)

shiftval=0;

for i=1:N
 	y_temp=bitshift(y, shiftval, 'int64');
	x_temp=bitshift(x, shiftval, 'int64');

	if (z >= 0)
		x_new=fixed_sub(x, y_temp, 48);
		y_new=fixed_add(y, x_temp, 48);
		z_new=fixed_sub(z, atan_table(i), 48);
	else
		x_new=fixed_add(x, y_temp, 48);
		y_new=fixed_sub(y, x_temp, 48);
		z_new=fixed_add(z, atan_table(i), 48);
	end

	x=x_new;
	y=y_new;
	z=z_new;
	shiftval=shiftval-1;
end

x_final=x;
y_final=y;
z_final=z;


% ----------------------------------------------------
% Heyberbolic Cordic
% ----------------------------------------------------
function [x_final, y_final, z_final]=cordic_hyperbolic(x, y, z, N, atanh_table)

shiftval=-1;
k=3;

for i=1:N
	for j=1:2
		% 2 repeated iterations for iteration #4, 7, ... 3n+1 where n=1..N_BITS-1
		% to ensure convergence for hyperbolic cordic

 		y_temp=bitshift(y, shiftval, 'int64');
		x_temp=bitshift(x, shiftval, 'int64');

		if (y < 0)
			x_new=fixed_add(x, y_temp, 48);
			y_new=fixed_add(y, x_temp, 48);
			z_new=fixed_sub(z, atanh_table(i), 48);
		else
			x_new=fixed_sub(x, y_temp, 48);
			y_new=fixed_sub(y, x_temp, 48);
			z_new=fixed_add(z, atanh_table(i), 48);
		end

		x=x_new;
		y=y_new;
		z=z_new;

		if (k > 0)
			k=k-1;
			break;
		else
			k=3;
		end
	end

	shiftval=shiftval-1;
end

x_final=x;
y_final=y;
z_final=z;



