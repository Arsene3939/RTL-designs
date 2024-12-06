--�C�q��ܾ� ,���y�u�����P��Ƥ���

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY fourDigits_SevenSegmentDisplay IS
PORT(
     clk:in std_logic;
	 dataBuffer:in std_logic_vector(15 downto 0);     
--     dot :in std_logic;                   			         --��0�줸DOT      
     dot :in std_logic_vector(3 downto 0);  			         --DOT      
     segData:out std_logic_vector(7 downto 0);          --�C�q��ܾ���ƽu    
     segPosition:out std_logic_vector(3 downto 0)               --�C�q��ܾ����y�u
    );
END fourDigits_SevenSegmentDisplay;

ARCHITECTURE beh OF fourDigits_SevenSegmentDisplay IS

  type state is (s0,s1,s2,s3);
  signal scanstate:state;    
  signal sel:std_logic_vector(3 downto 0);    
  signal ch_out:std_logic_vector(3 downto 0);    
  signal to_seg:std_logic_vector(6 downto 0);    
  signal ch_0: std_logic_vector(3 downto 0);                  --��0�줸��ܸ��
  signal ch_1: std_logic_vector(3 downto 0);                  --��1�줸��ܸ��
  signal ch_2: std_logic_vector(3 downto 0);                  --��2�줸��ܸ��
  signal ch_3: std_logic_vector(3 downto 0);                  --��3�줸��ܸ��

begin
	ch_0 <= dataBuffer(15 downto 12)	;
	ch_1 <= dataBuffer(11 downto 8)	;
	ch_2 <= dataBuffer(7 downto 4)	;
	ch_3 <= dataBuffer(3 downto 0)	;
 sync_out:process
 begin
    wait until clk='1';                            --���d�ұN��J500HZ clock ,����2ms�����@�����y�u
    case scanstate is 
       when s0 =>scanstate<=s1; segData(7)<= dot(0);   --DOT 
       when s1 =>scanstate<=s2; segData(7)<= dot(1);   --DOT
       when s2 =>scanstate<=s3; segData(7)<= dot(2);   --DOT
       when s3 =>scanstate<=s0; segData(7)<= dot(3);   --DOT
    end case;
    segPosition<=sel;                              --���y�u��X
    segData(6 downto 0)<= not to_seg;               --��ƽu��X
    	    	
 end process sync_out;

 mux_decode:process(scanstate) 
 begin
  case scanstate is                                --���A�P���y�u��M
--     when s0 =>ch_out<=ch_0;sel<="1000";           --�@��
--     when s1 =>ch_out<=ch_1;sel<="0100";
--     when s2 =>ch_out<=ch_2;sel<="0010";
--     when s3 =>ch_out<=ch_3;sel<="0001";
--     when others  =>        sel<="0000";    		
     when s0 =>ch_out<=ch_0;sel<="1110";           --�@��
     when s1 =>ch_out<=ch_1;sel<="1101";
     when s2 =>ch_out<=ch_2;sel<="1011";
     when s3 =>ch_out<=ch_3;sel<="0111";
     when others  =>        sel<="1111";    		

  end case;
 end process mux_decode;

 bcd_to_7seg:block
 begin
 WITH ch_out SELECT                                --�Ʀr�P�C�q��ܾ�����ഫ 

 to_seg <=    
          "0111111" when "0000" ,    -- 0--�@��
          "0000110" when "0001" ,    -- 1
          "1011011" when "0010" ,    -- 2
          "1001111" when "0011" ,    -- 3          
          "1100110" when "0100" ,    -- 4 
          "1101101" when "0101" ,    -- 5
          "1111100" when "0110" ,    -- 6
          "0000111" when "0111" ,    -- 7
          "1111111" when "1000" ,    -- 8
          "1101111" when "1001" ,    -- 9
          "0000000" when "1010" ,    -- " "   
          "1100011" when "1011" ,    -- "��"   
          "0111001" when "1100" ,    -- "C"   
          "1101101" when "1101" ,    -- "S"   
          "1110011" when "1110" ,    -- "P"               

          "-------" when others; 
 end block bcd_to_7seg;


end beh;

