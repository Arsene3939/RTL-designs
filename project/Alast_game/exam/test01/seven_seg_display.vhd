Library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity seven_seg_display is
	port(
		rst,ck0:in std_logic;
		digit1,digit2:buffer std_logic_vector(3 downto 0);
		ssd1,ssd2:buffer std_logic_vector(7 downto 0);
		display_data:in std_logic_vector(63 downto 0);
		point:in integer range 0 to 7;
		cathed:in std_logic
	);
end entity seven_seg_display;
architecture main of seven_seg_display is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 23) of std_logic_vector(7 downto 0);
	signal number:arr:=(X"FC",X"60",X"DA",X"F2",X"66",X"B6",X"BE",X"E1",X"FE",X"E6",X"9E",X"8E",X"E1",X"FE",X"FC",X"E1",X"6E",X"CE",X"1C",X"EE",X"4E",X"00",X"01",X"7C");
	signal addr:std_logic_vector(7 downto 0);
	signal ssd:std_logic_vector(7 downto 0);
	signal dot:std_logic;
begin
	fre:process(ck0)
	begin
		if rising_edge(ck0)then
			FD<=FD+1;
		end if;
	end process fre;
	display:process(FD(10),rst)
		variable i:integer range 0 to 15:=0;
		variable muxer:std_logic_vector(3 downto 0);
	begin
		if rst='0' then
			addr<="11111110";
			i:=0;
			if cathed='0' then
				number<=(X"FC",X"60",X"DA",X"F2",X"66",X"B6",X"BE",X"E1",X"FE",X"E6",X"9E",X"8E",X"E1",X"FE",X"FC",X"E1",X"6E",X"CE",X"1C",X"EE",X"4E",X"00",X"01",X"7C");
				--			0     1     2     3     4     5     6     7     8     L     E     F     T     B     O     T     H     P     L     A     Y   '  '  .
																			--    9     A     B     C     D     E	  F    10    11    12    13    14    15   16     17
			end if;
		elsif rising_edge(FD(10))then
			ssd<=number(conv_integer(display_data(i*8+7 downto i*8)))(7 downto 0);
			i:=i+1;
			if i>7 then
				i:=0;
			end if;
			addr<=addr(0)&addr(7 downto 1);
		end if;
	end process;
	digit1<=addr(3 downto 0);
	digit2<=addr(7 downto 4);
	ssd1<=ssd;
	ssd2<=ssd;
end main;

	