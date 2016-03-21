close all; clear all; clc;

rndval=rand(112, 1)*(2*pi);
idxmax=find(rndval > (2*pi));
rndval(idxmax)=(2*pi);

rndval_fixed=round(rndval.*(2^48));

fid=fopen('sincos_in.txt', 'w');
fprintf(fid, '56''sd%d\n', rndval_fixed);
fclose(fid);

fid=fopen('sincos_rtl_in.txt', 'w');
for i=1:length(rndval_fixed)
	fprintf(fid, '%s\n', dec2bin(rndval_fixed(i), 56));
end
fclose(fid);

fid=fopen('sin_out.txt', 'w');
for i=1:length(rndval_fixed)
	z1=cordic_fixedpt('sin', rndval_fixed(i), 'fixed');
	fprintf(fid, '%d\n', z1);
end
fclose(fid);


fid=fopen('cos_out.txt', 'w');
for i=1:length(rndval_fixed)
	z1=cordic_fixedpt('cos', rndval_fixed(i), 'fixed');
	fprintf(fid, '%d\n', z1);
end
fclose(fid);










