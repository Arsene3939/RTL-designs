Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.std_logic_arith.all;
entity DHT11_test is
	port(
		rst,clk:in std_logic;
		ssd:buffer std_logic_vector(6 downto 0);
		digit:buffer std_logic_vector(3 downto 0);
		data:inout std_logic;
		LED:buffer std_logic_vector(15 downto 0)
	);
end entity DHT11_test;
architecture main of DHT11_test is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 15) of std_logic_vector(3 downto 0);
	shared variable num:integer range 0 to 255;
	constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
	signal HU,TE:std_logic_vector(7 downto 0);
	component seven_seg_display is
		port(
			cathed:in std_logic;
			rst:in std_logic;
			ck0:in std_logic;
			digit:buffer std_logic_vector(3 downto 0);
			ssd:buffer std_logic_vector(6 downto 0);
			N1:in std_logic_vector(3 downto 0);
			N2:in std_logic_vector(3 downto 0);
			N3:in std_logic_vector(3 downto 0);
			N4:in std_logic_vector(3 downto 0)
		);
	end component seven_seg_display;
	component DHT11 is
		port(
			clk_50M:in std_logic;
			nrst:in std_logic;
			dat_bus: inout std_logic;
			HU, TE:out std_logic_vector(7 downto 0)
     );
	end component DHT11;
begin
	LED(7 downto 0)<=TE;
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
			num:=conv_integer(TE);
		end if;
	end process fre;
	U0:seven_seg_display
		port map(
			cathed=>'0',
			rst=>rst,
			ck0=>clk,
			digit=>digit,
			ssd=>ssd,
			N4=>to_vector(num/1000),
			N3=>to_vector((num/100) mod 10),
			N2=>to_vector((num/10)  mod 10),
			N1=>to_vector(num       mod 10)
		);
	DHT11_decoder:DHT11
		port map(
			clk_50M=>clk,
			nrst=>rst,
			dat_bus=>data,
			HU=>HU,
			TE=>TE
		);
end main;

	