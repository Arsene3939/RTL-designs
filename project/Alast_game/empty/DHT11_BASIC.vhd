--��J1MHZ CLOCK (0.02us)
--��J1Hz CLOCK FOR key ,����1����s1��HU, TE


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;
entity DHT11_BASIC is 
port(
	   clk:in std_logic;
     rst:in std_logic;
     key:in std_logic;
     dat_bus: inout std_logic;
     HU, TE:out std_logic_vector(7 downto 0);        --�ë׾��, �ū׾��
     error: out std_logic
     
     );
end DHT11_BASIC;

architecture beh of DHT11_BASIC is 
signal main_count,count1,wait_count,ret_count,hold_count,keep_count:integer:=0;
signal k:integer:=0;
signal flag:integer:=0;
signal level:std_logic;
signal data_out,data_in:std_logic;
signal data_out_en:std_logic;
signal data_buffer:std_logic;
signal clks: std_logic;
signal clks_reg:std_logic;
signal dat_out_temp1,dat_out_temp2:std_logic_vector(39 downto 0);
type arr is array(0 to 15) of std_logic_vector(3 downto 0);
constant to_vector:arr:=(X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F");
begin 
data_in <= dat_bus;
dat_bus <= data_out when data_out_en = '1' else 'Z';
clks_reg<=not clks;

process(clk,rst)
    variable intTE,intHU:integer range 0 to 99:=20;
begin 
if rst='0'then
    data_out_en <= '1';
    data_out <= '1';
    count1<=0;
    clks<='1';
    k<=0;
    error <= '0';
    
elsif key='0'then
    main_count <= 0;
elsif clk'event and clk='1'then
    case main_count is 
        when 255=>
            error <= '1';
        when 1010=>                                --�P�_0 or 1         	
            if  data_in= '1' then
                flag <=1;
                if count1 < 60 then                --60us�@�@�@
                    count1<=count1+1;
                else
                    count1<=0;
                    level <= '1';                    
                end if;
            else
               if count1 < 30 and count1>10 then  -- < 30us and > 20us
                   count1<=0;
                   level<='0';                        --�P�_��0
                   main_count <= ret_count;
               elsif level='1' then                   --�P�_��1
                   count1<=0;
                   main_count <= ret_count;
               else
                   main_count <= 255;
               end if;

            end if;
            
        when 1000=>                                 --����
            if data_in=not level then
                main_count <= ret_count;
            else
                if count1 < hold_count + 5 then
                    count1<=count1+1;
                    main_count<=keep_count;
                else
                    count1 <= 0;
                    main_count <= 255;              --error
                end if;    
            end if;
        when 0=>
            data_out_en <= '1';
            data_out<='0'; 
            main_count <= 1;
        when 1=>
            main_count <= 2;
        when 2=>                             --start signal
            if count1 >= 30000 then          --30ms    
                count1<=0;
                main_count<=3;
            else
                count1<=count1+1;
            end if;
        when 3=>
            data_out_en <='0';              -- io���A = in
            if data_in='1'then
                main_count<=4;
            else
                main_count<=3;
            end if;
        when 4=>                            --WIAT 20us     
            if count1 < 20 then             
                count1<=count1+1;
                main_count<=4;
            else
                count1<=0;
                main_count<=5;
            end if;
        when 5=>                            --���ݦ^��
            if data_in='0'then
                main_count<=6;              --DHT��LOW >�@NEXT
            else
                main_count<=5;
            end if;
        when 6=>                            --�^���T��LOW��80us
            count1 <= 0;
            level <= '0';                   --80us  low level
            hold_count <= 80;
            keep_count<=6;
            main_count <= 1000;            
            ret_count <= 7;
        when 7=>                            --�^���T��HI,��80us,�ǳƿ�X
            count1 <= 0;
            level <= '1';                   
            hold_count <= 80;               --80us  high level�@�@�@�@�@�@
            keep_count<=7;
            main_count <= 1000;
            ret_count <= 8;            
        when 8=> 
              if data_in='1'then          
              	 main_count <= 9;
              end if;	
        when 9=>                          --data
        	        	   
        	  if data_in='1'then 
               count1 <= 0;
               flag <= 0;
               main_count <= 1010;
               ret_count <= 10;           
            end if; 
            	
        when 10=>
            data_buffer<=level;
            k<=k+1;                        -- k=Ū���ƶq
            main_count <= 11;
        when 11=>           
        	  clks<=not clks;                -- Ĳ�odat_out_temp1�x�sdata_buffer
            main_count <= 12;
        when 12=>        	  
            if k<40 then                   -- �@��Ū��40bits�@
                main_count<=8;
            else 
               k<=0;
               main_count <= 13;
            end if;
        when 13=>                          -- Ū����������                
                count1 <= 0;
                level <= '0';
                keep_count<=13;
                hold_count <= 50;        -- 50us
                ret_count <= 14;
                main_count <= 1000;
        when 14=>
                intHU:=CONV_INTEGER(dat_out_temp2(39 downto 32));
                intTE:=CONV_INTEGER(dat_out_temp2(23 downto 16));
        	    HU <= to_vector(intHU/10)&to_vector(intHU mod 10);
                TE <= to_vector(intTE/10)&to_vector(intTE mod 10);
        	    main_count <= 15;
        when 15=>
            data_out_en <= '1';            -- io���A = in
            
            data_out<='1';
        when others=>null;      
    end case;
end if;
end process;

process(clks,rst)            
begin
    if rst='0'then
    dat_out_temp1<=(others=>'0');
    elsif clks'event and clks='0'then            --�t�t
        dat_out_temp1(0)<=data_buffer;
        dat_out_temp1(39 downto 1)<=dat_out_temp2(38 downto 0);
    else
        dat_out_temp1<=dat_out_temp1;
    end if;
end process;

process(clks_reg,rst)
begin
    if rst='0'then
    dat_out_temp2<=(others=>'0');
    elsif clks_reg'event and clks_reg='0'then        --���t
        dat_out_temp2(0)<=data_buffer;
        dat_out_temp2(39 downto 1)<=dat_out_temp1(38 downto 0);
    else
        dat_out_temp2<=dat_out_temp2;
    end if;
end process;

end beh;