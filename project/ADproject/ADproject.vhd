Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.numeric_std.all;
entity ADproject is
	port(
		rst,clk:in std_logic;
		BCD:buffer std_logic_vector(0 to 3);
		digit:buffer std_logic_vector(1 downto 0)
	);
end entity ADproject;
architecture main of ADproject is
	signal FD:std_logic_vector(20 downto 0);
	type arr is array(3 downto 0) of integer range 0 to 9;
	shared variable number:arr:=(0,0,0,0);
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	scan:process(FD(10))
		variable i:integer range 0 to 3;
	begin
		if rst='0' then
			digit<="00";
			i:=0;
		elsif rising_edge(FD(10))then
			if i>3 then
				i:=0;
			end if;
			digit<=digit+1;
			BCD<=std_logic_vector(to_signed(number(i),BCD'length));
			i:=i+1;
		end if;
	end process;
	count:process(FD(15))
	begin
		if rst='0' then
			number(3 downto 0):=(0,0,0,0);
		elsif riSing_edge(FD(15))then
			number(2):=number(2)+1;
			if(number(2)>9)then
				number(2):=0;
				number(1):=number(1)+1;
				if(number(1)>9)then
					number(1):=0;
					number(0):=number(0)+1;
					if(number(0)>9)then
						number(0):=0;
						number(3):=number(3)+1;
						if(number(3)>9)then
							number(3):=0;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
end main;

	