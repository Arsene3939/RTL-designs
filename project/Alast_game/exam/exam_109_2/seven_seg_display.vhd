Library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity seven_seg_display is
	port(
		rst,ck0:in std_logic;
		digit1,digit2:buffer std_logic_vector(3 downto 0);
		ssd1,ssd2:buffer std_logic_vector(7 downto 0);
		display_data:in std_logic_vector(31 downto 0);
		point:in integer range 0 to 7;
		cathed:in std_logic
	);
end entity seven_seg_display;
architecture main of seven_seg_display is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 15) of std_logic_vector(7 downto 0);
	signal number:arr:=(X"03",X"9F",X"25",X"0C",X"99",X"49",X"C1",X"1E",X"01",X"19",X"10",X"C0",X"62",X"84",X"60",X"70");
	signal addr:std_logic_vector(7 downto 0);
	signal ssd:std_logic_vector(6 downto 0);
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
				number<=(X"FC",X"60",X"DA",X"F3",X"66",X"B6",X"3E",X"E1",X"FE",X"E6",X"C6",X"9D",X"B6",X"CE",X"9F",X"00");
			else
				number<=(X"03",X"9F",X"25",X"0C",X"99",X"49",X"C1",X"1E",X"01",X"19",X"10",X"C0",X"62",X"84",X"60",X"70");
			end if;
		elsif rising_edge(FD(10))then
			ssd<=number(conv_integer(display_data(i*4+3 downto i*4)))(7 downto 1);
			if i=point then
				dot<='1';
			else
				dot<='0';
			end if;
			i:=i+1;
			if i>7 then
				i:=0;
			end if;
			addr<=addr(0)&addr(7 downto 1);
		end if;
	end process;
	digit1<=addr(3 downto 0);
	digit2<=addr(7 downto 4);
	ssd1<=ssd&dot;
	ssd2<=ssd&dot;
end main;

	