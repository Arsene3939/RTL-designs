Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity RGB_array is
	port(
		clk,rst:in std_logic;
		addr:buffer std_logic_vector(3 downto 0);
		R,G,B:buffer std_logic;
		sck,EA,LE:buffer std_logic;
		LED:buffer std_logic_vector(15 downto 0);
		debug:buffer std_logic_vector(7 downto 0)
	);
end entity RGB_array;
architecture main of RGB_array is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 2,0 to 15)of std_logic_vector(15 downto 0);
	constant data:arr:=(
		(X"0000", X"0000", X"C000", X"F030", X"3C3F", X"0E7F", X"C0C3", X"F183", X"3C03", X"0E03", X"C003", X"F006", X"3C0C", X"0E38", X"0070", X"0000"),
		(X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000"),
		(X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000")
	);
	constant speed:integer range 0 to 31:=7;
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	LED(4)<=not sck;
	LED(5)<=not B;
	debug(5 downto 0)<=not LED(5 downto 0);
	trsnsmit:process(FD(speed))
		variable i,j:integer range 0 to 31:=0;
		variable fsm:integer range 0 to 7:=0;
	begin
		if rising_edge(FD(speed))then
			LED(3 downto 0)<=not conv_std_logic_vector(i,4);
			case fsm is
				when 0 =>
					EA<='0';
					B<=data(0,conv_integer(15-j))(15-i);
					R<=not data(0,conv_integer(15-j))(15-i);
					G<=data(0,conv_integer(15-j))(15-i);
					i:=i+1;
					fsm:=3;
				when 1 =>
					LE<='1';
					fsm:=2;
					sck<='0';
				when 2 =>
					LE<='0';
					fsm:=0;
				when 3 =>
					if i>15 then
						i:=0;
						EA<='1';
						addr<=conv_std_logic_vector(j,4);
						j:=j+1;
						if j>15 then
							j:=0;
						end if;
						fsm:=1;
					else
						fsm:=4;
					end if;
					sck<='1';
				when 4 =>
					sck<='0';
					fsm:=0;
				when others =>
			end case;
		end if;
	end process;
end main;

	