library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

entity marquee is
	port(    	      	                                       --Ã¦ÂÂ¹Ã®ÂÂ¿Ã©ÂÂ
         fin, nReset : in 	   std_logic;                       --9) & RESET145) 
         dipsw1    	: IN 	   std_logic_vector(7 downto 0);    --DIP SW()
         key_col   	: IN 	   std_logic_vector(3 downto 0);    --KEYBOARD ()
         key_scan  	: OUT    std_logic_vector(3 downto 0);  
         LED         : buffer	std_logic_vector(15 downto 0);
         BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC              	--LCD
   );
end entity;
architecture beh of marquee is
	type State_type4 is (event_check, button_process );
	SIGNAL  Main_State  : State_type4;
      --KEYBOARD , DIP switch
   signal  key_pressed,key_pressed2: std_logic ;
   signal  number,workingMode: std_logic_vector(3 downto 0);
   signal  actionID: std_logic_vector(3 downto 0) ;           
   --other
   signal  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : STD_LOGIC;
   signal  mode_lcd:integer range 0 to 15;
   type arr is array(0 to 15) of std_logic_vector(3 downto 0);
	constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
   --LCD
   signal  lcd_write, lcd_show, lcd_busy    : std_logic;
   signal  lcd_address          : std_logic_vector(14 downto 0);
   signal  lcd_color            : std_logic_vector(5 DOWNTO 0);  
	
	signal  T_SBUF					  : std_logic_vector(7 downto 0);
	signal  R_SBUF					  : std_logic_vector(7 downto 0);
	signal  uart_pers	 			  : std_logic;
	signal  sendclk				  : std_logic;
   component lcdControl is	
      port (  	clk : in std_logic;
					LED:buffer std_logic_vector(15 downto 0);
               nReset: in std_logic;
               mode_lcd: in integer range 0 to 15; 
               key_pressed,key_pressed2: in std_logic ;
               workingMode: in std_logic_vector(3 downto 0) ;
               lcd_busy  : in    STD_LOGIC;                     
               lcd_write, lcd_show  : out  STD_LOGIC ;
               lcd_address          : buffer  std_logic_vector(14 downto 0);
               lcd_color            : out  std_logic_vector(5 DOWNTO 0);
					
					T_SBUF     :buffer std_logic_vector(7 downto 0) ;
					R_SBUF     : in std_logic_vector(7 downto 0) ;
					uart_pers	 : in std_logic;
					sendclk    : buffer std_logic
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
   port(								                            --Ã¦ÂÂ¹Ã®ÂÂ¿Ã©ÂÂ
           fin, nReset  :in std_logic;                    --9) & RESET145)
           BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;       --LCD 
           lcd_busy  : OUT    STD_LOGIC;
           lcd_write, lcd_show  : in  STD_LOGIC ;
           lcd_address          : in  std_logic_vector(14 downto 0);
           lcd_color            : in  std_logic_vector(5 DOWNTO 0)

       );
   end component LCD_DRV;
	signal FD:std_logic_vector(21 downto 0);
begin
	actionID <= dipsw1(7 downto 4);
	process(key_pressed)
 	begin
		if(rising_edge(key_pressed))then
			workingMode <= number ;
		end if;
 	end process;
	fre:process(fin)
	begin
		if rising_edge(fin)then
			FD<=FD+1;
		end if;
	end process;
	process(FD(21))
		variable i:integer range 0 to 3:=0;
	begin
		if (key_col(0) and key_col(1) and key_col(2) and key_col(3))='0' then
			key_pressed2<='1';
		elsif rising_edge(FD(21))then
			i:=i+1;
			if i>=3 then
				i:=0;
				key_pressed2<='0';
			end if;
		end if;
	end process;
   process(nReset,clk_1MHz)
      variable delay_1   :integer range 0 to 100;
      variable i,j         :integer range 0 to 100;
      variable dbg: std_logic_vector(5 downto 0);
 	begin
      if(nReset='0')then
			mode_lcd   <= 0;
			dbg := "111111";
      elsif rising_edge(fin) then
			if workingMode="0000"then
				mode_lcd<=conv_integer(dipsw1);
			end if;
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
		 LED				=> LED,
       mode_lcd		=> mode_lcd,
       key_pressed 	=> key_pressed,
		 key_pressed2	=> key_pressed2,
       workingMode 	=> workingMode,
		 R_SBUF 		   => R_SBUF,
		 T_SBUF			=> T_SBUF,
       uart_pers		=> uart_pers,
		 sendclk			=> sendclk,
       lcd_address 	=> lcd_address,
       lcd_color   	=> lcd_color, 
       lcd_write 		=> lcd_write, 
       lcd_show  		=> lcd_show,  
       lcd_busy  		=> lcd_busy
    );
   u3:LCD_DRV           --LCD Ã©ÂÂ¿
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
         nReset		=> nReset,
         key_col   	=> key_col,               
         key_scan  	=> key_scan ,
         key_pressed => key_pressed, 
         number 		=>	number
       );
end beh;