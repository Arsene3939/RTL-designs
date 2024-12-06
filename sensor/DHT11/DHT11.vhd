Library ieee;
Use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity DHT11 is
	port(
		DHT11_data:inout std_logic;
		clk,rst:in std_logic;
		digit:buffer std_logic_vector(3 downto 0);
		ssd1:buffer std_logic_vector(7 downto 0);
		LED:buffer std_logic_vector(15 downto 0);
		debug:buffer std_logic_vector(7 downto 0)
	);
end entity DHT11;
architecture main of DHT11 is
	component seven_seg_display is
		port(
			rst,ck0:in std_logic;
			digit:buffer std_logic_vector(3 downto 0);
			ssd1:buffer std_logic_vector(7 downto 0);
			display_data:in std_logic_vector(15 downto 0);
			point:in integer range 0 to 7;
			cathed:in std_logic
		);
	end component seven_seg_display;
	signal FD:std_logic_vector(50 downto 0);
	signal databus:std_logic_vector(31 downto 0);
	signal fsm:integer range 0 to 6:=0;
	signal ssd_data:std_logic_vector(15 downto 0);
begin
	show:process(FD(25))
		variable i:integer range 0 to 1:=0;
	begin
		if rising_edge(FD(25))then
			LED<=not databus(23+i*16 downto i*16+8);
			i:=i+1;
		end if;
	end process;
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	debug(0)<=DHT11_data;
	detect:process(clk)
		variable delay:integer range 0 to 5000000:=0;
		variable bit_index:integer range 0 to 63:=39;
	begin
		if rst='0' then
			fsm<=0;
			DHT11_data<='Z';
		elsif rising_edge(clk)then
			ssd_data<=X"00"&conv_std_logic_vector(bit_index/10,4)&conv_std_logic_vector(bit_index mod 10,4);
			case fsm is
				when 0 =>  		--start
					debug(7 downto 2)<="000001";
					if delay>900000 then
						delay:=0;
						DHT11_data<='Z';
						fsm<=1;
					else
						DHT11_data<='0';
						delay:=delay+1;
					end if;
				when 1 =>		--DHT11 response
					debug(7 downto 2)<="000010";
					if DHT11_data='0' then
						fsm<=2;
					end if;
				when 2 =>		--DHT11 pull up
					debug(7 downto 2)<="000100";
					if DHT11_data='1' then
						fsm<=3;
					end if;
				when 3 =>		-- start transmition
					debug(7 downto 2)<="001000";
					if DHT11_data='1' and delay>2500 then
						fsm<=4;
						delay:=0;
					elsif DHT11_data='0'then
						delay:=delay+1;
					end if;
				when 4 =>		--wait '1' time
					debug(7 downto 2)<="010000";
					if DHT11_data='1' then
						delay:=delay+1;
					elsif(DHT11_data='0' and delay>1250) then
						fsm<=5;
					end if;
				when 5 =>		--judge '1' or '0' signal 
					debug(7 downto 2)<="100000";
					if bit_index>=0 then
						if delay < 2500 then
							databus(bit_index)<='0';
						elsif delay > 3000 then
							databus(bit_index)<='1';
						end if;
						fsm<=3;
						delay:=0;
						bit_index:=bit_index-1;
					else
						bit_index:=39;
						fsm<=0;
					end if;
				when others =>
			end case;
		end if;
	end process;
	u0:seven_seg_display
		port map(
			rst=>rst,
			ck0=>clk,
			digit=>digit,
			ssd1=>ssd1,
			display_data=>ssd_data,
			point=>0,
			cathed=>'0'
		);
end main;

	