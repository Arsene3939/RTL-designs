LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity SD178 is
port(    	      	                                      --鈭伐方   
        fin, nReset  :in std_logic;                     --恃岳149) & RESET145) 
        
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
end SD178;
architecture beh of SD178 is

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

type word_buffer is array(0 to 149)of std_logic_vector(7 downto 0);                                --SD178B 止筐貔芷
signal  word_buf:word_buffer:=(   x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                          x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"
                                       );

type State_type3 is (sd178_init, event_check, sd178_send , sd178_d1, sd178_d2, sd178_d3, sd178_d4, sd178_d5, sd178_delay1,sd178_delay2, sd178_set_ch,sd178_play1,sd178_play2);
SIGNAL  sd178State  : State_type3; 

--SD178B  
SIGNAL  sd178_ena, sd178_rw, sd178_busy, sd178_ack_error  : std_logic;   
SIGNAL  sd178_addr      : STD_LOGIC_VECTOR(6 DOWNTO 0);     
SIGNAL  sd178_data_wr, sd178_data_rd   : STD_LOGIC_VECTOR(7 DOWNTO 0);   
SIGNAL  cnt_byte   :integer range 0 to 150; 
SIGNAL  var_vol,var_vol_last  :integer range 0 to 9; 

--TSL2561
SIGNAL  TSL2561_int  :integer range 0 to 9999;            
SIGNAL  d0, d0_last  :integer range 0 to 9999;   
SIGNAL  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9;   	                                



--other
type arrr is array(0 to 1,0 to 1) of std_logic_vector(7 downto 0);
constant rf:arrr:=((X"B6",X"B6"),(X"B0",X"66"));
SIGNAL  d3            :integer range 0 to 20;
signal dbg :std_logic;
begin
   debug<=conv_std_logic_vector(d3,4);
