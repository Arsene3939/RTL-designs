LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity lcdControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_lcd: in integer range 0 to 15;
        dipsw:in std_logic_vector(7 downto 0);
        
        LED:buffer std_logic_vector(15 downto 0);
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
        TSL2561_data : STD_LOGIC_VECTOR(19 DOWNTO 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0) ;
        R_SBUF     : in std_logic_vector(7 downto 0) ;
        T_SBUF     : out std_logic_vector(7 downto 0) ;
        card        :in      integer range 0 to 3;
        cost        :in  std_logic_vector(15 downto 0);
        last        :in  std_logic_vector(15 downto 0);
        uart_pers	 : in std_logic;
        lcd_busy  : in    STD_LOGIC;                     
        lcd_write, lcd_show  : out  STD_LOGIC ;
        lcd_address          : buffer  std_logic_vector(14 downto 0);
        lcd_color            : out  std_logic_vector(5 DOWNTO 0) 
       );
end lcdControl;

architecture behavioral of lcdControl is
--LCD NUMBER DATA
type oled_num_tb is array (0 to 14,0 to 15) of std_logic_vector(15 downto 0);                      --19
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
   	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",--A
   	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff"
   ),
   (
      X"0000", X"0000", X"1FE0", X"1FF0", X"1810", X"1818", X"1818", X"1818",--B--B
      X"1FF0", X"1FC0", X"1830", X"1818", X"1FF8", X"1FF0", X"0000", X"0000"
   ),
   (
      X"0000", X"03C0", X"07E0", X"0C30", X"0C30", X"1818", X"1818", X"1818",--C--A
      X"1818", X"1FF8", X"3FFC", X"300C", X"300C", X"300C", X"300C", X"0000"
   ),
   (
      X"0000", X"0000", X"1E18", X"1E18", X"1B18", X"1B18", X"1998", X"1998",--D--N 
      X"18D8", X"18D8", X"1878", X"1878", X"1838", X"0000", X"0000", X"0000"
   ),
   (
      X"0000", X"0000", X"0C10", X"0C30", X"0C60", X"0CC0", X"0D80", X"0F00",--E--K
      X"0F00", X"0D80", X"0CC0", X"0C60", X"0C70", X"0C38", X"0000", X"0000"
   )
);
--LCD   
signal  clk_25MHz : STD_LOGIC;
--signal  mode_lcd :integer range 0 to 15;
  
signal  fsm,fsm_back,fsm_back2   :integer range 0 to 200;
signal  data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal  DC_data    : std_logic;   

--Serial
type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
signal ipress:integer:=0;
signal Serial_max:integer range 0 to 11:=10;
signal addr:std_logic_vector(14 downto 0);

begin
   Serial:process(uart_pers)             --Serial controll
      variable Serial_count:integer range 0 to 11:=0;
   begin
      if falling_edge(uart_pers) then
         if R_SBUF=X"FF" then
            Serial_count:=0;
         else
            Serial_available(Serial_count)<=R_SBUF;
            Serial_count:=Serial_count+1;
         end if;
      end if;
   end process;
   detect:process(key_pressed,workingMode)
