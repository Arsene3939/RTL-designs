------ myFirst.vhd ------
-- 宣告函數庫
Library IEEE;
Use IEEE.std_logic_1164.all;
Use IEEE.std_logic_unsigned.all;
-- 定義接腳  
entity firstDesign is
  port(	rstP99,gckP31:in std_logic;	-- 系統重置、系統時脈
		LED:buffer std_logic_vector(15 downto 0); -- LED
  		-- 87,93,95,94,100,101,102,103 
		-- 106,107,108,110,111,112,113,114
  		SW:in std_logic);				-- 指撥開關(56)
end entity firstDesign;
-- 描述電路    
architecture Albert of firstDesign is
  signal FD:std_logic_vector(25 downto 0);
  
begin   	

Freq_Div:process(rstP99,gckP31) 	-- 除頻器
begin
  if rstP99= '0' then
	FD<=(others=>'0'); 				-- 除頻器歸零
  elsif rising_edge(gckp31) then	-- 當系統脈波升緣時
  	FD<=FD+1; 						-- 計數器加1
  end if;
end process Freq_Div;

scanLED:process(rstP99,FD(20))		-- FD(20)約24Hz
begin
  if rstP99='0' then
	LED<="0111111111111111";		-- 關閉LED(高態動作)
  elsif rising_edge(FD(20)) then
	if SW='1' then
  		LED <=LED(0) & LED(15 downto 1); -- 右移
	else 
  		LED <=LED(14 downto 0) & LED(15); -- 左移
	end if;
  end if;
end process scanLED;

end Albert;
