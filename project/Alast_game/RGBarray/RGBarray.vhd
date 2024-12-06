Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
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
		RS,RW,EA:buffer std_logic;
		R,G,B:buffer std_logic;
		cross:buffer std_logic_vector(3 downto 0);
		sck:buffer std_logic;
		OE,LE:buffer std_logic;
		io,jo:buffer std_logic_vector(3 downto 0)
	);
end entity RGBarray;
architecture main of RGBarray is
	signal FD:std_logic_vector(50 downto 0);
	type converter is array(0 to 15) of std_logic_vector(3 downto 0);
	constant conv:converter:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
	signal RGBdata:std_logic_vector(47 downto 0):=X"111122224444";
	type LEDarray is array(0 to 15) of std_logic_vector(47 downto 0);
	constant data:LEDarray:=(X"000000000000",X"A663A0600000",X"EA94E0900000",X"A692A0900000",X"AA91A0900000",X"460640000000",X"000000000000",X"000000000000",X"000000000000",X"000000000000",X"492940200000",X"A955A0500000",X"A953A0500000",X"4B2540200000",X"050900000000",X"000100000000");
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	display:process(sck)
		variable i,j:integer range 0 to 16:=0;
	begin
		if falling_edge(sck)then
			RGBdata<=data(j);
			R<=RGBdata(i+32);
			G<=RGBdata(i+16);
			B<=RGBdata(i);
			cross<=conv(j);
			jo<=cross;
			io<=conv(i);
			i:=i+1;
			if i=15 then
				OE<='1';
				j:=j+1;
			elsif i>15 then
				i:=0;
				LE<='1';
				OE<='0';
				if j>15 then
					j:=0;
				end if;
			else
				LE<='0';
			end if;
		end if;
	end process;
	sck<=FD(7);
	LED<=X"FFFF";
end main;

	