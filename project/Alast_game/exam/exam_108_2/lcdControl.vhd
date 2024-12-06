LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity lcdControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_lcd: in integer range 0 to 15;
        dipsw:in std_logic_vector(7 downto 0);
        
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
        TSL2561_data : STD_LOGIC_VECTOR(19 DOWNTO 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0) ;
        R_SBUF     : in std_logic_vector(7 downto 0) ;
        uart_pers	 : in std_logic;

        moders     : in std_logic;
        motordic    :out std_logic;
        lcd_busy  : in    STD_LOGIC;                     
        lcd_write, lcd_show  : out  STD_LOGIC ;
        lcd_address          : buffer  std_logic_vector(14 downto 0);
        lcd_color            : out  std_logic_vector(5 DOWNTO 0) 
       );
end lcdControl;

architecture behavioral of lcdControl is
--LCD NUMBER DATA
type oled_num_tb is array (0 to 31,0 to 15) of std_logic_vector(15 downto 0);                      --19
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
	   X"0000",	X"0000",	X"ff80",	X"3078",	X"100c",	X"100c",	X"100c",	X"1038",   --R--B
	   X"1fc0",	X"10c0",	X"1060",	X"1030",	X"3818",	X"fe0f",	X"0000",	X"0000"
	),	
	(
    	X"0000",	X"0000",	X"ffff",	X"c183",	X"8181",	X"0180",	X"0180",	X"0180",   --T --C
	   X"0180",	X"0180",	X"0180",	X"0180",	X"0180",	X"0ff0",	X"0000",	X"0000"  
	),
	(
	   X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"03c0",	X"0180",   --:--D
	   X"0000",	X"0000",	X"0000",	X"0000",	X"0180",	X"03c0",	X"0000",	X"0000"	   
	),
	(
	   X"0000",	X"07e0",	X"0ff0",	X"1818",	X"380c",	X"300c",	X"6006",	X"6006",   --正轉--E
	   X"6006",	X"6006",	X"300c",	X"300c",	X"1918",	X"0f30",	X"0700",	X"0f00"	   
	),
	(
	   X"0000",	X"07e0",	X"0ff0",	X"1818",	X"380c",	X"300c",	X"6006",	X"6006",   --反轉--F
	   X"6006",	X"6006",	X"300c",	X"300c",	X"1898",	X"0cf0",	X"00e0",	X"00f0"
	),
   ( 
	   X"0000",	X"0000",	X"1210",	X"0bf8",	X"0250",	X"22b0",	X"1310",	X"03f0",   --溫--10
	   X"0000",	X"0bf8",	X"12a8",	X"12a8",	X"22a8",	X"27fc",	X"0000",	X"0000"
   ),
   (
	   X"0000",	X"0000",	X"0080",	X"1ffc",	X"1220",	X"1ffc",	X"1220",	X"13e0",   --度--11
	   X"1000",	X"17f0",	X"1120",	X"10c0",	X"2130",	X"2e0c",	X"0000",	X"0000"
   ),
   (	
	   X"0000",	X"0000",	X"13f8",	X"0a08",	X"03f8",	X"2208",	X"13f8",	X"0114",   --濕--12
	   X"02a8",	X"0954",	X"13fc",	X"1000",	X"22a8",	X"24a4",	X"0000",	X"0000"
   ),
   (
      X"FDFC", X"8424", X"8424", X"8444", X"8444", X"FCA4", X"8518", X"8400",   --照--13
      X"85FC", X"8504", X"FDFC", X"0000", X"66D8", X"66D8", X"C36C", X"8126"
   ),
   (
      X"0000", X"1800", X"1800", X"1800", X"1800", X"1800", X"1800", X"1800",   --L --14
      X"1800", X"1800", X"1800", X"1800", X"1800", X"1FF0", X"1FF8", X"0000"
   ),
   (
      X"0000", X"0000", X"0000", X"0000", X"3018", X"3018", X"3018", X"3018",   --u --15
      X"3018", X"3018", X"3018", X"3018", X"3018", X"3018", X"1FFC", X"0FF6"
   ),
   (
      X"0000", X"0000", X"0000", X"0000", X"0000", X"300C", X"1818", X"0C30",   --x --16
      X"0660", X"03C0", X"0180", X"03C0", X"0660", X"0C30", X"1818", X"300C"
   ),
   (
      X"0000", X"0000", X"7000", X"53F0", X"77F8", X"0C0C", X"1800", X"1800",   --'C--17
      X"1800", X"1800", X"1800", X"1800", X"1800", X"0C0C", X"07F8", X"03F0"
   ),
   (
      X"0000", X"0000", X"180C", X"2418", X"2430", X"1860", X"00C0", X"0180",   --% --18
      X"0300", X"0618", X"0C24", X"1824", X"3018", X"0000", X"0000", X"0000"
   ),
   (
      X"0000", X"0FF0", X"1FF8", X"381C", X"700E", X"6006", X"6006", X"6006",   --O --19
      X"6006", X"6006", X"6006", X"700E", X"381C", X"1FF8", X"0FF0", X"0000"
   ),
   (
      X"0000", X"3FFC", X"3FFC", X"3000", X"3000", X"3000", X"3000", X"3FF8",   --F --1A
      X"3FF8", X"3000", X"3000", X"3000", X"3000", X"3000", X"3000", X"0000"
   ),
   (
      X"0000", X"0000", X"381C", X"3C3C", X"366C", X"33CC", X"318C", X"318C",   --M --1B
      X"318C", X"318C", X"318C", X"318C", X"318C", X"300C", X"0000", X"0000"
   ),
   (
      X"0000", X"0018", X"0018", X"0018", X"0018", X"0798", X"1FF8", X"1878",   --d --1C
      X"3018", X"3018", X"3018", X"3018", X"1FF8", X"0FD8", X"0000", X"0000"
   ),
   (
      X"0000", X"0000", X"0000", X"03F0", X"07F8", X"0C1C", X"180C", X"180C",   --e-- 1D
      X"1FFC", X"1FFC", X"1800", X"180C", X"0FFC", X"07F0", X"0000", X"0000"
   ),
   (
      X"0000", X"0000", X"1FF0", X"1FF8", X"180C", X"180C", X"180C", X"1FF8",   --R-- 1E
      X"1FF0", X"1B80", X"19C0", X"18E0", X"1878", X"183C", X"0000", X"0000"
   ),
   (
      X"0000", X"0000", X"07F0", X"0FF8", X"180C", X"1800", X"1800", X"1800",   --S-- 1F
      X"0FF8", X"07FC", X"000C", X"100C", X"1FFC", X"0FF0", X"0000", X"0000"
   )
);
--LCD   
signal  clk_25MHz : STD_LOGIC;
--signal  mode_lcd :integer range 0 to 15;
  
