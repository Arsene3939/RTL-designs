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
use ieee.numeric_std.all;

entity OLED128x32 is
port(    	      	                                      --接腳說明   
        fin, nReset  :in std_logic;                     --震盪輸入(149) & RESET按鈕(145) 
        TSL2561_sda : INOUT  STD_LOGIC;                 --TSL2561 IIC SDA()
        TSL2561_scl : INOUT  STD_LOGIC;                 --TSL2561 IIC SCL()                                                             

        SD178_sda  : INOUT  STD_LOGIC;                  --SD178B IIC SDA() 
        SD178_scl  : INOUT  STD_LOGIC;                  --SD178B IIC SCL()                                                              
        SD178_nrst : OUT    STD_LOGIC;                  --SD178B nRESET ()  

        SHT11_PIN : inout  STD_LOGIC;                   -- DHT11 PIN 

        dipsw1    : IN std_logic_vector(7 downto 0);    --DIP SW()
        key_col   : IN std_logic_vector(0 to 3);        --BUTTON ()               
        key_scan  : OUT  std_logic_vector(0 to 3);  
        debug  : OUT    STD_LOGIC;  
        	
        segout  :out std_logic_vector(7 downto 0);      --左邊七段顯示器資料腳()
        segsel  :out std_logic_vector(0 to 3);          --左邊七段顯示器掃描腳()           
        segout_2:out std_logic_vector(7 downto 0);      --右邊七段顯示器資料腳()       	        	        	
        segsel_2:out std_logic_vector(0 to 3);          --右邊七段顯示器掃描腳()           
        
        BL,RES,CS,DC,SDA,SCL : OUT    STD_LOGIC;        --LCD 
        motor_out1,motor_out2,motor_pwm1 : OUT    STD_LOGIC
    );
end OLED128x32;
architecture beh of OLED128x32 is

component i2c_master is
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 100_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
end component i2c_master; 

component TSL2561 is 
port(
	  clk_50M:in std_logic;
     nrst:in std_logic;

     sda       : INOUT  STD_LOGIC;                   --TSL2561 IIC SDA(161)
     scl       : INOUT  STD_LOGIC;                   --TSL2561 IIC SCL(160)                                                             
     
     TSL2561_data : OUT  std_logic_vector(14 downto 0)

     );
end component TSL2561;

component DHT11 is 
port(
	   clk_50M:in std_logic;
     nrst:in std_logic;
     dat_bus: inout std_logic;
     HU, TE:out std_logic_vector(7 downto 0);        --????, ????
     error: out std_logic
     
     );
end component DHT11;

component sync_segscan IS
PORT(
     clk:in std_logic;
     ch_0:in std_logic_vector(3 downto 0);
     ch_1:in std_logic_vector(3 downto 0);
     ch_2:in std_logic_vector(3 downto 0);
     ch_3:in std_logic_vector(3 downto 0);
     dot :in std_logic_vector(0 to 3);
     sync_segout:out std_logic_vector(7 downto 0);
     sync_segsel:out std_logic_vector(0 to 3)
    );
end component sync_segscan ;

component up_mdu2 is
   port(    
        fin:in std_logic;    
        fout:buffer std_logic   
       );
end component up_mdu2;

component up_mdu3 is
   port(    
        fin:in std_logic;    
        fout:buffer std_logic   
       );
end component up_mdu3;

component up_mdu4 is
   port(    
        fin:in std_logic;    
        fout:buffer std_logic   
       );
end component up_mdu4;

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

