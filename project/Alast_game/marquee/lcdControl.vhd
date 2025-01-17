LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity lcdControl is
port (   
         clk : in std_logic;
         nReset: in std_logic;
         LED:buffer std_logic_vector(15 downto 0);
         mode_lcd: in integer range 0 to 15;
         HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
         TSL2561_data : STD_LOGIC_VECTOR(19 DOWNTO 0);
         key_pressed,key_pressed2: in std_logic ;
         workingMode: in std_logic_vector(3 downto 0) ;
         T_SBUF     :	buffer std_logic_vector(7 downto 0) ; 
         R_SBUF     : in std_logic_vector(7 downto 0) ;
         uart_pers	 : in std_logic;
         sendclk    : buffer std_logic;

         lcd_busy  : in    STD_LOGIC;                     
         lcd_write, lcd_show  : out  STD_LOGIC ;
         lcd_address          : buffer  std_logic_vector(14 downto 0);
         lcd_color            : out  std_logic_vector(5 DOWNTO 0)
       );
end lcdControl;

architecture behavioral of lcdControl is
--LCD NUMBER DATA
type oled_num_tb is array (0 to 19,0 to 15) of std_logic_vector(15 downto 0);                      --19
constant table16:oled_num_tb:=
(   
   (
      X"1E00", X"1E00", X"6180", X"6180", X"6180", X"6180", X"6180", X"6180",  
      X"6180", X"6180", X"6180", X"6180", X"1E00", X"1E00", X"0000", X"0000"  --0
   ),
   (
      X"0600", X"0600", X"1E00", X"1E00", X"0600", X"0600", X"0600", X"0600",  
      X"0600", X"0600", X"0600", X"0600", X"1F80", X"1F80", X"0000", X"0000"  --1
   ),
   (
      X"1E00", X"1E00", X"6180", X"6180", X"0180", X"0180", X"0180", X"0180",  
      X"0600", X"0600", X"1800", X"1800", X"7F80", X"7F80", X"0000", X"0000"  --2
   ),
   (
      X"1E00", X"1E00", X"6180", X"6180", X"0180", X"0180", X"1E00", X"1E00",  
      X"0180", X"0180", X"6180", X"6180", X"1E00", X"1E00", X"0000", X"0000"  --3
   ),
   (
      X"0600", X"0600", X"1E00", X"1E00", X"6600", X"6600", X"6600", X"6600",  
      X"7F80", X"7F80", X"0600", X"0600", X"0600", X"0600", X"0000", X"0000"  --4
   ),
   (
      X"7F80", X"7F80", X"6000", X"6000", X"6000", X"6000", X"1F80", X"1F80",  
      X"0180", X"0180", X"6180", X"6180", X"1E00", X"1E00", X"0000", X"0000"  --5
   ),
   (
      X"1E00", X"1E00", X"6180", X"6180", X"6000", X"6000", X"7E00", X"7E00",  
      X"6180", X"6180", X"6180", X"6180", X"1E00", X"1E00", X"0000", X"0000"  --6
   ),
   (
      X"7F80", X"7F80", X"6180", X"6180", X"6180", X"6180", X"0600", X"0600",  
      X"0600", X"0600", X"0600", X"0600", X"0600", X"0600", X"0000", X"0000"  --7
   ),
   (
      X"1E00", X"1E00", X"6180", X"6180", X"6180", X"6180", X"1E00", X"1E00",  
      X"6180", X"6180", X"6180", X"6180", X"1E00", X"1E00", X"0000", X"0000"  --8
   ),
   (
      X"1E00", X"1E00", X"6180", X"6180", X"6180", X"6180", X"1F80", X"1F80",  
      X"0180", X"0180", X"6180", X"6180", X"1E00", X"1E00", X"0000", X"0000"  --9
   ),
   ( 
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0FF0", X"0000", X"0000",--=--10
      X"0FF0", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000"
   ),
   (
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000", --11
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000"
   ),
	(
      X"0000", X"0000", X"0180", X"0180", X"0180", X"0180", X"0180", X"3FFC",   --+--12
      X"3FFC", X"0180", X"0180", X"0180", X"0180", X"0180", X"0000", X"0000"
	),
	(
      X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"3FFC",   -----13
      X"3FFC", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000", X"0000"
	),
	(
      X"0000", X"6006", X"700E", X"381C", X"1C38", X"0E70", X"07E0", X"03C0",   --x--14
      X"03C0", X"07E0", X"0E70", X"1C38", X"381C", X"700E", X"6006", X"0000"
	),
	(
      X"0000", X"0000", X"0300", X"0300", X"0180", X"0080", X"0000", X"3FFC",   --/--15
      X"3FFC", X"0000", X"0180", X"0180", X"00C0", X"0040", X"0000", X"0000"		   
	),
   (
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",    --16
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000"
   ),
   (
	   X"0000",	X"0000",	X"0080",	X"1ffc",	X"1220",	X"1ffc",	X"1220",	X"13e0",   ---17
	   X"1000",	X"17f0",	X"1120",	X"10c0",	X"2130",	X"2e0c",	X"0000",	X"0000"
   ),
   (	
	   X"0000",	X"0000",	X"13f8",	X"0a08",	X"03f8",	X"2208",	X"13f8",	X"0114",   ---18
	   X"02a8",	X"0954",	X"13fc",	X"1000",	X"22a8",	X"24a4",	X"0000",	X"0000"
   ),
   (
      X"FDFC", X"8424", X"8424", X"8444", X"8444", X"FCA4", X"8518", X"8400",
      X"85FC", X"8504", X"FDFC", X"0000", X"66D8", X"66D8", X"C36C", X"8126"
   )
);
--LCD   
signal  clk_25MHz : STD_LOGIC;
--signal  mode_lcd :integer range 0 to 15;
  
