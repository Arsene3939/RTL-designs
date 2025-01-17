library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
entity LCD1602 is
	port(
		clk,rst:in std_logic;
		RS,RW,E:buffer  std_logic;
		DB:buffer  std_logic_vector(7 downto 0);
		LED_inveter:buffer std_logic_vector(15 downto 0);
		RX:in std_logic;
		A0,B0:out std_logic_vector(7 downto 0)
	);
end LCD1602;
architecture main of LCD1602 is
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
	type arr is array(0 to 3) of std_logic_vector(7 downto 0);
	constant boost:arr:=(X"38",X"01",X"06",X"0C");
	type arr2 is array(0 to 15)of std_logic_vector(7 downto 0);
	signal str:arr2:=(X"30",X"31",X"32",X"33",X"34",X"35",X"36",X"37",X"38",X"39",X"41",X"42",X"43",X"44",X"45",X"46");
	signal LED:std_logic_vector(15 downto 0);
	type arr3 is array(0 to 1) of std_logic_vector(7 downto 0);
	signal Serial_read:arr3:=(X"00",X"02");
	signal R_SBUF:std_logic_vector(7 downto 0);
	signal countE1:std_logic;
begin
	LED(15 downto 4)<=countE1&E&"0000000000";
	A0<=DB;
	B0(2 downto 0)<=E&RS&RW;
	Serial:process(countE1)
		variable Serial_count:integer range 0 to 3;
	begin
		if falling_edge(countE1) then
			if R_SBUF=X"FF" or Serial_count>1 then
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
		variable fsm:integer range 0 to 5:=0;
		variable i:integer range 0 to 15:=0;
	begin
		if rst='0' then
			E<='1';
			RS<='0';
			RW<='0';
			DB<=X"00";
			fsm:=5;
			i:=0;
		elsif rising_edge(FD(14))then
			LED(3 downto 0)<=conv_std_logic_vector(fsm,4);
			if countE1='1' then
				fsm:=2;
				E<='1';
			else
				case fsm is
					when 0 =>
						E<='1';
						DB<=boost(i);
						fsm:=1;
					when 1 =>
						E<='0';
						i:=i+1;
						if i>3 then
							fsm:=5;
							i:=0;
						else
							fsm:=0;
						end if;
					when 2 =>
						RS<=Serial_read(0)(1);
						RW<=Serial_read(0)(0);
						DB<=Serial_read(1);
						fsm:=3;
					when 3 =>
						E<='1';
						fsm:=4;
					when 4 =>
						E<='0';
						fsm:=5;
					when others =>
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