library IEEE;
USE IEEE.std_logic_unsigned.all;
USE IEEE.std_logic_1164.all;
entity gurenka is
	port( clk,rst,speed,rstbz:in std_logic;
			bz,LED:buffer std_logic;
			S1,S2:in std_logic;
			DB_io:inout std_logic_vector(3 downto 0);
			RSo,RWo,Eo:out std_logic
	);
end gurenka;
architecture Albert of gurenka is
	component LCM_4bit_driver is
	port(LCM_CLK,LCM_RESET:in std_logic;
		 RS,RW:in std_logic;
		 DBi:in std_logic_vector(7 downto 0);
		 DBo:out std_logic_vector(7 downto 0);
		 DB_io:inout std_logic_vector(3 downto 0);
		 RSo,RWo,Eo:out std_logic;
		 LCMok,LCM_S:out boolean
		 );
	end component;
	signal LCM_RESET,RS,RW:std_logic;
	signal DBi,DBo:std_logic_vector(7 downto 0);
	signal LCMok,LCM_S:boolean;
	signal FD:std_logic_vector(25 downto 0);
	signal times:integer range 0 to 2047;
	type coula is array(0 to 40) of integer range 0 to 2047;
	constant songs:coula:=(100000,262,277,292,311,330,000,349,371,393,413,440,467,494,000,262*2,277*2,292*2,311*2,330*2,000,349*2,371*2,393*2,413*2,440*2,467*2,494*2,000,262*4,277*4,292*4
	,311*4,330*4,0000,349*4,371*4,393*4,413*4,440*4,220);
	type song is array(0 to 230)of integer;
	constant tosTone:song:=(
 0, 0,23,22,23, 0,23,22,23, 0, 9,23,22,19,17,17, 0,13,17,19, 0,19,23,25, 0,23,25,27, 0,
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
23,25,27,25, 0,25,25,25,27, 0
								);
	constant tosbeat:song:=(
 50,50,8, 6,20, 4, 8, 6,16, 4, 6, 8, 6,16, 4,20, 4, 8, 4,20, 2, 8, 4,20, 2, 8, 4,32,32,
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
 8, 4, 4,16, 2, 4, 8, 8,32,24);
	signal dive:integer range 0 to 50000000;
	signal trigg:std_logic;
	shared variable ton:integer:=20;
	shared variable beat:integer:=0;
	constant long:integer:=232;
