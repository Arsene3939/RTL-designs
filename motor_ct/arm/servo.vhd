library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity servo is
	port(
		clk,rst:in std_logic;
		sig:buffer std_logic;
		degree:in integer range 0 to 180;
		judge:in std_logic;
		enable:in std_logic
	);
end servo;
architecture main of servo is
	signal deg:integer range 30000 to 130000;
begin
	count:process(clk)
		variable cnt:integer range 0 to 1_000_000;
	begin
		if enable='0' then
			sig<='0';
		elsif rising_edge(clk)then
			cnt:=cnt+1;
			if cnt>deg then
				sig<='0';
			else
				sig<='1';
			end if;
			if cnt>1_000_000 then
				cnt:=0;
			end if;
		end if;
	end process;
	deg<=degree*500+30000 when judge='1' else 75000;
end main;
			