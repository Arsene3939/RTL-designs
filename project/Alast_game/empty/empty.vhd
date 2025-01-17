
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity empty is
	port(
         fin, nReset : in 	   std_logic;
		   SD178_sda  	: inout  std_logic;                  	   --SD178B IIC SDA() 
         SD178_scl  	: inout  std_logic;                  	   --SD178B IIC SCL()                                                              
         SD178_nrst 	: out    std_logic;                  	   --SD178B nRESET ()  
		   TSL2561_sda : inout  std_logic;                 		--TSL2561 IIC SDA()
         TSL2561_scl : inout  std_logic;                 		--TSL2561 IIC SCL()                
		   DHT11_PIN 	: inout  std_logic;                   	   --DHT11 Pin
         dipsw1    	: in 	   std_logic_vector(7 downto 0);    --DIP SW()
         key_col   	: in 	   std_logic_vector(3 downto 0);    --KEYBOARD ()
         key_scan  	: out    std_logic_vector(3 downto 0);  
         bz          : buffer std_logic;
			iroiroLED	: buffer std_logic_vector(7 downto 0);
         --ssd
         ssd1        : buffer std_logic_vector(7 downto 0);
         digit1      : buffer std_logic_vector(3 downto 0);
         ssd2        : buffer std_logic_vector(7 downto 0);
         digit2      : buffer std_logic_vector(3 downto 0);
         -- uart --
         TX          : out    std_logic;
         RX          : in     std_logic; 
         S,R,G       : buffer std_logic_vector(7 downto 0);    --dual_array
         LED         : buffer	std_logic_vector(15 downto 0);
         BL,RES,CS,DC,SDA,SCL : out    std_logic;              	--LCD
			-- motor 
			mp,mm			:buffer std_logic
	 );
end empty;
architecture beh of empty is
component pwm is
	port(
		rst,clk:in std_logic;
		pin1,pin2:buffer std_logic;
		duty:in integer range 0 to 10;
		motor_dir:in std_logic
	);
end component pwm;
component lcdControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_lcd: in integer range 0 to 15; 
        HU_BUFF, TE_BUFF : in std_logic_vector(7 downto 0);  
        TSL2561_data : std_logic_vector(19 downto 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0);
		  dipsw		:  in std_logic_vector(7 downto 0);
		  
		  R_SBUF		 : in std_logic_vector(7 downto 0) ;
		  uart_pers  : in std_logic;
		  T_SBUF     : in std_logic_vector(7 downto 0) ;
		  LED			: buffer std_logic_vector(15 downto 0) ;
		  trigger	  : in std_logic;
        lcd_busy  : in    std_logic;                     
        lcd_write, lcd_show  : out  std_logic ;
        lcd_address          : buffer  std_logic_vector(14 downto 0);
        lcd_color            : out  std_logic_vector(5 downto 0)
       );
end component lcdControl;
component DHT11 is
	port(
		clk_50M:in std_logic;
		nrst:in std_logic;
		dat_bus: inout std_logic;
		HU, TE:out std_logic_vector(7 downto 0)
	);
	end component DHT11;
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
        key_col   : in std_logic_vector(3 downto 0);        --BUTTON ()               
        key_scan  : out  std_logic_vector(3 downto 0);  
        key_pressed: out std_logic ;
        number: out std_logic_vector(3 downto 0)
       );
end component keypad;
component LCD_DRV is
port(								                            --芾撒刻頛魂智
        fin, nReset  :in std_logic;                    --9) & RESET145) 
        BL,RES,CS,DC,SDA,SCL : out    std_logic;       --LCD 
        lcd_busy  : out    std_logic;
        lcd_write, lcd_show  : in  std_logic ;
        lcd_address          : in  std_logic_vector(14 downto 0);
        lcd_color            : in  std_logic_vector(5 downto 0)               

    );
end component LCD_DRV;
component SD178 is 
port(
   fin, nReset  :in std_logic;        
   SD178_sda  : inout  std_logic;                  --SD178B IIC SDA() 
   SD178_scl  : inout  std_logic;                  --SD178B IIC SCL()                                                              
   SD178_nrst : out    std_logic;                  --SD178B nRESET ()  

   R_SBUF     : in std_logic_vector(7 downto 0) ;
   uart_pers	 : in std_logic;

   mode_sd178  :in integer range 0 to 15;
   HU_BUFF, TE_BUFF : in std_logic_vector(7 downto 0);  
   TSL2561_data :in std_logic_vector(19 downto 0);
   key_pressed: in std_logic ;
   workingMode: in std_logic_vector(3 downto 0) ;

   dipsw1    : in std_logic_vector(3 downto 0)  ;  --DIP SW()        
   debug  : out std_logic_vector(7 downto 0)
);
end component SD178;
component TSL2561 is
   port(
        clk_50M:in std_logic;
        nrst:in std_logic;
        sda       : inout  std_logic;                   --TSL2561 IIC SDA(161)
        scl       : inout  std_logic;                   --TSL2561 IIC SCL(160)                                                             
        TSL2561_data : out  std_logic_vector(19 downto 0)
    );
