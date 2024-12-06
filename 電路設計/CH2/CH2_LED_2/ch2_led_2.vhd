--LED霹靂燈2:強生計數器演算法
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckP31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- -----------------------------------------------------
entity CH2_LED_2 is
port(gckP31,rstP99:in std_logic;	-- 系統時脈、系統重置
	 LEDs:buffer std_logic_vector(15 downto 0) 	--LED
	 -- 87,93,95,94,100,101,102,103 
	 -- 106,107,108,110,111,112,113,114
	);
end entity CH2_LED_2;

-- -----------------------------------------------------
architecture Albert of CH2_LED_2 is
	signal FD:std_logic_vector(24 downto 0);--除頻器
	
-- --------------------------
begin

--LED_P 主控器----------------------------------------------
LED_P:process (FD(16))
variable N:integer range 0 to 127;			--執行次數
variable LED_point:integer range 0 to 15;	--LED_指標
variable dir_LR,set10,incDec:std_logic;	--方向,全設,LED_指標_遞增遞減
begin
	if rstP99='0' then			--系統重置
		N:=64;					--次數由64開始
		LED_point:=0;			--LED_指標由0開始
		dir_LR:='0';			--方向:向右
		set10:='0';				--全設0
		incDec:='1';			--遞增
		LEDs<=(others=>'0'); 	--LED全亮
	elsif rising_edge(FD(21)) then			--約12Hz
		if N=0 then	--次數已結束
			if LEDs/=(LEDs'range=>set10) then	--恢復原狀
				if dir_LR='0' then	--方向:向右
					LEDs<=set10 & LEDs(15 downto 1);--方向:向右
				else				--方向:向左
					LEDs<=LEDs(14 downto 0) & set10;--方向:向左
				end if;
			else	--重設參數
				N:=64;						--次數由64開始
				if LED_point=0 and incDec='0' then
					dir_LR:=not dir_LR;		--方向:向左
					incDec:='1';			--指標遞增
					set10:=set10 xor dir_LR;--全設:0<-->1
				elsif  LED_point=15 and incDec='1' then
					incDec:='0';			--指標遞減
				elsif incDec='1' then	--遞增
					LED_point:=LED_point+1;	--LED_指標遞增
				else					--遞減
					LED_point:=LED_point-1;	--LED_指標遞減
				end if;
				LEDs<=(others=>set10); --LED全亮
			end if;
		else		--次數未結束
			if dir_LR='0' then	--方向:向右
				LEDs<=not LEDs(LED_point) & LEDs(15 downto 1);--方向:向右
			else				--方向:向左
				LEDs<=LEDs(14 downto 0) & not LEDs(LED_point);--方向:向左
			end if;
			N:=N-1;	--次數-1
		end if;
	end if;
end process LED_P;
	
-- 除頻器----------------------------------------
Freq_Div:process(gckP31)			--系統頻率gckP31:50MHz
begin
	if rstP99='0' then				--系統重置
		FD<=(others=>'0');			--除頻器:歸零
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--除頻器:2進制上數(+1)計數器
	end if;
end process Freq_Div;

end Albert;
