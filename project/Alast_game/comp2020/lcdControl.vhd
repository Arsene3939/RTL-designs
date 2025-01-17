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
--LCD NUMBER DATA
type oled_num_tb is array (0 to 18,0 to 15) of std_logic_vector(15 downto 0);                      --19個資料
constant table16:oled_num_tb:=
(   
   (
   	X"0000",	X"0000",	X"03e0",	X"1c18",	X"300c",	X"300c",	X"7006",	X"6006",
   	X"6006",	X"6006",	X"300c",	X"300c",	X"1818",	X"07f0",	X"0000",	X"0000"
   ),
   (
	   X"0000",	X"0000",	X"0080",	X"0f80",	X"0180",	X"0180",	X"0180",	X"0180",
	   X"0180",	X"0180",	X"0180",	X"0180",	X"0180",	X"0ff0",	X"0000",	X"0000"  
   ),   
   (   
	  X"0000",	X"0000",	X"07c0",	X"1870",	X"2018",	X"4018",	X"0018",	X"0010",
	  X"0030",	X"00c0",	X"0100",	X"0600",	X"0806",	X"7ffc",	X"0000",	X"0000"   
   ),
   (
   	X"0000",	X"0000",	X"07e0",	X"1830",	X"2018",	X"0010",	X"0020",	X"01e0",
   	X"0638",	X"001c",	X"000c",	X"0008",	X"0010",	X"3fe0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"0010",	X"0070",	X"00b0",	X"0130",	X"0230",	X"0c30",
   	X"1830",	X"2030",	X"7ffe",	X"0030",	X"0030",	X"0030",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"03fc",	X"0600",	X"0400",	X"0c00",	X"1fe0",	X"0070",
   	X"0018",	X"000c",	X"000c",	X"0008",	X"0010",	X"3fe0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"003c",	X"03c0",	X"0600",	X"1800",	X"31c0",	X"3e38",
   	X"700c",	X"600c",	X"2006",	X"3004",	X"1808",	X"07f0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"1ffc",	X"100c",	X"2008",	X"0018",	X"0010",	X"0030",
   	X"0060",	X"0060",	X"00c0",	X"0080",	X"0180",	X"0300",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"07e0",	X"1818",	X"3008",	X"3018",	X"1c30",	X"07c0",
   	X"06e0",	X"1838",	X"300c",	X"3006",	X"300c",	X"0ff0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"07c0",	X"1830",	X"300c",	X"200c",	X"700c",	X"300c",
   	X"180c",	X"07fc",	X"0018",	X"0030",	X"00c0",	X"3f00",	X"0000",	X"0000"
   ),
   (
   	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",
   	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff"
   ),
   (
	   X"0000",	X"0000",	X"ff80",	X"3078",	X"100c",	X"100c",	X"100c",	X"1038",   --R
	   X"1fc0",	X"10c0",	X"1060",	X"1030",	X"3818",	X"fe0f",	X"0000",	X"0000"
	),	
	(
    	X"0000",	X"0000",	X"ffff",	X"c183",	X"8181",	X"0180",	X"0180",	X"0180",   --T 
	   X"0180",	X"0180",	X"0180",	X"0180",	X"0180",	X"0ff0",	X"0000",	X"0000"  
	),
	(
	   X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"03c0",	X"0180",   --:
	   X"0000",	X"0000",	X"0000",	X"0000",	X"0180",	X"03c0",	X"0000",	X"0000"	   
	),
	(
	   X"0000",	X"07e0",	X"0ff0",	X"1818",	X"380c",	X"300c",	X"6006",	X"6006",   --逆轉
	   X"6006",	X"6006",	X"300c",	X"300c",	X"1918",	X"0f30",	X"0700",	X"0f00"	   
	),
	(
	   X"0000",	X"07e0",	X"0ff0",	X"1818",	X"380c",	X"300c",	X"6006",	X"6006",   --正轉
	   X"6006",	X"6006",	X"300c",	X"300c",	X"1898",	X"0cf0",	X"00e0",	X"00f0"		   
	),
   ( 
	   X"0000",	X"0000",	X"1210",	X"0bf8",	X"0250",	X"22b0",	X"1310",	X"03f0",   --溫
	   X"0000",	X"0bf8",	X"12a8",	X"12a8",	X"22a8",	X"27fc",	X"0000",	X"0000"
   ),
   (
	   X"0000",	X"0000",	X"0080",	X"1ffc",	X"1220",	X"1ffc",	X"1220",	X"13e0",   --度
	   X"1000",	X"17f0",	X"1120",	X"10c0",	X"2130",	X"2e0c",	X"0000",	X"0000"
   ),
   (	
	   X"0000",	X"0000",	X"13f8",	X"0a08",	X"03f8",	X"2208",	X"13f8",	X"0114",   --濕
	   X"02a8",	X"0954",	X"13fc",	X"1000",	X"22a8",	X"24a4",	X"0000",	X"0000"
   )      	
);
--LCD   
SIGNAL  clk_25MHz : STD_LOGIC;
--SIGNAL  mode_lcd :integer range 0 to 15;
  
SIGNAL  fsm,fsm_back,fsm_back2   :integer range 0 to 200;
SIGNAL  data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  DC_data    : std_logic;   