end component TSL2561;
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
--TSL2561
signal  TSL2561_data : std_logic_vector(19 downto 0); --5 digits in BCD
signal  TSL2561_int  :integer range 0 to 9999;            
signal  d0, d0_last  :integer range 0 to 9999;   
signal  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9; 
--DHT11
signal HU_BUFF, TE_BUFF : std_logic_vector(7 downto 0);  
signal DHT11_error : std_logic;   
--KEYBOARD , DIP switch
signal  key_pressed: std_logic ;
signal  number, workingMode: std_logic_vector(3 downto 0) ;
signal  actionID: std_logic_vector(3 downto 0) ;           
--other
signal  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : std_logic;        
signal  mode_lcd, mode_7seg, mode_sd178, mode_motor   :integer range 0 to 15;
signal  motor_speed   :integer range 0 to 10;
signal  motor_dir : std_logic:='0';
signal  FD:std_logic_vector(50 downto 0);      
--LCD   
signal  lcd_write, lcd_show, lcd_busy    : std_logic;
signal  lcd_address          : std_logic_vector(14 downto 0);
signal  lcd_color            : std_logic_vector(5 downto 0);  
--SD178B  
signal        SD178_debug :   std_logic_vector(7 downto 0); 
--Serial
signal  uart_pers,trigger    : std_logic;
signal  R_SBUF,T_SBUF: std_logic_vector(7 downto 0);
type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
--dual_array
type arr2 is array(0 to 7) of std_logic_vector(15 downto 0);
signal matrix_data:arr2:=(X"7C83",X"20DF",X"10EF",X"08F7",X"04FB",X"44BB",X"44BB",X"38C7");
--seven_seg_display
signal ssd_data:std_logic_vector(31 downto 0);
signal lcd_LED,main_LED:std_logic_vector(15 downto 0);
signal LED_select:std_logic:='1';
begin
   LED<=not lcd_LED when LED_select='1' else not main_LED;
   ssd_data<=X"01234567";
	bz<=FD(25);
	iroiroLED<=FD(27 downto 20);
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
	T_SBUF<=X"0"&workingMode;
	trigger<=key_pressed;
	Serial:process(uart_pers)             --Serial controll
      variable Serial_count:integer range 0 to 11:=0;
      variable Serial_max:integer range 0 to 11:=10;
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
         i:=i+1;
         if i>10 then
            i:=0;
         end if;
			motor_speed<=motor_speed+1;
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
	
 	process(nReset,clk_1MHz)            --
      variable delay_1   :integer range 0 to 100;
      variable i,j         :integer range 0 to 100;
      variable dbg: std_logic_vector(5 downto 0); 
 	begin	  
      if(nReset='0')then
         mode_lcd   <= 0;
         delay_1   := 0;
		 dbg := "111111";
       Main_State  <= event_check;

      elsif(clk_1MHz'event AND clk_1MHz='1')then
         case Main_State is                
            when event_check=>       
            	if (key_pressed = '1') then 
         	      delay_1 :=0;
         	      Main_State <= button_process;
       	         mode_lcd<=conv_integer(dipsw1(7 downto 4));
               end if;           

            when button_process =>              		   
                  if delay_1 >= 10 then                                   -- us恃景芣button_event                        
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
          
   ------------------------------------------------------------------------撠嗡辣摨
	u0:DHT11
		port map(
			clk_50M=>fin,
			nrst=>nReset,
			dat_bus=>DHT11_PIN,
			HU=>HU_BUFF,
			TE=>TE_BUFF
		);      
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
         HU_BUFF		   => HU_BUFF, 
         TE_BUFF  		=> TE_BUFF,
         TSL2561_data	=> TSL2561_data,
         key_pressed 	=> key_pressed,
         workingMode 	=> workingMode,
			dipsw				=> dipsw1,
         R_SBUF 		   => R_SBUF,
         uart_pers		=> uart_pers,
			T_SBUF 		   => T_SBUF,
			LED            => lcd_LED,
			trigger			=> trigger,
         lcd_address 	=> lcd_address,
         lcd_color   	=> lcd_color, 
         lcd_write 		=> lcd_write, 
         lcd_show  		=> lcd_show,  
         lcd_busy  		=> lcd_busy  
       );
   u3:LCD_DRV           --LCD 
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
			nReset => nReset,
			key_col   	=> key_col,               
			key_scan  	=> key_scan ,
			key_pressed => key_pressed, 
			number 		=>	number
       );
   u5: SD178 
      port map(    	   
         fin 			   => fin,
         nReset 			=> nReset,
         SD178_sda		=> SD178_sda,
         SD178_scl		=> SD178_scl,
         SD178_nrst		=> SD178_nrst,
         mode_sd178		=> 1,
         HU_BUFF			=> HU_BUFF, 
         TE_BUFF  		=> TE_BUFF,
         TSL2561_data	=> TSL2561_data,
         key_pressed 	=> key_pressed,
         workingMode 	=> workingMode,
         dipsw1			=> dipsw1(7 downto 4),
         debug			=> SD178_debug,

         R_SBUF 		   => R_SBUF,
         uart_pers		=> uart_pers
     );    
   u6:TSL2561
      port map(
         clk_50M=>fin,
         nrst=>nReset,
         sda=>TSL2561_sda,
         scl=>TSL2561_scl,
         TSL2561_data =>TSL2561_data
     );
	u7:uart
     port map(
        clk=>fin,
        rst=>nReset,
        TX=>TX,
        RX=>RX,
		  trigger=>trigger,
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
