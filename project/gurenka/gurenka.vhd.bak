library IEEE;
USE IEEE.std_logic_unsigned.all;
USE IEEE.std_logic_1164.all;
entity buzzer is
	port(clk,rst,speed:in std_logic;
			bz,LED:buffer std_logic);
end;
architecture song of buzzer is
	type coula is array(0 to 40) of integer range 0 to 2047;
	constant songs:coula:=(100000,262,277,292,311,330,000,349,371,393,413,440,467,494,000,262*2,277*2,292*2,311*2,330*2,000,349*2,371*2,393*2,413*2,440*2,467*2,494*2,000,262*4,277*4,292*4
	,311*4,330*4,0000,349*4,371*4,393*4,413*4,440*4,220);
	type song is array(0 to 228)of integer;
	constant tosTone:song:=(
23,22,23, 0,23,22,23, 0, 9,23,22,19,17,17, 0,13,17,19, 0,19,23,25, 0,23,25,27, 0,
19,23,22,17,19,17, 0,11, 9, 9,11,15,13, 5, 0,
 5, 9,11,13,11,13,17,19,23,22, 0,17,19,17,19,19,19,27,25,27,25,27,29,27,23, 0,
23,22,22,23,25, 0,23,25,23,19,23,27,25, 0,23,25,23,19,23,31, 0,
23,25,23,19,23,27,25, 0,25,27,25,27,31,27,25,23, 0,23,22,22,23,25, 0,
23,22,23, 0,23,22,23, 0, 9,23,22,19,17,17, 0,13,17,19, 0,19,23,25, 0,23,25,27,
17,17,27,25,27,31,27,25,27,27, 0,23,25,27,31,27,25,27,27, 0,
17,17,23,23,17,17,23,25,23,31,29,27,25,23,23, 0,
23,25,27,25, 0,18,25,27,31,27, 0,
17,17,27,25,27,31,27,25,27,27, 0,23,23,25,27,31,27,25,27,23, 0,
23,23,25,27,27,37,36,31,27,25,23,23, 0,
23,25,27,25, 0,17,17, 0,19, 0
								);
	constant tosbeat:song:=(
 8, 6,20, 4, 8, 6,16, 4, 6, 8, 6,16, 4,20, 4, 8, 4,20, 2, 8, 4,20, 2, 8, 4,32,32,
 8, 6, 8, 4, 4,16, 4, 4, 2, 2, 4, 4, 6,24, 4,
 4, 2, 4, 6, 4, 4, 4, 6, 6, 6, 2, 4, 4,12, 4, 2, 2, 2, 2, 2, 2, 4, 4, 6,20, 4,
 8, 6, 6, 4, 8, 4, 8, 6, 6, 6, 6, 8,12, 8, 4, 6, 6, 6, 6,20,16,
 4, 6, 6, 6, 6, 6, 6, 8, 4, 4, 4, 4, 4, 4, 6,10, 2, 4, 6, 6, 4, 8, 4,
 8, 6,20, 4, 8, 6,16, 4, 4, 6, 6,16, 4,20, 4, 8, 4,16, 4, 8, 4,16, 4, 8, 4,32,
 8, 8, 8, 4, 4, 4, 4, 4, 2, 2, 4, 4, 4, 4, 4, 4, 4, 2, 2, 4,
 4, 4, 2, 6, 4, 4, 4, 4, 4, 8, 8, 6, 6, 4, 8, 4,
 8, 4, 4, 4, 8, 4, 8, 4, 4,32, 8,
 8, 8, 8, 4, 4, 4, 4, 4, 2, 2, 4, 2, 2, 4, 4, 4, 4, 4, 2, 2, 4,
 4, 6, 6, 8, 4, 4,12, 8, 6, 6, 4, 6, 8,
 8, 4, 4,16, 2, 4, 4, 2, 8,50);
	signal FD:std_logic_vector(24 downto 0);
	signal dive:integer range 0 to 5000000;
	shared variable ton:integer:=20;
	shared variable beat:integer:=0;
	constant long:integer:=229;
begin
	Freq_Div:process(clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk) then	
			FD<=FD+1;					
		end if;
	end process Freq_Div;
	tone:process(clk)
	begin
		if rising_edge(clk)then
			dive<=dive+1;
			if dive*ton>=50000000 then
				dive<=0;
				bz<=not bz;
				LED<=bz;
			end if;
		end if;
	end process tone;
	upp:process(FD(19))
		variable i:integer:=0;
		variable n:integer:=1;
	begin
		if speed='0'then
			n:=0;
		else 
			n:=2;
		end if;
		if rst='0'then
			i:=0;
			ton:=songs(0);
		elsif rising_edge(FD(17+n))then
			beat:=beat+1;
			if beat>2*tosbeat(i-1)-1 then
				ton:=songs(0);
				if beat>2*tosbeat(i-1)then
					ton:=songs(tosTone(i));	
					beat:=0;
					i:=i+1;
				end if;
				if i>long then
					i:=0;
				end if;
			end if;
		end if;
	end process upp;
end song;