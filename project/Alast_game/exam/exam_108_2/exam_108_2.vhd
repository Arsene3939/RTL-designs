
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity exam_108_2 is
	port(
         fin, nReset : in 	   std_logic;
		   SD178_sda  	: INOUT  STD_LOGIC;                  	   --SD178B IIC SDA() 
         SD178_scl  	: INOUT  STD_LOGIC;                  	   --SD178B IIC SCL()                                                              
         SD178_nrst 	: OUT    STD_LOGIC;                  	   --SD178B nRESET ()  
		   TSL2561_sda : INOUT  STD_LOGIC;                 		--TSL2561 IIC SDA()
         TSL2561_scl : INOUT  STD_LOGIC;                 		--TSL2561 IIC SCL()                
		   DHT11_PIN 	: inout  STD_LOGIC;                   	   --DHT11 PIN
         dipsw1    	: IN 	   std_logic_vector(7 downto 0);    --DIP SW()
         key_col   	: IN 	   std_logic_vector(3 downto 0);    --KEYBOARD ()
         key_scan  	: OUT    std_logic_vector(3 downto 0);  
         bz          :out STD_LOGIC;
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
         BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;              	--LCD
			-- motor 
			mp,mm			:buffer std_logic
	 );
end exam_108_2;
architecture beh of exam_108_2 is
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
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
        TSL2561_data : STD_LOGIC_VECTOR(19 DOWNTO 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0);
		  dipsw		:  in std_LOGIC_vector(7 downto 0);
		  moders		:in std_logic;
        R_SBUF		 : in std_LOGIC_vector(7 downto 0) ;
        motordic    :out std_logic;
		  uart_pers  : in std_logic;
        lcd_busy  : in    STD_LOGIC;                     
        lcd_write, lcd_show  : out  STD_LOGIC ;
        lcd_address          : buffer  std_logic_vector(14 downto 0);
        lcd_color            : out  std_logic_vector(5 DOWNTO 0)
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
        key_col   : IN std_logic_vector(3 downto 0);        --BUTTON ()               
        key_scan  : OUT  std_logic_vector(3 downto 0);  
        key_pressed: out std_logic ;
        number: out std_logic_vector(3 downto 0)
       );
end component keypad;
component LCD_DRV is
port(								                            --寥謜
        fin, nReset  :in std_logic;                    --9) & RESET145) 
        BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;       --LCD 
        lcd_busy  : OUT    STD_LOGIC;
        lcd_write, lcd_show  : in  STD_LOGIC ;
        lcd_address          : in  std_logic_vector(14 downto 0);
        lcd_color            : in  std_logic_vector(5 DOWNTO 0)               

    );
end component LCD_DRV;
component SD178 is 
port(    	      	                                      --謘 
        fin, nReset  :in std_logic;                     --暹49) & RESET145) 
        
        SD178_sda  : INOUT  STD_LOGIC;                  --SD178B IIC SDA() 
        SD178_scl  : INOUT  STD_LOGIC;                  --SD178B IIC SCL()                                                              
        SD178_nrst : OUT    STD_LOGIC;                  --SD178B nRESET ()  

        R_SBUF     : in std_logic_vector(7 downto 0) ;
        uart_pers	 : in std_logic;
        
        mode_sd178  :in integer range 0 to 15;
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
        TSL2561_data :in STD_LOGIC_VECTOR(19 DOWNTO 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0) ;
        motor_speed: in std_logic_vector(3 downto 0) ;
        motor_dir:   in std_logic;

        dipsw1    : IN std_logic_vector(3 downto 0)  ;  --DIP SW()        
        debug  : OUT    std_logic_vector(3 downto 0)
    );
end component SD178;
component TSL2561 is
   port(
        clk_50M:in std_logic;
        nrst:in std_logic;
        sda       : INOUT  STD_LOGIC;                   --TSL2561 IIC SDA(161)
        scl       : INOUT  STD_LOGIC;                   --TSL2561 IIC SCL(160)                                                             
        TSL2561_data : OUT  std_logic_vector(19 downto 0)
    );
