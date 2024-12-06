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

type word_buffer is array(0 to 99)of std_logic_vector(7 downto 0);                                --SD178B 止筐貔芷
signal  word_buf:word_buffer:=(   x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
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
SIGNAL  cnt_byte   :integer range 0 to 99; 
SIGNAL  var_vol,var_vol_last  :integer range 0 to 9; 

--TSL2561
SIGNAL  TSL2561_int  :integer range 0 to 9999;            
SIGNAL  d0, d0_last  :integer range 0 to 9999;   
SIGNAL  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9;   	                                



--other
SIGNAL  d3            :integer range 0 to 20;
signal dbg :std_logic;
--Serial
type    arr1 is array(0 to 19) of std_logic_vector(7 downto 0);--
signal  Serial_available:word_buffer:=(   x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
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

begin
   debug<=conv_std_logic_vector(d3,4);

   Serial:process(uart_pers)             --Serial controll
      variable Serial_count:integer range 0 to 99:=0;
		variable Serial_max:integer range 0 to 99:=99;
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

process(fin)                        --sd178
   variable cnt_delay      :integer range 0 to 50000000;       
   variable cnt_loop       :integer range 0 to 99;       
   variable cnt3,cnt_next  :integer range 0 to 14;      
   variable cnt4,cnt4_set  :integer range 0 to 300;
   variable flag_play   :STD_LOGIC;
   variable vol_loop       :integer range 0 to 100;
   begin  
      if(rising_edge(fin))then
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
                     if (dipsw1 = "0001")then
                	     if (key_pressed='1' and workingMode = "0100") then           --------------check ?  key_pressed='1' and workingMode = "0000"          	                            	           
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
                	             cnt_byte <= 8;                                --cnt3,對箄
               	             word_buf(0 to 19)<= (x"A8",x"74",x"B2",x"CE",x"B6",x"7D",x"BE",x"F7",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3       := 12;                             --12 勗蹓皜
                               cnt4       := 0;                              --cnt4    ,勗蹓 
                               cnt4_set   := 5;                              --cnt4_set,勗蹓
                               cnt_next   := 1;                              
                               cnt_delay:= 0;
                            
                            elsif cnt3 = 1 then                              --□-豲典
                               cnt3       := 2;                          
                               
                            elsif cnt3 = 2 then                              --"撞??典" 
                	           cnt_byte <= 8;                                --cnt3,對箄
               	            word_buf(0 to 19) <= (x"B7",x"C5",x"AB",x"D7",conv_std_logic_vector(CONV_INTEGER(TE_BUFF(7 downto 4)),8) or x"30",conv_std_logic_vector(CONV_INTEGER(TE_BUFF(3 downto 0)),8) or x"30",x"AB",x"D7",x"43",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
                               sd178State <= sd178_send;
                               cnt3       := 12;                             --12 勗蹓皜
                               cnt4       := 0;                              --cnt4    ,勗蹓 
                               cnt4_set   := 5;                              --cnt4_set,勗蹓
                               cnt_next   := 3;                              
                               cnt_delay:= 0;                                                                     

                            elsif cnt3 = 3 then                              --□-豲典
                                cnt3       := 4;      
								lx1 <= CONV_INTEGER(TSL2561_data(19 downto 16));                               
								lx2 <= CONV_INTEGER(TSL2561_data(15 downto 12));                   
								lx3 <= CONV_INTEGER(TSL2561_data(11 downto 8));
								lx4 <= CONV_INTEGER(TSL2561_data(7 downto 4));
								lx5 <= CONV_INTEGER(TSL2561_data(3 downto 0));                                                                                                                          
                                                                    
                            elsif cnt3 = 4 then                              --"剜瞍???     
                	           cnt_byte <= 19;                       	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12; 
                               cnt4     := 0;
                               cnt4_set := 7;
                               cnt_next   := 5;                                   
                               cnt_delay:= 0;                                    

                            elsif cnt3 = 5 then                              --鈭止澗                              
                   	           cnt_byte <= 11;                           
                  	           word_buf(0 to 19) <= (  x"BC",x"BD",x"A9",x"F1",x"C0",x"C9",x"AE",x"D7",x"88",x"27",x"0D",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12; 
                               cnt4     := 0;
                               cnt4_set := 300;                               --10
                               cnt_next := 6;
                               cnt_delay:= 0;
                               
                            elsif cnt3 = 6 then                              --謒LOOP
               	               cnt_byte <= 4;                           
              	               word_buf(0) <=  x"80";                      	                           	                               
              	               word_buf(1) <=  x"80";                      	                           	                               
              	               word_buf(2) <=  x"80";                      	                           	                               
              	               word_buf(3) <=  x"80";                      	                           	                                     
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 3;
                               cnt_next := 1;
                               cnt_delay:= 0;                                                         	                           	                               
                               
                            elsif cnt3 = 7 then                              --謒LOOP                               
               	               cnt_byte <= 1;                           
              	               word_buf(0) <=  x"80";                      	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 1;
                               cnt_next := 6;                                   
                               cnt_delay:= 0;
                            
                            elsif cnt3 = 8 then                              --謒
               	               cnt_byte <= 1;                           
              	               word_buf(0) <=  x"80";
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;                                   
                               cnt4     := 0;
                               cnt4_set := 1;
                               cnt_next := 8;                                   
                               cnt_delay:= 0;
                               
                            elsif cnt3 = 9 then                                --方葭桀脤航
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

                            
                            elsif cnt3 = 10 then                               --皝OLED
                               cnt3     := 13;                                   
                               cnt_next := 11;                                   
                               cnt_delay:= 0;
                                                                   
                            elsif cnt3 = 11 then                               --"剜瞍zz  
                	           cnt_byte <= 19;                           
               	               word_buf(0 to 19) <= (  x"AB",x"47",x"AB",x"D7",x"31",x"32",x"33",x"34",x"B0",x"C7",x"A7",x"4A",x"A5",x"71",x"87",x"00",x"00",x"0B",x"B8",x"00");
                               sd178State <= sd178_send;                                  
                               cnt3     := 12; 
                               cnt4     := 0;
                               cnt4_set := 7;
                               cnt_next := 14;
                               cnt_delay:= 0; 

                            elsif cnt3 = 14 then                              --"蝯胼"
                	           cnt_byte <= 16;                           
               	               word_buf(0 to 19) <= (x"A8",x"74",x"B2",x"CE",x"B6",x"69",x"A4",x"4A",x"BA",x"CE",x"AF",x"76",x"BC",x"D2",x"A6",x"A1",x"00",x"00",x"00",x"00");                        	                           	                               
                               sd178State <= sd178_send;                                  
                               cnt3     := 12;
                               cnt4     := 0;
                               cnt4_set := 7;
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
                     elsif dipsw1 = "0010" then
                        if (key_pressed='1' and workingMode = "0100") then           --------------check ?  key_pressed='1' and workingMode = "0000"          	                            	           
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
                	             cnt_byte <= CONV_INTEGER(Serial_available(0));                                --cnt3,對箄
               	             word_buf(0 to 98) <= Serial_available(1 to 99);
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
                  	     word_buf(0 to 19) <= (  x"8B",x"07",x"86",x"D6",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                          	                               
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