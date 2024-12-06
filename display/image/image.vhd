
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity image is
	port(    	      	                                       --ï§ï¢è¬ 
         fin, nReset : in 	   std_logic;                       --æ¹49) & RESET145)  
         -- uart --
         TX          : out    std_logic;
         RX          : in     std_logic; 
         LED         : buffer	std_logic_vector(15 downto 0);
         BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;              	--LCD
			SW:in std_logic;
			dipsw1:in std_logic_vector(7 downto 0)
	 );
end image;
architecture beh of image is
component lcdControl is
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
component LCD_DRV is
port(								                            --ï§ï¢è¬ 
        fin, nReset  :in std_logic;                    --æ¹49) & RESET145) 
        BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;       --LCD 
        lcd_busy  : OUT    STD_LOGIC;
        lcd_write, lcd_show  : in  STD_LOGIC ;
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
		T_SBUF:in  std_logic_vector(7 downto 0);
		R_SBUF:out std_logic_vector(7 downto 0)
	);
end component uart;
type State_type4 is (event_check, button_process );
SIGNAL  Main_State  : State_type4;
SIGNAL  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : STD_LOGIC;        
SIGNAL  mode_lcd:integer range 0 to 15;
signal  FD:std_logic_vector(50 downto 0);
--LCD   
SIGNAL  lcd_write, lcd_show, lcd_busy    : std_logic;
SIGNAL  lcd_address          : std_logic_vector(14 downto 0);
SIGNAL  lcd_color            : std_logic_vector(5 DOWNTO 0);  
--Serial
signal  uart_pers    : std_logic;
signal  R_SBUF,T_SBUF: std_logic_vector(7 downto 0);
type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
begin
	LED(7 downto 0)<=not R_SBUF;
   fre:process(nReset,fin)
	begin
		if nReset='0' then
			FD<=(others=>'0');
		elsif rising_edge(fin)then
			FD<=FD+1;
		end if;
   end process fre;
	
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
         LED(15 downto 8)<=not (Serial_available(i));
         i:=i+1;
         if i>10 then
            i:=0;
         end if;
      end if;
   end process;	         
	mode_lcd<=conv_integer(not dipsw1);
   ------------------------------------------------------------------------è³¹ï±î© 
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
         R_SBUF 		   => R_SBUF,
         uart_pers		=> uart_pers,
			SW					=> SW,
         lcd_address 	=> lcd_address,
         lcd_color   	=> lcd_color, 
         lcd_write 		=> lcd_write, 
         lcd_show  		=> lcd_show,  
         lcd_busy  		=> lcd_busy  
       );
   u3:LCD_DRV           --LCD ä½
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
end beh;
