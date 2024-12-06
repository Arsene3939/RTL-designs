--FOR EP3C16Q240C8
--dipsw1的dipsw1(5)='1'，dipsw1(6)='0'，dipsw1(7)='0'，
--增加第5功能(
--1.讓照度顯示在七段顯示器
--2.溫濕度顯示tft lcd(顯示紅色"溫度"與藍色"濕度")
--  且可同時顯示32x32 與 16x16 兩種字形
--3.馬達隨溫度高低加減速，
--4.同時語音IC上交替播放照度與溫濕度)


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity comp2020 is
	port(    	      	                                    --接腳說明   
        fin, nReset : in 	std_logic;                     	--震盪輸入(149) & RESET按鈕(145) 
		SD178_sda  	: INOUT STD_LOGIC;                  	--SD178B IIC SDA() 
        SD178_scl  	: INOUT STD_LOGIC;                  	--SD178B IIC SCL()                                                              
        SD178_nrst 	: OUT   STD_LOGIC;                  	--SD178B nRESET ()  
		TSL2561_sda : INOUT STD_LOGIC;                 		--TSL2561 IIC SDA()
        TSL2561_scl : INOUT STD_LOGIC;                 		--TSL2561 IIC SCL()                
		DHT11_PIN 	: inout STD_LOGIC;                   	-- DHT11 PIN
        dipsw1    	: IN 	std_logic_vector(3 downto 0);   --DIP SW()
        key_col   	: IN 	std_logic_vector(3 downto 0);   --KEYBOARD ()               
        key_scan  	: OUT  	std_logic_vector(3 downto 0);  
        debug  		: OUT  	std_logic_vector(7 downto 0);  
        	
        segout  	:out 	std_logic_vector(7 downto 0);   --左邊七段顯示器資料腳()
        segsel  	:out 	std_logic_vector(3 downto 0);   --左邊七段顯示器掃描腳()           
        
        BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;	     --LCD 
		  LED:buffer std_logic_vector(15 downto 0)
    );
end comp2020;
architecture beh of comp2020 is

component SD178 is
port(    	      	                                      --接腳說明   
        fin, nReset  :in std_logic;                     --震盪輸入(149) & RESET按鈕(145) 
        
        SD178_sda  : INOUT  STD_LOGIC;                  --SD178B IIC SDA() 
        SD178_scl  : INOUT  STD_LOGIC;                  --SD178B IIC SCL()                                                              
        SD178_nrst : OUT    STD_LOGIC;                  --SD178B nRESET ()  

        mode_sd178  :in integer range 0 to 15;
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
        TSL2561_data :in STD_LOGIC_VECTOR(19 DOWNTO 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0) ;

        dipsw1    : IN std_logic_vector(3 downto 0);    --DIP SW()        
        debug  : OUT    STD_LOGIC  
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
	 
component DHT11_BASIC is 
port(
	 clk_1M:in std_logic;
     nrst:in std_logic;
     key:in std_logic;
     dat_bus: inout std_logic;
     HU, TE:out std_logic_vector(7 downto 0);        --溼度整數, 溫度整數
     error: out std_logic
     
     );
end component DHT11_BASIC;

component lcdControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_lcd: in integer range 0 to 15; 
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);  
        TSL2561_data : STD_LOGIC_VECTOR(19 DOWNTO 0);
        key_pressed: in std_logic ;
        workingMode: in std_logic_vector(3 downto 0) ;
        --BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC       ; --LCD 
        
        lcd_busy  : in    STD_LOGIC;                     
        lcd_write, lcd_show  : out  STD_LOGIC ;
        lcd_address          : buffer  std_logic_vector(14 downto 0);
        lcd_color            : out  std_logic_vector(5 DOWNTO 0) 
       );
end component lcdControl;

component sevenSegmentControl is
port (  clk : in std_logic;
        nReset: in std_logic;
        mode_7seg: in integer range 0 to 15; 
        TSL2561_data: in std_logic_vector(19 DOWNTO 0);
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);
		dataBuffer: out std_logic_vector(15 DOWNTO 0)
       );
end component sevenSegmentControl;

component keypad is
port (  clk : in std_logic;
        nReset: in std_logic;
        key_col   : IN std_logic_vector(3 downto 0);        --BUTTON ()               
        key_scan  : OUT  std_logic_vector(3 downto 0);  
        key_pressed: out std_logic ;
        number: out std_logic_vector(3 downto 0) 
       );
end component keypad;

