Library IEEE;						
Use IEEE.std_logic_1164.all;		
Use IEEE.std_logic_unsigned.all;	
entity vending_machine is
	port(clk,rstP99:in std_logic;		 
			LED:buffer std_logic_vector(15 downto 0);
			seven_seg:buffer std_logic_vector(7 downto 0);
			digit:buffer std_logic_vector(3 downto 0);
			button:in std_logic_vector(4 downto 0)
	);
end entity vending_machine; 
architecture circuit of vending_machine is
	signal FD:std_logic_vector(24 downto 0);
	signal button_edge:std_logic_vector(4 downto 0);
	type LED_T is array(0 to 9) of std_logic_vector(7 downto 0);
	constant LED_Tdata:LED_T:=(X"03",X"9F",X"25",X"0C",X"99",X"49",X"C1",X"1E",X"01",X"19");
	shared variable var:Integer:=0;
	shared variable btbf:std_logic_vector(4 downto 0):="11111";
	begin	
	Freq_Div:process(clk)			
	begin
		if rstp99='0' then				
			FD<=(others=>'0');			
		elsif rising_edge(clk) then	
			FD<=FD+1;					
		end if;
	end process Freq_Div;
	digit_sacn:process(FD(16))
	begin
		if rstP99='0' then
			digit<="0111";
		elsif rising_edge(FD(16))then
			digit<=digit(0)&digit(3 downto 1);
			if digit(0)='0' then
				digit<=digit(0)&digit(3 downto 1);
				seven_seg<=LED_Tdata((var-var rem 1000)/1000);
			elsif digit(3)='0' then
				digit<=digit(0)&digit(3 downto 1);
				seven_seg<=LED_Tdata(((var-var rem 100)/100) rem 10);
			elsif digit(2)='0'then
				digit<=digit(0)&digit(3 downto 1);
				seven_seg<=LED_Tdata(((var-var rem 10)/10) rem 10);
			elsif digit(1)='0' then
				digit<=digit(0)&digit(3 downto 1);
				seven_seg<=LED_Tdata(var rem 10);
			end if;
		end if;
	end process digit_sacn;
	reading:process(button)
		constant  priceA:Integer:=20;
		constant  priceB:Integer:=25;
		variable rightmost:Integer range 0 to 60:=0;
		variable leftmost:Integer;
	begin
		--0:drinkA;
		--1:drinkB;
		--2:cancel;
		--3:5$coin;
		--4:10$coin;
		if rstP99='0' then
			btbf:="11111";
		elsif rising_edge(FD(16))then
			if(btbf(0)/=button(0))and button(0)='0'then
				leftmost:=priceA;
			elsif(btbf(1)/=button(1))and button(1)='0'then
				leftmost:=priceB;
			elsif(btbf(2)/=button(2))and button(2)='0'then
				leftmost:=0;
			elsif rightmost<96 then
				if(btbf(3)/=button(3))and button(3)='0'then
					rightmost:=rightmost+5;
				elsif(btbf(4)/=button(4))and button(4)='0'then
					rightmost:=rightmost+10;
				end if;
			end if;
			btbf:=button;
			LED(4 downto 0)<=btbf;
			LED(15 downto 11)<=button;
		end if;
		var:=rightmost+leftmost*100;
	end process reading;
end circuit;