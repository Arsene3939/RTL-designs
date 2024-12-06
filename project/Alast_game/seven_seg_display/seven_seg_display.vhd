Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity seven_seg_display is
	port(
		rst,ck0:in std_logic;
		digit:buffer std_logic_vector(3 downto 0);
		ssd:buffer std_logic_vector(6 downto 0);
		N1,N2,N3,N4:in std_logic_vector(3 downto 0);
		cathed:in std_logic
	);
end entity seven_seg_display;
architecture main of seven_seg_display is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 15) of std_logic_vector(7 downto 0);
	signal number:arr:=(X"03",X"9F",X"25",X"0C",X"99",X"49",X"C1",X"1E",X"01",X"19",X"10",X"C0",X"62",X"84",X"60",X"70");
	type fsd is array(0 to 3) of std_logic_vector(3 downto 0);
	signal N:fsd;
begin
	fre:process(ck0)
	begin
		if rising_edge(ck0)then
			FD<=FD+1;
		end if;
	end process fre;
	display:process(FD(10),rst)
		variable i:integer range 0 to 3:=0;
		variable muxer:std_logic_vector(3 downto 0);
	begin
		if rst='0' then
			digit<="1110";
			i:=0;
			if cathed='0' then
				number<=(X"FC",X"60",X"DA",X"F3",X"66",X"B6",X"3E",X"E1",X"FE",X"E6",X"EF",X"3F",X"9D",X"7B",X"9F",X"8F");
			else
				number<=(X"03",X"9F",X"25",X"0C",X"99",X"49",X"C1",X"1E",X"01",X"19",X"10",X"C0",X"62",X"84",X"60",X"70");
			end if;
		elsif rising_edge(FD(10))then
			muxer:=N(i);
			case muxer is
				when X"0" => ssd<=number(0)(7 downto 1);
				when X"1" => ssd<=number(1)(7 downto 1);
				when X"2" => ssd<=number(2)(7 downto 1);
				when X"3" => ssd<=number(3)(7 downto 1);
				when X"4" => ssd<=number(4)(7 downto 1);
				when X"5" => ssd<=number(5)(7 downto 1);
				when X"6" => ssd<=number(6)(7 downto 1);
				when X"7" => ssd<=number(7)(7 downto 1);
				when X"8" => ssd<=number(8)(7 downto 1);
				when X"9" => ssd<=number(9)(7 downto 1);
				when X"A" => ssd<=number(10)(7 downto 1);
				when X"B" => ssd<=number(11)(7 downto 1);
				when X"C" => ssd<=number(12)(7 downto 1);
				when X"D" => ssd<=number(13)(7 downto 1);
				when X"E" => ssd<=number(14)(7 downto 1);
				when X"F" => ssd<=number(15)(7 downto 1);
			end case;
			i:=i+1;
			digit<=digit(0)&digit(3 downto 1);
			if i>3 then
				i:=0;
			end if;
		end if;
	end process;
	N<=(N1,N2,N3,N4);
end main;

	