close all; clear all; clc;

N=10000;

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

	u0=double(u0_int)/(2^48);
	u1=double(u1_int)/(2^16);

	e=-2*log(u0);
	f=sqrt(e);
	g0=sin(2*pi*u1);
	g1=cos(2*pi*u1);
	x0=f*g0;
	x1=f*g1;

	x0_array(i)=x0;
	x1_array(i)=x1;
end

x=[x0_array; x1_array];
x=x(:);
