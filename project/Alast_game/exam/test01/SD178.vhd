LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity SD178 is
port(    	      	                                      --鈭伐方   
        fin, nReset  :in std_logic;                     --恃岳149) & RESET145) 
        
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

        dipsw1    : in std_logic_vector(1 downto 0)  ;  --DIP SW()        
        debug  : out    std_logic_vector(7 downto 0);

        ch:       in integer range 0 to 3;
        vol:      in integer range 0 to 10
    );
end SD178;
architecture beh of SD178 is

component i2c_master is
  GENERIC(
    input_clk : integer := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : integer := 100_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : in     std_logic;                    --system clock
    reset_n   : in     std_logic;                    --active low reset
    ena       : in     std_logic;                    --latch in command
    addr      : in     std_logic_vector(6 downto 0); --address of target slave
    rw        : in     std_logic;                    --'0' is write, '1' is read
    data_wr   : in     std_logic_vector(7 downto 0); --data to write to slave
    busy      : out    std_logic;                    --indicates transaction in progress
    data_rd   : out    std_logic_vector(7 downto 0); --data read from slave
    ack_error : buffer std_logic;                    --flag if improper acknowledge from slave
    sda       : inout  std_logic;                    --serial data output of i2c bus
    scl       : inout  std_logic);                   --serial clock output of i2c bus
end component i2c_master; 

