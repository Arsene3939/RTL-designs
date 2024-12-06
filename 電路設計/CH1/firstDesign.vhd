------ myFirst.vhd ------
-- �ŧi��Ʈw
Library IEEE;
Use IEEE.std_logic_1164.all;
Use IEEE.std_logic_unsigned.all;
-- �w�q���}  
entity firstDesign is
  port(	rstP99,gckP31:in std_logic;	-- �t�έ��m�B�t�ήɯ�
		LED:buffer std_logic_vector(15 downto 0); -- LED
  		-- 87,93,95,94,100,101,102,103 
		-- 106,107,108,110,111,112,113,114
  		SW:in std_logic);				-- �����}��(56)
end entity firstDesign;
-- �y�z�q��    
architecture Albert of firstDesign is
  signal FD:std_logic_vector(25 downto 0);
  
begin   	

Freq_Div:process(rstP99,gckP31) 	-- ���W��
begin
  if rstP99= '0' then
	FD<=(others=>'0'); 				-- ���W���k�s
  elsif rising_edge(gckp31) then	-- ��t�ίߪi�ɽt��
  	FD<=FD+1; 						-- �p�ƾ��[1
  end if;
end process Freq_Div;

scanLED:process(rstP99,FD(20))		-- FD(20)��24Hz
begin
  if rstP99='0' then
	LED<="0111111111111111";		-- ����LED(���A�ʧ@)
  elsif rising_edge(FD(20)) then
	if SW='1' then
  		LED <=LED(0) & LED(15 downto 1); -- �k��
	else 
  		LED <=LED(14 downto 0) & LED(15); -- ����
	end if;
  end if;
end process scanLED;

end Albert;