component fourDigits_SevenSegmentDisplay IS
PORT(
     clk:in std_logic;
     dataBuffer:in std_logic_vector(15 downto 0);
     dot :in std_logic_vector(3 downto 0);
     segData:out std_logic_vector(7 downto 0);
     segPosition:out std_logic_vector(3 downto 0)
    );
end component fourDigits_SevenSegmentDisplay ;
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
port(    	      	                                  --接腳說明   
        fin, nReset  :in std_logic;                    --震盪輸入(149) & RESET按鈕(145) 
        BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;       --LCD 
        lcd_busy  : OUT    STD_LOGIC;                     
        lcd_write, lcd_show  : in  STD_LOGIC ;
        lcd_address          : in  std_logic_vector(14 downto 0);
        lcd_color            : in  std_logic_vector(5 DOWNTO 0)               

    );
end component LCD_DRV;

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
signal  actionID: std_logic_vector(2 downto 0) ;

--7SEG 
SIGNAL seg1_dot, seg2_dot                              : std_logic_vector(3 downto 0);     
signal dataBuffer: std_logic_vector(15 DOWNTO 0)  ;

--SD178B  
signal        SD178_debug :   STD_LOGIC;                    

--other
SIGNAL  clk_1KHz,clk_1MHz, clk_100hz, clk_1hz : STD_LOGIC;        
SIGNAL  mode_lcd, mode_7seg, mode_sd178, mode_motor   :integer range 0 to 15;
SIGNAL  motor_speed   :integer range 0 to 10;
SIGNAL  motor_dir : STD_LOGIC;        

--LCD   
SIGNAL  lcd_write, lcd_show, lcd_busy    : std_logic;
SIGNAL  lcd_address          : std_logic_vector(14 downto 0);
SIGNAL  lcd_color            : std_logic_vector(5 DOWNTO 0);  

