function val=cordic(funcname, funcarg)

% Number of precision bits and number of iterations
N_BITS=32;

atan_table=[ ...
	0.7853981633974483; 0.4636476090008061; 0.2449786631268641; 0.1243549945467614; ...
	0.0624188099959574; 0.0312398334302683; 0.0156237286204768; 0.0078123410601011; ...
	0.0039062301319670; 0.0019531225164788; 0.0009765621895593; 0.0004882812111949; ...
	0.0002441406201494; 0.0001220703118937; 0.0000610351561742; 0.0000305175781155; ...
	0.0000152587890613; 0.0000076293945311; 0.0000038146972656; 0.0000019073486328; ...
	0.0000009536743164; 0.0000004768371582; 0.0000002384185791; 0.0000001192092896; ...
	0.0000000596046448; 0.0000000298023224; 0.0000000149011612; 0.0000000074505806; ...
	0.0000000037252903; 0.0000000018626451; 0.0000000009313226; 0.0000000004656613; ...
	];

atanh_table=[ ...
	0.5493061443340548; 0.2554128118829954; 0.1256572141404531; 0.0625815714770030; ...
	0.0312601784906670; 0.0156262717520523; 0.0078126589515404; 0.0039062698683968; ...
	0.0019531274835326; 0.0009765628104410; 0.0004882812888051; 0.0002441406298506; ...
	0.0001220703131063; 0.0000610351563258; 0.0000305175781345; 0.0000152587890637; ...
	0.0000076293945314; 0.0000038146972657; 0.0000019073486328; 0.0000009536743164; ...
	0.0000004768371582; 0.0000002384185791; 0.0000001192092896; 0.0000000596046448; ...
	0.0000000298023224; 0.0000000149011612; 0.0000000074505807; 0.0000000037252903; ...
	0.0000000018626451; 0.0000000009313226; 0.0000000004656613; 0.0000000002328306; ...
	];

A_CIRC=0.6072529350088816;
A_HYPERB=1.2075344952763745;

switch lower(funcname)
	case 'sincos'
		x=A_CIRC;
		y=0;
		z=funcarg;
		[x_ret, y_ret, z_ret]=cordic_circular(x, y, z, N_BITS, atan_table);
		val=[x_ret; y_ret];

	case 'log'
		x=funcarg+1;
		y=funcarg-1;
		z=0;
		[x_ret, y_ret, z_ret]=cordic_hyperbolic(x, y, z, N_BITS, atanh_table);
		val=2*z_ret;

	case 'sqrt'
		x=funcarg+0.25;
		y=funcarg-0.25;
		z=0;
		[x_ret, y_ret, z_ret]=cordic_hyperbolic(x, y, z, N_BITS, atanh_table);
		val=x_ret*A_HYPERB;

	otherwise
		val = 0;
		disp(sprintf('Unsupported CORDIC function %s', funcname));
end

% ----------------------------------------------------
% Circular Cordic
% ----------------------------------------------------
function [x_final, y_final, z_final]=cordic_circular(x, y, z, N, atan_table)

theta=1;

for i=1:N
	if (z >= 0)
		x_new=x-(y*theta);
		y_new=y+(x*theta);
		z_new=z-atan_table(i);
	else
		x_new=x+(y*theta);
		y_new=y-(x*theta);
		z_new=z+atan_table(i);
	end

	x=x_new;
	y=y_new;
	z=z_new;
	theta=theta/2;
end

x_final=x;
y_final=y;
z_final=z;


% ----------------------------------------------------
% Heyberbolic Cordic
% ----------------------------------------------------
function [x_final, y_final, z_final]=cordic_hyperbolic(x, y, z, N, atanh_table)

theta=0.5;
k=3;

for i=1:N
	for j=1:2
		% 2 repeated iterations for iteration #4, 7, ... 3n+1 where n=1..N_BITS-1
		% to ensure convergence for hyperbolic cordic
		if (y < 0)
			x_new=x+(y*theta);
			y_new=y+(x*theta);
			z_new=z-atanh_table(i);
		else
			x_new=x-(y*theta);
			y_new=y-(x*theta);
			z_new=z+atanh_table(i);
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

	theta=theta/2;
end

x_final=x;
y_final=y;
z_final=z;











