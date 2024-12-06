Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity SD178_test is
	port(
		clk,rst:in std_logic;
		SD178_sda  : inout  std_logic;
		SD178_scl  : inout  std_logic;
		SD178_nrst : out    std_logic;
		LED:buffer std_logic_vector(15 downto 0);
      dipsw1    	: IN 	std_logic_vector(7 downto 0);   --DIP SW()
      key_col   	: IN 	std_logic_vector(3 downto 0);   --KEYBOARD ()               
	  	key_scan  	: OUT  	std_logic_vector(3 downto 0);
		-- uart --
		TX          : out    std_logic;
		RX          : in     std_logic
	);
end entity SD178_test;
architecture main of SD178_test is
	signal FD:std_logic_vector(50 downto 0);
	signal debug :std_logic_vector(15 downto 0);
	signal  key_pressed: std_logic ;
	signal  number, workingMode: std_logic_vector(3 downto 0);
	SIGNAL  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : STD_LOGIC;
	signal  uart_pers    : std_logic;
	signal  R_SBUF,T_SBUF: std_logic_vector(7 downto 0);
	type    arr1 is array(0 to 10) of std_logic_vector(7 downto 0);
	signal  Serial_available:arr1:=(X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
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

			dipsw1    : IN std_logic_vector(3 downto 0)  ;  --DIP SW()        
			debug  : OUT std_logic_vector(7 downto 0)
		);
	end component SD178;
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
begin
	process(key_pressed)
	begin		
	   if(rising_edge(key_pressed))then
		   workingMode <= number ;
	   end if;
	end process;
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
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
	u0: SD178 
		port map(    	   
			fin 			=> clk,
        	nReset 			=> rst,
			SD178_sda		=> SD178_sda,
			SD178_scl		=> SD178_scl,
			SD178_nrst		=> SD178_nrst,
        	mode_sd178		=> 1,
        	HU_BUFF			=> X"20", 
			TE_BUFF  		=> X"20",
			
			R_SBUF			=>R_SBUF,
			uart_pers		=>uart_pers,
			debug				=>LED(7 downto 0),
        	TSL2561_data	=> X"00120",
        	key_pressed 	=> key_pressed,
        	workingMode 	=> workingMode,
			dipsw1			=> dipsw1(7 downto 4)
    );
	u1: keypad
		port map(  
				 clk    		=> clk_100hz,
				 nReset => rst,
				 key_col   	=> key_col,               
				 key_scan  	=> key_scan ,
				 key_pressed => key_pressed, 
				 number 		=>number
			);
	   u2:clock_generator
   port map(    
			  fin    => clk,  
			  clk_1MHz   => clk_1MHz , 
			  clk_1KHz   => clk_1KHz ,  
			  clk_100Hz   => clk_100hz,
	          clk_1Hz   => clk_1hz
	);
	u3:uart
	port map(
	   clk=>clk,
	   rst=>rst,
	   TX=>TX,
	   RX=>RX,
	   countE1=>uart_pers,
	   R_SBUF=>R_SBUF,
	   T_SBUF=>T_SBUF
	);
end main;

	