signal  fsm,fsm_back,fsm_back2   :integer range 0 to 200;
signal  data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal  DC_data    : std_logic;

-- computer
shared variable ipress:integer range 0 to 99:=0;
signal selectchar:integer range 0 to 51:=51;
signal FD:std_logic_vector(30 downto 0);
signal workinginteger:integer range 0 to 15:=0;
type starray is array(0 to 63) of std_logic_vector(15 downto 0);--&size  &color(121) &char
--   4       4         8   
shared variable str:starray:=(                                                       --□殉⊿64荒撖謅
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
   X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020"
);
begin
   process(clk, nReset)                -- LCD
      variable delay_1         :integer range 0 to 50000000;                                                      	               	
      variable address_start,address_end   : STD_LOGIC_VECTOR(14 DOWNTO 0);
      variable disp_color      : STD_LOGIC_VECTOR(5 DOWNTO 0);
      variable posx0,pos_x_start,pos_y_start,pos_x_end,pos_y_end :integer range 0 to 159;
      variable pos_x,pos_y    :integer range 0 to 160;
      variable pos_now              :integer range 0 to 20479;
      variable cnt_number,cnt_number_max   :integer range 0 to 90:=64;
 
      variable dx,dy           :integer range 0 to 160;
      variable cnt1        :integer range 0 to 99;                  
      variable bit_index   :integer range 0 to 128; 	               	
      variable font_num    :integer range 0 to 128;
      variable font_Xsize  :integer range 0 to 7:=1;                         --times 0~7
      variable font_Ysize  :integer range 0 to 7:=1;                         --times 0~7
      variable hv          :std_logic:='1';
      variable pos_x_max,pos_y_max:integer range 0 to 160;
      variable now_time    :integer range 0 to 1000:=0;
      variable now_posy    :integer range 0 to 160;
      variable data_mode   :integer range 0 to 7:=0;
      variable delaytime   :integer range 0 to 10000:=100;
      variable marquee     :std_logic:='0';
      variable long        :integer range 0 to 1000:=0;
   begin
      if(nReset ='0')then
         fsm <= 0;
         delay_1 :=0;
         lcd_write <= '0';
         lcd_show  <= '0';
      ELSIF(clk'EVENT AND clk='1')then
         if (key_pressed='1' and workingMode = "0000") then                    -- 湛DEMO
               delay_1 :=0;
               lcd_write <= '0';
               lcd_show  <= '0';
               str:=(                                                       --□殉⊿64荒撖謅
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020"
                           ); 
               if (mode_lcd=0) then
                  fsm     <= 1;
               elsif (mode_lcd=1) then
                  fsm     <= 100;                                              --踐走
               else                                                            --輯扳謅
                  fsm     <= 110;
               end if;
         else
            CASE fsm IS

               when 0 =>                                -- idle  


               when 1 =>           
                        delay_1 :=0;  
                        fsm       <= 59;
                        fsm_back2 <= 60;

               when 10 =>                                --皝
                        if(lcd_busy = '0') then          --LCD
                           lcd_show <= '1';
                           fsm      <= 11;                           
                        end if;                    

               when 11 =>                                                                             
                        if(lcd_busy = '1') then         --察,萄兵CD鈭止餈箱d_show鞈剛  
                           lcd_show <= '0';                           
                           delay_1 :=0;    
                           fsm      <= 12;
                        end if;                    

               when 12 =>                                                                             
                        if(lcd_busy = '0') then         --察,萄兵CD鈭止餈箱d_show鞈剛  
                           fsm      <= fsm_back;
                        end if;               
               
               when 20 =>                                    --write ram 
                        if(lcd_busy = '0') then              --LCD
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
                        if delay_1 >= delaytime*50000 then                     
                           delay_1 :=0;
                           fsm <= fsm_back2;
                        else
                           delay_1:=delay_1+1;                          
                        end if;
   ----------------------------------------------------------------------------  MODE = "000" ,遴唳∪    
               when 60 =>                                   -- 1 賣□    
                        lcd_address   <= "000000000000000";                         
                        address_end   := "101000000000000";
                        lcd_color     <= "000001";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 61;                             

               when 61 =>                                   --皝
                        fsm       <= 10;                   
                        fsm_back  <= 62;

               when 62 =>                                   -- delay 1s  
                        delay_1 :=0;
                        fsm       <= 59;                           
                        fsm_back2 <= 63;
               when 63 =>                                   -- 1 賣□    
                        lcd_address   <= "000000000000000";                         
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 64;                             

               when 64 =>                                   --皝    
                        fsm       <= 10;                   
                        fsm_back  <= 65;   

               when 65 =>                                   -- delay 1s  
                        delay_1 :=0;
                        fsm       <= 59;
                        fsm_back2 <= 60;
   ----------------------------------------------------------------------------  MODE = "001" ,鞈迎嗆
               when 100 =>                                   -- 1 賣□    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 101;

               when 101 =>                                   --皝    
                        fsm       <= 10;                   
                        fsm_back <= 102;

               when 102 =>                                   -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 100;
                        
   ----------------------------------------------------------------------------  MODE = "010" ,輯改 謘潸 刻
               when 110 =>                                   -- 謒豰   
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";           -- 嗆
                        fsm       <= 20;                   
                        fsm_back  <= 111;

   ----------------------------------------------------------------------------瞉 殉16x16 
               when 111 =>                                   -- 1.豲▼  
                        pos_x       := 0;
                        pos_y       := 0;
                        cnt1        := 0; 
                        bit_index   := 0;
                        hv:='0';
                        if mode_lcd=2 then
                           cnt_number_max:=12;
                           str(0 to cnt_number_max-1):=(
                              X"0022",X"2110",X"2111",X"210D",X"200"&TE_BUFF(7 downto 4),X"200"&TE_BUFF(3 downto 0),X"2021",--(選,0) 撞: ? ?
                              X"2112",X"2111",X"210D",X"200"&HU_BUFF(7 downto 4),X"200"&HU_BUFF(3 downto 0)                 --         瞍 ? ?
                           );
                           fsm         <= 112;
                        elsif mode_lcd=3 then
                           cnt_number_max:=40;
                           str(0 to cnt_number_max):=(
                              X"2000",X"2001",X"2002",X"2003",X"2004",X"2005",X"2006",X"2007",X"2008",X"2009",X"200A",X"200B",X"200C",X"200D",X"200E",X"200F",X"2010",X"2011",X"2012",X"2013",X"5021",X"1800",X"1801",X"1802",X"1803",X"1804",X"1805",X"1806",X"1807",X"1808",X"1809",X"180A",X"180B",X"180C",X"180D",X"180E",X"180F",X"1810",X"1811",X"1812",X"1813"
                           );
                           fsm         <= 112;
                        elsif mode_lcd=4 then
                           marquee:='1';
                           delaytime:=70;
                           cnt_number_max:=10;
                           str(0):=X"0022";
                           str(1 to cnt_number_max):=(
                              X"3000",X"3001",X"3002",X"3003",X"3004",X"3005",X"3006",X"3007",X"3008",X"3009"--,X"3010",X"3011",X"3012"
                           );
                           fsm         <= 112;
                        end if;
               when 112 =>
                        cnt_number:=0;
                        pos_x_start  := 0;
                        posx0:=pos_x_start;
                        pos_y_start  := 0;
                        long:=0;
                        fsm <= 130;
               when 130 =>
                        if cnt_number<cnt_number_max then
                           if conv_integer(str(cnt_number)(7 downto 0))<9 then
                              long:=long+6;
                           elsif conv_integer(str(cnt_number)(7 downto 0))<32 then
                              long:=long+9;
                           end if;
                           cnt_number:=cnt_number+1;
                           fsm <= 130;
                        else
                           cnt_number:=cnt_number+1;
                           cnt_number:=0;
                           fsm <= 113;
                        end if;
                        
               when 113 =>
                        if str(cnt_number)(7 downto 0)=X"20" or str(cnt_number)(7 downto 0)=X"FF"     then            --捂赯
                           pos_x_start:=pos_x_start+CONV_INTEGER(str(cnt_number)(15 downto 8))*16;
                           cnt_number:=cnt_number+1;
                        elsif str(cnt_number)(7 downto 0)=X"21"  then            --謜
                           font_Ysize:=CONV_INTEGER(str(cnt_number)(15 downto 12));
                           pos_y_start:=pos_y_start+font_Ysize*8;
                           pos_x_start:=posx0;
                           cnt_number:=cnt_number+1;
                        elsif str(cnt_number)(7 downto 0)=X"22"  then            --謜
                           pos_x_start:=CONV_INTEGER(str(cnt_number)(15 downto 12))*10;
                           posx0:=pos_x_start;
                           pos_Y_start:=CONV_INTEGER(str(cnt_number)(11 downto  8))*10;
                           cnt_number:=cnt_number+1;
                        elsif str(cnt_number)(7 downto 0)=X"23"  then            --芸音
                           hv:=not hv;
                           pos_x:=pos_x_start;
                           pos_x_start:=pos_y_start;
                           pos_y_start:=pos_x;
                           pos_x:=0;
                           cnt_number:=cnt_number+1;
                        else
                           disp_color:= str(cnt_number)(11)&'0'&str(cnt_number)(10 downto  8)&'0';
                           font_Xsize:= CONV_INTEGER(str(cnt_number)(15 downto 12));
                           font_Ysize:= font_Xsize;
                           fsm<=114;
                           if marquee='1'then
                              if conv_integer(str(cnt_number)(7 downto 0)) <= 9 then
                                 pos_x_start:=5*font_Xsize+1;
                                 pos_x_start:=pos_x_max-now_time+cnt_number*6*font_Xsize;
                              elsif conv_integer(str(cnt_number)(7 downto 0)) < 20 then
                                 pos_x_start:=8*font_Xsize+1;
                                 pos_x_start:=pos_x_max-now_time+cnt_number*8*font_Xsize;
                              end if;
                           end if;
                           if hv='0' then
                              pos_y_max:=160;
                              pos_x_max:=128;
                              if pos_x_start+pos_x<pos_x_max then
                                 pos_now   := pos_x_start + ((pos_y_start + pos_y) * 128) + pos_x;
                                 LED(0)<='0';
                              else
                                 LED(0)<='1';
                                 --fsm<=121;
                              end if;
                           else
                              pos_x_max:=160;
                              pos_y_max:=128;
                              pos_now   := 128-pos_y_start + ((pos_x_start+pos_x) * 128) - pos_y;
                           end if;
                           pos_x:=pos_x+1;
                        end if;
               when 114 =>                                     -- set address 
                        lcd_address   <= conv_std_logic_vector(pos_now,15);
                        fsm  <= 115;
                        
               when 115 =>
                        if(selectchar=cnt_number xor (table16(CONV_INTEGER(str(cnt_number)(7 downto 0)), cnt1*2/font_Ysize)(15-bit_index*2/font_Xsize) = '1')) then
                           lcd_color  <= disp_color;
                        else
                           lcd_color  <= "111111";
                        end if;
                        fsm  <= 116;
                        
               when 116 =>
                        if(lcd_busy = '0') then
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm  <= 117;
                        end if;

               when 117 =>                                     -- write
                        if delay_1 >= 10 then
                           lcd_write <= '0';
                           delay_1 :=0;     
                           if pos_x >= 8*font_Xsize-1 then
                              pos_x := 0; 
                              pos_y := pos_y + 1;
                           end if;

                           if(bit_index >= 8*font_Xsize-1) then
                              bit_index := 0;
                              fsm  <= 118; 						-- next row
                           else
                              bit_index   := bit_index + 1;                                             
                              fsm  <= 113;      				  -- next bit
                           end if;                                                                                                                                                                                                          
                        else
                           delay_1:=delay_1+1;
                        end if;

               when 118 =>                                                               
                           if cnt1 >= 8*font_Ysize-1 then                  --伍rd(16bits)
                              cnt1 := 0;
                              if marquee='1'then
                                 --
                              else
                                 if conv_integer(str(cnt_number)(7 downto 0)) <=9 then
                                    pos_x_start:=pos_x_start+5*font_Xsize+1;
                                 else
                                    pos_x_start:=pos_x_start+8*font_Xsize+1;
                                 end if;
                                 if pos_x_start>pos_x_max-20 then
                                    pos_x_start:=0;
                                    pos_y_start:=pos_y_start+font_Ysize*8;
                                 end if;
                              end if;
                              fsm  <= 119; 
                           else
                              cnt1 := cnt1 + 1;
                              fsm  <= 115; 
                           end if;
                        
               when 119 =>                                    
                        if (cnt_number < (cnt_number_max)) then  -- 輯扯
                           cnt_number := cnt_number + 1;           -- 抬
                           pos_x:=0;
                           pos_y:=0;
                           fsm       <= 113;
                        else
                           cnt_number := 0;
                           fsm       <= 120; 
                        end if;
               when 120 =>                                   --皝    
                        fsm       <= 10;
                        fsm_back  <= 121;
               when 121 =>                                  -- delay 1s , 1謆
                        delay_1 :=0;
                        now_time:=now_time+font_Xsize;
                        if now_time>=long+256-2*6*3 then
                           now_time:=0;
                        end if;
                        fsm       <= 59;
                        fsm_back2 <= 110;
               when others =>
            END CASE;             
         end if;
      end if;
   end process;
   --LED(7 downto 0)<=not (conv_std_logic_vector(fsm/10,4)&conv_std_logic_vector(fsm mod 10,4));
end behavioral;