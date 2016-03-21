function urnd=tauss(seed_in, N)

s0=bitxor(seed_in, hex2dec('128617D1'));
s1=bitxor(seed_in, hex2dec('3A0E8247'));
s2=bitxor(seed_in, hex2dec('C5B9D11A'));

urnd=zeros(N,1);

for i=1:N
	b=bitshift(bitxor(bitshift(s0, 13, 'uint32'), s0), -19, 'uint32');
	s0=bitxor(bitshift(bitand(s0, hex2dec('FFFFFFFE')), 12, 'uint32'), b);

	b=bitshift(bitxor(bitshift(s1, 2, 'uint32'), s1), -25, 'uint32');
	s1=bitxor(bitshift(bitand(s1, hex2dec('FFFFFFF8')), 4, 'uint32'), b);
	
	b=bitshift(bitxor(bitshift(s2, 3, 'uint32'), s2), -11, 'uint32');
	s2=bitxor(bitshift(bitand(s2, hex2dec('FFFFFFF0')), 17, 'uint32'), b);
	
	urnd(i)=bitxor(s2, bitxor(s0, s1));
end

urnd=uint32(urnd);

