--4位數掃瞄式共陽極七段顯示器
--計數器:手動計量器
--106.12.30版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ---------------------------------------
entity CH5_7SLED_1 is	
	port(gckP31,rstP99:in std_logic;--系統頻率,系統reset(歸零)
		 S1,S8:in std_logic;		--遞增按鈕(131),歸零(117)
		 --4位數掃描式顯示器
		 SCANo:buffer std_logic_vector(3 downto 0);--掃瞄器輸出
		 Disp7S:buffer std_logic_vector(7 downto 0)--計數位數解碼輸出
		 );
end entity CH5_7SLED_1;

-- -----------------------------------------
architecture Albert of CH5_7SLED_1 is
	signal FD:std_logic_vector(26 downto 0);	--系統除頻器
	type Disp7DataT is array(0 to 3) of integer range 0 to 9;--計數器格式
	signal Disp7Data:Disp7DataT;				--計數器
	signal scanP:integer range 0 to 3;			--掃瞄器指標
	signal S1S,S8S:std_logic_vector(2 downto 0);--防彈跳計數器
begin

--計數器--------------------------
counter_P:process(FD(18))
begin
	if rstP99='0' or S8S(2)='1' then	--系統重置,歸零
		Disp7Data(3)<=0;	--計數器:千位歸零
		Disp7Data(2)<=0;	--計數器:百位歸零
		Disp7Data(1)<=0;	--計數器:十位歸零
		Disp7Data(0)<=0;	--計數器:個位歸零
	elsif rising_edge(FD(18)) then
		if S1S(2)='1' then	--BCD碼遞增
			if Disp7Data(0)/=9 then	Disp7Data(0)<=Disp7Data(0)+1; else Disp7Data(0)<=0;--調整個位數
			if Disp7Data(1)/=9 then	Disp7Data(1)<=Disp7Data(1)+1; else Disp7Data(1)<=0;--調整十位數
			if Disp7Data(2)/=9 then	Disp7Data(2)<=Disp7Data(2)+1; else Disp7Data(2)<=0;--調整百位數
			if Disp7Data(3)/=9 then	Disp7Data(3)<=Disp7Data(3)+1; else Disp7Data(3)<=0;--調整千位數
		end if;end if;end if;end if;end if;
	end if;
end process counter_P;

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

--BCD碼解:共陽極七段顯示碼pgfedcba
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
process(FD(17))
begin
	--S8防彈跳
	If S8='1' then
		S8S<="000";
	elsif rising_edge(FD(17)) then
		S8S<=S8S+ not S8S(2);
	end if;
	--S1防彈跳
	If S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
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