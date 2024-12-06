
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity exam_108_1 is
    port(
         fin, nReset : in      std_logic;
           SD178_sda    : INOUT  std_logic;                        --SD178B IIC SDA()
         SD178_scl      : INOUT  std_logic;                        --SD178B IIC SCL()
         SD178_nrst     : OUT    std_logic;                        --SD178B nRESET ()
           TSL2561_sda : INOUT  std_logic;                      --TSL2561 IIC SDA()
         TSL2561_scl : INOUT  std_logic;                        --TSL2561 IIC SCL()
           DHT11_PIN    : inout  std_logic;                        --DHT11 PIN
         dipsw1     : IN       std_logic_vector(7 downto 0);    --DIP SW()
         key_col    : IN       std_logic_vector(3 downto 0);    --KEYBOARD ()
         key_scan   : OUT    std_logic_vector(3 downto 0);
         bz          :out std_logic;
         --ssd
         ssd1        :buffer std_logic_vector(7 downto 0);
         digit1      :buffer std_logic_vector(3 downto 0);
         ssd2        :buffer std_logic_vector(7 downto 0);
         digit2      :buffer std_logic_vector(3 downto 0);

         -- uart --
         TX          : out    std_logic;
         RX          : in     std_logic; 
         S,R,G       : buffer std_logic_vector(7 downto 0);    --dual_array
         LED         : buffer   std_logic_vector(15 downto 0);
         BL,RES,CS,DC,SDA,SCL : OUT    std_logic;               --LCD
            -- motor 
            mp,mm           :buffer std_logic
     );
end exam_108_1;
architecture beh of exam_108_1 is
component lcdControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_lcd: in integer range 0 to 15; 
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0);
          dipsw     :  in std_logic_vector(7 downto 0);
          T_SBUF         : out std_logic_vector(7 downto 0) ;
          R_SBUF         : in std_logic_vector(7 downto 0) ;
        uart_pers  : in std_logic;
        LED       :buffer std_logic_vector(15 downto 0) ;
      --bank
         card        :in      integer range 0 to 3;
         cost        :in  std_logic_vector(15 downto 0);
         last        :in  std_logic_vector(15 downto 0);
        lcd_busy  : in    std_logic;                     
        lcd_write, lcd_show  : out  std_logic ;
        lcd_address          : buffer  std_logic_vector(14 downto 0);
        lcd_color            : out  std_logic_vector(5 DOWNTO 0)
       );
end component lcdControl;
component clock_generator is
port( 
     fin:in std_logic;
     clk_1MHz:buffer std_logic ;
     clk_1KHz:buffer std_logic ;
     clk_100Hz:buffer std_logic ;
     clk_1Hz:buffer std_logic  
    );
end component clock_generator;
component keypad is
port (  clk : in std_logic;
        nReset: in std_logic;
        key_col   : IN std_logic_vector(3 downto 0);        --BUTTON ()               
        key_scan  : OUT  std_logic_vector(3 downto 0);  
        key_pressed: out std_logic ;
        number: out std_logic_vector(3 downto 0)
       );
end component keypad;
component LCD_DRV is
port(                                                           --
        fin, nReset  :in std_logic;                    --) & RESET145) 
        BL,RES,CS,DC,SDA,SCL : OUT    std_logic;       --LCD 
        lcd_busy  : OUT    std_logic;
        lcd_write, lcd_show  : in  std_logic ;
        lcd_address          : in  std_logic_vector(14 downto 0);
        lcd_color            : in  std_logic_vector(5 DOWNTO 0)               
    );
end component LCD_DRV;
component uart is
    port(
        rst,clk:in std_logic;
        TX:buffer std_logic;
        RX:in std_logic;
        countE1:buffer std_logic;
        trigger:in std_logic;
        T_SBUF:in  std_logic_vector(7 downto 0);
        R_SBUF:out std_logic_vector(7 downto 0)
    );
end component uart;
component seven_seg_display is
   port(
      cathed:in std_logic;
      rst:in std_logic;
      ck0:in std_logic;
      digit1:buffer std_logic_vector(3 downto 0);
      ssd1:buffer std_logic_vector(7 downto 0);
      digit2:buffer std_logic_vector(3 downto 0);
      ssd2:buffer std_logic_vector(7 downto 0);
      display_data: in std_logic_vector(31 downto 0);
      point:in integer range 0 to 7
   );
