--°£ÀW
--¿é¤J50MHz clock 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity clock_generator is
port(    
     fin:in std_logic;    
     clk_1MHz:buffer std_logic ;
     clk_1KHz:buffer std_logic ;
     clk_100Hz:buffer std_logic ;
     clk_1Hz:buffer std_logic 
    );
end clock_generator;

architecture beh of clock_generator is
begin

  process(fin)    -- 1MHz
   variable cnt:integer range 0 to 25;
  begin   
   if rising_edge(fin) then
      if cnt>= 24 then        
        clk_1MHz<=not clk_1MHz;
        cnt:= 0;
      else          
        cnt:=cnt+1;
      end if;   
    end if;  
  end process;   
  
  process(clk_1MHz)    -- 1KHz
   variable cnt:integer range 0 to 500;
  begin   
   if rising_edge(clk_1MHz) then
      if cnt>= 499 then        
        clk_1KHz<=not clk_1KHz;
        cnt:= 0;
      else          
        cnt:=cnt+1;
      end if;   
    end if;  
  end process;   
  
  process(clk_1KHz)    -- 100Hz
   variable cnt:integer range 0 to 5;
  begin   
   if rising_edge(clk_1KHz) then
      if cnt>= 4 then        
        clk_100Hz<=not clk_100Hz;
        cnt:= 0;
      else          
        cnt:=cnt+1;
      end if;   
    end if;  
  end process;   
 
process(clk_100Hz)    -- 1Hz
   variable cnt:integer range 0 to 50;
  begin   
   if rising_edge(clk_100Hz) then
      if cnt>= 49 then        
        clk_1Hz<=not clk_1Hz;
        cnt:= 0;
      else          
        cnt:=cnt+1;
      end if;   
    end if;  
  end process;       
  
end beh;

