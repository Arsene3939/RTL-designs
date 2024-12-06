Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.numeric_std.all;
entity uart is
	port(
		rst,clk:in std_logic;
		TX:buffer std_logic;
		RX:in std_logic;
		countE1:buffer std_logic;
		T_SBUF:in  std_logic_vector(7 downto 0);
		R_SBUF:out std_logic_vector(7 downto 0)
	);
end entity uart;
architecture main of uart is
	signal FD:std_logic_vector(50 downto 0);
	signal uck1,uck2:std_logic;
	signal countE2:std_logic;
	signal outserial,inserial:std_logic_vector(9 downto 0);
	signal ii2:integer range 0 to 10:=0;
	type arr1 is array(0 to 15) of std_logic_vector(3 downto 0);
	constant conv:arr1:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	baud:process(clk)
		variable i1,i2:integer range 0 to 50000001;
	begin
		if rising_edge(clk)then
			i2:=i2+1;
			if countE1='1'then	
				i1:=i1+1;
				if i1*9600>25000000 then
					uck1<=not uck1;
					i1:=0;
				end if;
			else uck1<='0';
			end if;
			if i2*9600>25000000 then
				uck2<=not uck2;
				i2:=0;
			end if;
		end if;
	end process;
	Receive:process(uck1,RX,countE1)
		variable ii1:integer range 0 to 16:=0;
	begin
		if RX='0' and countE1='0' then
			countE1<='1';
		elsif countE1<='1' and ii1=10 then
			countE1<='0';
		end if;
		if countE1='0' and RX='1' then
			ii1:=0;
		elsif rising_edge(uck1)then
			if ii1>=10 then
				ii1:=0;
			end if;
			if ii1>0 then
				inserial(ii1-1)<=RX;
			end if;
			ii1:=ii1+1;
		end if;
	end process;
	transmit:process(uck2,FD(24),ii2)
	begin
		if rising_edge(uck2) and countE2='1'then
			outserial<='1'&T_SBUF&'0';
			if ii2<10 then
				TX<=outserial(ii2);
			end if;
			ii2<=ii2+1;
		end if;
		if ii2=11	then
			countE2<='0';
			ii2<=0;
		elsif rising_edge(FD(24))then
			countE2<='1';
		end if;
	end process;
	R_SBUF<=inserial(7 downto 0);
end main;