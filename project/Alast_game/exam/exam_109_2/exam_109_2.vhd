
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity exam_109_2 is
	port(
         fin, nReset : in 	   std_logic;
		   SD178_sda  	: INOUT  std_logic;                  	   --SD178B IIC SDA() 
         SD178_scl  	: INOUT  std_logic;                  	   --SD178B IIC SCL()                                                              
         SD178_nrst 	: OUT    std_logic;                  	   --SD178B nRESET ()  
		   TSL2561_sda : INOUT  std_logic;                 		--TSL2561 IIC SDA()
         TSL2561_scl : INOUT  std_logic;                 		--TSL2561 IIC SCL()
		   DHT11_PIN 	: inout  std_logic;                   	   --DHT11 PIN
         dipsw1    	: IN 	   std_logic_vector(7 downto 0);    --DIP SW()
         key_col   	: IN 	   std_logic_vector(3 downto 0);    --KEYBOARD ()
         key_scan  	: OUT    std_logic_vector(3 downto 0);  
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
         LED         : buffer	std_logic_vector(15 downto 0);
         BL,RES,CS,DC,SDA,SCL : OUT    std_logic              	--LCD
	 );
end exam_109_2;
architecture beh of exam_109_2 is
component lcdControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_lcd: in integer range 0 to 15; 
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0);
		  R_SBUF		 : in std_LOGIC_vector(7 downto 0) ;
		  uart_pers  : in std_logic;
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
port(								                            --癟簞聶癟礎簧癟簞聶癟翻癟癒癟竄 
        fin, nReset  :in std_logic;                    --癟癟繒49) & RESET145) 
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
type State_type4 is (event_check, button_process );
signal  Main_State  : State_type4;   
--KEYBOARD , DIP switch
signal  key_pressed: std_logic ;
signal  number, workingMode: std_logic_vector(3 downto 0) ;
signal  actionID: std_logic_vector(3 downto 0);
--other
signal  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : std_logic;        
signal  mode_lcd:integer range 0 to 15;
signal  FD:std_logic_vector(50 downto 0);      
--LCD   
signal  lcd_write, lcd_show, lcd_busy    : std_logic;
signal  lcd_address          : std_logic_vector(14 downto 0);
signal  lcd_color            : std_logic_vector(5 DOWNTO 0);  
--Serial
signal  uart_pers    : std_logic;
signal  R_SBUF,T_SBUF: std_logic_vector(7 downto 0);
type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
--dual_array
type arr2 is array(0 to 7) of std_logic_vector(15 downto 0);
signal matrix_data:arr2:=(X"7C83",X"20DF",X"10EF",X"08F7",X"04FB",X"44BB",X"44BB",X"38C7");
--seven_seg_display
signal ssd_data:std_logic_vector(31 downto 0);
begin
    with workingMode select
      actionID<=  X"1" when X"0",
                  X"2" when X"1",
                  X"3" when X"2",
                  X"4" when X"4",
                  X"5" when X"5",
                  X"6" when X"6",
                  X"7" when X"8",
                  X"8" when X"9",
                  X"9" when X"A",
						X"0" when X"D",
                  X"A" when X"7",
                  X"B" when X"B",
                  X"C" when X"F",
                  X"F" when others;
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
      variable Serial_max:integer range 0 to 11:=3;
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
   display:process(FD(20))
      variable i:integer range 0 to 11:=0;
   begin
      if rising_edge(FD(22)) then
         LED(15 downto 8)<=not (Serial_available(i));
         LED(7 downto 0) <=not T_SBUF;
         i:=i+1;
         if i>10 then
            i:=0;
         end if;
      end if;
   end process;
	
	scan:process(FD(10))----------------dual_array
		variable i:integer range 0 to 7:=0;
	begin
		if nReset='0' then
			S<=X"01";
			i:=0;
		elsif rising_edge(FD(12))then
			R<=matrix_data(7-i)(15 downto 8);
			G<=matrix_data(7-i)(7 downto 0);
			S<=S(0)&S(7 downto 1);
			i:=i+1;
		end if;
	end process;
	T_SBUF<=conv_std_logic_vector(mode_lcd,8);
 	process(nReset,clk_1MHz)
      variable delay_1   :integer range 0 to 100;
      variable i,j         :integer range 0 to 100;
      variable dbg: std_logic_vector(5 downto 0); 
 	begin	  
      if(key_pressed = '1' and actionID=X"A")then
         mode_lcd   <= 0;
         delay_1   := 0;
		   dbg := "111111";
         Main_State  <= event_check;
         ssd_data<=X"00000000";
      elsif(clk_1MHz'EVENT AND clk_1MHz='1')then
         CASE Main_State IS
            when event_check=>
            	if (key_pressed = '1') then
         	      delay_1 :=0;
                  Main_State <= button_process;
                  case dipsw1 is
                     when "00000000" =>
                        mode_lcd<=0;
                     when "00000001" =>
                        mode_lcd<=1;
                     when "00000010" =>
                        mode_lcd<=2;
                     when "00000100" =>
                        mode_lcd<=3;
                     when "00001000" =>
                        mode_lcd<=4;
                     when "00010000" =>
                        mode_lcd<=5;
                     when "00100000" =>
                        mode_lcd<=6;
                     when "01000000" =>
                        mode_lcd<=7;
                     when "10000000" =>
                        mode_lcd<=8;
                     when others =>
                        mode_lcd<=9;
                  end case;
                  if actionID<X"A" then
                     ssd_data<=ssd_data(27 downto 0)&actionID;
                  elsif actionID=X"B" then
                     ssd_data<=X"00000000";
                  end if;
               end if;           
                                                                                                                                                
            when button_process =>              		   
                  if delay_1 >= 10 then                                   -- us癟癟罈癟簞職癟簞癒,button_event                        
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
          
   ------------------------------------------------------------------------癟癒癟糧禮癟繒癟簞聶癟簞瞿癟簞職癟穢瞽     
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
		   clk 			   => fin,
         nReset 		   => nReset,
         mode_lcd		   => mode_lcd,
         key_pressed 	=> key_pressed,
         workingMode 	=> actionID,
         R_SBUF 		   => R_SBUF,
         uart_pers		=> uart_pers,
         lcd_address 	=> lcd_address,
         lcd_color   	=> lcd_color, 
         lcd_write 		=> lcd_write, 
         lcd_show  		=> lcd_show,  
         lcd_busy  		=> lcd_busy  
       );
   u3:LCD_DRV           --LCD 癟瞿癟聶罈
      port map(      
		   fin       		=> fin,       
		   nReset    		=> nReset,        
		   BL        		=> BL,
		   RES       		=> RES,
		   CS        		=> CS,
		   DC        		=> DC,
		   SDA       		=> SDA,
		   SCL       		=> SCL,
		   lcd_address => lcd_address,
		   lcd_color   => lcd_color, 
		   lcd_write   => lcd_write, 
		   lcd_show    => lcd_show,
		   lcd_busy    => lcd_busy
   ); 
   u4: keypad
   port map(  
			clk    		=> clk_100hz,
			nReset      => nReset,
			key_col   	=> key_col,               
			key_scan  	=> key_scan ,
			key_pressed => key_pressed,
			number 		=>	number
       );
	u7:uart
     port map(
        clk=>fin,
        rst=>nReset,
        TX=>TX,
        RX=>RX,
        trigger=>key_pressed,
        countE1=>uart_pers,
        R_SBUF=>R_SBUF,
        T_SBUF=>T_SBUF
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
end beh;
