Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity TSL2561_test is
	port(
		rst,clk:in std_logic;
		ssd:buffer std_logic_vector(6 downto 0);
		digit:buffer std_logic_vector(3 downto 0);
		TSLSDA,TSLSCL:inout std_logic;
		LED:buffer std_logic_vector(15 downto 0)
	);
end entity TSL2561_test;
architecture main of TSL2561_test is
	signal FD:std_logic_vector(50 downto 0);
	shared variable num:integer range 0 to 9999 :=0;
	type arr is array(0 to 15) of std_logic_vector(3 downto 0);
	constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
	signal TSL2561_data:std_logic_vector(19 downto 0);
	component TSL2561 is
		port(
	  		clk_50M:in std_logic;
     		nrst:in std_logic;
     		sda       : INOUT  STD_LOGIC;                   --TSL2561 IIC SDA(161)
     		scl       : INOUT  STD_LOGIC;                   --TSL2561 IIC SCL(160)                                                             
     		TSL2561_data : OUT  std_logic_vector(19 downto 0)
		 );
	end component TSL2561;
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
	begin
	LED<=TSL2561_data(15 downto 0);
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	U0:seven_seg_display
	port map(
		cathed=>'0',
		rst=>rst,
		ck0=>clk,
		digit=>digit,
		ssd=>ssd,
		N4=>TSL2561_data(15 downto 12),
		N3=>TSL2561_data(11 downto 8),
		N2=>TSL2561_data(7 downto 4),
		N1=>TSL2561_data(3 downto 0)
	);
	U1:TSL2561
		port map(
			clk_50M=>clk,
     		nrst=>rst,
			sda=>TSLSDA,
     		scl=>TSLSCL,
     		TSL2561_data =>TSL2561_data
		);
end main;

	