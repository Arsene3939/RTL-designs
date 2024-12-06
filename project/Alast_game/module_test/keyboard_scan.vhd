library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity keyboard_scan is 
port(
		clk:in std_logic;
		rst:in std_logic;
		scanning:buffer std_logic_vector(3 downto 0);
		reading:in std_logic_vector(3 downto 0);
		state:out std_logic_vector(3 downto 0)
     );
end keyboard_scan;
architecture beh of keyboard_scan is
	signal FD: std_logic_vector(50 downto 0);
	type arr is array(0 to 15) of std_logic_vector(3 downto 0);
	constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
begin
	fre:process(clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process;
	main:process(FD(12))
		variable i:integer range 0 to 4;
		variable leave:std_logic;
	begin
		if rst='0'then
			scanning<=X"E";
			i:=0;
			leave:='1';
		elsif rising_edge(FD(12))then
			if i=0 then
				leave:='1';
			end if;
			scanning<=scanning(2 downto 0)&scanning(3);
			if reading/="1111" then
				case reading is
					when "1110" => state<=to_vector(i);
					when "1101" => state<=to_vector(i+4);
					when "1011" => state<=to_vector(i+8);
					when "0111" => state<=to_vector(i+12);
					when others => state<="0000";
				end case;
				leave:='0';
			end if;
			i:=i+1;
			if i>3 then
				if leave='1' then
					state<="0000";
				end if;
				i:=0;
			end if;
		end if;
	end process;
end beh;