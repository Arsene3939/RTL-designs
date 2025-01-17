--4位數掃瞄式共陽極七段顯示器
--倒時計時器59分59秒
--106.12.30版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ---------------------------------------
entity CH5_7SLED_2 is	
	port(gckP31,rstP99:in std_logic;--系統頻率,系統reset(歸零)
		 S1,S2,S8:in std_logic;
		 --分(131),秒(128)遞增按鈕,設定/暫停/倒時(117)按鈕
		 --4位數掃描式顯示器
		 SCANo:buffer std_logic_vector(3 downto 0);	--掃瞄器輸出
		 Disp7S:buffer std_logic_vector(7 downto 0);--計數位數解碼輸出
		 Dd:buffer std_logic						--狀態顯示
		 );
end entity CH5_7SLED_2;

-- -----------------------------------------
architecture Albert of CH5_7SLED_2 is
	signal FD:std_logic_vector(26 downto 0);	--系統除頻器
	signal Scounter:integer range 0 to 390625;	--半秒計時器
	type Disp7DataT is array(0 to 3) of integer range 0 to 9;--顯示區格式
	signal Disp7Data:Disp7DataT;				--顯示區
	signal scanP:integer range 0 to 3;			--掃瞄器指標
	signal S2S,S1S,S8S:std_logic_vector(2 downto 0);--防彈跳計數器
	signal M,S:integer range 0 to 59;			--分,秒
	signal Ss,M_S_P_clk:std_logic;				--1秒,M_S_P時脈操作
	signal MSs:std_logic_vector(1 downto 0);	--設定on/off
begin

Disp7Data(3)<=M/10;			--分十位
Disp7Data(2)<=M mod 10;		--分個位
Disp7Data(1)<=S/10;			--秒十位
Disp7Data(0)<=S mod 10;		--秒個位
Dd<='0' when MSs>0 else Ss;	--MSs=0暫停,恆亮；MSs=1倒數,閃秒

--倒數計時器--------------------
M_S_P_clk<=FD(23) when MSs>0 else Ss;	--M_S_P 時脈選擇
M_S_P:process(M_S_P_clk)
begin
	if rstP99='0' then	--系統重置,歸零
		M<=0;			--分歸零
		S<=0;			--秒歸零
		MSs<="00";		--狀態切換控制
	elsif rising_edge(M_S_P_clk) then
		if S8S(2)='1' then			--狀態進行切換
			if MSs=0 or MSs=2 then	--計時轉設定 or 設定轉計時
				MSs<=MSs+1;			--切換
			end if;
		else						--狀態轉換
			if MSs=1 or MSs=3 then	--計時轉設定 or 設定轉計時
				MSs<=MSs+1;			--轉換:轉可執行穩定狀態
			end if;
		end if;
		if MSs>0 then	--狀態中
			if MSs=2 then	--可設定	
				if S1S(2)='1' then	--調整分
					if M=59 then
						M<=0;
					else
						M<=M+1;
					end if;
				end if;
				if S2S(2)='1' then	--調整秒
					if S=59 then
						S<=0;
					else
						S<=S+1;
					end if;
				end if;
			end if;
		elsif M/=0 or S/=0 then	--時未到
			if S/=0 then		--倒時計時
				S<=S-1;
			else
				S<=59;
				M<=M-1;
			end if;
		end if;				
	end if;
end process M_S_P;

-- --------------------------
--秒信號產生器
S_G_P:process(FD(5))
begin
	if rstP99='0' or MSs>0 then	--系統重置 or 重新計時
		Ss<='1';
		Scounter<=390625;		--半秒計時器預設
	elsif rising_edge(FD(5)) then--781250Hz
		Scounter<=Scounter-1;	--半秒計時器遞減
		if Scounter=1 then		--半秒到
			Scounter<=390625;	--半秒計時器重設
			Ss<=not Ss;			--1秒狀態
		end if;
	end if;
end process S_G_P;

--4位數掃瞄器---------------------------------------------------
scan_P:process(FD(17),rstP99)
begin
	if rstP99='0' then
		scanP<=0;		--位數取值指標
		SCANo<="1111";	--掃瞄信號 all off
	elsif rising_edge(FD(17)) then
		scanP<=scanP+1;	--位數取值指標遞增
		SCANo<=SCANo(2 downto 0)&SCANo(3);
		if scanP=3 then		--最後一位數了
			scanP<=0;		----位數取值指標重設
			SCANo<="1110";	--掃瞄信號重設
		end if;
	end if;
end process scan_P;

--BCD碼解共陽極七段顯示碼pgfedcba
with Disp7Data(scanP) select --取出顯示值
	Disp7S<=
	"11000000" when 0,
	"11111001" when 1,
	"10100100" when 2,
	"10110000" when 3,
	"10011001" when 4,
	"10010010" when 5,
	"10000010" when 6,
	"11111000" when 7,
	"10000000" when 8,
	"10010000" when 9,
	"11111111" when others;	--不顯示

----防彈跳----------------------------------
debouncer:process(FD(15))
begin
	--S8防彈跳
	if S8='1' then
		S8S<="000";
	elsif rising_edge(FD(17)) then
		S8S<=S8S+ not S8S(2);
	end if;
	--S1防彈跳
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	--S1防彈跳
	if S2='1' then
		S2S<="000";
	elsif rising_edge(FD(17)) then
		S2S<=S2S+ not S2S(2);
	end if;
end process;

-- --------------------------
--除頻器
Freq_Div:process(gckP31)			--系統頻率gckP31:50MHz
begin
	if rstP99='0' then				--系統重置
		FD<=(others=>'0');			--除頻器:歸零
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--除頻器:2進制上數(+1)計數器
	end if;
end process Freq_Div;

-- ----------------------------------------
end Albert;