end component TSL2561;
component uart is
	port(
		rst,clk:in std_logic;
		TX:buffer std_logic;
		RX:in std_logic;
		countE1:buffer std_logic;
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
SIGNAL  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : STD_LOGIC;        
SIGNAL  mode_lcd, mode_7seg, mode_sd178, mode_motor   :integer range 0 to 15;
SIGNAL  motor_speed   :integer range 0 to 10;
SIGNAL  motor_dir : STD_LOGIC:='0';
signal  FD:std_logic_vector(50 downto 0);      
--LCD   
SIGNAL  lcd_write, lcd_show, lcd_busy    : std_logic;
SIGNAL  lcd_address          : std_logic_vector(14 downto 0);
SIGNAL  lcd_color            : std_logic_vector(5 DOWNTO 0);  
--SD178B  
signal        SD178_debug :   STD_LOGIC_vector(3 downto 0); 
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
signal moders:std_logic:='1';
shared variable speed:integer range 0 to 3:=0;
begin
   
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
 	process(nReset,clk_1MHz)            --
      variable delay_1   :integer range 0 to 100;
      variable i,j         :integer range 0 to 100;
      variable dbg: std_logic_vector(5 downto 0); 
		variable now_te:integer range 0 to 63:=20;
		
		variable ifwork1:std_logic:='1';
 	begin	  
      if(nReset='0')then
         mode_lcd   <= 0;
         delay_1   := 0;
		 dbg := "111111";
		 ssd_data<=X"FFFFFFFF";
       Main_State  <= event_check;
      ELSIF(clk_1MHz'EVENT AND clk_1MHz='1')then
         CASE Main_State IS                
            when event_check=>
					if (mode_lcd=1 or mode_lcd=3) and ifwork1='1' then
						if now_te<(conv_integer(TE_BUFF(3 downto 0))+10*conv_integer(TE_BUFF(7 downto 4))) and speed<3 then
							speed:=speed+1;
						elsif now_te>(conv_integer(TE_BUFF(3 downto 0))+10*conv_integer(TE_BUFF(7 downto 4))) and speed>0 then
							speed:=speed-1;
						end if;
						if key_pressed='1' then
							LED(2)<=not LED(2);
							if (workingMode=X"4" and speed<3)then
								speed:=speed+1;
								LED(0)<=not LED(0);
							elsif (workingMode=X"5" and speed>0)then
								speed:=speed-1;
							end if;
						end if;
						now_te:=conv_integer(TE_BUFF(3 downto 0))+10*conv_integer(TE_BUFF(7 downto 4));
						ssd_data<="000000"&conv_std_logic_vector(speed,2)&X"CD"&TE_BUFF&X"AB";
						motor_speed<=speed*3;
					end if;
					if (key_pressed = '1') then 
						if workingMode="0000" then
							ifwork1:='1';
						elsif workingMode="0010" then
							ifwork1:='0';
						end if;
						if mode_lcd=2 then
							motor_speed<=10;
							if workingMode=X"2" then
								moders<=not moders;
							end if;
						elsif mode_lcd=3 then
							
						end if;
         	      delay_1 :=0;
         	      Main_State <= button_process;
       	         mode_lcd<=conv_integer(dipsw1(7 downto 4));
					end if;
            when button_process =>
                  if delay_1 >= 10 then                                   -- us塗庢utton_event                        
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
          
   ------------------------------------------------------------------------頩橫鞊堆
	
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
         motordic       => motor_dir,
			dipsw				=> dipsw1,
         R_SBUF 		   => R_SBUF,
         uart_pers		=> uart_pers,
			moders 			=> moders,
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
         mode_sd178		=> mode_lcd,
         HU_BUFF			=> HU_BUFF, 
         TE_BUFF  		=> TE_BUFF,
         TSL2561_data	=> TSL2561_data,
         key_pressed 	=> key_pressed,
         workingMode 	=> workingMode,
         dipsw1			=> dipsw1(7 downto 4),
         debug			   => SD178_debug,
         motor_speed    => conv_std_logic_vector(speed,4),
         motor_dir      => motor_dir,
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
