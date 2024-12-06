library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity servo_test is
	port(
		clk,rst:in std_logic;
		dipsw1,dipsw2:in std_logic;
		sig:buffer std_logic;
		LED:buffer std_logic_vector(15 downto 0)
	);
end servo_test;
architecture main of servo_test is
	signal FD:std_logic_vector(30 downto 0);
	signal deg:integer range 0 to 180;
	component servo is
		port(
			clk,rst:in std_logic;
			sig:buffer std_logic;
			degree:in integer range 0 to 180;
			judge:in std_logic;
			enable:in std_logic
		);
	end component;
begin
	LED(1 downto 0)<=not dipsw1&dipsw2;
	deg<=0 when FD(26)='1' else 180;
	fre:process(clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process;
	u0:servo
		port map(
			clk=>clk,
			rst=>rst,
			judge=>dipsw1,
			enable=>dipsw2,
			degree=>deg
		);
end main;