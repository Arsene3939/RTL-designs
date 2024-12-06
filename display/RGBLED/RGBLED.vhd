library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity RGBLED is
	port(
		clk,rst:in std_logic;
		Do:out std_logic;
		A0:out std_logic_vector(7 downto 0)
	);
end RGBLED;
architecture main of RGBLED is
	component serialRGBLED is
		generic(N:integer range 0 to 255:=6);
		port(
			clk,rst:in std_logic;
			Do:out std_logic;
			busy:out std_logic;
			ena,RW:in std_logic;
			addr:in std_logic_vector(7 downto 0);
			color_bus:in std_logic_vector(23 downto 0);
			dbg:out std_logic_vector(7 downto 0)
		);
	end component serialRGBLED;
	signal FD:std_logic_vector(30 downto 0);
	signal busy,ena,RW:std_logic;
	signal addr:std_logic_vector(7 downto 0);
	signal color_bus:std_logic_vector(23 downto 0):=X"800000";
begin
	A0<=addr;
	fre:process(clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process;
	onuse:process(FD(25))
		variable fsm:integer range 0 to 1:=0;
	begin
		if rst='0' then
			RW<='0';
			ena<='0';
		elsif rising_edge(FD(20))then
			if fsm=0 then
				if busy='0' then
					addr<="00000"&conv_std_logic_vector(conv_integer(FD(25 downto 23))mod 6,3);
					color_bus<=color_bus(22 downto 0)&color_bus(23);
					RW<='1';
					ena<='1';
					fsm:=1;
				else
					fsm:=0;
				end if;
			elsif fsm=1 then
				RW<='0';
				ena<='0';
				fsm:=0;
			end if;
		end if;
	end process;
	u0:serialRGBLED
		port map(
			clk=>clk,
			rst=>rst,
			Do=>Do,
			busy=>busy,
			ena=>ena,
			RW=>RW,
			addr=>addr,
			color_bus=>color_bus
		);
end main;