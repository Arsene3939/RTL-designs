Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.std_logic_arith.all;
entity parallel_RGBLED is
	port(
		rst,clk:in std_logic;
		LED:buffer std_logic_vector(2 downto 0);
		RGB_data:in std_logic_vector(23 downto 0)
	);
end entity parallel_RGBLED;
architecture main of parallel_RGBLED is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 2)of integer range 0 to 255;
	signal state:arr:=(0,0,0);
begin
	fre:process(rst,clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	pwm:process(FD(20))
		variable n:integer range 0 to 256:=0;
	begin
		if rising_edge(FD(3)) then
			if state(0)>n	then
				LED(0)<='1';
			else
				LED(0)<='0';
			end if;
			if state(1)>n then
				LED(1)<='1';
			else
				LED(1)<='0';
			end if;
			if state(2)>n then
				LED(2)<='1';
			else
				LED(2)<='0';
			end if;
			n:=n+1;
		end if;
	end process;
	state(2)<=conv_integer(RGB_data(23 downto 16));
	state(1)<=conv_integer(RGB_data(15 downto 8));
	state(0)<=conv_integer(RGB_data(7 downto 0));
end main;

	

	