signal  fsm,fsm_back,fsm_back2   :integer range 0 to 200;
signal  data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal  DC_data    : std_logic;   


--TSL2561
signal  TSL2561_int  :integer range 0 to 9999:=32;            
signal  d0, d0_last  :integer range 0 to 9999;   
signal  lx1,lx2,lx3,lx4,lx5 :std_logic_vector(3 downto 0);
--Serial
type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
shared variable ipress:integer:=0;
signal Serial_max:integer range 0 to 11:=10;

begin
   Serial:process(uart_pers)             --Serial controll
      variable Serial_count:integer range 0 to 11:=0;
   begin
      if falling_edge(uart_pers) then
         if R_SBUF=X"FF" or Serial_count>Serial_max then
            Serial_count:=0;
         else
            Serial_available(Serial_count)<=R_SBUF;
            Serial_count:=Serial_count+1;
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
      type wirarray is array(0 to 15) of std_logic_vector(35 downto 0);  --x_start & y_start & x_end & y_end &color
                                                                                       --   4         4        4       4      4
      variable wire:wirarray:=(                                                        --皞蝛箇怎鞈 銝16
                              X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",
                              X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F",X"00000000F"
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
      variable i6066       :integer range 0 to 3:=0;
      variable stt         :std_logic:='0';
      variable i68         :integer range 0 to 10:=9;
      variable selectchar  :integer range 0 to 51:=51;
	begin	
      if(nReset ='0')then                                	                
         fsm <= 0;
         delay_1 :=0;
         lcd_write <= '0';       
         lcd_show  <= '0';       

      ELSIF(clk'EVENT AND clk='1')then     
 
         if (key_pressed='1' and workingMode = "0000") then                    -- 憿DEMO            
               delay_1 :=0;                        
               lcd_write <= '0';       
               lcd_show  <= '0';                   
               str:=(                                                       --皞蝛箇摮葡鞈 銝64寞摮)
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
               elsif (mode_lcd=7) then
                  fsm     <= 100;                                              --函
               else                                                            --憿舐內摮葡
                  fsm     <= 110;
               end if; 

         elsif (key_pressed='1' and workingMode = "0010" and mode_lcd=0) then                 -- 迫憿DEMO
            fsm <= 0;
            delay_1 :=0;

         else

            CASE fsm IS                                          

               when 0 =>                                -- idle  


               when 1 =>           
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 69;
                                       
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
                  
--   ----------------------------------------------------------------------------       
               when 59 =>                                  -- delay 1s
                        if delay_1 >= delaytime*50000 then                     
                           delay_1 :=0;
                           fsm <= fsm_back2;
                        else
                           delay_1:=delay_1+1;
                        end if;
   ----------------------------------------------------------------------------  MODE = "000" ,憿撅內    
               when 69 =>                                   -- 1 靽格    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";
                        fsm<=70;
               when 70 =>                                  -- 2 靽格                                                             
                        fsm       <= 20;
                        fsm_back  <= 71;
               when 71 =>                                   --湔恍    
                        fsm       <= 10;                   
                        fsm_back  <= 72;
               when 72 =>                                  -- delay 1s  
                        delay_1 :=0;   
                        delaytime:=100;
                        fsm       <= 59;
                        fsm_back2 <= 60;
               when 60 =>                                   -- 1 靽格
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "0000"&conv_std_logic_vector(i6066,2);
                        fsm<=61;
               when 61 =>                                  -- 2 靽格                                                             
                        fsm       <= 20;                   
                        fsm_back  <= 62;
               when 62 =>                                   -- 1 靽格    
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "00"&conv_std_logic_vector(i6066,2)&"00";
                        fsm<=63;
               when 63 =>                                  -- 2 靽格                                                             
                        fsm       <= 20;                   
                        fsm_back  <= 64;
               when 64 =>                                   -- 1 靽格    
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= conv_std_logic_vector(i6066,2)&"00"&"00";
                        fsm<=65;
               when 65 =>                                  -- 2 靽格                                                             
                        fsm       <= 20;                   
                        fsm_back  <= 66;
               when 66 =>                                   --湔恍    
                        fsm       <= 10;                   
                        fsm_back  <= 67;
               when 67 =>                                  -- delay 1s  
                        delay_1 :=0;   
                        delaytime:=100;
                        fsm       <= 59;
                        fsm_back2 <= 60;
                        i6066:=i6066+conv_integer(stt)*2-1;
                        if i6066>=3 then
                           stt:='0';
                        elsif i6066<=0 then
                           stt:='1';
                        end if;
   ----------------------------------------------------------------------------  MODE = "001" ,質其漁
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
                        if mode_lcd=15 then
                           cnt_number_max:=19;
                           delaytime:=100;
                           if dipsw(0)='1'then
                              str(0 to 8):=(X"0023",X"0022",X"380"&lx2,X"380"&lx3,X"380"&lx4,X"380"&lx5,X"2814",X"2815",X"2816");
                           elsif dipsw(0)='0' then
                              str(0 to 8):=(X"0022",X"0023",X"0120",X"4119",X"411A",X"411A",X"0020",X"0020",X"0020");
                           end if;
                           if dipsw(1)='1'then
                              str(9 to 13):=(X"0522",X"0120",X"400"&TE_BUFF(7 downto 4),X"400"&TE_BUFF(3 downto 0),X"4617");
                           elsif dipsw(1)='0' then
                              str(9 to 13):=(X"0522",X"0120",X"4119",X"411A",X"411A");
                           end if;
                           if dipsw(2)='1'then
                              str(14 to 18):=(X"0A22",X"0120",X"400"&HU_BUFF(7 downto 4),X"400"&HU_BUFF(3 downto 0),X"4118");
                           elsif dipsw(2)='0' then
                              str(14 to 18):=(X"0A22",X"0120",X"4119",X"411A",X"411A");
                           end if;
                           str(19):=X"100"&Serial_available(0)(3 downto 0);
                           fsm         <= 112;
                        elsif mode_lcd=2 or mode_lcd=3 then
                           cnt_number_max:=20;
                           delaytime:=100;
                           str(0):=X"0022";
                           str(1 to 6):=(X"201B",X"2019",X"201C",X"201D",X"200D",X"201"&conv_std_logic_vector(14+conv_integer(moders),4));
                           str(7 to 15):=(X"3021",X"380"&lx2,X"380"&lx3,X"380"&lx4,X"380"&lx5,X"2814",X"2815",X"2816",X"4021");
                           if conv_integer(lx2)*1000+conv_integer(lx3)*100+conv_integer(lx4)*10+conv_integer(lx5) > 15 then
                              if moders='1' then
                                 str(16 to 19):=(X"300B",X"300C",X"300D",X"300E");
                                 motordic<='1';
                              else
                                 str(16 to 19):=(X"300B",X"300C",X"300D",X"300F");
                                 motordic<='0';
                              end if;
                           else
                              if moders='1' then
                                 str(16 to 19):=(X"300B",X"300C",X"300D",X"310F");
                                 motordic<='0';
                              else
                                 str(16 to 19):=(X"300B",X"300C",X"300D",X"310E");
                                 motordic<='1';
                              end if;
                           end if;
                           fsm         <= 112;
                        end if;
						      lx1 <= TSL2561_data(19 downto 16);
						      lx2 <= TSL2561_data(15 downto 12);
						      lx3 <= TSL2561_data(11 downto 8);
						      lx4 <= TSL2561_data(7 downto 4);
						      lx5 <= TSL2561_data(3 downto 0);
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
                           if now_time>129 then
                              now_time:=0;
                              fsm <= 110;
                           end if;
                        end if;
               when 120 =>                                   --湔恍    
                        fsm       <= 10;
                        fsm_back  <= 121;
               when 121 =>                                  -- delay 1s , 1蝘甈∟
                        delay_1 :=0;
                        fsm       <= 59;
                        if mode_lcd=3 then
                           fsm_back2 <= 111;
                        elsif mode_lcd=0 then
                           fsm_back2 <= 68;
                        else
                           fsm_back2 <= 110;
                        end if; 
               when others =>                          
            END CASE;             
            
         end if;                                                             
                             
      end if; 	   

	end process;
   
  
end behavioral;