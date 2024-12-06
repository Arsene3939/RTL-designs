LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
--use ieee.numeric_std.all;

entity keypad is
port (  clk : in std_logic;
        nReset: in std_logic;
        key_col   : IN std_logic_vector(3 downto 0);        --BUTTON ()               
        key_scan  : OUT  std_logic_vector(3 downto 0);  
        key_pressed: out std_logic ;
        number: out std_logic_vector(3 downto 0) 
       );
end keypad;

architecture behavioral of keypad is

SIGNAL keyin,keyin_last : std_logic_vector(0 to 15);                       
SIGNAL button_event     : std_logic_vector(0 to 15);   
signal tmpTouch: std_logic ;
signal n: std_logic_vector(3 downto 0) ;
begin
number <= n ;
key_pressed <= tmpTouch ;
process(nReset, clk)          --���䰣�u��
 	 variable scan_number    :integer range 0 to 3; 	 
 	 begin	
 	  
      if(nReset='0')then 	
         keyin      <= "1111111111111111";    
         keyin_last <= "1111111111111111";    
         tmpTouch   <= '0' ;
         n <= "0000" ;
      elsif(rising_edge(clk))then
         if scan_number = 0 then
            keyin_last(0)  <= keyin(0);
            keyin_last(4)  <= keyin(4);
            keyin_last(8)  <= keyin(8);                              
            keyin_last(12)  <= keyin(12);                              

            keyin(0)       <= key_col(0);  
            keyin(4)       <= key_col(1);  
            keyin(8)       <= key_col(2);                 
            keyin(12)      <= key_col(3);                                          
            key_scan <= "1101";       
            scan_number := 1;

         ELSIF scan_number = 1 then
            keyin_last(1)  <= keyin(1);
            keyin_last(5)  <= keyin(5);
            keyin_last(9)  <= keyin(9);                              
            keyin_last(13)  <= keyin(13);

            keyin(1)       <= key_col(0);  
            keyin(5)       <= key_col(1);  
            keyin(9)       <= key_col(2);                 
            keyin(13)      <= key_col(3); 
            key_scan <= "1011";                           
            scan_number := 2;  

         ELSIF scan_number = 2 then
            keyin_last(2)  <= keyin(2);
            keyin_last(6)  <= keyin(6);
            keyin_last(10) <= keyin(10);                              
            keyin_last(14) <= keyin(14);

            keyin(2)       <= key_col(0);  
            keyin(6)       <= key_col(1);  
            keyin(10)      <= key_col(2);                 
            keyin(14)      <= key_col(3);                
            key_scan <= "0111";                           
            scan_number := 3;  
                                 
         else
            keyin_last(3)  <= keyin(3);
            keyin_last(7)  <= keyin(7);
            keyin_last(11)  <= keyin(11);                              
            keyin_last(15)  <= keyin(15);
               
            keyin(3)       <= key_col(0);  
            keyin(7)       <= key_col(1);  
            keyin(11)      <= key_col(2);                 
            keyin(15)      <= key_col(3);                
            key_scan <= "1110";                           
            scan_number := 0;
            tmpTouch <='0' ;
            n <= "0000" ;
            for i in 0 to 15 loop            	
				if (keyin(i) = '0' and keyin_last(i) = '1' ) then --
					tmpTouch <='1';
					--n <= std_logic_vector(to_unsigned(i, n'length)) ;
					n <=conv_std_logic_vector(i, n'length);
				--else
					--pressed(i) <= '0';
				end if ;
			end loop;
			
         end if;                         
      end if; 	   
end process;
  
end behavioral;
