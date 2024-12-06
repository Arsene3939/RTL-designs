Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity module_test is
	port(
		rst,clk:in std_logic;
		ssd:buffer std_logic_vector(6 downto 0);
		digit:buffer std_logic_vector(3 downto 0);
		ssd2:buffer std_logic_vector(6 downto 0);
		digit2:buffer std_logic_vector(3 downto 0);
		RGB_LED:buffer std_logic_vector(2 downto 0);
		keyC:buffer std_logic_vector(3 downto 0);
		keyR:in std_logic_vector(3 downto 0);
		bigLED:buffer std_logic_vector(3 downto 0)
	);
end entity module_test;
architecture main of module_test is
	signal FD:std_logic_vector(50 downto 0);
	shared variable num,num2:integer range 0 to 9999:=8763;
	type arr is array(0 to 15) of std_logic_vector(3 downto 0);
	constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
	signal RGB_data:std_logic_vector(23 downto 0):=X"000001";
	signal key_state:std_logic_vector(3 downto 0);
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
	component parallel_RGBLED is
		port(
			rst,clk:in std_logic;
			LED:buffer std_logic_vector(2 downto 0);
			RGB_data:in std_logic_vector(23 downto 0)
		);
	end component parallel_RGBLED;
	component keyboard_scan is 
		port(
			clk:in std_logic;
			rst:in std_logic;
			scanning:buffer std_logic_vector(3 downto 0);
			reading:in std_logic_vector(3 downto 0);
			state:out std_logic_vector(3 downto 0)
		 );
	end component keyboard_scan;
begin
	bigLED<=key_state;
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	count:process(FD(15))
	begin
		if rst='0' then
			RGB_data<=X"000001";
		elsif rising_edge(FD(22))then
			RGB_data<=RGB_data(0)&RGB_data(23 downto 1);
		end if;
	end process;
	U0:seven_seg_display
		port map(
			cathed=>'0',
			rst=>rst,
			ck0=>clk,
			digit=>digit,
			ssd=>ssd,
			N4=>X"0",
			N3=>X"0",
			N2=>X"0",
			N1=>key_state
		);
	U1:seven_seg_display
		port map(
			cathed=>'0',
			rst=>rst,
			ck0=>clk,
			digit=>digit2,
			ssd=>ssd2,
			N4=>to_vector(num2/1000),
			N3=>to_vector((num2/100) mod 10),
			N2=>to_vector((num2/10)  mod 10),
			N1=>to_vector(num2       mod 10)
		);
	U2:parallel_RGBLED
		port map(
			rst=>rst,
			clk=>clk,
			LED=>RGB_LED,
			RGB_data=>RGB_data
		);
	U3:keyboard_scan
			port map(
				clk => clk,
				rst => rst,
				scanning => keyC,
				reading  => keyR,
				state => key_state
			);
end main;

	