--TSL2561
SIGNAL  TSL2561_int  :integer range 0 to 9999:=32;            
SIGNAL  d0, d0_last  :integer range 0 to 9999;   
SIGNAL  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9;  
begin
           
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
	begin	
      if(nReset ='0')then                                	                
         fsm <= 0;
         delay_1 :=0;
         lcd_write <= '0';       
         lcd_show  <= '0';

      ELSIF(clk'EVENT AND clk='1')then     
 
         if (SW='1') then                    -- 開始顏色DEMO            
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
                        if delay_1 >= 5000000 then                     
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
                        lcd_color     <= "000001";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 64;                             
    
               when 64 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 65;

               when 65 =>                                  -- delay 1s  
                        delay_1 :=0;    
                        fsm       <= 59;                       
                        fsm_back2 <= 66;

               when 66 =>                                  -- 3 修改圖型 
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "000010";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 67;

               when 67 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 68;

               when 68 =>                                  -- delay 1s  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 69;
               
               when 69 =>                                  -- 4
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "000011";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 70;

               when 70 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 71;

               when 71 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 72;           

               when 72 =>                                  -- 5
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "010000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 73;

               when 73 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 74;

               when 74 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 75; 


               when 75 =>                                  -- 6
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "100000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 76;

               when 76 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 77;

               when 77 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 78;

               when 78 =>                                  -- 7
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "110000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 79;

               when 79 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 80;

               when 80 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 81;

               when 81 =>                                  -- 8
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "000100";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 82;

               when 82 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 83;

               when 83 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 84;

               when 84 =>                                  -- 9
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "001000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 85;

               when 85 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 86;

               when 86 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 87;

               when 87 =>                                  -- 10
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "001100";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 88;

               when 88 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 89;

               when 89 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 90;

               when 90 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 91;
                        
               when 91 =>                                  -- LOOP,全亮
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";         -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 63;                              

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

   ----------------------------------------------------------------------------開始貼圖, 字型16x16 
               when 111 =>                                   -- 1.初始化變數   
                        pos_x       := 0;
                        pos_y       := 0;
                        varl        := 0;                    -- 顯示文字的選擇
                        cnt_number  := 0;                    -- 目前顯示第幾個文字                        
                        cnt_number_max := 1;                 -- 要顯示的文字數量   
                        cnt1        := 0;                    -- 
                        bit_index   := 15;                   -- 
						--TSL2561_int  <= CONV_INTEGER(TSL2561_data) mod 10000;						
 
--                        fsm         <= 113;   
                        fsm         <= 112;   
                                               
               when 112 =>                                   -- 2.設定顯示文字 & 貼圖位置                    

                        if (cnt_number = 0)  then   
                           if TSL2561_int >= 0 then                                                   
                              varl := 14;                       -- '正逆轉'
                              disp_color    := "000000";        -- 文字的顏色,黑
                           else
                              varl := 15;                       -- '正逆轉'
                              disp_color    := "110000";        -- 文字的顏色,紅                              
                           end if;      
                           pos_x_start  := 64;                           
                           pos_y_start  := 80;                                                                                                                                                                                         
                        end if;
                        fsm       <= 113;                   
                        
               when 113 =>                                     -- 2.設定LCD位址,範圍0 - (128*160-1)  ,111-115完成8點(1個BYTE)的資料寫入
                        pos_now := pos_x_start + ((pos_y_start + pos_y) * 128) + pos_x;    
                        pos_x   := pos_x + 1;                         
                        fsm       <= 114;                   

               when 114 =>                                     -- set address 
                        lcd_address   <= conv_std_logic_vector(pos_now,15);
                        fsm  <= 115;
                        
               when 115 =>                                     -- set data
                        if(table16(varl, cnt1/font_size)(bit_index/font_size) = '1') then                                                      
                           lcd_color  <= disp_color;                 --                              
                        else
                           lcd_color  <= "111111";                                             
                        end if;                               
                        fsm  <= 116; 
                        
               when 116 =>                                     -- write
                        if(lcd_busy = '0') then              --等待LCD閒置
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm  <= 117; 
                        end if;

               when 117 =>                                     -- write
                        if delay_1 >= 10 then 
                           lcd_write <= '0';
                           delay_1 :=0;     

                           if pos_x >= 16*font_size then                    --字體寬度20
                              pos_x := 0; 
                              pos_y := pos_y + 1;                 --字體高度40(40/8byte = 5)
                           end if;
                                                                              
                           if(bit_index = 0) then
                              bit_index := 16*font_size-1;
                              fsm  <= 118; 						-- next row
                           else   
                              bit_index   := bit_index - 1;                                             
                              fsm  <= 113;      				  -- next bit                   
                           end if;                                                                                                                                                                                                          
                        else
                           delay_1:=delay_1+1;                          
                        end if;                  
                                                                  
               when 118 =>                                                               
                           if cnt1 >= 16*font_size-1 then                  --每個數字16個word(16bits)
                              cnt1 := 0;
                              fsm  <= 119; 
                           else
                              cnt1 := cnt1 + 1;                     
                              fsm  <= 112; 
                           end if;
                        
               when 119 =>                                    
                        if (cnt_number < (cnt_number_max-1)) then  -- 顯示數量
                           cnt_number := cnt_number + 1;           -- 指到下個數字                                                                                 
                           pos_x       := 0;
                           pos_y       := 0;
                           
                           fsm       <= 113;      
                        else
                           cnt_number := 0;
                           fsm       <= 120;                                
                        end if;   
               
               when 120 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 121;                  

               when 121 =>                                  -- delay 1s , 1秒更新1次資料  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 110;
               
               when others =>                          
                             
            END CASE;             
            
         end if;                                                             
                             
      end if; 	   

	end process;

   
  
end behavioral;