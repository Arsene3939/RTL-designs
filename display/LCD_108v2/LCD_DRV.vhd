--FOR EP3C16Q240C8

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity LCD_DRV is
port(    	      	                                  --接腳說明   
        fin, nReset  :in std_logic;                    --震盪輸入(149) & RESET按鈕(145) 
        BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;       --LCD 
        lcd_busy  : OUT    STD_LOGIC;                     
        lcd_write, lcd_show  : in  STD_LOGIC ;
        lcd_address          : in  std_logic_vector(14 downto 0);
        lcd_color            : in  std_logic_vector(5 DOWNTO 0)                            

    );
end LCD_DRV;
architecture beh of LCD_DRV is

component up_mdu5 is
   port(    
        fin:in std_logic;    
        fout:buffer std_logic   
       );
end component up_mdu5;

component cmd_rom is
   port(    
        address   : IN std_logic_vector(15 downto 0); 
        data_out  : OUT std_logic_vector(7 downto 0); 
        DC_data   : OUT std_logic   
       );
end component cmd_rom;

component raminfr is
generic ( 
          bits : integer := 6;                -- number of bits per RAM word
          addr_bits : integer := 15);         -- 2^addr_bits = number of words in RAM

port (clk : in std_logic;
       we : in std_logic;
        a : in std_logic_vector(addr_bits-1 downto 0);
       di : in std_logic_vector(bits-1 downto 0);
       do : out std_logic_vector(bits-1 downto 0));
end component raminfr;  

--LCD   
SIGNAL  clk_25MHz : STD_LOGIC;        
SIGNAL  fsm,fsm_back,fsm_back2   :integer range 0 to 150;
SIGNAL  address : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL  data_out ,RGB_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  DC_data    : std_logic;   
--RAM
SIGNAL we2   : std_logic;
SIGNAL a2     : std_logic_vector(14 downto 0);
SIGNAL di2, do2 : std_logic_vector(5 downto 0); 
  
