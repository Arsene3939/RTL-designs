library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
entity LCD12864 is
	port(
		clk,rst:in std_logic;
		SCK,SDA,CS:buffer std_logic;
		LED_inveter:buffer std_logic_vector(15 downto 0);
		RX:in std_logic;
		A0,B0:out std_logic_vector(7 downto 0)
	);
end LCD12864;
architecture main of LCD12864 is
	component uart is 
		port(
			rst,clk:in std_logic;
			TX:buffer std_logic;
			RX:in std_logic;
			countE1:buffer std_logic;
			trigger:in std_logic;
			T_SBUF:in  std_logic_vector(7 downto 0);
			R_SBUF:out std_logic_vector(7 downto 0)
		);
	end component uart;
	signal FD:std_logic_vector(30 downto 0);
	type arr2 is array(0 to 15)of std_logic_vector(7 downto 0);
	signal str:arr2:=(X"30",X"31",X"32",X"33",X"34",X"35",X"36",X"37",X"38",X"39",X"41",X"42",X"43",X"44",X"45",X"46");
	signal LED:std_logic_vector(15 downto 0);
	type arr3 is array(0 to 1) of std_logic_vector(7 downto 0);
	signal Serial_read:arr3:=(X"00",X"02");
	signal R_SBUF:std_logic_vector(7 downto 0);
	signal countE1:std_logic;
	signal data_bus:std_logic_vector(23 downto 0);
begin
	LED(15 downto 4)<=countE1&SCK&"0000000000";
	A0(2 downto 0)<=CS&SCK&SDA;
	
	Serial:process(countE1)
		variable Serial_count:integer range 0 to 3;
	begin
		if falling_edge(countE1) then
			if R_SBUF=X"55" or Serial_count>1 then
				Serial_count:=0;
			else
				Serial_read(Serial_count)<=R_SBUF;
				Serial_count:=Serial_count+1;
			end if;
		end if;
	end process;
	fre:process(clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process;
	display:process(FD(14))
		variable fsm:integer range 0 to 7:=0;
		variable i:integer range 0 to 24:=0;
	begin
		if rst='0' then
			fsm:=5;
			i:=0;
		elsif rising_edge(FD(14))then
			LED(3 downto 0)<=conv_std_logic_vector(fsm,4);
			if countE1='1' then
				fsm:=1;
			else
				case fsm is
					when 1 =>
						SCK<='0';
						CS<='0';
						fsm:=2;
					when 2 =>
						CS<='1';
						data_bus<="11111"&Serial_read(0)(0)&Serial_read(0)(1)&'0'&Serial_read(1)(7 downto 4)&X"0"&Serial_read(1)(3 downto 0)&X"0";
						fsm:=3;
					when 3 =>
						SCK<='1';
						SDA<=data_bus(23-i);
						fsm:=4;
					when 4 =>
						SCK<='0';
						if i>=23 then
							fsm:=5;
							i:=0;
							CS<='0';
						else
							i:=i+1;
							fsm:=3;
						end if;
					when others =>
						CS<='0';
				end case;
			end if;
		end if;
	end process;
	LED_inveter<=not LED;
	u0:uart
		port map(
			rst=>rst,
			clk=>clk,
			RX=>RX,
			trigger=>'1',
			T_SBUF=>X"20",
			countE1=>countE1,
			R_SBUF=>R_SBUF
		);
	
end main;