SIGNAL  segCounter            : std_logic_vector(15 DOWNTO 0):="0000000000000000"; 
signal idx: integer range 0 to 127:=0;
begin  
	--debug <=  clk_1hz & key_pressed & (not workingMode); 
	debug <=  SD178_debug & workingMode &   actionID; 
	actionID <= dipsw1(2 downto 0) ;
	LED(15 downto 0)<=  TSL2561_data(15 downto 0);
	
	process(key_pressed)
 	begin		
		if(rising_edge(key_pressed))then
			workingMode <= number ;
		end if;
 	end process;
	
	process(clk_1hz)
	begin
		if(nReset='0')then
			segCounter <= "0000000000000000";
		elsif(rising_edge(clk_1hz))then
			segCounter <= segCounter +1;
		end if ;
	end process;
	
 	       
 	process(nReset,clk_1MHz)            --按鍵控制
      variable delay_1   :integer range 0 to 100;   	         
      variable i,j         :integer range 0 to 100;
      variable dbg: std_logic_vector(5 downto 0); 
 	begin	  
      if(nReset='0')then
         mode_lcd   <= 0;
         mode_7seg  <= 0; 
         mode_sd178 <= 0; 
         mode_motor <= 0;          
         delay_1   := 0;    
		 dbg := "111111";

         Main_State  <= event_check;            

      ELSIF(clk_1MHz'EVENT AND clk_1MHz='1')then   

         CASE Main_State IS                
            
            when event_check=>       
            	if (key_pressed = '1') then 
         	         --產生EVENT PULSE
         	         delay_1 :=0; 
         	         --j := to_integer(unsigned(workingMode));
         	         Main_State <= button_process; 
         	         --
               	     if(workingMode = "0000") then       -- 按下KEY1   i-->j      	                  	         	      
               	        if(actionID = "000") then  
               	           mode_lcd  <= 0;   
               	           mode_7seg <= 1;
               	           mode_sd178 <= 1; --0
               	           mode_motor <= 0;   
                        elsif(actionID = "001") then     
                           mode_lcd  <= 1;        
                           mode_7seg <= 2;                                     --顯示溫度
                           mode_sd178 <= 0;
                           mode_motor <= 1; 
                        elsif(actionID = "010") then         	         
                           mode_lcd  <= 2;     
                           mode_7seg <= 0;
                           mode_sd178 <= 0;
                           mode_motor <= 2; 
                        elsif(actionID = "011") then         	         
                           mode_lcd   <= 3;   
                           mode_7seg  <= 0; 
                           mode_sd178 <= 1;                                    --開始循環撥放                                                                 
                           mode_motor <= 0; 
                        elsif(actionID = "100") then         	         
                           mode_lcd  <= 4;    
                           mode_7seg <= 3;                                     --顯示光強度           
                           mode_sd178 <= 1;
                           mode_motor <= 1; 
               	        end if;            	      
               	        
               	     elsif(workingMode = "0010")  then    -- 按下KEY3   i-->j            	                     	      
               	        if(actionID = "000") then         	                  	         
               	           mode_lcd  <= 0;     
               	           mode_7seg <= 0;
               	           mode_sd178 <= 0;
                        elsif(actionID = "001") then         	         
                           mode_7seg  <= 1;                                   --停止顯示溫度  
                           mode_motor <= 0;                                   --停止馬達   
                        elsif(actionID = "010") then         	         
                           mode_7seg  <= 0;     
                           mode_motor <= 0;                                   --停止馬達                        
                        elsif(actionID = "011") then         	         
               	           mode_sd178 <= 0;
                        elsif(actionID = "100") then         	         
                           mode_7seg  <= 1;                                   --停止顯示光強度   	         
               	           mode_sd178 <= 0;                                       
                           mode_motor <= 0;          
               	        end if;   
                 	end if;	         	         
                end if;           
                                                                                                                                                
            when button_process =>              		   
                  if delay_1 >= 10 then                                   -- 產生10us觸發訊號 ,button_event                        
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
          
   ------------------------------------------------------------------------零件庫 
   u1:TSL2561
   port map(
         clk_50M => fin,
         nrst    => nReset,    
         
         sda       => TSL2561_sda,
         scl       => TSL2561_scl,
         
         TSL2561_data => TSL2561_data

           );

   u2: DHT11_BASIC
	port map(
		clk_1M => clk_1MHz,
        nrst    => nReset,   
		key		=> clk_1Hz,
		dat_bus => DHT11_PIN,
		HU      => HU_BUFF,
        TE      => TE_BUFF,                 
        error   => DHT11_error 
     
     );
	 
   u3:fourDigits_SevenSegmentDisplay      --左邊七段顯示器掃描
   port map(
              clk    => clk_1KHz,
              dataBuffer   => dataBuffer,
              dot    => seg1_dot,
              segData => segout,
              segPosition => segsel
           );
           
   u4:clock_generator
   port map(    
			  fin    => fin,  
			  clk_1MHz   => clk_1MHz , 
			  clk_1KHz   => clk_1KHz ,  
			  clk_100Hz   => clk_100hz,
	          clk_1Hz   => clk_1hz 
    );

   u5: keypad
   port map(  
			clk    		=> clk_100hz,
			nReset => nReset,
			key_col   	=> key_col,               
			key_scan  	=> key_scan ,
			key_pressed => key_pressed, 
			number 		=>number
       );
   u6: lcdControl
	port map(  
		clk 			=> fin,
        nReset 			=> nReset,
        mode_lcd		=> mode_lcd,
        HU_BUFF			=> HU_BUFF, 
        TE_BUFF  		=> TE_BUFF,
        TSL2561_data		=> TSL2561_data,
        key_pressed 	=> key_pressed,
        workingMode 	=> workingMode,
        
        
        lcd_address 	=> lcd_address,
        lcd_color   	=> lcd_color, 
        lcd_write 		=> lcd_write, 
        lcd_show  		=> lcd_show,  
        lcd_busy  		=> lcd_busy  
       );
   u0: SD178 
	port map(    	   
		fin 			=> fin,
        nReset 			=> nReset,
		SD178_sda		=> SD178_sda,
		SD178_scl		=> SD178_scl,
		SD178_nrst		=> SD178_nrst,
        mode_sd178		=> mode_sd178,
        HU_BUFF			=> HU_BUFF, 
        TE_BUFF  		=> TE_BUFF,
        TSL2561_data	=> TSL2561_data,
        key_pressed 	=> key_pressed,
        workingMode 	=> workingMode,
		dipsw1			=> dipsw1,
		debug			=> SD178_debug
    );
   u7: sevenSegmentControl 
   port map(  
        clk 			=> clk_100hz,
        nReset 			=> nReset,
        mode_7seg		=> mode_7seg,
        TSL2561_data		=> TSL2561_data,
        HU_BUFF			=> HU_BUFF, 
        TE_BUFF  		=> TE_BUFF,
		dataBuffer		=> dataBuffer
       );
   u8:LCD_DRV           --LCD 驅動
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
		lcd_write => lcd_write, 
		lcd_show  => lcd_show,  
		lcd_busy  => lcd_busy           
   ); 
                 
end beh;