--X"AC",X"F5",X"BD",X"AC",X"B5",X"D8",b'\n'
--X"A7",X"DA",X"AA",X"BE",X"B9",X"44",X"A6",X"70",X"A6",X"F3",X"C5",X"DC",X"B1",X"6A",X"AA",X"BA",X"B2",X"7A" ,X"A5",X"D1",X"A4",X"46",b'\n'
--X"A5",X"A6",X"A4",X"DE",X"BB",X"E2",X"A7",X"DA",X"A6",X"56",X"AB",X"65",X"C1",X"DA",X"B6",X"69",b'\n'
--X"A8",X"49",X"BE",X"4B",X"A6",X"62",X"AA",X"64",X"C0",X"D7",X"AA",X"BA",X"A8",X"AB",X"B0",X"A8",X"BF",X"4F" ,X"A4",X"A4",b'\n'
--X"C5",X"DC",X"B1",X"6F",X"BB",X"F8",X"B5",X"77",X"AA",X"BA",X"A4",X"DF",b'\n'
--X"A7",X"DA",X"A5",X"CE",X"C5",X"B8",X"A7",X"DD",X"AA",X"BA",X"A4",X"E2",X"B7",X"51",X"A7",X"EC",X"A6",X"ED" ,X"A8",X"C7",X"AC",X"C6",X"BB",X"F2",b'\n'
--X"B4",X"4E",X"A5",X"75",X"AC",X"4F",X"B3",X"6F",X"BC",X"CB",b'\n'
--X"B6",X"C2",X"A9",X"5D",X"AA",X"BA",X"AE",X"F0",X"A8",X"FD", X"BE",X"AE",X"B5",X"F8",X"B5",X"DB",X"A4",X"D1" ,X"AA",X"C5",b'\n'
--X"AF",X"E0",X"A7",X"EF",X"C5",X"DC",X"AA",X"BA",X"A5",X"75",X"A6",X"B3",X"A6",X"DB",X"A4",X"76",X"A6",X"D3" ,X"A4",X"77",b'\n'
--X"B4",X"4E",X"A5",X"75",X"AC",X"4F",X"B3",X"6F",X"BC",X"CB",b'\n'
--X"A7",X"DA",X"AA",X"BE",X"B9",X"44",X"A6",X"70",X"A6",X"F3",X"C5",X"DC",X"B1",X"6A",X"AA",X"BA",X"B2",X"7A" ,X"A5",X"D1",X"A4",X"46",b'\n'
--X"A5",X"A6",X"A4",X"DE",X"BB",X"E2",X"A7",X"DA",X"A6",X"56",X"AB",X"65",X"C1",X"DA",X"B6",X"69",b'\n'
--X"B5",X"4C",X"BD",X"D7",X"A6",X"70",X"A6",X"F3",b'\n'
--X"A4",X"B4",X"A6",X"B3",X"B5",X"4C",X"AA",X"6B",X"A9",X"D9",X"B7",X"C0",X"AA",X"BA",X"B9",X"DA",b'\n'
--X"A4",X"B4",X"A6",X"B3",X"B5",X"4C",X"AA",X"6B",X"B0",X"B1",X"A4",X"EE",X"AA",X"BA",X"B7",X"ED",X"A4",X"55"
--X"A6",X"FD",X"AD",X"59",X"A7",X"DA",X"AF",X"E0",X"AC",X"B0",X"A4",X"46",X"BD",X"D6",X"A6",X"D3",X"C5",X"DC" ,X"B1",X"6F",X"B1",X"6A",X"A4",X"6A",b'\n'
--X"B5",X"4C",X"BD",X"D7",X"B4",X"58",X"A6",X"B8",X"A7",X"DA",X"B3",X"A3",X"B7",X"7C",X"AF",X"B8",X"B0",X"5F" ,X"A8",X"D3",b'\n'
--X"B3",X"51",X"A5",X"40",X"AC",X"C9",X"AC",X"BD",X"AC",X"BD",X"A5",X"B4",X"C0",X"BB",b'\n'
--X"A7",X"DA",X"A9",X"FA",X"A5",X"D5",X"A5",X"A2",X"B1",X"D1",X"AA",X"BA",X"B7",X"4E",X"B8",X"71",b'\n'
--X"AC",X"F5",X"BD",X"AC",X"A4",X"A7",X"AA",X"E1",X"AA",X"FC",X"BA",X"EC",X"A9",X"F1",X"A7",X"61",b'\n'
--X"B7",X"D3",X"AB",X"47",X"A9",X"52",X"B9",X"42",X"A7",X"61",b'\n'
	type LCM_T is array (0 to 20) of std_logic_vector(7 downto 0);
	constant LCM_IT:LCM_T:=(X"0f",X"06",
							"00101000","00101000","00101000",
							"00000110","00001100","00000001",
							X"AC",X"F5",X"BD",X"AC",X"B5",X"D8",X"20",X"20",X"4C",X"49",X"53",X"41",X"20");
	signal LCM_IT_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"4C",X"49",X"53",X"41",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_0:LCM_T:=(X"15",X"01",
							"00000001",
							X"A7",X"DA",X"AA",X"BE",X"B9",X"44",X"A6",X"70",X"A6",X"F3",X"C5",X"DC",X"b1",X"6a",X"aa",X"ba",X"b2",X"7a");
	signal LCM_0_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"A5",X"D1",X"A4",X"46",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_1:LCM_T:=(X"15",X"01",
							"00000001",
							X"A5",X"A6",X"A4",X"DE",X"BB",X"E2",X"A7",X"DA",X"A6",X"56",X"AB",X"65",X"C1",X"DA",X"B6",X"69",X"20",X"20");
	signal LCM_2:LCM_T:=(X"15",X"01",
							"00000001",
							X"A8",X"49",X"BE",X"4B",X"A6",X"62",X"AA",X"64",X"C0",X"D7",X"AA",X"BA",X"A8",X"AB",X"B0",X"A8",X"BF",X"4F");
	signal LCM_2_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"A4",X"A4",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
   signal LCM_3:LCM_T:=(X"15",X"01",
							"00000001",
							X"C5",X"DC",X"B1",X"6F",X"BB",X"F8",X"B5",X"77",X"AA",X"BA",X"A4",X"DF",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_4:LCM_T:=(X"15",X"01",
							"00000001",
							X"A7",X"DA",X"A5",X"CE",X"C5",X"B8",X"A7",X"DD",X"AA",X"BA",X"A4",X"E2",X"B7",X"51",X"A7",X"EC",X"A6",X"ED");
	signal LCM_4_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"A8",X"C7",X"AC",X"C6",X"BB",X"F2",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_5:LCM_T:=(X"15",X"01",
							"00000001",
							X"B4",X"4E",X"A5",X"75",X"AC",X"4F",X"B3",X"6F",X"BC",X"CB",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_6:LCM_T:=(X"15",X"01",
							"00000001",
							X"B6",X"C2",X"A9",X"5D",X"AA",X"BA",X"AE",X"F0",X"A8",X"FD",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_6_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"BE",X"AE",X"B5",X"F8",X"B5",X"DB",X"A4",X"D1",X"AA",X"C5",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_7:LCM_T:=(X"15",X"01",
							"00000001",
							X"AF",X"E0",X"A7",X"EF",X"C5",X"DC",X"AA",X"BA",X"A5",X"75",X"A6",X"B3",X"A6",X"DB",X"A4",X"76",X"A6",X"D3");
	signal LCM_7_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"A4",X"77",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_8:LCM_T:=(X"15",X"01",
							"00000001",
							X"B4",X"4E",X"A5",X"75",X"AC",X"4F",X"B3",X"6F",X"BC",X"CB",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_9:LCM_T:=(X"15",X"01",
							"00000001",
							X"A7",X"DA",X"AA",X"BE",X"B9",X"44",X"A6",X"70",X"A6",X"F3",X"C5",X"DC",X"B1",X"6A",X"AA",X"BA",X"B2",X"7A");
	signal LCM_9_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"A5",X"D1",X"A4",X"46",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_10:LCM_T:=(X"15",X"01",
							"00000001",
							X"A5",X"A6",X"A4",X"DE",X"BB",X"E2",X"A7",X"DA",X"A6",X"56",X"AB",X"65",X"C1",X"DA",X"B6",X"69",X"20",X"20");
	signal LCM_11:LCM_T:=(X"15",X"01",
							"00000001",
							X"B5",X"4C",X"BD",X"D7",X"A6",X"70",X"A6",X"F3",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_12:LCM_T:=(X"15",X"01",
							"00000001",
							X"A4",X"B4",X"A6",X"B3",X"B5",X"4C",X"AA",X"6B",X"A9",X"D9",X"B7",X"C0",X"AA",X"BA",X"B9",X"DA",X"20",X"20");
	signal LCM_13:LCM_T:=(X"15",X"01",
							"00000001",
							X"A4",X"B4",X"A6",X"B3",X"B5",X"4C",X"AA",X"6B",X"B0",X"B1",X"A4",X"EE",X"AA",X"BA",X"B7",X"ED",X"A4",X"55");
	signal LCM_14:LCM_T:=(X"15",X"01",
							"00000001",
							X"A6",X"FD",X"AD",X"59",X"A7",X"DA",X"AF",X"E0",X"AC",X"B0",X"A4",X"46",X"BD",X"D6",X"A6",X"D3",X"C5",X"DC");
	signal LCM_14_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"B1",X"6F",X"B1",X"6A",X"A4",X"6A",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_15:LCM_T:=(X"15",X"01",
							"00000001",
							X"B5",X"4C",X"BD",X"D7",X"B4",X"58",X"A6",X"B8",X"A7",X"DA",X"B3",X"A3",X"B7",X"7C",X"AF",X"B8",X"B0",X"5F");
	signal LCM_15_0:LCM_T:=(X"15",X"01",
							"10010000",
							X"A8",X"D3",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_16:LCM_T:=(X"15",X"01",
							"00000001",
							X"B3",X"51",X"A5",X"40",X"AC",X"C9",X"AC",X"BD",X"AC",X"BD",X"A5",X"B4",X"C0",X"BB",X"20",X"20",X"20",X"20");
	signal LCM_17:LCM_T:=(X"15",X"01",
							"00000001",
							X"A7",X"DA",X"A9",X"FA",X"A5",X"D5",X"A5",X"A2",X"B1",X"D1",X"AA",X"BA",X"B7",X"4E",X"B8",X"71",X"20",X"20");
	signal LCM_18:LCM_T:=(X"15",X"01",
							"00000001",
							X"AC",X"F5",X"BD",X"AC",X"A4",X"A7",X"AA",X"E1",X"AA",X"FC",X"20",X"20",X"BA",X"EC",X"A9",X"F1",X"A7",X"61");
	signal LCM_19:LCM_T:=(X"15",X"01",
							"00000001",
							X"B7",X"D3",X"AB",X"47",X"A9",X"52",X"B9",X"42",X"A7",X"61",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");
	signal LCM_com_data,LCM_com_data2:LCM_T;
	signal LCM_INI:integer range 0 to 31;
	signal LCMP_RESET,LN,LCMPok:std_logic;
	signal LCM,LCMx:integer range 0 to 32;
	
	signal S2S,S1S:std_logic_vector(2 downto 0);
begin
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);
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
		if rstbz='0'then
			i:=0;
			trigg<='0';
			ton:=songs(0);
		elsif rising_edge(FD(17+n))then
			beat:=beat+1;
			if beat>2*tosbeat(i-1)-1 then
				ton:=songs(0);
				if beat>2*tosbeat(i-1)then
					if i=2 or i=9 or i=16 or i=22 or i=29 or i=36 or i=44 or i=47 or i=51 or i=60 or i=70 or i=72 or i=75 or i=83 or i=91 or i=99 or i=107 or i=110 or i=114 or i=121 or i=128 or i=134 or i=140 or i=141 or i=143 or i=146 or i=150 or i=155 or i=160 or i=168 or i=176 or i=181 or i=187 or i=192 or i=197 or i=202 or i=208 or i=214 or i=221 or i=231 or i=230 or i=229 then
						trigg<=not trigg;
					end if;
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
C_LCD_P:process(FD(25))
begin
	if rst='0' then
		LCM<=0;
		LCMP_RESET<='0';
	elsif rstbz='0' then
			LCM<=0;
	elsif rising_edge(trigg) then
		LCMP_RESET<='1';
		if LCMPok='1' then
			if LCM<20 then
				LCM<=LCM+1;
			else 
				LCM<=0;
			end if;
		end if;
	end if;
end process C_LCD_P;
LCM_P:process(FD(0))
	variable SW:Boolean;
begin
	if LCM/=LCMx or LCMP_RESET='0' then
		LCMx<=LCM;
		LCM_RESET<='0';
		LCM_INI<=2;
		LN<='0';
		case LCM is
			when 0=>
				LCM_com_data<=LCM_IT;	
				LCM_com_data2<=LCM_IT_0;
				LN<='1';
			when 1=>
				LCM_com_data<=LCM_0;
				LCM_com_data2<=LCM_0_0;			
				LN<='1';
			when 2=>
				LCM_com_data<=LCM_1;	
			when 3=>
				LCM_com_data<=LCM_2;	
				LCM_com_data2<=LCM_2_0;
			when 4=>
				LCM_com_data<=LCM_3;	
			when 5=>
				LCM_com_data<=LCM_4;--*
				LCM_com_data2<=LCM_4_0;			
				LN<='1';	
			when 6=>
				LCM_com_data<=LCM_5;	
			when 7=>
				LCM_com_data<=LCM_6;--*
				LCM_com_data2<=LCM_6_0;			
				LN<='1';
			when 8=>
				LCM_com_data<=LCM_7;--*
				LCM_com_data2<=LCM_7_0;			
				LN<='1';
			when 9=>
				LCM_com_data<=LCM_8;	
			when 10=>
				LCM_com_data<=LCM_9;--*
				LCM_com_data2<=LCM_9_0;			
				LN<='1';
			when 11=>
				LCM_com_data<=LCM_10;	
			when 12=>
				LCM_com_data<=LCM_11;	
			when 13=>
				LCM_com_data<=LCM_12;	
			when 14=>
				LCM_com_data<=LCM_13;
			when 15=>
				LCM_com_data<=LCM_14;--*
				LCM_com_data2<=LCM_14_0;			
				LN<='1';	
			when 16=>
				LCM_com_data<=LCM_15;	
				LCM_com_data2<=LCM_15_0;			
				LN<='1';	
			when 17=>
				LCM_com_data<=LCM_16;	
			when 18=>
				LCM_com_data<=LCM_17;	
			when 19=>
				LCM_com_data<=LCM_18;	
			when others =>
				LCM_com_data<=LCM_19;	
		end case;
		LCMPok<='0';					
		SW:=False;						
	elsif rising_edge(FD(0)) then
		if SW then
			LCM_RESET<='1';
			SW:=False;
		elsif LCM_RESET='1' then
			if LCMok then
				LCM_RESET<='0';
			end if;
		elsif LCM_INI<LCM_com_data(0) and LCM_INI<LCM_com_data'length then
			if LCM_INI<=(LCM_com_data(1)+1) then
				RS<='0';
			else
				RS<='1';	
			end if;
			RW<='0';		
			DBi<=LCM_com_data(LCM_INI);
			LCM_INI<=LCM_INI+1;
			SW:=True;
		else
			if LN='1' then
				LN<='0';
				LCM_INI<=2;
				LCM_com_data<=LCM_com_data2;
			else
				LCMPok<='1';
			end if;
		end if;
	end if;
end process LCM_P;
process(FD(17))
begin
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	if S2='1' then
		S2S<="000";
	elsif rising_edge(FD(17)) then
		S2S<=S2S+ not S2S(2);
	end if;
end process;
Freq_Div:process(clk)
begin
	if rst='0' then
		FD<=(others=>'0');
	elsif rising_edge(clk) then
		FD<=FD+1;
	end if;
end process Freq_Div;
end Albert;
Library IEEE;
Use IEEE.std_logic_1164.all;
Use IEEE.std_logic_unsigned.all;
entity LCM_4bit_driver is
	port(LCM_CLK,LCM_RESET:in std_logic;
		 RS,RW:in std_logic;
		 DBi:in std_logic_vector(7 downto 0);
		 DBo:out std_logic_vector(7 downto 0);
		 DB_io:inout std_logic_vector(3 downto 0);
		 RSo,RWo,Eo:out std_logic;
		 LCMok,LCM_S:out boolean
		);
end LCM_4bit_driver;
architecture Albert of LCM_4bit_driver is
	signal RWS,BF:std_logic;			
	signal LCMruns:std_logic_vector(3 downto 0);
	signal DBii:std_logic_vector(3 downto 0);
	signal Timeout:integer range 0 to 256;
begin
RWo<=RWS;
DB_io<=DBii when RWS='0' else "ZZZZ";
LCM_4BIT_OUT:process(LCM_CLK,LCM_RESET)
begin
	if LCM_RESET='0' then
		DBo<=(DBo'Range=>'0');
		DBii<=DBi(7 downto 4);
		RSo<=RS;
		BF<='1';
		RWs<=RW;
		Eo<='0';
		LCMok<=False;
		LCM_S<=False;	----
		LCMruns<="0000";
		Timeout<=0;
	elsif Rising_Edge(LCM_CLK) then
		case LCMruns is
			when "0000"=>
				Eo<='1';
				LCMruns<="0001";
			when "0001"=>
				Eo<='0';
				if RW='1' then
					DBo(7 downto 4)<=DB_io;
				end If;
				LCMruns<="101" & RWS;
			when "1010"=>
				DBii<=DBi(3 downto 0);
				LCMruns<="1011";
			when "1011"=>
				Eo<='1';
				LCMruns<="0011";
			when "0011"=>
				if RW='1' then
					DBo(3 downto 0)<=DB_io;
				end If;
				Eo<='0';
				LCMruns<="1000";
			when "1100"=>
				Eo<='1';
				LCMruns<="0110";
			when "0110"=>
				Eo<='0';
				BF<=DB_io(3);
				LCMruns<="0111";
			when "0111"=>
				Eo<='1';
				LCMruns<="1000";
			when "1000"=>
				Timeout<=Timeout+1;
				if RS='0' then
					if DBi=1 then
						if Timeout=220 then
							LCMruns<="0100";
						end if;
					elsif Timeout=2 then
						LCMruns<="0100";
					end if;
				elsif Timeout=5 then
					LCM_S<=true;
					LCMruns<="0100";
				else
					LCMruns<=BF & "100";
				end if;
				Eo<='0';
				RSo<='0';
				RWS<='1';
			when others=>
				LCMok<=True;
		end case;
	end if;
end process LCM_4BIT_OUT;
end Albert;