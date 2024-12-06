library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

entity lcd_char is
	port(    	      	                                       --æ¹î¿é
         fin, nReset : in 	   std_logic;                       --9) & RESET145) 
         dipsw1    	: IN 	   std_logic_vector(7 downto 0);    --DIP SW()
         LED         : buffer	std_logic_vector(15 downto 0);
         BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;              	--LCD
			key_pressed : in     std_logic 
   );
end entity;
architecture beh of lcd_char is
	type State_type4 is (event_check, button_process );
	SIGNAL  Main_State  : State_type4;     
   --other
   signal  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : STD_LOGIC;
   signal  mode_lcd:integer range 0 to 15;
   type arr is array(0 to 15) of std_logic_vector(3 downto 0);
	constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
   --LCD
   signal  lcd_write, lcd_show, lcd_busy    : std_logic;
   signal  lcd_address          : std_logic_vector(14 downto 0);
   signal  lcd_color            : std_logic_vector(5 DOWNTO 0);  
   component lcdControl is	
      port (  	clk : in std_logic;
					LED:buffer std_logic_vector(15 downto 0);
               nReset: in std_logic;
               mode_lcd: in integer range 0 to 15; 
               key_pressed: in std_logic ;
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
   port(								                            --æ¹î¿é
           fin, nReset  :in std_logic;                    --9) & RESET145)
           BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;       --LCD 
           lcd_busy  : OUT    STD_LOGIC;
           lcd_write, lcd_show  : in  STD_LOGIC ;
           lcd_address          : in  std_logic_vector(14 downto 0);
           lcd_color            : in  std_logic_vector(5 DOWNTO 0)

       );
   end component LCD_DRV;
signal FD:std_logic_vector(21 downto 0);
signal lcd_LED,main_LED:std_logic_vector(15 downto 0);
begin
	mode_lcd<=conv_integer(not dipsw1(3 downto 0));
	LED<=not main_LED when dipsw1(7)='1' else not lcd_LED;
	main_LED(7 downto 0)<=not dipsw1;
	fre:process(fin)
	begin
		if rising_edge(fin)then
			FD<=FD+1;
		end if;
	end process;
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
		 LED				=> lcd_LED,
       mode_lcd		=> mode_lcd,
       key_pressed 	=> key_pressed,
       lcd_address 	=> lcd_address,
       lcd_color   	=> lcd_color, 
       lcd_write 		=> lcd_write, 
       lcd_show  		=> lcd_show,  
       lcd_busy  		=> lcd_busy
    );
   u3:LCD_DRV           --LCD é¿
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
end beh;