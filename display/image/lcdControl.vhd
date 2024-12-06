LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity lcdControl is
   port (  
      clk : in std_logic;
      nReset: in std_logic;
      mode_lcd:in integer range 0 to 15;
      SW:in std_logic;
      R_SBUF		 : in std_LOGIC_vector(7 downto 0) ;
      uart_pers  : in std_logic;
      lcd_busy  : in    STD_LOGIC;                     
      lcd_write, lcd_show  : out  STD_LOGIC ;
      lcd_address          : buffer  std_logic_vector(14 downto 0);
      lcd_color            : out  std_logic_vector(5 DOWNTO 0)
  );
end lcdControl;

architecture behavioral of lcdControl is
--LCD   
SIGNAL  clk_25MHz : STD_LOGIC;
--SIGNAL  mode_lcd :integer range 0 to 15;
  
SIGNAL  fsm,fsm_back,fsm_back2   :integer range 0 to 200;
SIGNAL  data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  DC_data    : std_logic;
type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
signal  addr:std_logic_vector(14 downto 0);
begin
   Serial:process(uart_pers)             --Serial controll
      variable Serial_count:integer range 0 to 11:=0;
   begin
      if falling_edge(uart_pers) then
         if R_SBUF=X"FF" then
            Serial_count:=0;
            addr<="000000000000000";
         else
            Serial_available(Serial_count)<=R_SBUF;
            Serial_count:=Serial_count+1;
         end if;
         addr<=addr+1;
         if addr>"101000000000000" then
            addr<="000000000000000";
         end if;
      end if;
   end process;     
	process(clk, nReset)                -- LCD
      variable delay_1         :integer range 0 to 50000000;                                                      	               	
      variable address_start,address_end   : STD_LOGIC_VECTOR(14 DOWNTO 0); 	               	
      variable disp_color      : STD_LOGIC_VECTOR(5 DOWNTO 0); 	               	
      variable pos_x_start,pos_y_start :integer range 0 to 159;  
      variable pos_x,pos_y    :integer range 0 to 160;         
      variable pos_now              :integer range 0 to 20479;   	                  
      variable varl,cnt_number,cnt_number_max   :integer range 0 to 20;                                      
      variable cnt1           :integer range 0 to 99;                  
      variable bit_index   :integer range 0 to 32; 	               	
      variable font_num    :integer range 0 to 128;
      variable font_size   :integer range 0 to 7:=2;                         --times 0~7
      variable delaytime   :integer range 0 to 5000000;
	begin	
      if(nReset ='0')then                                	                
         fsm <= 0;
         delay_1 :=0;
         lcd_write <= '0';       
         lcd_show  <= '0';

      ELSIF(clk'EVENT AND clk='1')then     
 
         if (SW='0') then                    -- 開始顏色DEMO            
               delay_1 :=0;                        
               lcd_write <= '0';       
               lcd_show  <= '0';                   

               if (mode_lcd=0) then
                  fsm     <= 1; --1
               elsif ((mode_lcd=1) or (mode_lcd=3)) then   
                  fsm     <= 100; 
               elsif (mode_lcd=2) then
                  fsm     <= 110;
               elsif (mode_lcd=4) then   
                  fsm     <= 130;

               end if; 

         else

            CASE fsm IS                                          

               when 0 =>                                -- idle  


               when 1 =>           
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 60;                                        
                                       
               when 10 =>                                --更新畫面
                        if(lcd_busy = '0') then          --等待LCD閒置
                           lcd_show <= '1';
                           fsm      <= 11;
                        end if;                    

               when 11 =>                                                                             
                        if(lcd_busy = '1') then         --等待忙碌,表示LCD接收到lcd_show命令  
                           lcd_show <= '0';                           
                           delay_1 :=0;    
                           fsm      <= 12;
                        end if;                    

               when 12 =>                                                                             
                        if(lcd_busy = '0') then         --等待忙碌,表示LCD接收到lcd_show命令  
                           fsm      <= fsm_back;
                        end if;               
               
               when 20 =>                                    --write ram 
                        if(lcd_busy = '0') then              --等待LCD閒置
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm         <= 21;
                        end if;                                            

               when 21 =>                                    
                        if delay_1 >= 10 then 
                           lcd_write <= '0';
                           delay_1 :=0;
                           fsm      <= 22;
                        else
                           delay_1:=delay_1+1;                          
                        end if;
                        
               when 22 =>                                    -- set data
                        lcd_address <= lcd_address + "000000000000001"; --------------------*******
                        fsm  <= 23;
                        
               when 23 =>                                    -- address
                        if(lcd_address = address_end) then   -- 128 * 160
                           fsm        <= fsm_back;
                        else
                           fsm        <= 20;               
                        end if;                                    
                  
--   ----------------------------------------------------------------------------       
               when 59 =>                                  -- delay 1s
                        if delay_1 >= delaytime*50 then                     
                           delay_1 :=0;                           
                           fsm <= fsm_back2;
                        else
                           delay_1:=delay_1+1;                          
                        end if;
   ----------------------------------------------------------------------------  MODE = "000" ,顏色展示    
               when 60 =>                                   -- 1 修改圖型    
                        lcd_address   <= "000000000000000";                         
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 61;
                        delaytime:=500;
               when 61 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 62;   

               when 62 =>                                   -- delay 1s  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 63;
                                
               when 63 =>                                  -- 2 修改圖型
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "000000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 64;                             
    
               when 64 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 60;

               when 65 =>                                  -- delay 1s  
                        delay_1 :=0;    
                        fsm       <= 59;                       
                        fsm_back2 <= 66;
   ----------------------------------------------------------------------------  MODE = "001" ,白色全亮
               when 100 =>                                   -- 1 修改圖型    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 101;                             
               
               when 101 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back <= 102;   

               when 102 =>                                   -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;
                        fsm_back2 <= 100;
                        
   ----------------------------------------------------------------------------  MODE = "010" ,顯示文字 圖形, 光強度數值
               when 110 =>                                   -- 清除畫面    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";           -- 全亮
                        fsm       <= 20;                   
                        fsm_back  <= 111;
               when 111 =>
                        lcd_address   	<= addr;
                        lcd_color   	<= R_SBUF(5 downto 0);
                        fsm <= 112;
               when 112 =>                                     -- write
                        if(lcd_busy = '0') then              --蝑LCD蔭
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm  <= 113;
                        end if;
               when 113 =>                                     -- write
                        if delay_1 >= 10 then
                           lcd_write <= '0';
                           delay_1 :=0;
                           fsm   <= 111;
                           if addr>="101000000000000" then
                              lcd_address<="000000000000000";
                              fsm<=114;
                           end if;
                        else
                           delay_1:=delay_1+1;
                        end if;
               when 114 =>
                        delaytime:=0;
                        fsm       <= 10;
                        fsm_back  <= 115;
               when 115 =>                                   -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;
                        fsm_back2 <= 111;
               when others =>                          
                             
            END CASE;             
            
         end if;                                                             
                             
      end if; 	   

	end process;

   
  
end behavioral;