type word_buffer is array(0 to 19)of std_logic_vector(7 downto 0);                                --SD178B 語音資料串
signal  word_buf:word_buffer:=( x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");   	                          
signal   word1:word_buffer:= (  x"8B",x"07",x"86",x"C3",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");--設定聲道
constant word2:word_buffer:= (  x"BC",x"BD",x"A9",x"F1",x"C0",x"C9",x"AE",x"D7",x"88",x"27",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");--播放檔案 >> 88H 27H 0EH 00H 01H  播放檔名9998.wav 1次  
constant word3:word_buffer:= (  x"A8",x"74",x"B2",x"CE",x"B6",x"7D",x"BE",x"F7",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");--系統開機   
constant word4:word_buffer:= (  x"BC",x"BD",x"A9",x"F1",x"C0",x"C9",x"AE",x"D7",x"88",x"27",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");--播放檔案 >> 88H 27H 0EH 00H 01H  播放檔名9998.wav 1次
signal   word5:word_buffer:= (  x"AB",x"47",x"AB",x"D7",x"31",x"32",x"33",x"34",x"B0",x"C7",x"A7",x"4A",x"A5",x"71",x"87",x"00",x"00",x"0B",x"B8",x"00");--"亮度????勒克司" >> 延遲3秒
signal   word6:word_buffer:= (  x"B7",x"C5",x"AB",x"D7",x"31",x"32",x"AB",x"D7",x"43",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");--"溫度??度C" >> 延遲3秒
constant word7:word_buffer:= (  x"A8",x"74",x"B2",x"CE",x"B6",x"69",x"A4",x"4A",x"BA",x"CE",x"AF",x"76",x"BC",x"D2",x"A6",x"A1",x"00",x"00",x"00",x"00");--"系統進入睡眠模式"
            
type State_type3 is (sd178_init, event_check, sd178_send , sd178_d1, sd178_d2, sd178_d3, sd178_d4, sd178_d5, sd178_delay1,sd178_delay2, sd178_set_ch,sd178_play1,sd178_play2);
SIGNAL  sd178State  : State_type3; 

type State_type4 is (event_check, button_process );
SIGNAL  Main_State  : State_type4;

--LCD NUMBER DATA
type oled_num_tb is array (0 to 18,0 to 15) of std_logic_vector(15 downto 0);                      --19個資料
constant table16:oled_num_tb:=
(   
   (
   	X"0000",	X"0000",	X"03e0",	X"1c18",	X"300c",	X"300c",	X"7006",	X"6006",
   	X"6006",	X"6006",	X"300c",	X"300c",	X"1818",	X"07f0",	X"0000",	X"0000"
   ),
   (
	   X"0000",	X"0000",	X"0080",	X"0f80",	X"0180",	X"0180",	X"0180",	X"0180",
	   X"0180",	X"0180",	X"0180",	X"0180",	X"0180",	X"0ff0",	X"0000",	X"0000"  
   ),   
   (   
	  X"0000",	X"0000",	X"07c0",	X"1870",	X"2018",	X"4018",	X"0018",	X"0010",
	  X"0030",	X"00c0",	X"0100",	X"0600",	X"0806",	X"7ffc",	X"0000",	X"0000"   
   ),
   (
   	X"0000",	X"0000",	X"07e0",	X"1830",	X"2018",	X"0010",	X"0020",	X"01e0",
   	X"0638",	X"001c",	X"000c",	X"0008",	X"0010",	X"3fe0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"0010",	X"0070",	X"00b0",	X"0130",	X"0230",	X"0c30",
   	X"1830",	X"2030",	X"7ffe",	X"0030",	X"0030",	X"0030",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"03fc",	X"0600",	X"0400",	X"0c00",	X"1fe0",	X"0070",
   	X"0018",	X"000c",	X"000c",	X"0008",	X"0010",	X"3fe0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"003c",	X"03c0",	X"0600",	X"1800",	X"31c0",	X"3e38",
   	X"700c",	X"600c",	X"2006",	X"3004",	X"1808",	X"07f0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"1ffc",	X"100c",	X"2008",	X"0018",	X"0010",	X"0030",
   	X"0060",	X"0060",	X"00c0",	X"0080",	X"0180",	X"0300",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"07e0",	X"1818",	X"3008",	X"3018",	X"1c30",	X"07c0",
   	X"06e0",	X"1838",	X"300c",	X"3006",	X"300c",	X"0ff0",	X"0000",	X"0000"
   ),
   (
   	X"0000",	X"0000",	X"07c0",	X"1830",	X"300c",	X"200c",	X"700c",	X"300c",
   	X"180c",	X"07fc",	X"0018",	X"0030",	X"00c0",	X"3f00",	X"0000",	X"0000"
   ),
   (
   	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",
   	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff",	X"ffff"
   ),
   (
	   X"0000",	X"0000",	X"ff80",	X"3078",	X"100c",	X"100c",	X"100c",	X"1038",   --R
	   X"1fc0",	X"10c0",	X"1060",	X"1030",	X"3818",	X"fe0f",	X"0000",	X"0000"
	),	
	(
    	X"0000",	X"0000",	X"ffff",	X"c183",	X"8181",	X"0180",	X"0180",	X"0180",   --T 
	   X"0180",	X"0180",	X"0180",	X"0180",	X"0180",	X"0ff0",	X"0000",	X"0000"  
	),
	(
	   X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"03c0",	X"0180",   --:
	   X"0000",	X"0000",	X"0000",	X"0000",	X"0180",	X"03c0",	X"0000",	X"0000"	   
	),
	(
	   X"0000",	X"07e0",	X"0ff0",	X"1818",	X"380c",	X"300c",	X"6006",	X"6006",   --逆轉
	   X"6006",	X"6006",	X"300c",	X"300c",	X"1918",	X"0f30",	X"0700",	X"0f00"	   
	),
	(
	   X"0000",	X"07e0",	X"0ff0",	X"1818",	X"380c",	X"300c",	X"6006",	X"6006",   --正轉
	   X"6006",	X"6006",	X"300c",	X"300c",	X"1898",	X"0cf0",	X"00e0",	X"00f0"		   
	),
   ( 
	   X"0000",	X"0000",	X"1210",	X"0bf8",	X"0250",	X"22b0",	X"1310",	X"03f0",   --溫
	   X"0000",	X"0bf8",	X"12a8",	X"12a8",	X"22a8",	X"27fc",	X"0000",	X"0000"
   ),
   (
	   X"0000",	X"0000",	X"0080",	X"1ffc",	X"1220",	X"1ffc",	X"1220",	X"13e0",   --度
	   X"1000",	X"17f0",	X"1120",	X"10c0",	X"2130",	X"2e0c",	X"0000",	X"0000"
   ),
   (	
	   X"0000",	X"0000",	X"13f8",	X"0a08",	X"03f8",	X"2208",	X"13f8",	X"0114",   --濕
	   X"02a8",	X"0954",	X"13fc",	X"1000",	X"22a8",	X"24a4",	X"0000",	X"0000"
   )      	
);

type lcd_table2 is array  (0 to 2 ,0 to 63) of std_logic_vector(15 downto 0);                       --3個資料
constant table32:lcd_table2:=
(   
   (                                                                                                --'溫' 
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0604",	X"0180",	X"0307",	X"ffc0",
   	X"01c6",	X"3180",	X"00c6",	X"3180",	X"00c6",	X"6180",	X"0006",	X"7180",
   	X"1006",	X"dd80",	X"0c06",	X"cd80",	X"0707",	X"8580",	X"0386",	X"0180",
   	X"0107",	X"ff80",	X"0006",	X"0180",	X"0000",	X"0000",	X"0048",	X"00c0",
   	X"00cf",	X"ffe0",	X"018d",	X"ccc0",	X"018d",	X"ccc0",	X"030d",	X"ccc0",
   	X"060d",	X"ccc0",	X"0e0d",	X"ccc0",	X"1c0d",	X"ccc0",	X"1c0d",	X"ccc0",
   	X"087d",	X"ddf0",	X"007f",	X"fff0",	X"0000",	X"0000",	X"0000",	X"0000"
   ),	
   (
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",                       --'度'
   	X"0000",	X"0000",	X"0004",	X"0000",	X"0003",	X"0000",	X"0001",	X"0040",
   	X"0fff",	X"ffe0",	X"0c00",	X"0000",	X"0c1c",	X"1800",	X"0c18",	X"1000",
   	X"0c18",	X"1080",	X"0fff",	X"ffc0",	X"0c18",	X"1000",	X"0c18",	X"1000",
   	X"0c18",	X"1000",	X"0c18",	X"1000",	X"0c1f",	X"e800",	X"0c00",	X"0000",
   	X"0840",	X"0600",	X"083f",	X"fe00",	X"0808",	X"0c00",	X"080c",	X"1800",
   	X"0806",	X"3000",	X"0801",	X"e000",	X"1001",	X"e000",	X"1006",	X"3c00",
   	X"2018",	X"0fc0",	X"27e0",	X"01a0",	X"0000",	X"0000",	X"0000",	X"0000"
   ),	
   (
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",	X"0000",                       --'濕' 
   	X"0000",	X"0000",	X"0000",	X"0000",	X"0810",	X"0100",	X"061f",	X"ff80",
   	X"0310",	X"0100",	X"0110",	X"0100",	X"001f",	X"ff00",	X"0010",	X"0100",
   	X"3010",	X"0100",	X"0c1f",	X"ff00",	X"0610",	X"0100",	X"020c",	X"0600",
   	X"000a",	X"0400",	X"0091",	X"8880",	X"0123",	X"11c0",	X"013e",	X"1f00",
   	X"012c",	X"1500",	X"0213",	X"0880",	X"027f",	X"bfc0",	X"0430",	X"9060",
   	X"0c40",	X"2000",	X"0822",	X"2100",	X"1823",	X"1080",	X"3021",	X"0840",
   	X"1041",	X"0860",	X"0080",	X"0040",	X"0000",	X"0000",	X"0000",	X"0000"
   )     
);

--TSL2561
SIGNAL  TSL2561_data : STD_LOGIC_VECTOR(14 DOWNTO 0);
SIGNAL  TSL2561_int  :integer range 0 to 9999;            
SIGNAL  d0, d0_last  :integer range 0 to 9999;   
SIGNAL  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9;   	                                
--DHT11
SIGNAL HU_BUFF, TE_BUFF : STD_LOGIC_VECTOR(7 DOWNTO 0);  
SIGNAL DHT11_error : STD_LOGIC;   
--KEYBOARD
SIGNAL keyin,keyin_last : std_logic_vector(0 to 15);                       
SIGNAL button_event     : std_logic_vector(0 to 15);   
--7SEG
SIGNAL D0_BUFFER,D1_BUFFER,D2_BUFFER,D3_BUFFER         : std_logic_vector(3 downto 0);
SIGNAL D0_BUFFER_2,D1_BUFFER_2,D2_BUFFER_2,D3_BUFFER_2 : std_logic_vector(3 downto 0);   
SIGNAL seg1_dot, seg2_dot                              : std_logic_vector(0 to 3);       
--SD178B  
SIGNAL  sd178_ena, sd178_rw, sd178_busy, sd178_ack_error  : std_logic;   
SIGNAL  sd178_addr      : STD_LOGIC_VECTOR(6 DOWNTO 0);     
SIGNAL  sd178_data_wr, sd178_data_rd   : STD_LOGIC_VECTOR(7 DOWNTO 0);   
SIGNAL  cnt_byte   :integer range 0 to 30; 
SIGNAL  var_vol,var_vol_last  :integer range 0 to 9;   
--other
SIGNAL  clk_1KHz,clk_1MHz, clk_100hz : STD_LOGIC;        
SIGNAL  d3            :integer range 0 to 20; 
SIGNAL  mode_lcd,mode_7seg, mode_sd178, mode_motor   :integer range 0 to 10;
SIGNAL  motor_speed   :integer range 0 to 10;
SIGNAL  motor_dir : STD_LOGIC;        
--LCD   
SIGNAL  clk_25MHz : STD_LOGIC;        
SIGNAL  fsm,fsm_back,fsm_back2   :integer range 0 to 200;
SIGNAL  data_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  DC_data    : std_logic;   
SIGNAL  lcd_write, lcd_show, lcd_busy    : std_logic;
SIGNAL  lcd_address          : std_logic_vector(14 downto 0);
SIGNAL  lcd_color            : std_logic_vector(5 DOWNTO 0);  
 
begin  

 	process(nReset, clk_100hz)          --按鍵除彈跳
 	 variable scan_number    :integer range 0 to 3; 	 
 	 begin	
      if(nReset='0')then 	
         keyin      <= "1111111111111111";    
         keyin_last <= "1111111111111111";    
      elsif(clk_100hz 'event and clk_100hz ='1')then
         if scan_number = 0 then
            keyin_last(0)  <= keyin(0);
            keyin_last(4)  <= keyin(4);
            keyin_last(8)  <= keyin(8);                              
            keyin_last(12)  <= keyin(12);                              

            keyin(0)       <= key_col(0);  
            keyin(4)       <= key_col(1);  
            keyin(8)       <= key_col(2);                 
            keyin(12)      <= key_col(3);                                          
            key_scan <= "1011";       
            scan_number := 1;

         ELSIF scan_number = 1 then
            keyin_last(1)  <= keyin(1);
            keyin_last(5)  <= keyin(5);
            keyin_last(9)  <= keyin(9);                              
            keyin_last(13)  <= keyin(13);

            keyin(1)       <= key_col(0);  
            keyin(5)       <= key_col(1);  
            keyin(9)       <= key_col(2);                 
            keyin(13)      <= key_col(3); 
            key_scan <= "1101";                           
            scan_number := 2;  

         ELSIF scan_number = 2 then
            keyin_last(2)  <= keyin(2);
            keyin_last(6)  <= keyin(6);
            keyin_last(10) <= keyin(10);                              
            keyin_last(14) <= keyin(14);

            keyin(2)       <= key_col(0);  
            keyin(6)       <= key_col(1);  
            keyin(10)      <= key_col(2);                 
            keyin(14)      <= key_col(3);                
            key_scan <= "1110";                           
            scan_number := 3;  
                                 
         else
            keyin_last(3)  <= keyin(3);
            keyin_last(7)  <= keyin(7);
            keyin_last(11)  <= keyin(11);                              
            keyin_last(15)  <= keyin(15);
               
            keyin(3)       <= key_col(0);  
            keyin(7)       <= key_col(1);  
            keyin(11)      <= key_col(2);                 
            keyin(15)      <= key_col(3);                
            key_scan <= "0111";                           
            scan_number := 0;
          
         end if;                         
      end if; 	   
 	end process;
       
 	process(nReset,clk_1MHz)            --按鍵控制
      variable delay_1   :integer range 0 to 100;   	         
      variable i,j         :integer range 0 to 100;
 	begin	  
      if(nReset='0')then
         mode_lcd   <= 0;
         mode_7seg  <= 0; 
         mode_sd178 <= 0; 
         mode_motor <= 0;          
         delay_1   := 0;                          

         button_event <= X"0000";  
         Main_State  <= event_check;            

      ELSIF(clk_1MHz'EVENT AND clk_1MHz='1')then   

         CASE Main_State IS                
            
            when event_check=>       
            	for i in 0 to 15 loop            	
            	   if   (keyin(i) = '0') and (keyin_last(i) = '1') then 
         	         --產生EVENT PULSE
         	         delay_1 :=0; 
         	         j := i;
         	         Main_State <= button_process; 
         	         
         	         --
               	   if(i = 0) then       -- 按下KEY1         	                  	         	      
               	      if   (dipsw1(5) = '0') and (dipsw1(6) = '0') and (dipsw1(7) = '0') then 
               	         mode_lcd  <= 0;        	                  	         
               	         mode_7seg <= 0;
               	         mode_sd178 <= 0; 
               	         mode_motor <= 0;   
                        elsif(dipsw1(5) = '0') and (dipsw1(6) = '0') and (dipsw1(7) = '1') then        
                           mode_lcd  <= 1;        	                  	          	         
                           mode_7seg <= 2;                                     --顯示溫度
                           mode_sd178 <= 0;
                           mode_motor <= 1; 
                        elsif(dipsw1(5) = '0') and (dipsw1(6) = '1') and (dipsw1(7) = '0') then         	         
                           mode_lcd  <= 2;        	                  	                              
                           mode_7seg <= 0;
                           mode_sd178 <= 0;
                           mode_motor <= 2; 
                        elsif(dipsw1(5) = '0') and (dipsw1(6) = '1') and (dipsw1(7) = '1') then         	         
                           mode_lcd   <= 3;        	                  	                              
                           mode_7seg  <= 0; 
                           mode_sd178 <= 1;                                    --開始循環撥放                                                                 
                           mode_motor <= 0; 

                        elsif(dipsw1(5) = '1') and (dipsw1(6) = '0') and (dipsw1(7) = '0') then         	         
                           mode_lcd  <= 4;        	                  	                              
                           mode_7seg <= 3;                                     --顯示光強度           
                           mode_sd178 <= 1;
                           mode_motor <= 1;                            
                           
               	      end if;            	      
               	      
               	   elsif(i = 2)  then    -- 按下KEY3               	                     	      
               	      if(dipsw1(5) = '0') and(dipsw1(6) = '0') and (dipsw1(7) = '0') then         	                  	         
               	         mode_lcd  <= 0;        	                  	         
               	         mode_7seg <= 0;
               	         mode_sd178 <= 0;
                        elsif(dipsw1(5) = '0') and(dipsw1(6) = '0') and (dipsw1(7) = '1') then         	         
                           mode_7seg  <= 1;                                   --停止顯示溫度  
                           mode_motor <= 0;                                   --停止馬達   
                        elsif(dipsw1(5) = '0') and(dipsw1(6) = '1') and (dipsw1(7) = '0') then         	         
                           mode_7seg  <= 0;     
                           mode_motor <= 0;                                   --停止馬達                        
                        elsif(dipsw1(5) = '0') and(dipsw1(6) = '1') and (dipsw1(7) = '1') then         	         
               	         mode_sd178 <= 0;            
               	            	         
                        elsif(dipsw1(5) = '1') and(dipsw1(6) = '0') and (dipsw1(7) = '0') then         	         
                           mode_7seg  <= 1;                                   --停止顯示光強度   	         
               	         mode_sd178 <= 0;                                       
                           mode_motor <= 0;                            
                                                      
               	      end if;          	                     	                                                           
                 	   end if;	         	         
                  end if;                      
            	end loop;             	                                         
                                                                                                                                                
            when button_process =>              		   
                  if delay_1 >= 10 then                                   -- 產生10us觸發訊號 ,button_event                        
       		         button_event(j) <= '0';           		                      		              		                                                                   		         
          		      if(keyin(j) = '1')  then  
                        delay_1 :=0;                                                     
                        Main_State <= event_check;                                                                       
                     end if;                           
                  else
                     delay_1:= delay_1+1;
          		      button_event(j) <= '1';
                  end if;  
                      
            when others =>  
                      Main_State <= event_check;                                                                        
                          
            END CASE;            
      end if; 	   
 	end process;
 	         
   process(nReset,clk_100hz)           --七段顯示器
      variable cnt_step        :integer range 0 to 9;
   begin
      if(nReset='0')then 
         cnt_step  := 0;         
         D0_BUFFER   <= "1010";  D1_BUFFER   <= "1010"; D2_BUFFER   <= "1010"; D3_BUFFER   <= "1010";
         D0_BUFFER_2 <= "1010";  D1_BUFFER_2 <= "1010"; D2_BUFFER_2 <= "1010"; D3_BUFFER_2 <= "1010"; 

         seg1_dot <= "0000";           
         seg2_dot <= "0000";         
         motor_speed <= 0;
         
      ELSIF(clk_100hz'EVENT AND clk_100hz='1')then
         if cnt_step = 0 then                                  --轉換TSL2561資料 & 馬達轉速
            TSL2561_int  <= CONV_INTEGER(TSL2561_data) mod 10000;
                              
            if(CONV_INTEGER(TE_BUFF) <= 22) then               --溫度小於等於22,馬達轉速0 
               motor_speed <= 0;   
            elsif(CONV_INTEGER(TE_BUFF) >= 32) then            --溫度大於等於32,馬達轉速10 
               motor_speed <= 10;                  
            else
               motor_speed <= CONV_INTEGER(TE_BUFF) - 22;      --溫度提高1度，轉速會變快+1                
            end if;                  
            cnt_step := 1;
            
         ELSIF cnt_step = 1 then    
            lx1 <= (TSL2561_int / 10000) mod 10;                               
            lx2 <= (TSL2561_int / 1000) mod 10;                   
            lx3 <= (TSL2561_int / 100) mod 10;
            lx4 <= (TSL2561_int / 10) mod 10;
            lx5 <= TSL2561_int mod 10;  
                                 
            cnt_step := 2;
            
         ELSIF cnt_step = 2 then                            --判斷顯示什麼 
            
            if(mode_7seg = 0) then                          --全滅,不顯示
               D0_BUFFER   <= "1010";  D1_BUFFER   <= "1010"; D2_BUFFER   <= "1010"; D3_BUFFER   <= "1010";
               D0_BUFFER_2 <= "1010";  D1_BUFFER_2 <= "1010"; D2_BUFFER_2 <= "1010"; D3_BUFFER_2 <= "1010"; 
               seg1_dot <= "0000";           
               seg2_dot <= "0000";  

            ELSIF mode_7seg = 1 then                        --IDLE 停止不更新畫面

               
            ELSIF mode_7seg = 2 then                        --顯示溫度               
               D0_BUFFER   <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF)/10),4);       --溫度
               D1_BUFFER   <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF) mod 10),4);                                            
               D2_BUFFER   <= "1011";       --度 
               D3_BUFFER   <= "1100";       --C 
               
               D0_BUFFER_2 <= conv_std_logic_vector((motor_speed/10),4);                 --馬達速度
               D1_BUFFER_2 <= conv_std_logic_vector((motor_speed mod 10),4);     
               D2_BUFFER_2 <= "1101";	     --SP  
               D3_BUFFER_2 <= "1110";       --SP         
               seg1_dot <= "0000";           
               seg2_dot <= "0011";  

            ELSIF mode_7seg = 3 then                        --顯示光強度值               
               D0_BUFFER <= conv_std_logic_vector(lx1,4);   --最左邊位元
               D1_BUFFER <= conv_std_logic_vector(lx2,4);	
               D2_BUFFER <= conv_std_logic_vector(lx3,4);	
               D3_BUFFER <= conv_std_logic_vector(lx4,4);                                                                                                     
               D0_BUFFER_2 <= conv_std_logic_vector(lx5,4);
               D1_BUFFER_2 <= "1010";	    
               D2_BUFFER_2 <= "1010";	    
               D3_BUFFER_2 <= "1010";      
               seg1_dot <= "0000";           
               seg2_dot <= "0000";                                                    
               
            end if;   
            
            cnt_step := 0;      
         end if;               
      end if;     
   end process;    
       
   process(fin)                        --sd178
   variable cnt_delay      :integer range 0 to 50000000;       
   variable cnt_loop       :integer range 0 to 50;       
   variable cnt3,cnt_next  :integer range 0 to 14;      
   variable cnt4,cnt4_set  :integer range 0 to 20;      
   variable flag_play   :STD_LOGIC;
   variable vol_loop       :integer range 0 to 100;      
               
   begin  
      if(fin'EVENT AND fin='1')then     
         if(nReset='0')then 
            SD178_nrst <= '1'; 
            sd178_ena  <= '0';                                      
            sd178State <= sd178_init; 

            flag_play  := '0';            
            var_vol <= 6; 
            vol_loop := 0;
            
            D0       <= 378;
            d3       <= 1;
         else
                                                  
            CASE sd178State IS  
               when sd178_init=>  
                       SD178_nrst <= '0'; 
                        
               	     if cnt_delay =  50000000 then            -- 1s    	
            	           cnt_delay := 0;            	             
            	           sd178State <= event_check;
            	        else   
                          cnt_delay :=  cnt_delay + 1;             	             
            	        end if;            	
            	
               when event_check=>  
                         
                       if (mode_sd178 = 1)then

                	       if (button_event(0) = '1') then                     	                            	           
                            if (flag_play = '0') then 
                                d3       <= 2;                                 
                                
                                sd178State <= sd178_set_ch;                       --需先設定輸出通道&音量 > 延遲 > 撥放
                                
                                if(dipsw1(7) = '1') and (dipsw1(6) = '1') then
                                   word1(1) <=  x"07";                            --左右聲道都有
                                elsif(dipsw1(7) = '0') and (dipsw1(6) = '1') then    
                                   word1(1) <=  x"06";                            --右聲道
                                elsif(dipsw1(7) = '1') and (dipsw1(6) = '0') then    
                                   word1(1) <=  x"05";                            --左聲道
                                elsif(dipsw1(7) = '0') and (dipsw1(6) = '0') then    
                                   word1(1) <=  x"03";                            --左右聲道都無
                                end if; 
                                var_vol      <= 6;   
                                var_vol_last <= 6;
                                cnt3       := 0;
                            else
                                flag_play := '0';
                                
                  	             cnt_byte <= 1;                            
                                word_buf(0) <=  x"80";                --停止        	                           	                               
                                vol_loop :=  0;                                  
                                var_vol      <= 6;   
                                var_vol_last <= 6;  
                                sd178State <= sd178_send;                                                             
                            end if;                 	                                              
                                                           
                         elsif (flag_play = '1') then                        --循環播放語音
                            d3       <= cnt_next;                                --DEBUG
                            if cnt3 = 0 then                                 --撥 "系統開機"
                	             cnt_byte <= 8;                                --cnt3,控制循環播放
               	               word_buf <= word3;                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3       := 12;                             --12 進入延遲迴圈
                               cnt4       := 0;                              --cnt4    ,延遲計數 
                               cnt4_set   := 5;                              --cnt4_set,延遲秒數
                               cnt_next   := 1;                              
                               cnt_delay:= 0;                                                                
                            
                            elsif cnt3 = 1 then                              --準備資料-”溫度??度C”
                               cnt3       := 2;                                                                              
                               word6(4) <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF)/10),8) or x"30";        --溫度資料 -- +48 是轉成ASCII                          
                     		    word6(5) <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF) mod 10),8) or x"30";               -- +48 是轉成ASCII                          
                               
                            elsif cnt3 = 2 then                              --撥 "溫度??度C" 
                	             cnt_byte <= 8;                                --cnt3,控制循環播放
               	               word_buf <= word6;                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3       := 12;                             --12 進入延遲迴圈
                               cnt4       := 0;                              --cnt4    ,延遲計數 
                               cnt4_set   := 5;                              --cnt4_set,延遲秒數
                               cnt_next   := 3;                              
                               cnt_delay:= 0;                                                                     

                            elsif cnt3 = 3 then                              --準備資料-”溫度??度C”
                               cnt3       := 4;                                                                                                              
                               word5(4) <= conv_std_logic_vector(lx2,8) or x"30";             -- +48 是轉成ASCII                          
                       		    word5(5) <= conv_std_logic_vector(lx3,8) or x"30";             -- +48 是轉成ASCII                          
                       		    word5(6) <= conv_std_logic_vector(lx4,8) or x"30";             -- +48 是轉成ASCII                          
                       		    word5(7) <= conv_std_logic_vector(lx5,8) or x"30";             -- +48 是轉成ASCII                                                                                                                        
                                                                    
                            elsif cnt3 = 4 then                              --撥 "亮度????勒克司"      
                	             cnt_byte <= 19;                           
               	             word_buf <= word5;                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12; 
                               cnt4     := 0;
                               cnt4_set := 7;
                               cnt_next   := 5;                                   
                               cnt_delay:= 0;                                    

                            elsif cnt3 = 5 then                              --撥放檔案                              
                   	          cnt_byte <= 11;                           
                  	          word_buf <= word4;                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12; 
                               cnt4     := 0;
                               cnt4_set := 10;                               --播放10秒 
                               cnt_next := 6;                                   
                               cnt_delay:= 0;
                               
                            elsif cnt3 = 6 then                              --清除播放後,LOOP
               	             cnt_byte <= 4;                           
              	                word_buf(0) <=  x"80";                      	                           	                               
              	                word_buf(1) <=  x"80";                      	                           	                               
              	                word_buf(2) <=  x"80";                      	                           	                               
              	                word_buf(3) <=  x"80";                      	                           	                                     
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 3;
                               cnt_next := 0;                                   
                               cnt_delay:= 0;                                                         	                           	                               
                               
                            elsif cnt3 = 7 then                              --清除播放後,LOOP                               
               	             cnt_byte <= 1;                           
              	                word_buf(0) <=  x"80";                      	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 1;
                               cnt_next := 6;                                   
                               cnt_delay:= 0;
                            
                            elsif cnt3 = 8 then                              --清除播放
               	             cnt_byte <= 1;                           
              	                word_buf(0) <=  x"80";                      	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 1;
                               cnt_next := 8;                                   
                               cnt_delay:= 0;
                               
                            elsif cnt3 = 9 then                                --調整音量至預設,未使用
                	             cnt_byte <= 2;                           
               	             word_buf(0) <=  x"86";                       	                           	                               
               	             word_buf(1) <=  x"C3";                       	                           	                                
                               sd178State <= sd178_send;                                  
                               var_vol      <= 6;   
                               var_vol_last <= 6;
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 1;
                               cnt_next := 10;                                   
                               cnt_delay:= 0; 

                               word5(4) <= conv_std_logic_vector(lx2,8) or x"30";              -- +48 是轉成ASCII                          
                          	   word5(5) <= conv_std_logic_vector(lx3,8) or x"30";             -- +48 是轉成ASCII                          
                          	   word5(6) <= conv_std_logic_vector(lx4,8) or x"30";             -- +48 是轉成ASCII                          
                          	   word5(7) <= conv_std_logic_vector(lx5,8) or x"30";             -- +48 是轉成ASCII 
                            
                            elsif cnt3 = 10 then                               --更新OLED
                               cnt3     := 13;                                   
                               cnt_next := 11;                                   
                               cnt_delay:= 0;                                  
                                                                   
                            elsif cnt3 = 11 then                               --撥 "亮度 zz 勒克司"  
                	             cnt_byte <= 19;                           
               	             word_buf <= word5;                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12; 
                               cnt4     := 0;
                               cnt4_set := 7;
                               cnt_next := 14;                                   
                               cnt_delay:= 0; 

                            elsif cnt3 = 14 then                              --撥 "系統進入睡眠模式"
                	              cnt_byte <= 16;                           
               	                word_buf <= word7;                        	                           	                               
                                sd178State <= sd178_send;                                  
                                cnt3     := 12;
                                cnt4     := 0;
                                cnt4_set := 7;
                                cnt_next   := 0; 
                                cnt_delay:= 0;

                            elsif cnt3 = 12 then                              --延遲迴圈
                               cnt_delay:=cnt_delay+1;                                                             
                               if cnt_delay = 50000000 then                 
                                  cnt_delay:= 0; 
                                  cnt4     := cnt4 + 1;
                               else
                                  if cnt4 = cnt4_set then                                                                  
                                     cnt3 := cnt_next;                                                                              
                                  end if;                                                
                               end if;
                                                                                                                                  
                            end if;                                                           
                         end if;                           
                                                                                                                                      
                      end if;  

               WHEN sd178_set_ch =>                   
                   	     cnt_byte <= 4;                           
                  	     word_buf <= word1;                          	                               
                         sd178State <= sd178_send;                                                                                                                                                                                                                                                                                        
                         flag_play  := '1';
                         
               WHEN sd178_send =>                   
                                                
                        cnt_loop := 0;
                        sd178State      <= sd178_d1;                                                                                                                               
                                                                       
               WHEN sd178_d1=>                                       --start write data

                        sd178_addr      <= "0100000";               --write sd178_address 0xx20
                        sd178_data_wr   <= word_buf(cnt_loop);	           --更換資料                         
                        sd178_rw        <= '0';                     --0/write  
                        sd178State      <= sd178_d2;
                        
                        cnt_loop := cnt_loop + 1;                   --傳送資料上數+1 
               WHEN sd178_d2=>                      
                        sd178_ena   <= '1';                                                                    
                        sd178State  <= sd178_d3;   

               WHEN sd178_d3=>                      
                        if sd178_busy = '1' then  
                            if cnt_loop >= cnt_byte  then 
                               sd178_ena    <= '0';
                               sd178State   <= sd178_d5;   
                            else                            
                               sd178_data_wr <= word_buf(cnt_loop);         --command    
                               sd178_rw      <= '0';                 --0/write                                                                                                                                                                             
                               cnt_loop := cnt_loop + 1;             --傳送資料上數+1
                               sd178State    <= sd178_d4;
                           end if; 
                        end if;                         
               WHEN sd178_d4=>            
                        if sd178_busy = '0' then                             
                           sd178_ena    <= '0';                                                                                       
                           if cnt_loop >= cnt_byte  then                --cnt_byte 傳送數量
                              sd178State   <= sd178_d5;   
                           else                           
                              sd178State   <= sd178_delay1;
                           end if;          
                           cnt_delay := 0;                                                                                                                                     
                        end if; 
                           
               WHEN sd178_delay1=>                                  --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 4000000 then                 --80ms
                           cnt_delay:=0; 
                           sd178State <= sd178_d1;
                        end if; 
                                                      
               WHEN sd178_d5=>                                      --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 5000000 then                 --100ms
                           cnt_delay:=0; 
                           sd178State <= event_check;
                        end if; 

               WHEN sd178_play1=>                                  --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 5000000 then                --100ms
                           cnt_delay:=0; 
                           sd178State <= sd178_play2;                         
                        end if; 

               WHEN sd178_play2=>                                  --delay                    	                           	                               
                   	    cnt_byte <= 11;                           
                  	    word_buf <= word4;                        	                           	                               

                         sd178State <= sd178_send;    

               WHEN sd178_delay2=>                                  --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 5000000 then                 --100ms
                           cnt_delay:=0; 
                           sd178State <= event_check;
                        end if;
                                                                                                         
              when others =>                                          
                        sd178State     <= sd178_init;
                          
            END CASE;
                           
    
         end if;
      end if;    
   end process;  

	process(fin, nReset)                -- LCD
      variable delay_1         :integer range 0 to 50000000;                                                      	               	
      variable address_start,address_end   : STD_LOGIC_VECTOR(14 DOWNTO 0); 	               	
      variable disp_color      : STD_LOGIC_VECTOR(5 DOWNTO 0); 	               	
      variable pos_x_start,pos_y_start :integer range 0 to 159;  
      variable pos_x,pos_y    :integer range 0 to 39;         
      variable pos_now              :integer range 0 to 20479;   	                  
      variable varl,cnt_number,cnt_number_max   :integer range 0 to 20;                                      
      variable cnt1           :integer range 0 to 99;                  
      variable bit_index   :integer range 0 to 32; 	               	
      variable font_num    :integer range 0 to 128;

	begin	
      if(nReset ='0')then                                	                
         fsm <= 0;
         delay_1 :=0;
         lcd_write <= '0';       
         lcd_show  <= '0';       

      ELSIF(fin'EVENT AND fin='1')then     
 
         if (button_event(0) = '1') then                    -- 開始顏色DEMO            
               delay_1 :=0;                        
               lcd_write <= '0';       
               lcd_show  <= '0';                   

               if (mode_lcd = 0) then
                  fsm     <= 1; 
               elsif ((mode_lcd = 1) or (mode_lcd = 3)) then   
                  fsm     <= 100; 
               elsif (mode_lcd = 2) then   
                  fsm     <= 110; 
               elsif (mode_lcd = 4) then   
                  fsm     <= 130;

               end if; 

         elsif (button_event(2) = '1') then                 -- 停止顏色DEMO
            fsm <= 0;                                                         	                
            delay_1 :=0;

         else

            CASE fsm IS                                          

               when 0 =>                                -- idle  


               when 1 =>           
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 60;                                        
                                       
               when 10 =>                                --更新畫面
                        if(lcd_busy = '0') then          --等待LCD閒置
                           lcd_show <= '1';
                           fsm      <= 11;                           
                        end if;                    

               when 11 =>                                                                             
                        if(lcd_busy = '1') then         --等待忙碌,表示LCD接收到lcd_show命令  
                           lcd_show <= '0';                           
                           delay_1 :=0;    
                           fsm      <= 12;
                        end if;                    

               when 12 =>                                                                             
                        if(lcd_busy = '0') then         --等待忙碌,表示LCD接收到lcd_show命令  
                           fsm      <= fsm_back;
                        end if;               
               
               when 20 =>                                    --write ram 
                        if(lcd_busy = '0') then              --等待LCD閒置
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
                        lcd_address <= lcd_address + "000000000000001"; 
                        fsm  <= 23; 
                        
               when 23 =>                                    -- address
                        if(lcd_address = address_end) then   -- 128 * 160
                           fsm        <= fsm_back;                
                        else
                           fsm        <= 20;               
                        end if;                                    
                  
--   ----------------------------------------------------------------------------       
               when 59 =>                                  -- delay 1s
                        if delay_1 >= 50000000 then                     
                           delay_1 :=0;                           
                           fsm <= fsm_back2;
                        else
                           delay_1:=delay_1+1;                          
                        end if;
   ----------------------------------------------------------------------------  MODE = "000" ,顏色展示    
               when 60 =>                                   -- 1 修改圖型    
                        lcd_address   <= "000000000000000";                         
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 61;                             

               when 61 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 62;   

               when 62 =>                                   -- delay 1s  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 63;
                                
               when 63 =>                                  -- 2 修改圖型                                                             
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "000001";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 64;                             
    
               when 64 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 65;

               when 65 =>                                  -- delay 1s  
                        delay_1 :=0;    
                        fsm       <= 59;                       
                        fsm_back2 <= 66;

               when 66 =>                                  -- 3 修改圖型 
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "000010";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 67;

               when 67 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 68;

               when 68 =>                                  -- delay 1s  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 69;
               
               when 69 =>                                  -- 4
                        lcd_address   <= "000000000000000";
                        address_end   := "001100100000000";
                        lcd_color     <= "000011";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 70;

               when 70 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 71;

               when 71 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 72;           

               when 72 =>                                  -- 5
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "010000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 73;

               when 73 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 74;

               when 74 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 75; 


               when 75 =>                                  -- 6
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "100000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 76;

               when 76 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 77;

               when 77 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 78;

               when 78 =>                                  -- 7
                        lcd_address   <= "001100100000000";
                        address_end   := "011001000000000";
                        lcd_color     <= "110000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 79;

               when 79 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 80;

               when 80 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 81;

               when 81 =>                                  -- 8
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "000100";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 82;

               when 82 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 83;

               when 83 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 84;

               when 84 =>                                  -- 9
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "001000";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 85;

               when 85 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 86;

               when 86 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 87;

               when 87 =>                                  -- 10
                        lcd_address   <= "011001000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "001100";         -- R"00"G"00"B"00"                   
                        fsm       <= 20;                   
                        fsm_back  <= 88;

               when 88 =>                                  -- 更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 89;

               when 89 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 90;

               when 90 =>                                  -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 91;
                        
               when 91 =>                                  -- LOOP,全亮
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";         -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 63;                              

   ----------------------------------------------------------------------------  MODE = "001" ,白色全亮
               when 100 =>                                   -- 1 修改圖型    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";          -- R - f800   G - 07e0  B - 001f                    
                        fsm       <= 20;                   
                        fsm_back  <= 101;                             

               when 101 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back <= 102;   

               when 102 =>                                   -- delay 1s  
                        delay_1 :=0;  
                        fsm       <= 59;                          
                        fsm_back2 <= 100;
                        
   ----------------------------------------------------------------------------  MODE = "010" ,顯示文字 圖形, 光強度數值
               when 110 =>                                   -- 清除畫面    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";           -- 全亮
                        fsm       <= 20;                   
                        fsm_back  <= 111;                             

   ----------------------------------------------------------------------------開始貼圖, 字型16x16 
               when 111 =>                                   -- 1.初始化變數   
                        pos_x       := 0;
                        pos_y       := 0;
                        varl        := 0;                    -- 顯示文字的選擇
                        cnt_number  := 0;                    -- 目前顯示第幾個文字                        
                        cnt_number_max := 9;                 -- 要顯示的文字數量   
                        cnt1        := 0;                    -- 
                        bit_index   := 15;                   -- 
--                        fsm         <= 113;   
                        fsm         <= 112;   
                                               
               when 112 =>                                   -- 2.設定顯示文字 & 貼圖位置                    
               	      if (cnt_number = 0) then             --   LOOP 112-119 
                           varl := lx1;    
                           if TSL2561_int > 20 then
                              disp_color  := "000000";          -- 文字的顏色,黑                                                                                                       
                              motor_dir <= '0';                  -- 馬達反轉
                           else
                              disp_color  := "001100";          -- 文字的顏色,綠   
                              motor_dir <= '1';                  -- 馬達正轉
                           end if;                              
                           pos_x_start  := 20;
                           pos_y_start  := 20;                
                        elsif (cnt_number = 1)  then                            
                           varl := lx2;    
                           pos_x_start  := 36;
                           pos_y_start  := 20;                                          
                        elsif (cnt_number = 2)  then                            
                           varl := lx3;
                           pos_x_start  := 52;
                           pos_y_start  := 20;                                          
                        elsif (cnt_number = 3)  then                                                      
                           varl := lx4;
                           pos_x_start  := 68;                           
                           pos_y_start  := 20; 
                        elsif (cnt_number = 4)  then                                                      
                           varl := lx5;
                           pos_x_start  := 84;                           
                           pos_y_start  := 20;                            
                        elsif (cnt_number = 5)  then                                                      
                           varl := 11;                         -- 'R'
                           disp_color    := "000000";          -- 文字的顏色,黑
                           pos_x_start  := 20;                           
                           pos_y_start  := 60; 
                        elsif (cnt_number = 6)  then                                                      
                           varl := 12;                         -- 'T'
                           disp_color    := "000000";          -- 文字的顏色,黑
                           pos_x_start  := 36;                           
                           pos_y_start  := 60;   
                        elsif (cnt_number = 7)  then                                                      
                           varl := 13;                         -- ':'
                           disp_color    := "000000";          -- 文字的顏色,黑
                           pos_x_start  := 52;                           
                           pos_y_start  := 60;  
                        elsif (cnt_number = 8)  then   
                           if TSL2561_int > 20 then                                                   
                              varl := 14;                       -- '正逆轉'
                              disp_color    := "000000";        -- 文字的顏色,黑
                           else
                              varl := 15;                       -- '正逆轉'
                              disp_color    := "110000";        -- 文字的顏色,紅                              
                           end if;      
                           pos_x_start  := 80;                           
                           pos_y_start  := 60;                                                                                                                                                                                         
                        end if;
                        fsm       <= 113;                   
                        
               when 113 =>                                     -- 2.設定LCD位址,範圍0 - (128*160-1)  ,111-115完成8點(1個BYTE)的資料寫入
                        pos_now := pos_x_start + ((pos_y_start + pos_y) * 128) + pos_x;    
                        pos_x   := pos_x + 1;                         
                        fsm       <= 114;                   

               when 114 =>                                     -- set address 
                        lcd_address   <= conv_std_logic_vector(pos_now,15);
                        fsm  <= 115;
                        
               when 115 =>                                     -- set data
                        if(table16(varl, cnt1)(bit_index) = '1') then                                                      
                           lcd_color  <= disp_color;                 --                              
                        else
                           lcd_color  <= "111111";                                             
                        end if;                               
                        fsm  <= 116; 
                        
               when 116 =>                                     -- write
                        if(lcd_busy = '0') then              --等待LCD閒置
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm  <= 117; 
                        end if;

               when 117 =>                                     -- write
                        if delay_1 >= 10 then 
                           lcd_write <= '0';
                           delay_1 :=0;     

                           if pos_x >= 16 then                    --字體寬度20
                              pos_x := 0; 
                              pos_y := pos_y + 1;                 --字體高度40(40/8byte = 5)
                           end if;
                                                                              
                           if(bit_index = 0) then
                              bit_index := 15;
                              fsm  <= 118; 
                           else   
                              bit_index   := bit_index - 1;                                             
                              fsm  <= 113;                         
                           end if;                                                                                                                                                                                                          
                        else
                           delay_1:=delay_1+1;                          
                        end if;                  
                                                                  
               when 118 =>                                                               
                           if cnt1 >= 15 then                  --每個數字16個word(16bits)
                              cnt1 := 0;
                              fsm  <= 119; 
                           else
                              cnt1 := cnt1 + 1;                     
                              fsm  <= 112; 
                           end if;
                        
               when 119 =>                                    
                        if (cnt_number < (cnt_number_max-1)) then  -- 顯示數量
                           cnt_number := cnt_number + 1;           -- 指到下個數字                                                                                 
                           pos_x       := 0;
                           pos_y       := 0;
                           
                           fsm       <= 113;      
                        else
                           cnt_number := 0;
                           fsm       <= 120;                                
                        end if;   
               
               when 120 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 121;                  

               when 121 =>                                  -- delay 1s , 1秒更新1次資料  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 110;

   ----------------------------------------------------------------------------  MODE = "100" ,顯示溫濕數值,字型16x16 
               when 130 =>                                   -- 清除畫面    
                        lcd_address   <= "000000000000000";
                        address_end   := "101000000000000";
                        lcd_color     <= "111111";           -- 全亮
                        fsm       <= 20;                   
                        fsm_back  <= 131;                             

   ----------------------------------------------------------------------------開始貼圖 
               when 131 =>                                   -- 1.初始化變數   
                        pos_x       := 0;
                        pos_y       := 0;
                        varl        := 0;                    -- 顯示文字的選擇
                        cnt_number  := 0;                    -- 目前顯示第幾個文字                        
                        cnt_number_max := 8;                 -- 要顯示的文字數量   
                        cnt1        := 0;                    -- 
                        bit_index   := 15;                   -- 
                        fsm         <= 132;                           
                                               
               when 132 =>                                   -- 2.設定顯示文字 & 貼圖位置          
                        if (cnt_number = 0) then 
                           disp_color  := "000011";             --文字的顏色,藍                            
                           varl := 0;                           --溫度
                           font_num := 1;                       --32x32                             
                           pos_x_start  :=  5;                           
                           pos_y_start  := 10;                            
                        elsif (cnt_number = 1)  then                                                      
                           varl := 1;  
                           pos_x_start  := 37;                           
                           pos_y_start  := 10;                   
                        elsif (cnt_number = 2) then 
                           varl := 2;                           --濕度
                           font_num := 1;                       --32x32                             
                           pos_x_start  :=  5;                           
                           pos_y_start  := 42;                            
                        elsif (cnt_number = 3)  then                                                      
                           varl := 1;  
                           pos_x_start  := 37;                           
                           pos_y_start  := 42; 
                            
               	      elsif (cnt_number = 4) then                                                                
                           disp_color  := "110000";             --文字的顏色,紅                            
                           varl := (CONV_INTEGER(TE_BUFF)/10);  --溫度數值
                           font_num := 0;                       --16x16  
                           pos_x_start  := 73;                           
                           pos_y_start  := 20;                            
                        elsif (cnt_number = 5)  then                                                      
                           varl := (CONV_INTEGER(TE_BUFF) mod 10);  
                           pos_x_start  := 89;                           
                           pos_y_start  := 20;                                                                                                                                                                 
                        elsif (cnt_number = 6)  then                                                      
                           varl := (CONV_INTEGER(HU_BUFF)/10);  --濕度數值
                           pos_x_start  := 73;                           
                           pos_y_start  := 55;                            
                        elsif (cnt_number = 7)  then                                                      
                           varl := (CONV_INTEGER(HU_BUFF) mod 10);  
                           pos_x_start  := 89;                           
                           pos_y_start  := 55;                                                                                                                                                                                       
                        end if;
                        fsm       <= 133;                   
                        
               when 133 =>                                     -- 2.設定LCD位址,範圍0 - (128*160-1)  ,131-135完成8點(1個BYTE)的資料寫入
                        pos_now := pos_x_start + ((pos_y_start + pos_y) * 128) + pos_x;    
                        pos_x   := pos_x + 1;                         
                        fsm       <= 134;                   

               when 134 =>                                     -- set address 
                        lcd_address   <= conv_std_logic_vector(pos_now,15);
                        fsm  <= 135;
                        
               when 135 =>                                     -- set data                       
                        if(font_num = 0) then                                    
                           if(table16(varl, cnt1)(bit_index) = '1') then                                                      
                              lcd_color  <= disp_color;                                               
                           else
                              lcd_color  <= "111111";                                             
                           end if;                               
                        elsif(font_num = 1) then      
                           if(table32(varl, cnt1)(bit_index) = '1') then                                                      
                              lcd_color  <= disp_color;                                               
                           else
                              lcd_color  <= "111111";                                             
                           end if;                             
                        end if;                                 
                        fsm  <= 136; 
                        
               when 136 =>                                     -- write
                        if(lcd_busy = '0') then              --等待LCD閒置
                           lcd_write   <= '1';
                           delay_1 :=0;
                           fsm  <= 137; 
                        end if;

               when 137 =>                                     -- write
                        if delay_1 >= 10 then 
                           lcd_write <= '0';
                           delay_1 :=0;     

                           if(font_num = 0) then 
                              if pos_x >= 16 then            --字體寬度
                                 pos_x := 0; 
                                 pos_y := pos_y + 1;      
                              end if;
                           elsif(font_num = 1) then 
                              if pos_x >= 32 then            --字體寬度
                                 pos_x := 0; 
                                 pos_y := pos_y + 1;      
                              end if;                                                                                                                          
                           end if;                                  
                                                                              
                           if(bit_index = 0) then
                              bit_index := 15;
                              fsm  <= 138; 
                           else   
                              bit_index   := bit_index - 1;                                             
                              fsm  <= 133;                         
                           end if;                                                                                                                                                                                                          
                        else
                           delay_1:=delay_1+1;                          
                        end if;                  
                                                                  
               when 138 =>                                  
                        if(font_num = 0) then                                                                                 
                           if cnt1 >= 15 then                  --每個數字16個word(16bits)
                              cnt1 := 0;
                              fsm  <= 139; 
                           else
                              cnt1 := cnt1 + 1;                     
                              fsm  <= 132; 
                           end if;
                        elsif(font_num = 1) then                                                                                 
                           if cnt1 >= 63 then                  --每個數字64個word(16bits)
                              cnt1 := 0;
                              fsm  <= 139; 
                           else
                              cnt1 := cnt1 + 1;                     
                              fsm  <= 132; 
                           end if;                              
                        end if;
               when 139 =>                                    
                        if (cnt_number < (cnt_number_max-1)) then  -- 顯示數量
                           cnt_number := cnt_number + 1;           -- 指到下個數字                                                                                 
                           pos_x       := 0;
                           pos_y       := 0;
                           
                           fsm       <= 133;      
                        else
                           cnt_number := 0;
                           fsm       <= 140;                                
                        end if;   
               
               when 140 =>                                   --更新畫面    
                        fsm       <= 10;                   
                        fsm_back  <= 141;                  

               when 141 =>                                  -- delay 1s , 1秒更新1次資料  
                        delay_1 :=0; 
                        fsm       <= 59;                           
                        fsm_back2 <= 130;
               
               when others =>                          
                             
            END CASE;             
            
         end if;                                                             
                             
      end if; 	   

	end process;

   process(nReset, clk_1KHz)           -- MOTOR-PWM
 	   variable scan_number    :integer range 0 to 9; 	 
   begin	
      if(nReset='0')then 	
         motor_out1 <= '0';
         motor_out2 <= '0';
         motor_pwm1 <= '0';
         scan_number := 0;
         
      elsif(clk_1KHz 'event and clk_1KHz ='1')then
         
         if(mode_motor = 1) then                 
            motor_out1 <= '1';
            motor_out2 <= '0';
            
            if(scan_number >= 9) then 
               scan_number := 0;
            else      
               scan_number := scan_number + 1;                        
            end if;   
               
            if(motor_speed > scan_number) then 
               motor_pwm1 <= '1';
            else      
               motor_pwm1 <= '0';
            end if; 

         elsif(mode_motor = 2) then                 --全速
            motor_pwm1 <= '1';                   
            
            if(motor_dir = '0') then
               motor_out1 <= '1';                   --正轉
               motor_out2 <= '0';            
            else           
               motor_out1 <= '0';                   --反轉
               motor_out2 <= '1';                           
            end if;   
                                                                
         else
            motor_out1 <= '0';
            motor_out2 <= '0';
            motor_pwm1 <= '0';
            scan_number := 0;            
               
         end if;                         
                                    
      end if;   

   end process;
           
   ------------------------------------------------------------------------零件庫 
   u0:i2c_master        --SD178驅動 所使用IIC
   generic map 
   (
	  input_clk => 50_000_000,
	  bus_clk   => 10_000               --10_000
   )
   port map 
   (
	 clk       => fin,
	 reset_n   => nReset,
    
    ena       => sd178_ena, 
    addr      => sd178_addr,
    rw        => sd178_rw, 
    data_wr   => sd178_data_wr,
    busy      => sd178_busy,
    data_rd   => sd178_data_rd, 
    ack_error => sd178_ack_error,
  
    sda       => SD178_sda,
    scl       => SD178_scl
   );

   u1:TSL2561
   port map(
         clk_50M => fin,
         nrst    => nReset,    
         
         sda       => TSL2561_sda,
         scl       => TSL2561_scl,
         
         TSL2561_data => TSL2561_data

           );

   u2:DHT11
   port map(
         clk_50M => fin,
         nrst    => nReset,    
         dat_bus => SHT11_PIN,
         HU      => HU_BUFF,
         TE      => TE_BUFF,                 
         error   => DHT11_error 

           );
  
   u3:sync_segscan      --左邊七段顯示器掃描
   port map(
              clk    => clk_1KHz,
              ch_0   => D0_BUFFER,              
              ch_1   => D1_BUFFER,
              ch_2   => D2_BUFFER,              
              ch_3   => D3_BUFFER,
              dot    => seg1_dot,
              sync_segout => segout,
              sync_segsel => segsel
           );

   u4:sync_segscan      --右邊七段顯示器掃描
   port map(
              clk    => clk_1KHz,
              ch_0   => D0_BUFFER_2,              
              ch_1   => D1_BUFFER_2,
              ch_2   => D2_BUFFER_2,              
              ch_3   => D3_BUFFER_2,
              dot    => seg2_dot,
              sync_segout => segout_2,
              sync_segsel => segsel_2
           );

   u5:up_mdu2           --除頻電路 
   port map(      
                fin       => fin,       
	             fout      => clk_100hz
      
            );

   u6:up_mdu3           --除頻電路
   port map(      
                fin       => fin,       
	             fout      => clk_1KHz
      
            );

   u7:up_mdu4           --除頻電路 
   port map(      
                fin       => fin,       
	             fout      => clk_1MHz      
            );          

   u8:LCD_DRV           --LCD 驅動
   port map(      
                fin       => fin,       
                nReset    => nReset,        
                BL        => BL,
                RES       => RES,
                CS        => CS,
                DC        => DC,
                SDA       => SDA,
                SCL       => SCL,
                
                lcd_address => lcd_address,
                lcd_color   => lcd_color, 
                lcd_write => lcd_write, 
                lcd_show  => lcd_show,  
                lcd_busy  => lcd_busy  
         
            ); 
                 
end beh;
