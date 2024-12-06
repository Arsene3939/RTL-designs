library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity serialRGBLED is
	generic(N:integer range 0 to 255:=6);
	port(
		clk,rst:in std_logic;
		Do:out std_logic;
		busy:out std_logic;
		ena,RW:in std_logic;
		addr:in std_logic_vector(7 downto 0);
		color_bus:in std_logic_vector(23 downto 0)
	);
end serialRGBLED;
architecture main of serialRGBLED is
	signal sck:std_logic;
	type arr is array(0 to N-1) of std_logic_vector(23 downto 0);
	signal colordata:arr;
	type ar2 is array(0 to 1) of std_logic_vector(2 downto 0);
	constant state:ar2:=("001","011");
begin
	colordata(conv_integer(addr))<=color_bus when RW='1';		
	fre:process(clk)
		variable counter:integer range 0 to 20:=0;
	begin
		if rising_edge(clk)then
			counter:=counter+1;
			if counter>=10 then
				sck<=not sck;
				counter:=0;
			end if;
		end if;
	end process;
	serial:process(sck)
		variable bitindex:integer range 0 to 24:=0;
		variable ledindex:integer range 0 to N:=0;
		variable i:integer range 0 to 3:=0;
		variable fsm:integer range 0 to 3:=0;
		variable delay:integer range 0 to 300:=0;
		variable ena_pre:std_logic:='0';
	begin
		if rst='0' then
			bitindex:=0;
			ledindex:=0;
			i:=0;
			fsm:=0;
			delay:=0;
		elsif rising_edge(sck) then
			if fsm=0 then
				if i>2 then
					i:=0;
					bitindex:=bitindex+1;
				end if;
				if bitindex>23 then
					bitindex:=0;
					ledindex:=ledindex+1;
				end if;
				if ledindex>N-1 then
					fsm:=1;
					ledindex:=0;
				end if;
				Do<=state(conv_integer(colordata(ledindex)(bitindex)))(i);
				i:=i+1;
			elsif fsm=1 then
				Do<='0';
				delay:=delay+1;
				if delay>290 then
					fsm:=2;
					delay:=0;
				end if;
			else
				if ena='1' and ena_pre='0' then
					fsm:=0;
					bitindex:=0;
					ledindex:=0;
					i:=0;
					delay:=0;
					busy<='1';
				end if;
				busy<='0';
				ena_pre:=ena;
			end if;
		end if;
	end process;
end main;

--Library IEEE;
--Use IEEE.std_logic_1164.all;
--USE IEEE.std_logic_unsigned.all;
--entity serialRGBLED is
--	port(
--		rst,clk:in std_logic;
--		Button1,Button2,Button3,Button4,Button5:in std_logic;
--		LED:buffer std_logic_vector(15 downto 0);
--		Do:buffer std_logic;
--		io:buffer std_logic_vector(4 downto 0);
--		logico:buffer std_logic_vector(2 downto 0);
--		thro:buffer std_logic_vector(1 downto 0);
--		digit:buffer std_logic_vector(3 downto 0);
--		ssd:buffer std_logic_vector(6 downto 0)
--	);
--end entity serialRGBLED;
--architecture main of serialRGBLED is
--	signal FD:std_logic_vector(50 downto 0);
--	signal color:std_logic_vector(0 to 23):=X"000001";
--	signal DFF:std_logic_vector(3 downto 0):=X"E";
--	signal sck:std_logic;
--	type arr is array(0 to 31) of std_logic_vector(4 downto 0);
--	constant conv:arr:=("00000","00001","00010","00011","00100","00101","00110","00111","01000","01001","01010","01011","01100","01101","01110","01111"
--							 ,"10000","10001","10010","10011","10100","10101","10110","10111","11000","11001","11010","11011","11100","11101","11110","11111");
--	shared variable number:integer range 0 to 9999:=1234;
--	type Avec is array(0 to 9) of std_logic_vector(6 downto 0);
--	constant font:Avec:=("0000001","1001111","0010010","0000110","1001100","0100100","1100000","0001111","0000000","0001100");
--begin
--	fre:process(rst,clk)
--	begin
--		if rst='0' then
--			FD<=(others=>'0');
--		elsif rising_edge(clk)then
--			FD<=FD+1;
--		end if;
--	end process fre;
--	zp4us:process(clk)
--		variable i:integer range 0 to 9;
--	begin
--		if rising_edge(clk) then
--			i:=i+1;
--			if i>9 then
--				i:=0;
--				sck<=not sck;
--			end if;
--		end if;
--	end process;
--	ppcol:process(FD(20))
--	begin
--		if rising_edge(FD(20))then
--			color<=color(1 to 23)&color(0);
--		end if;
--	end process;
-- 	emit:process(sck,FD(12))
--		variable i:integer range 0 to 24:=0;
--		variable f0us:integer range 0 to 150:=0;
--		variable thr:integer range 0 to 2:=0;
--		variable logic:std_logic_vector(0 to 2);
--	begin
--		if rising_edge(sck) then
--			if f0us>=140 then
--				io<=conv(i);
--				logic:='1'&color(i-1)&'0';
--				thro<=conv(thr)(1 downto 0);
--				logico<=logic;
--				Do<=logic(thr);
--				thr:=thr+1;
--				if thr>2 then
--					thr:=0;
--					i:=i+1;
--				end if;
--				if i>24 then
--					i:=0;
--					f0us:=0;
--				end if;
--			end if;
--			if i=0 and f0us<150 then
--				f0us:=f0us+1;
--				Do<='0';
--			end if;
--			number:=f0us+i*1000;
--		end if;
--	end process;
--	scan:process(FD(16))
--		type fint is array(0 to 3)of integer range 0 to 1000;
--		constant pow:fint:=(1000,100,10,1);
--		variable i:integer range 0 to 3;
--	begin
--		if rising_edge(FD(16))then
--			DFF<=DFF(0)&DFF(3 downto 1);
--			ssd<=font((number/pow(i))mod 10);
--			i:=i+1;
--		end if;
--	end process;
--	digit<=DFF;
--	LED<=X"FFFF";
--end main;