end component seven_seg_display;
component pwm is
    port(
        rst,clk:in std_logic;
        pin1,pin2:buffer std_logic;
        duty:in integer range 0 to 10;
        motor_dir:in std_logic
    );
end component pwm;
type State_type4 is (event_check, button_process,delay);
SIGNAL  Main_State  : State_type4;   
--TSL2561
SIGNAL  TSL2561_data : STD_LOGIC_VECTOR(19 DOWNTO 0); --5 digits in BCD
SIGNAL  TSL2561_int  :integer range 0 to 9999;
SIGNAL  d0, d0_last  :integer range 0 to 9999;
SIGNAL  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9; 
--DHT11
SIGNAL HU_BUFF, TE_BUFF : STD_LOGIC_VECTOR(7 DOWNTO 0);  
SIGNAL DHT11_error : STD_LOGIC;   
--KEYBOARD , DIP switch
signal  key_pressed: std_logic ;
signal  number, workingMode: std_logic_vector(3 downto 0) ;
signal  actionID: std_logic_vector(3 downto 0) ;           
--other
SIGNAL  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : std_logic;        
SIGNAL  mode_lcd, mode_7seg, mode_sd178, mode_motor   :integer range 0 to 15;
SIGNAL  motor_speed   :integer range 0 to 10;
SIGNAL  motor_dir : std_logic:='0';
signal  FD:std_logic_vector(50 downto 0);
--LCD
SIGNAL  lcd_write, lcd_show, lcd_busy    : std_logic;
SIGNAL  lcd_address          : std_logic_vector(14 downto 0);
SIGNAL  lcd_color            : std_logic_vector(5 DOWNTO 0);  
signal card :integer range 0 to 3;
signal cost :integer range 0 to 9999;
signal last :integer range 0 to 9999;
type   pricearr is array(0 to 2) of integer range 0 to 3000;
signal price:pricearr:=(1000,2000,3000);
--SD178B  
signal        SD178_debug :   STD_LOGIC_vector(3 downto 0); 
--Serial
signal  uart_pers    : std_logic;
signal  R_SBUF,T_SBUF: std_logic_vector(7 downto 0);
type    arr1 is array(0 to 4) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF");
type passarr is array(0 to 2) of arr1;
signal password :passarr:=((X"01",X"02",X"03",X"04",X"05"),(X"02",X"03",X"04",X"05",X"06"),(X"03",X"04",X"05",X"06",X"07"));
--dual_array
type arr2 is array(0 to 7) of std_logic_vector(15 downto 0);
signal matrix_data:arr2:=(X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000");
constant arch:arr2:=(X"1818",X"3C3C",X"7E7E",X"1818",X"1818",X"1818",X"1818",X"1818");
--seven_seg_display
signal ssd_data:std_logic_vector(31 downto 0);
signal lcd_LED,main_LED:std_logic_vector(15 downto 0);
signal LED_select:std_logic:='0';
begin
    LED_select<=dipsw1(0);
   LED<=not lcd_LED when LED_select='1' else not main_LED;
   fre:process(nReset,fin)
    begin
        if nReset='0' then
            FD<=(others=>'0');
        elsif rising_edge(fin)then
            FD<=FD+1;
        end if;
   end process fre;
    process(key_pressed)
    begin
        if(rising_edge(key_pressed))then
            workingMode <= number ;
        end if;
    end process;
   Serial:process(uart_pers)             --Serial controll
   variable Serial_count:integer range 0 to 11:=0;
   begin
      if falling_edge(uart_pers) then
       if R_SBUF=X"FF" then
          Serial_count:=0;
          Serial_available(0 to 4)<=(X"FF",X"FF",X"FF",X"FF",X"FF");
       else
          Serial_available(Serial_count)<=R_SBUF;
          Serial_count:=Serial_count+1;
       end if;
    end if;
 end process;
   
   display:process(FD(22))
      variable i:integer range 0 to 11:=0;
   begin
      if rising_edge(FD(22)) then
         main_LED(15 downto 8)<=Serial_available(i);
         i:=i+1;
         if i>5 then
            i:=0;
         end if;
      end if;
   end process;

    scan:process(FD(10))----------------dual_array
      variable i:integer range 0 to 7:=0;
      variable i2:integer range 0 to 15:=0;
      variable matrixfsm:integer range 0 to 30:=0;
      variable x,y:integer range 0 to 4:=0;
        variable ss:std_logic_vector(2 downto 0);
    begin
        if nReset='0' then
         S<=X"01";
         matrixfsm:=0;
            i:=0;
      elsif rising_edge(FD(12))then
         case matrixfsm is
            when 0=>
               if mode_lcd=0 then
                  matrix_data<=(X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF");
                  matrixfsm:=2;
               elsif (mode_lcd=1 and dipsw1=X"000") or mode_lcd=6 then
                  matrix_data<=arch;
                  matrixfsm:=2;
               elsif (mode_lcd=2 or mode_lcd=3 or mode_lcd=4)and dipsw1/=X"00" then
                  matrix_data<=(X"3C00",X"3C00",X"3C00",X"3C00",X"3C00",X"3C00",X"3C00",X"3C00");
                  matrixfsm:=2;
               elsif mode_lcd=5 and dipsw1/=X"000" then
                  matrix_data<=(X"3C3C",X"3C3C",X"3C3C",X"3C3C",X"3C3C",X"3C3C",X"3C3C",X"3C3C");
                  matrixfsm:=2;
               elsif mode_lcd=5 and dipsw1=X"000" then
                  matrix_data<=(X"003C",X"003C",X"003C",X"003C",X"003C",X"003C",X"003C",X"003C");
                  matrixfsm:=2;
               end if;
               x:=0;
               y:=0;
               --matrixfsm:=1;
               ss:=dipsw1(7 downto 5);
            when 2 =>
                  R<=not matrix_data(i)(15 downto 8);
                  G<=not matrix_data(i)(7 downto 0);
                  S<=S(0)&S(7 downto 1);
               i:=i+1;
               
               if key_pressed='1' or dipsw1(7 downto 5)/=ss then
                  matrixfsm:=0;
               end if;
               ss:=dipsw1(7 downto 5);
                when others =>
                    matrixfsm:=2;
         end case;
        end if;
   end process;
   
   with workingMode select
   actionID<=  X"1" when X"0",
               X"2" when X"1",
               X"3" when X"2",
               X"A" when X"3",
               X"4" when X"4",
               X"5" when X"5",
               X"6" when X"6",
               X"B" when X"7",
               X"7" when X"8",
               X"8" when X"9",
               X"9" when X"A",
               X"C" when X"B",
               X"0" when X"D",
               X"F" when others;
   with dipsw1(7 downto 5) select
      card<=1 when "100",
            2 when "010",
            3 when "001",
                0 when others;
    process(nReset,clk_1MHz)            --
      variable delay_1   :integer range 0 to 100;
      variable i,j       :integer range 0 to 100;
      variable dbg: std_logic_vector(5 downto 0); 
        variable times:integer range 0 to 50000000:=0;
    begin     
      if(key_pressed='1' and actionID=X"A")then
         mode_lcd   <= 0;
         delay_1   := 0;
       dbg := "111111";
       times:=0;
       cost<=0;
       Main_State  <= event_check;
      ELSIF(clk_1MHz'EVENT AND clk_1MHz='1')then
         CASE Main_State IS
            when event_check=>
               if (key_pressed = '1') then
                  if mode_lcd=3 then
                     last<=price(card-1);
                     ssd_data(31 downto 16)<=(conv_std_logic_vector(last/1000,4)&conv_std_logic_vector((last/100)mod 10,4)&conv_std_logic_vector((last/10)mod 10,4)&conv_std_logic_vector(last mod 10,4));
                  end if;
                  if mode_lcd=3 and actionID<=X"9" and cost<1000 then
                     ssd_data(15 downto 0)<=ssd_data(11 downto 0)&actionID;
                     cost<=cost*10+conv_integer(actionID);
                  end if;
                  if actionID=X"A" then
                     cost<=0;
                     last<=0;
                     price<=(1000,2000,3000);
                     ssd_data<=X"00000000";
                  elsif actionID=X"C" then
                     if mode_lcd=2 then
                        if Serial_available(0 to 4)=password(card-1)(0 to 4) then
                           mode_lcd<=mode_lcd+1;
                        else
                           mode_lcd<=5;
                        end if;
                     elsif mode_lcd=3 then
                        price(card-1)<=price(card-1)-cost;
                        last<=price(card-1);
                        ssd_data(31 downto 16)<=(conv_std_logic_vector(last/1000,4)&conv_std_logic_vector((last/100)mod 10,4)&conv_std_logic_vector((last/10)mod 10,4)&conv_std_logic_vector(last mod 10,4));
                        mode_lcd<=mode_lcd+1;
                     else
                        mode_lcd<=mode_lcd+1;
                            end if;
                  elsif actionID=X"B" then
                     mode_lcd<=mode_lcd-1;
                  end if;
                  main_LED(3 downto 0)<=main_LED(3 downto 0)+1;
                  main_LED(7)<=not main_LED(7);
                  main_LED(6)<=key_pressed;
                  Main_State<=button_process;
               end if;
            when button_process =>                         
                  if delay_1 >= 10 then                                   -- usvent                        
                      if(key_pressed = '0')  then  
                        delay_1 :=0;
                        Main_State <= event_check;                                                                       
                     end if;                           
                  else
                     delay_1:= delay_1+1;
                  end if;  
            when others =>  
                      Main_State <= event_check;                                                                        
                          
            END CASE;            
      end if;      
    end process;
          
   ------------------------------------------------------------------------
   u1:clock_generator
      port map(    
            fin         => fin,  
            clk_1MHz    => clk_1MHz , 
            clk_1KHz    => clk_1KHz ,  
            clk_100Hz   => clk_100hz,
          clk_1Hz     => clk_1hz
    );
   u2: lcdControl
       port map(  
           clk             => fin,
         nReset            => nReset,
         mode_lcd          => mode_lcd,
         key_pressed    => key_pressed,
         workingMode    => actionID,
            dipsw               => dipsw1,
         R_SBUF            => R_SBUF,
         T_SBUF            => T_SBUF,
         uart_pers      => uart_pers,
         card           => card,
         cost           => ssd_data(15 downto 0),
         last           => ssd_data(31 downto 16),
         LED            => lcd_LED,
         lcd_address    => lcd_address,
         lcd_color      => lcd_color, 
         lcd_write      => lcd_write, 
         lcd_show       => lcd_show,  
         lcd_busy       => lcd_busy
       );
   u3:LCD_DRV           --LCD 
      port map(      
           fin              => fin,       
           nReset           => nReset,        
           BL               => BL,
           RES              => RES,
           CS               => CS,
           DC               => DC,
           SDA              => SDA,
           SCL              => SCL,
           lcd_address => lcd_address,
           lcd_color   => lcd_color, 
           lcd_write   => lcd_write, 
           lcd_show    => lcd_show,
           lcd_busy    => lcd_busy
   ); 
   u4: keypad
   port map(  
            clk         => clk_100hz,
            nReset => nReset,
            key_col     => key_col,               
            key_scan    => key_scan ,
            key_pressed => key_pressed, 
            number      =>  number
       );
    u7:uart
     port map(
        clk=>fin,
        rst=>nReset,
        TX=>TX,
        RX=>RX,
        countE1=>uart_pers,
        trigger=>key_pressed,
        R_SBUF=>R_SBUF,
        T_SBUF=>X"0"&conv_std_logic_vector(mode_lcd,4)
     );
   u8:seven_seg_display
   port map(
      cathed=>'0',
      rst=>nReset,
      ck0=>fin,
      digit2=>digit1,
      ssd2=>ssd1,
      digit1=>digit2,
      ssd1=>ssd2,
      point=>3,
      display_data=>ssd_data
   );
   u9:pwm
    port map(
        rst=>nreset,
        clk=>fin,
        pin1=>mm,
        pin2=>mp,
        duty=>motor_speed,
        motor_dir=>motor_dir
    );
end beh;