begin
   if nreset='0' then
   elsif (key_pressed'EVENT AND key_pressed='1') then
      if workingmode<X"A" then
         ipress<=ipress+1;
         if ipress>3 then
            ipress<=0;
         end if;
      elsif workingmode=X"B" then
      elsif workingmode=X"C" then
         ipress<=0;
      end if;
   end if;
end process;
	process(clk, nReset)                -- LCD
      variable delay_1         :integer range 0 to 100000000;
      variable address_start,address_end   : STD_LOGIC_VECTOR(14 DOWNTO 0); 	               	
      variable disp_color      : STD_LOGIC_VECTOR(5 DOWNTO 0); 	               	
      variable posx0,pos_x_start,pos_y_start,pos_x_end,pos_y_end :integer range 0 to 159;  
      variable pos_x,pos_y    :integer range 0 to 160;         
      variable pos_now              :integer range 0 to 20479;
      variable cnt_number,cnt_number_max,cnt_wire_max   :integer range 0 to 90:=64;
      type starray is array(0 to cnt_number_max-1) of std_logic_vector(15 downto 0);--&Xsize  &color(121) &char
                                                                                    --   4       4         8   
      variable str:starray:=(                                                       --皞蝛箇摮葡鞈 銝64寞摮)
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020"
                           ); 
      variable dx,dy           :integer range 0 to 160;
      variable cnt1        :integer range 0 to 99;                  
      variable bit_index   :integer range 0 to 128; 	               	
      variable font_num    :integer range 0 to 128;
      variable font_Xsize  :integer range 0 to 8:=1;                         --times 0~8
      variable font_Ysize  :integer range 0 to 8:=1;                         --times 0~8
      variable hv          :std_logic:='1';
      variable pos_x_max,pos_y_max:integer range 0 to 160;
      variable now_time    :integer range 0 to 160;
      variable now_TE      :std_logic_vector(3 downto 0):="0000";
      variable now_posy    :integer range 0 to 160;
      variable data_mode   :integer range 0 to 7:=0;
      variable wire_color  :std_logic_vector(3 downto 0):="0000";
      variable delaytime   :integer range 0 to 100000000;
      variable i6066       :integer range 0 to 10:=10;
      variable i68         :integer range 0 to 10:=9;
      variable selectchar  :integer range 0 to 51:=51;
	begin	
      if(nReset ='0')then                                	                
         fsm <= 0;
         delay_1 :=0;
         lcd_write <= '0';       
         lcd_show  <= '0';       
      ELSIF(clk'EVENT AND clk='1')then
 
         if (key_pressed='1' and workingMode = X"C") then
               delay_1 :=0;                        
               lcd_write <= '0';       
               lcd_show  <= '0';
               str:=(
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",
                              X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020",X"0020"
                           ); 
               if mode_lcd=0 or mode_lcd=6 then
                  fsm     <= 100;
               else
                  fsm     <= 110;
               end if; 
         elsif (key_pressed='1' and workingMode = X"A") then
               fsm     <= 100;
         else

            CASE fsm IS                                          

               when 0 =>                                -- idle  


               when 1 =>           
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 60;
                                       
               when 10 =>                                --湔恍
                        if(lcd_busy = '0') then          --蝑LCD蔭
                           lcd_show <= '1';
                           fsm      <= 11;                           
                        end if;                    

               when 11 =>                                                                             
                        if(lcd_busy = '1') then         --蝑敹,銵函內LCD交追cd_show賭誘  
                           lcd_show <= '0';                           
                           delay_1 :=0;
                           fsm      <= 12;
                        end if;                    

               when 12 =>                                                                             
                        if(lcd_busy = '0') then         --蝑敹,銵函內LCD交追cd_show賭誘  
                           fsm      <= fsm_back;
                        end if;               
               
               when 20 =>                                    --write ram 
                        if(lcd_busy = '0') then              --蝑LCD蔭
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
               when 24 =>                                    --write ram 
                        lcd_address<="000000000000000";
                        fsm<=25;
               when 25 =>
                        if(lcd_busy = '0') then              --蝑LCD蔭
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm         <= 26;
                        end if;

               when 26 =>                                    
                        if delay_1 >= 10 then 
                           lcd_write <= '0';
                           delay_1 :=0;                                                      
                           fsm      <= 27;
                        else
                           delay_1:=delay_1+1;
                        end if;
                        
               when 27 =>                                    -- set data
                        lcd_address <= lcd_address + "000000000000001"; --------------------*******
                        fsm  <= 28;
                        
               when 28 =>                                    -- address
                        LED(14)<=not LED(14);   
                        if lcd_address="101000000000000" then   -- 128 * 160
                           fsm        <= fsm_back;
                        elsif (lcd_address = address_start) then
                           lcd_address <= address_end;
                           fsm        <= 25;
                        else
                           fsm        <= 25;
                        end if;

--   ----------------------------------------------------------------------------       
               when 59 =>                                  -- delay 1s
                        if delay_1 >= delaytime*50000 then                     
                           delay_1 :=0;
                           fsm <= fsm_back2;
                        else
                           delay_1:=delay_1+1;
                        end if;  



               when 100 =>                                   -- 1 靽格    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f
                        fsm       <= 20;                   
                        fsm_back  <= 101;

               when 101 =>                                   --湔恍    
                        fsm       <= 10;                   
                        fsm_back <= 102;   

               when 102 =>                                   -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 100;
                        
   ----------------------------------------------------------------------------  MODE = "010" ,憿舐內 耦, 撥摨行
               when 110 =>                                   -- 皜恍    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";           -- 其漁
                        fsm       <= 20;                   
                        fsm_back  <= 111;

   ----------------------------------------------------------------------------鞎澆, 摮16x16 
               when 111 =>                                   -- 1.  
                        pos_x       := 0;
                        pos_y       := 0;
                        cnt1        := 0; 
                        bit_index   := 0;
                        hv:='0';                             --閮剖恍箸帖撟
                        if mode_lcd=1 or mode_lcd=2 or mode_lcd=3 or mode_lcd=5 then
                           cnt_number_max:=5;
                           delaytime:=100;
                           str(0):=X"0522";
                           str(1 to 4):=(X"400B",X"400C",X"400D",X"400E");
                           fsm<=112;
                        elsif mode_lcd=4 and card/=0 then
                           cnt_number_max:=12;
                           delaytime:=100;
                           str(0):=X"0022";
                           str(1):=X"600"&conv_std_logic_vector(card,4);
                           str(2):=X"0622";
                           str(3 to 6):=(X"400"&cost(15 downto 12),X"400"&cost(11 downto 8),X"400"&cost(7 downto 4),X"400"&cost(3 downto 0));
                           str(7):=X"0C22";
                           str(8 to 11):=(X"400"&last(15 downto 12),X"400"&last(11 downto 8),X"400"&last(7 downto 4),X"400"&last(3 downto 0));
                           fsm<=112;
                        end if;
						      --TSL2561_int  <= CONV_INTEGER(TSL2561_data) mod 10000;						
--                        fsm         <= 113;
               when 112 =>                                   -- 2.閮剖憿舐內 & 鞎澆雿蔭
                        cnt_number:=0;
                        pos_x_start  := 0;
                        posx0:=pos_x_start;
                        pos_y_start  := 0;
                        fsm       <= 113;
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
                           if hv='0' then
                              pos_now   := pos_x_start + ((pos_y_start + pos_y) * 128) + pos_x;
                              pos_y_max:=160;
                              pos_x_max:=128;
                           else
                              pos_now   := 128-pos_y_start + ((pos_x_start+pos_x) * 128) - pos_y;
                              pos_x_max:=160;
                              pos_y_max:=128;
                           end if;
                           pos_x:=pos_x+1;
                           disp_color:= str(cnt_number)(11)&'0'&str(cnt_number)(10 downto  8)&'0';
                           font_Xsize:= CONV_INTEGER(str(cnt_number)(15 downto 12));
                           font_Ysize:= font_Xsize;
                           fsm<=114;
                        end if;
               when 114 =>                                     -- set address 
                        lcd_address   <= conv_std_logic_vector(pos_now,15);
                        fsm  <= 115;
                        
               when 115 =>
                        if(selectchar=cnt_number xor (table16(CONV_INTEGER(str(cnt_number)(7 downto 0)), cnt1*2/font_Ysize)(16-bit_index*2/font_Xsize) = '1')) then
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
                              if conv_integer(str(cnt_number)(7 downto 0)) <=9 then
                                 pos_x_start:=pos_x_start+5*font_Xsize+1;
                              else
                                 pos_x_start:=pos_x_start+8*font_Xsize+1;
                              end if;
                              if pos_x_start>pos_x_max-20 then
                                 pos_x_start:=0;
                                 pos_y_start:=pos_y_start+font_Ysize*8;
                              end if;
                              fsm  <= 119; 
                           else
                              cnt1 := cnt1 + 1;
                              fsm  <= 115; 
                           end if;
               when 119 =>                                    
                        if (cnt_number < (cnt_number_max-1)) then  -- 憿舐內賊
                           cnt_number := cnt_number + 1;           -- 銝摮
                           pos_x:=0;
                           pos_y:=0;
                           fsm       <= 113;
                        else
                           cnt_number := 0;
                           fsm       <= 120;
                        end if;
               when 120 =>                                   --湔恍    
                        fsm       <= 10;
                        fsm_back  <= 121;
               when 121 =>                                  -- delay 1s , 1蝘甈∟
                        delay_1 :=0;
                        fsm       <= 59;
                        fsm_back2 <= 110;
               when others =>                          
            end case;             
            
         end if;                                                             
                             
      end if; 	   

	end process;
  
end behavioral;