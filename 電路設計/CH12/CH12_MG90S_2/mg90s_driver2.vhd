--MG90S 測試
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP9

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ----------------------------------------------------
entity MG90S_Driver2 is
	port(MG90S_CLK,MG90S_RESET:in std_logic;		--MG90S_Driver驅動clk(25MHz),reset信號
		 MG90S_deg:in integer range 0 to 180;		--轉動角度
		 MG90S_o:out std_logic);					--Driver輸出
end entity MG90S_Driver2;

-- -----------------------------------------------------
architecture Albert of MG90S_Driver2 is
	signal MG90Servd:integer range 0 to 50010;	--角度換算值
	signal MG90Servs:integer range 0 to 63000;	--servo pwm比率值
	signal MG90Serv:integer range 0 to  500000;	--servo pwm產生器

-- --------------------------
begin

--角度換算值--0~180--------------------
MG90Servd<=2778*MG90S_deg/10;	--角度換算值0~50000
MG90Servs<=12500+MG90Servd;

--servo pwm產生器--------------------------------------------------
MG90S_o<='1' when MG90Serv<MG90Servs and MG90S_RESET='1' else '0';

--50Hz產生器
MG90S:process(MG90S_CLK,MG90S_RESET)
begin
	if MG90S_RESET='0' then
		MG90Serv<=0;
	elsif rising_edge(MG90S_CLK) then
		--20ms
		MG90Serv<=MG90Serv+1;
		if MG90Serv=499999 then	--50Hz
			MG90Serv<=0;
		end if;
	end if;
end process MG90S;

--------------------------------------------
end Albert;
