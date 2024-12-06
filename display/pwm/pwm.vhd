library IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
entity pwm is
	port(clk,rstP99:in std_logic;	 
		LED:buffer std_logic_vector(15 downto 0)
	);
end entity pwm;
architecture ledVector of pwm is
	signal FD:std_logic_vector(24 downto 0);
	type aray is array(0 to 15)of integer;
	shared variable LEDstate:aray:=(0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240);
begin
	Freq_Div:process(clk)			
	begin
		if rstp99='0' then				
			FD<=(others=>'0');
		elsif rising_edge(clk) then
			FD<=FD+1;					
		end if;
	end process Freq_Div;
	analog0:process(FD(8))
	variable i:integer:=0;
	begin
		if rising_edge(FD(8))then
			i:=i+1;
			if i=256 then
				i:=0;
			end if;
			if i<=LEDstate(0)then
				LED(0)<='0';
			else
				LED(0)<='1';
			end if;
			if i<=LEDstate(1)then
				LED(1)<='0';
			else
				LED(1)<='1';
			end if;
			if i<=LEDstate(2)then
				LED(2)<='0';
			else
				LED(2)<='1';
			end if;
			if i<=LEDstate(3)then
				LED(3)<='0';
			else
				LED(3)<='1';
			end if;
			if i<=LEDstate(4)then
				LED(4)<='0';
			else
				LED(4)<='1';
			end if;
			if i<=LEDstate(5)then
				LED(5)<='0';
			else
				LED(5)<='1';
			end if;
			if i<=LEDstate(6)then
				LED(6)<='0';
			else
				LED(6)<='1';
			end if;
			if i<=LEDstate(7)then
				LED(7)<='0';
			else
				LED(7)<='1';
			end if;
			if i<=LEDstate(8)then
				LED(8)<='0';
			else
				LED(8)<='1';
			end if;
			if i<=LEDstate(9)then
				LED(9)<='0';
			else
				LED(9)<='1';
			end if;
			if i<=LEDstate(10)then
				LED(10)<='0';
			else
				LED(10)<='1';
			end if;
			if i<=LEDstate(11)then
				LED(11)<='0';
			else
				LED(11)<='1';
			end if;
			if i<=LEDstate(12)then
				LED(12)<='0';
			else
				LED(12)<='1';
			end if;
			if i<=LEDstate(13)then
				LED(13)<='0';
			else
				LED(13)<='1';
			end if;
			if i<=LEDstate(14)then
				LED(14)<='0';
			else
				LED(14)<='1';
			end if;
			if i<=LEDstate(15)then
				LED(15)<='0';
			else
				LED(15)<='1';
			end if;
		end if;
	end process;
	maint:process(FD(16))
	variable v:aray:=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
	begin
		if rising_edge(FD(16))then
			if LEDstate(0)=10 then
				v(0):=2;
			elsif LEDstate(0)=200 then 
				v(0):=0;
			end if;
			LEDstate(0):=LEDstate(0)+v(0)-1;
			if LEDstate(1)=10 then
				v(1):=2;
			elsif LEDstate(1)=200 then 
				v(1):=0;
			end if;
			LEDstate(1):=LEDstate(1)+v(1)-1;
			if LEDstate(2)=10 then
				v(2):=2;
			elsif LEDstate(2)=200 then 
				v(2):=0;
			end if;
			LEDstate(2):=LEDstate(2)+v(2)-1;
			if LEDstate(3)=10 then
				v(3):=2;
			elsif LEDstate(3)=200 then 
				v(3):=0;
			end if;
			LEDstate(3):=LEDstate(3)+v(3)-1;
			if LEDstate(4)=10 then
				v(4):=2;
			elsif LEDstate(4)=200 then 
				v(4):=0;
			end if;
			LEDstate(4):=LEDstate(4)+v(4)-1;
			if LEDstate(5)=10 then
				v(5):=2;
			elsif LEDstate(5)=200 then 
				v(5):=0;
			end if;
			LEDstate(5):=LEDstate(5)+v(5)-1;
			if LEDstate(6)=10 then
				v(6):=2;
			elsif LEDstate(6)=200 then 
				v(6):=0;
			end if;
			LEDstate(6):=LEDstate(6)+v(6)-1;
			if LEDstate(7)=10 then
				v(7):=2;
			elsif LEDstate(7)=200 then 
				v(7):=0;
			end if;
			LEDstate(7):=LEDstate(7)+v(7)-1;
			if LEDstate(8)=10 then
				v(8):=2;
			elsif LEDstate(8)=200 then 
				v(8):=0;
			end if;
			LEDstate(8):=LEDstate(8)+v(8)-1;
			if LEDstate(9)=10 then
				v(9):=2;
			elsif LEDstate(9)=200 then 
				v(9):=0;
			end if;
			LEDstate(9):=LEDstate(9)+v(9)-1;
			if LEDstate(10)=10 then
				v(10):=2;
			elsif LEDstate(10)=200 then 
				v(10):=0;
			end if;
			LEDstate(10):=LEDstate(10)+v(10)-1;
			if LEDstate(11)=10 then
				v(11):=2;
			elsif LEDstate(11)=200 then 
				v(11):=0;
			end if;
			LEDstate(11):=LEDstate(11)+v(11)-1;
			if LEDstate(12)=10 then
				v(12):=2;
			elsif LEDstate(12)=200 then 
				v(12):=0;
			end if;
			LEDstate(12):=LEDstate(12)+v(12)-1;
			if LEDstate(13)=10 then
				v(13):=2;
			elsif LEDstate(13)=200 then 
				v(13):=0;
			end if;
			LEDstate(13):=LEDstate(13)+v(13)-1;
			if LEDstate(14)=10 then
				v(14):=2;
			elsif LEDstate(14)=200 then 
				v(14):=0;
			end if;
			LEDstate(14):=LEDstate(14)+v(14)-1;
			if LEDstate(15)=10 then
				v(15):=2;
			elsif LEDstate(15)=200 then 
				v(15):=0;
			end if;
			LEDstate(15):=LEDstate(15)+v(15)-1;
		end if;
	end process;
end ledVector;