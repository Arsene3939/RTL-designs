Library ieee;
Use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity RGBarray is
	port(
		rst,clk:in std_logic;
		S:in std_logic_vector(7 downto 0);
		KeyC:in std_logic_vector(3 downto 0);
		KeyR:buffer std_logic_vector(3 downto 0);
		LED:buffer std_logic_vector(15 downto 0);
		bz:buffer std_logic;
		ssd:buffer std_logic_vector(6 downto 0);
		digit:buffer std_logic_vector(3 downto 0);
		Do:buffer std_logic;
		DBo:buffer std_logic_vector(7 downto 0);
		RS,RW,EA:buffer std_logic
	);
end entity RGBarray;
architecture main of RGBarray is
	signal FD:std_logic_vector(50 downto 0);
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
end main;

	