Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.std_logic_arith.all;
entity pwm is
	port(
		rst,clk:in std_logic;
		pin1,pin2:buffer std_logic;
		duty:in integer range 0 to 10;
		motor_dir:in std_logic
	);
end entity pwm;
architecture main of pwm is
	signal FD:std_logic_vector(12 downto 0);
begin
	fre:process(rst,clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	pwm:process(FD(12))
		variable n:integer range 0 to 10:=0;
	begin
		if rising_edge(FD(12)) then
			if motor_dir='1' then
				pin2<='0';
				if duty>n then
					pin1<='1' ;
				else
					pin1<='0';
				end if;
			else
				pin1<='0';
				if duty>n then
					pin2<='1' ;
				else
					pin2<='0';
				end if;
			end if;
			n:=n+1;
			if n>10 then
				n:=0;
			end if;
		end if;
	end process;
end main;

	

	