type word_buffer is array(0 to 149)of std_logic_vector(7 downto 0);                                --SD178B 止筐貔芷
signal  data:word_buffer:=(               x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
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
type word_buffer2 is array(0 to 29)of std_logic_vector(7 downto 0);                                --SD178B 止筐貔芷
signal  word_buf:word_buffer2:=  (          
                                    x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                    x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                    x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"
                                 );

type State_type3 is (sd178_init, event_check, sd178_send , sd178_d1, sd178_d2, sd178_d3, sd178_d4, sd178_d5, sd178_delay1,sd178_delay2, sd178_set_ch,sd178_play1,sd178_play2);
signal  sd178State  : State_type3; 

--SD178B  
signal  sd178_ena, sd178_rw, sd178_busy, sd178_ack_error  : std_logic;   
signal  sd178_addr      : std_logic_vector(6 downto 0);     
signal  sd178_data_wr, sd178_data_rd   : std_logic_vector(7 downto 0);   
signal  cnt_byte   :integer range 0 to 150; 
signal  var_vol,var_vol_last  :integer range 0 to 9;

--TSL2561          
signal  d0, d0_last  :integer range 0 to 9999;   
signal  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9;   	                                



--other
signal FD:std_logic_vector(50 downto 0);   
signal  d3            :integer range 0 to 20;
signal dbg :std_logic;
--Serial
type    arr1 is array(0 to 19) of std_logic_vector(7 downto 0);--

begin
   fre:process(fin)
   begin
      if rising_edge(fin)then
         FD<=FD+1;
      end if;
   end process;
process(fin)                        --sd178
   variable cnt_delay      :integer range 0 to 50000000;
   variable cnt_loop       :integer range 0 to 150;
   variable cntnumber      :integer range 0 to 150:=0;
   variable cntnumber_max  :integer range 0 to 150:=0;
   variable cnt3,cnt_next  :integer range 0 to 14;      
   variable cnt4,cnt4_set  :integer range 0 to 300;      
   variable flag_play      :std_logic;
   variable vol_loop       :integer range 0 to 150;
   begin  
      if rising_edge(fin)then
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
                     if dipsw1 = "11" then
                        if (key_pressed='1' and workingMode = X"3") then           --------------check ?  key_pressed='1' and workingMode = "0000"          	                            	           
                            if (flag_play = '0') then 
                                d3       <= 2;
                                sd178State <= sd178_set_ch;
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

                         elsif (flag_play = '1') then
                            d3       <= cnt_next+3;
                            if cnt3 = 0 then
                              cntnumber_max:=62;
                               data(0 to 61) <=(
                                 X"A8",X"74",X"B2",X"CE",X"B6",X"7D",X"A9",X"6C",X"BC",X"BD",X"B3",X"F8",X"F2",
                                 X"A5",X"AA",X"A5",X"6B",X"A9",X"CE",X"C2",X"F9",X"C1",X"6E",X"B9",X"44",X"BC",X"B7",X"A9",X"F1",X"A4",X"A4",X"F2",
                                 X"B7",X"50",X"B4",X"FA",X"BE",X"B9",X"BC",X"C6",X"AD",X"C8",X"A9",X"B0",X"A8",X"AF",X"A4",X"A4",X"F2",
                                 X"B5",X"B2",X"A7",X"F4",X"A5",X"BB",X"A6",X"B8",X"BC",X"BD",X"B3",X"F8",X"F4"
                               );
                               cnt3       := 1;                             --12 勗蹓皜
                            elsif cnt3=1 then
                              if data(cntnumber)(7 downto 4)=X"F" then
                                 cnt3:=12;
                                 cnt4_set:=conv_integer(data(cntnumber)(3 downto 0));
                                 cnt4       := 0;
                                 cnt_next   := 0;
                                 cnt_delay:= 0;
                                 cntnumber:=cntnumber+1;
                              else
                                 if data(cntnumber)(7 downto 4)<=X"7" and data(cntnumber)(7 downto 4)>=X"3" and data(cntnumber)/=X"40" then
                                    cnt_byte<=1;
                                    word_buf(0)<=data(cntnumber);
                                    debug<=not word_buf(0);
                                    sd178State <= sd178_send;
                                    cntnumber:=cntnumber+1;
                                 else
                                    cnt_byte<=2;
                                    word_buf(0 to 1)<=(data(cntnumber),data(cntnumber+1));
                                    sd178State <= sd178_send;
                                    cntnumber:=cntnumber+2;
                                 end if;
                              end if;
                              if cntnumber>cntnumber_max then
                                 cntnumber:=0;
                              end if;
                              debug<=not conv_std_logic_vector(cntnumber,8);
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
                         end if;          -- workingMode=0000 ,  flag_play=
                     end if;  			  --mode_sd178 = 1

               when sd178_set_ch =>                   
                   	     cnt_byte <= 4;                           
                  	     word_buf(0 to 19) <= (  x"8B",x"07",x"86",x"D0",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                          	                               
                         sd178State <= sd178_send;
                         flag_play  := '1';
                         dbg <= not dbg ;
               when sd178_send =>

                        cnt_loop := 0;
                        sd178State      <= sd178_d1;                                                                                                                               

               when sd178_d1=>                                       --start write data

                        sd178_addr      <= "0100000";               --write sd178_address 0xx20
                        sd178_data_wr   <= word_buf(cnt_loop);	           --皝
                        sd178_rw        <= '0';                     --0/write
                        sd178State      <= sd178_d2;

                        cnt_loop := cnt_loop + 1;                   --笨蹓橫1 
               when sd178_d2=>
                        sd178_ena   <= '1';
                        sd178State  <= sd178_d3;
               when sd178_d3=>
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
               when sd178_d4=>            
                        if sd178_busy = '0' then                             
                           sd178_ena    <= '0';                                                                                       
                           if cnt_loop >= cnt_byte  then                --cnt_byte 笨蹓澗
                              sd178State   <= sd178_d5;
                           else                           
                              sd178State   <= sd178_delay1;
                           end if;          
                           cnt_delay := 0;
                        end if; 
                           
               when sd178_delay1=>                                  --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 4000000 then                 --80ms
                           cnt_delay:=0; 
                           sd178State <= sd178_d1;
                        end if; 
                                                      
               when sd178_d5=>                                      --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 5000000 then                 --100ms
                           cnt_delay:=0; 
                           sd178State <= event_check;
                        end if; 

               when sd178_play1=>                                  --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 5000000 then                --100ms
                           cnt_delay:=0; 
                           sd178State <= sd178_play2;                         
                        end if; 

               when sd178_play2=>                                  --delay                    	                           	                               
                   	    cnt_byte <= 11;                           
                  	    word_buf(0 to 19) <= (  x"BC",x"BD",x"A9",x"F1",x"C0",x"C9",x"AE",x"D7",x"88",x"27",x"0D",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");                        	                           	                               

                        sd178State <= sd178_send;    

               when sd178_delay2=>                                  --delay
                        cnt_delay:=cnt_delay+1;                                                             
                        if cnt_delay = 5000000 then                 --100ms
                           cnt_delay:=0; 
                           sd178State <= event_check;
                        end if;
               
              when others =>                                          
                        sd178State     <= sd178_init;
                          
            end case;
                           
    
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