process(fin)                        --sd178
   variable cnt_delay      :integer range 0 to 50000000;       
   variable cnt_loop       :integer range 0 to 150;       
   variable cnt3,cnt_next  :integer range 0 to 14;      
   variable cnt4,cnt4_set  :integer range 0 to 300;      
   variable flag_play   :STD_LOGIC;
   variable vol_loop       :integer range 0 to 150;
   begin  
      if(rising_edge(fin))then
         word_buf(0 to 97) <=(
            X"B4",X"BC",X"BC",X"7A",X"A9",X"7E",X"AE",X"61",X"B1",X"B1",X"B7",X"C5",X"A8",X"74",X"B2",X"CE",X"B1",X"D2",X"B0",X"CA",X"86",X"00",X"33",X"33",X"33",X"33",X"86",X"C0",
            X"AB",X"47",X"AB",X"D7",X"3"&TSL2561_data(15 downto 12),X"3"&TSL2561_data(11 downto 8),X"3"&TSL2561_data(7 downto 4),X"3"&TSL2561_data(3 downto 0),
            X"B0",X"C7",X"A7",X"4A",X"B4",X"B5",X"86",X"00",X"33",X"33",X"33",X"33",X"86",X"C0",
            X"A5",X"42",X"B7",X"C5",X"AB",X"D7",X"AC",X"B0",X"3"&TE_BUFF(7 downto 4),X"3"&TE_BUFF(3 downto 0),
            X"AB",X"D7",X"43",X"86",X"00",X"33",X"33",X"33",X"33",X"86",X"C0",
            X"C2",X"E0",X"B3",X"74",X"AC",X"B0",X"3"&motor_speed,rf(conv_integer(motor_dir),1),rf(conv_integer(motor_dir),0),
            X"AE",X"C9",X"C4",X"C1",X"B1",X"DB",X"C2",X"E0",X"86",X"00",X"33",X"33",X"33",X"33",X"33",X"33",X"86",X"C0"
          );
         if(nReset='0')then 
            SD178_nrst <= '1';
            sd178_ena  <= '0';
            sd178State <= sd178_init;
            flag_play  := '0';
            var_vol <= 8; 
            vol_loop := 0;
            dbg <= '0';
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
                     if mode_Sd178=3 then
                        if (key_pressed='1' and workingMode = "0000") then           --------------check ?  key_pressed='1' and workingMode = "0000"          	                            	           
                            if (flag_play = '0') then 
                                d3       <= 2;
                                
                                sd178State <= sd178_set_ch;                       --澈堊奕硃謍> 勗蹓> 鈭止
                                var_vol      <= 8;   
                                var_vol_last <= 8;
                                cnt3       := 0;
                            else
                                flag_play := '0';
                  	           cnt_byte <= 1;
                                word_buf(0) <=  x"80";                --謚怨翰        	                           	                               
                                vol_loop :=  0;
                                var_vol      <= 8;
                                var_vol_last <= 8;
                                sd178State <= sd178_send;
                            end if;

                         elsif (flag_play = '1') then                        --箄豯制
                            d3       <= cnt_next+3;                                --DEBUG
                            if cnt3 = 0 then                                 --"蝯"
                	             cnt_byte <= 99;                                --cnt3,對箄
               	             word_buf(0 to 97) <=(
                                 X"B4",X"BC",X"BC",X"7A",X"A9",X"7E",X"AE",X"61",X"B1",X"B1",X"B7",X"C5",X"A8",X"74",X"B2",X"CE",X"B1",X"D2",X"B0",X"CA",X"86",X"00",X"33",X"33",X"33",X"33",X"86",X"C0",
                                 X"AB",X"47",X"AB",X"D7",X"3"&TSL2561_data(15 downto 12),X"3"&TSL2561_data(11 downto 8),X"3"&TSL2561_data(7 downto 4),X"3"&TSL2561_data(3 downto 0),
                                 X"B0",X"C7",X"A7",X"4A",X"B4",X"B5",X"86",X"00",X"33",X"33",X"33",X"33",X"86",X"C0",
                                 X"A5",X"42",X"B7",X"C5",X"AB",X"D7",X"AC",X"B0",X"3"&TE_BUFF(7 downto 4),X"3"&TE_BUFF(3 downto 0),
                                 X"AB",X"D7",X"43",X"86",X"00",X"33",X"33",X"33",X"33",X"86",X"C0",
                                 X"C2",X"E0",X"B3",X"74",X"AC",X"B0",X"3"&motor_speed,rf(conv_integer(motor_dir),1),rf(conv_integer(motor_dir),0),
                                 X"AE",X"C9",X"C4",X"C1",X"B1",X"DB",X"C2",X"E0",X"86",X"00",X"33",X"33",X"33",X"33",X"33",X"33",X"86",X"C0"
                               );
                               sd178State <= sd178_send;
                               cnt3       := 12;                             --12 勗蹓皜
                               cnt4       := 0;                              --cnt4    ,勗蹓 
                               cnt4_set   := 8;                              --cnt4_set,勗蹓
                               cnt_next   := 0;
                               cnt_delay:= 0;

                            elsif cnt3 = 12 then                              --勗蹓皜
                               cnt_delay:=cnt_delay+1;
                               if cnt_delay = 50000000 then
                                  cnt_delay:= 0; 
                                  cnt4     := cnt4 + 1;
                               else
                                  if cnt4 = cnt4_set then                                                                  
                                     cnt3 := cnt_next;                                                                              
                                  end if;                                                
                               end if;
                                                                                                                                  
                            end if;       --cnt3    in flag_play=1                                                
                         end if;          -- workingMode=0000 ,  flag_play=1
                     end if;  			  --mode_sd178 = 1

               WHEN sd178_set_ch =>                   
                   	     cnt_byte <= 4;                           
                  	     word_buf(0 to 19) <= (  x"8B",x"07",x"86",x"C0",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                          	                               
                         sd178State <= sd178_send;
                         flag_play  := '1';
                         dbg <= not dbg ;
               WHEN sd178_send =>
                                                
                        cnt_loop := 0;
                        sd178State      <= sd178_d1;                                                                                                                               
                                                                       
               WHEN sd178_d1=>                                       --start write data
                        sd178_addr      <= "0100000";               --write sd178_address 0xx20
                        sd178_data_wr   <= word_buf(cnt_loop);	           --皝                        
                        sd178_rw        <= '0';                     --0/write  
                        sd178State      <= sd178_d2;
                        
                        cnt_loop := cnt_loop + 1;                   --笨蹓橫1 
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
                               cnt_loop := cnt_loop + 1;             --笨蹓橫1
                               sd178State    <= sd178_d4;
                           end if; 
                        end if;                         
               WHEN sd178_d4=>            
                        if sd178_busy = '0' then                             
                           sd178_ena    <= '0';                                                                                       
                           if cnt_loop >= cnt_byte  then                --cnt_byte 笨蹓澗
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
                  	    word_buf(0 to 19) <= (  x"BC",x"BD",x"A9",x"F1",x"C0",x"C9",x"AE",x"D7",x"88",x"27",x"0D",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                        	                           	                               

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
   
   u0:i2c_master        --SD178踝 輯撒IC
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
end beh ;