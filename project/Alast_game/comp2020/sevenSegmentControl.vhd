LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
--use ieee.numeric_std.all;

entity sevenSegmentControl is
port (  clk : in std_logic; --100hz
        nReset: in std_logic;
        mode_7seg: in integer range 0 to 15; 
        TSL2561_data: in std_logic_vector(19 DOWNTO 0);
        HU_BUFF, TE_BUFF : in STD_LOGIC_VECTOR(7 DOWNTO 0);
        dataBuffer: out std_logic_vector(15 DOWNTO 0)
       );
end sevenSegmentControl;

architecture behavioral of sevenSegmentControl is
SIGNAL D0_BUFFER,D1_BUFFER,D2_BUFFER,D3_BUFFER         : std_logic_vector(3 downto 0);
SIGNAL D0_BUFFER_2,D1_BUFFER_2,D2_BUFFER_2,D3_BUFFER_2 : std_logic_vector(3 downto 0);   
SIGNAL seg1_dot, seg2_dot                              : std_logic_vector(3 downto 0);     

SIGNAL  motor_speed   :integer range 0 to 10;
SIGNAL  motor_dir : STD_LOGIC;        
--TSL2561
SIGNAL  TSL2561_int  :integer range 0 to 9999;            
SIGNAL  d0, d0_last  :integer range 0 to 9999;   
--SIGNAL  lx1,lx2,lx3,lx4,lx5 :integer range 0 to 9;  

begin
   dataBuffer(15 downto 12)	<= D0_BUFFER ;
   dataBuffer(11 downto 8)	<= D1_BUFFER ;
   dataBuffer(7 downto 4)	<= D2_BUFFER ;
   dataBuffer(3 downto 0)	<= D3_BUFFER ;

   process(nReset,clk)           --�C�q��ܾ�
      variable cnt_step        :integer range 0 to 9;
   begin
      if(nReset='0')then 
         cnt_step  := 0;         
         D0_BUFFER   <= "0010";  D1_BUFFER   <= "1010"; D2_BUFFER   <= "1010"; D3_BUFFER   <= "1010";
         D0_BUFFER_2 <= "1010";  D1_BUFFER_2 <= "1010"; D2_BUFFER_2 <= "1010"; D3_BUFFER_2 <= "1010"; 

         seg1_dot <= "0000";           
         seg2_dot <= "0000";         
         motor_speed <= 0;
         
      ELSIF(rising_edge(clk))then
         if cnt_step = 0 then                                  --�ഫTSL2561��� & ���F��t
            TSL2561_int  <= CONV_INTEGER(TSL2561_data) mod 10000;
                              
            if(CONV_INTEGER(TE_BUFF) <= 22) then               --�ūפp�󵥩�22,���F��t0 
               motor_speed <= 0;   
            elsif(CONV_INTEGER(TE_BUFF) >= 32) then            --�ūפj�󵥩�32,���F��t10 
               motor_speed <= 10;                  
            else
               motor_speed <= CONV_INTEGER(TE_BUFF) - 22;      --�ū״���1�סA��t�|�ܧ�+1                
            end if;                  
            cnt_step := 1;
            
         ELSIF cnt_step = 1 then    
            
            cnt_step := 2;
            
         ELSIF cnt_step = 2 then                            --�P�_��ܤ��� 
            
            if(mode_7seg = 0) then                          --����,�����
               D0_BUFFER   <= "1010";  D1_BUFFER   <= "1010"; D2_BUFFER   <= "1010"; D3_BUFFER   <= "1010";
               D0_BUFFER_2 <= "1010";  D1_BUFFER_2 <= "1010"; D2_BUFFER_2 <= "1010"; D3_BUFFER_2 <= "1010"; 
               seg1_dot <= "0000";           
               seg2_dot <= "0000";  

            ELSIF mode_7seg = 1 then                        --IDLE �����s�e��
			   --D0_BUFFER   <= segCounter(3 downto 0);--conv_std_logic_vector((CONV_INTEGER(TE_BUFF)/10),4);       --�ū�
               --D1_BUFFER   <= segCounter(7 downto 4);--conv_std_logic_vector((CONV_INTEGER(TE_BUFF) mod 10),4);     
			   D3_BUFFER   <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF)/10),4);       --�ū�
               D2_BUFFER   <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF) mod 10),4);    
               D1_BUFFER   <= "1011";        --�� 
               D0_BUFFER   <= "1100";       --C 
               
            ELSIF mode_7seg = 2 then                        --��ܷū�               
               D3_BUFFER   <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF)/10),4);       --�ū�
               D2_BUFFER   <= conv_std_logic_vector((CONV_INTEGER(TE_BUFF) mod 10),4);                                            
               D1_BUFFER   <= "1011";       --�� 
               D0_BUFFER   <= "1100";       --C 
               
               D0_BUFFER_2 <= conv_std_logic_vector((motor_speed/10),4);                 --���F�t��
               D1_BUFFER_2 <= conv_std_logic_vector((motor_speed mod 10),4);     
               D2_BUFFER_2 <= "1101";	     --SP  
               D3_BUFFER_2 <= "1110";       --SP         
               seg1_dot <= "0000";           
               seg2_dot <= "0011";  

            ELSIF mode_7seg = 3 then                        --��ܥ��j�׭�               
               --D0_BUFFER <= conv_std_logic_vector(lx1,4);   --�̥���줸
               --D1_BUFFER <= conv_std_logic_vector(lx2,4);	
               --D2_BUFFER <= conv_std_logic_vector(lx3,4);	
               --D3_BUFFER <= conv_std_logic_vector(lx4,4); 
				
					
               --D3_BUFFER <= TSL2561_data(19 downto 16);                 			   
			   D3_BUFFER <= TSL2561_data(15 downto 12);   --�̥���줸
               D2_BUFFER <= TSL2561_data(11 downto 8);	
               D1_BUFFER <= TSL2561_data(7 downto 4);	
               D0_BUFFER <= TSL2561_data(3 downto 0);  
			   
               D0_BUFFER_2 <= TSL2561_data(3 downto 0);
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
       
   	  
  
end behavioral;
