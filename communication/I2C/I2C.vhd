Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity I2C is
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
		SCL,SDA,SCLA:buffer std_logic;
		io:buffer std_logic_vector(3 downto 0);
		jo:buffer std_logic
	);
end entity I2C;
architecture main of I2C is
	signal FD:std_logic_vector(50 downto 0);
	signal countE:std_logic:='1';
	constant addr:std_logic_vector(7 downto 0):=X"4E";
	signal data:std_logic_vector(7 downto 0):=X"AA";
	type stad is array(0 to 15)of std_logic_vector(3 downto 0);
	constant to_usin:stad:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
	shared variable duce:integer:=0;
	signal sttp:std_logic;
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	sck:process(clk)
		variable i:integer range 0 to 1000:=0;
	begin
		if rising_edge(clk)then
			if i>1000 then
				i:=0;
				SCLA<=not SCLA;
			end if;
			i:=i+1;
			if countE='1'then
				SCL<=SCLA;
			else
				if sttp='1' then
					SCL<='1';
				elsif sttp='0' then
					SCL<='0';
				end if;
			end if;
		end if;
	end process;
	transmit:process(SCLA,FD(10),clk)
		variable i,j:integer range 0 to 17:=0;
	begin
		if falling_edge(SCLA)then
			if j=1 then
				if i=0 then
					countE<='1';
				end if;
				SDA<=addr(7-i);
				i:=i+1;
				if i=8 then
					SDA<='0';
					sttp<='0';
				end if;
				if i=10 then
					countE<='0';
					j:=0;
					i:=0;
				end if;
			elsif j=0 then
				if i=0 then
					countE<='1';
				end if;
				if i<8 then
					SDA<=data(7-i);
				end if;
				i:=i+1;
				if i=9 then
					SDA<='0';
					countE<='0';
				elsif i=10 then
					sttp<='1';
				elsif i=11 then
					SDA<='1';
				elsif i=12 then
					SDA<='0';
				elsif i=13 then
					sttp<='0';
					j:=1;
					i:=0;
				end if;
			end if;
			jo<=to_usin(j)(0);
			io<=to_usin(i);
		end if;
	end process;
	LED<=X"FFFF";
	ssd<="1111111";
end main;