begin  

   BL  <= '1';
	process(clk_25MHz, nReset)          -- LCD
      variable delay_1         :integer range 0 to 25000000;                                                      	               	
      variable bit_cnt         :integer RANGE 0 TO 7 := 7;
      variable hi_lo           :integer range 0 to 1;
      variable address_start,address_end   : STD_LOGIC_VECTOR(14 DOWNTO 0); 	               	
      variable disp_color      : STD_LOGIC_VECTOR(5 DOWNTO 0); 	               	
      variable pos_x_start,pos_y_start :integer range 0 to 159;  
      variable pos_x,pos_y    :integer range 0 to 39;         
      variable pos_now              :integer range 0 to 20479;   	                  
      variable varl,cnt_number,cnt_number_max   :integer range 0 to 20;                                      
      variable cnt1           :integer range 0 to 99;                  
      variable bit_index   :integer range 0 to 16; 	               	
               
	begin	
      if(nReset ='0')then 
         RES <= '1';
         DC  <= '0';                              -- command
         CS  <= '1';
         SCL <= '1';                                     	                
         fsm <= 0;
         delay_1 :=0;
         address <= "0000000000000000";
         lcd_busy <= '1';
                  
      ELSIF(clk_25MHz'EVENT AND clk_25MHz='1')then           

         CASE fsm IS                                          
            when 0 =>                             -- idle
                     fsm <= 1;       
                     lcd_busy <= '1';
            when 1 =>                             -- 硬體RESET, 0-2 
                     RES <= '1';                  
                     if delay_1 >= 25000 then     -- 1ms = 40ns x 25000
                        delay_1 :=0;                           
                        fsm <= 2;
                     else
                        delay_1:=delay_1+1;                          
                     end if;

            when 2 =>                             
                     RES <= '0';                  -- 1ms
                     if delay_1 >= 25000 then                     
                        delay_1 :=0;                           
                        fsm <= 3;
                     else
                        delay_1:=delay_1+1;                          
                     end if;

            when 3 =>                            
                     RES <= '1';                  -- 120ms
                     if delay_1 >= 3000000 then                
                        delay_1 :=0;  
                        fsm   <=  4;
                        
                     else
                        delay_1:=delay_1+1;                          
                     end if;               

            when 4 =>                                --start loop ,lcd初始化命令,共85BYTES
                     if(address = "0000000001010101") then  
                        fsm        <= 5;                
                     else
                        fsm        <= 50;               
                        fsm_back   <=  4;            
                     end if;
                        
            when 5 =>                                -- 初始化後延遲    
                     if delay_1 >= 3000000 then       -- 120ms                                         
                        delay_1 :=0; 
                        fsm     <= 6; 
                     else
                        delay_1:=delay_1+1;                          
                     end if;

            when 6 =>                                -- idle   
                     fsm     <= 7; 
                            
            when 7 =>                                -- idle 
                  
                     if lcd_write = '1' then                                               
                        fsm       <= 20;
                        fsm_back  <= 7;                          
                        lcd_busy  <= '1';                 
                     elsif lcd_show = '1' then                                               
                        fsm       <= 10;
                        fsm_back2 <= 7;                          
                        lcd_busy <= '1';                                              
                     else                        
                        lcd_busy <= '0';                                              
                     end if;
            when 10 =>                                --更新畫面,DISP_WINDOWS ,10-13     
                     address <= "0000000001001010";                     
                     fsm        <= 11;                

            when 11 =>                                --loop ,DISP_WINDOWS 命令    
                     if(address = "0000000001010101") then  --共11BYTES
                        address <= "0000000000000000";
                        fsm        <= 12;                
                     else
                        fsm        <= 50;               
                        fsm_back   <= 11;            
                     end if;
                        
            when 12 =>                              -- start loop ,read ram                                 
                     hi_lo := 0;
                     we2  <= '0';
                     a2   <= address(14 downto 0);               -- set address                                           
                     fsm  <= 13;                        

            when 13 =>                              -- read ram                                 
                     if(hi_lo = 0)then              -- COLOR HI BYTE 
                                                    -- R - f800   G - 07e0  B - 001f 
                        RGB_data <= do2(5 downto 4) & "000" & do2(3 downto 2) & "0" ;
                                      
                        if(address = 20480) then     -- 128 * 160
                           fsm        <= fsm_back2;  -- 完成更新    
                        else
                           fsm        <= 40;               
                           fsm_back   <= 13;            
                        end if;
                                                                              
                     else                             --COLOR LO BYTE                         
                        RGB_data <=  "000" & do2(1 downto 0) & "000";
                           
                        fsm        <= 40;  
                        fsm_back   <= 12;                                                     
                     end if;                      

            when 20 =>                                    --write ram 
--                     address <= '0' & address_start;                     
                     fsm     <= 21;

            when 21 =>                                    
                     a2   <= lcd_address;                 -- set address                                                                
                     fsm  <= 22;
                     
            when 22 =>                                    -- set data
                     di2  <= lcd_color;                  
                     fsm  <= 23; 
                     
            when 23 =>                                    -- write
                     we2  <= '1';
                     fsm  <= 24; 

            when 24 =>                                    -- write
                     we2  <= '0';
                     fsm  <= 25; 

            when 25 =>                                    -- address               
                     fsm        <= fsm_back;               
--                     address <= address + "0000000000000001";                                                                
--                     fsm  <= 26; 
                     
            when 26 =>                                    -- address
                     if(address = address_end) then       -- 128 * 160
                        fsm        <= fsm_back;                
                     else
                        fsm        <= 21;               
                     end if;                                    
               

            when 40 =>                             -- write data START,40-45 
                     DC  <= '1';    
                     fsm <= 41; 
            when 41 =>                             -- CS = 0              
                     CS  <= '0';
                     bit_cnt := 7;  
                     fsm <= 42;                       
            
            when 42 =>                             -- LOOP x 8 ,set data            
                     SDA <= RGB_data(bit_cnt); 
                     fsm <= 43;                      
                     
            when 43 =>                             -- CLK = 0 
                     SCL <= '0';                           
                     fsm <= 44;
                                           
            when 44 =>                             -- CLK = 1 
                     SCL <= '1';                           
                     bit_cnt := bit_cnt - 1;
                     
                     if bit_cnt >= 7 then
                        fsm <= 45;                      
                     else
                        fsm <= 42;                                           
                     end if;
                        
            when 45 =>                             -- CS = 1              
                     CS  <= '1';                     
                     if(hi_lo = 0)then
                        hi_lo := 1;
                     else
                        hi_lo := 0; 
                        address <= address + "0000000000000001";                          
                     end if;   
                     fsm <= fsm_back;                                                               

            when 50 =>                             -- write command START,50-55
                     DC  <= DC_data;    
                     fsm <= 51;                     
                     
            when 51 =>                             -- CS = 0              
                     CS  <= '0';
                     bit_cnt := 7;  
                     fsm <= 52;                       
            
            when 52 =>                             -- LOOP x 8 ,set data            
                     SDA <= data_out(bit_cnt); 
                     fsm <= 53;                      
                     
            when 53 =>                             -- CLK = 0 
                     SCL <= '0';                           
                     fsm <= 54;
                                           
            when 54 =>                             -- CLK = 1 
                     SCL <= '1';                           
                     bit_cnt := bit_cnt - 1;
                     
                     if bit_cnt >= 7 then
                        fsm <= 55;                      
                     else
                        fsm <= 52;                                           
                     end if;
                        
            when 55 =>                             -- CS = 1              
                     CS  <= '1';
                     address <= address + "0000000000000001"; 
                     fsm <= fsm_back;             

----------------------------------------------------------------------------  MODE = "00" ,顏色展示    
            when 60 =>                                   -- 1 修改圖型    
                     address_start := "000000000000000";
                     address_end   := "101000000000000";
                     disp_color    := "111111";          -- R - f800   G - 07e0  B - 001f                    
                     fsm       <= 20;                   
                     fsm_back  <= 61;                             

            when 61 =>                                   --更新畫面    
                     fsm       <= 10;                   
                     fsm_back2 <= 7;                                              
            
            when others =>                          
                          
         END CASE;                                                                                   
                             
      end if; 	   
	end process;
           
   ------------------------------------------------------------------------零件庫  
   u0:up_mdu5           --除頻電路 
   port map(      
                fin       => fin,       
	             fout      => clk_25MHz      
            );

   u1:cmd_rom           --初始化命令資料
   port map 
   (
	 address   => address,
    data_out  => data_out,
    DC_data   => DC_data 
   );

   u2:raminfr          --LCD 顯示資料暫存RAM
   generic map 
	 (
		  bits        => 6,
		  addr_bits   => 15              
	 )            
   port map(      
               clk     => fin,       
	            we      => we2,
               a       => a2,
               di      => di2,
               do      => do2   
            );
                 
end beh;

