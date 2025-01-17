--基本I/O測試
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99

library ieee;						--連結零件庫
use ieee.std_logic_1164.all;		--引用套件
use ieee.std_logic_unsigned.all;	--引用套件

entity ROTATE_ENCODER_EP3C16Q240C8 is 
--port(gckp31,SResetp99:in std_logic;				--系統頻率,系統reset
port(gckp31,ROTATEreset:in std_logic;				--系統頻率,系統reset
	 APi,BPi,PBi:in std_logic;
	 rsw:buffer std_logic_vector(2 downto 0)	--3位元計數器
	);
end ROTATE_ENCODER_EP3C16Q240C8;

architecture Albert of ROTATE_ENCODER_EP3C16Q240C8 is
	signal FD: std_logic_vector(25 downto 0);					--除頻器
	signal APic,BPic,PBic:std_logic_vector(2 downto 0):="000";	--防彈跳計數器
begin

-- 旋轉編碼器介面電路----------------------------------------
EncoderInterface:process(APi,PBi,ROTATEreset)
begin
	if ROTATEreset='0' or PBic(2)='0' then	
		rsw<=(others=>'0');		-- 計數器歸零
	elsif rising_edge(APic(2)) then	-- 偵測到UD信號的升緣時
		if BPi='1' then				-- 如果B信號為高態，則上數
			rsw<=rsw+1;
		else						-- 如果B信號為低態，則下數
			rsw<=rsw-1;
		end if;
	end if;
end process EncoderInterface; 

---------------------------------------------------------------
-- 防彈跳電路
Debounce:process(FD(8))	--旋轉編碼器防彈跳頻率
begin

--APi防彈跳與雜訊
	if APi=APic(2) then	--若APi等於APic最左邊位元
		APic<=APic(2) & "00";
		--則APi等於APic(2)右邊位元歸零
	elsif rising_edge(FD(8)) then	
		APic<=APic+1;
		--否則隨F1的升緣，APic計數器遞增
	end if;

--BPi防彈跳與雜訊
	if BPi=BPic(2) then	--若BPi等於BPic最左邊位元
		BPic<=BPic(2)& "00";	
		--則BPi等於BPic(2)右邊位元歸零
	elsif rising_edge(FD(8)) then 
		BPic<=BPic+1;
		--否則隨F1的升緣，BPic計數器遞增
	end if;

--PBi防彈跳與雜訊
	if PBi=PBic(2) then	--若PBi等於PBic最左邊位元
		PBic<=PBic(2)& "00";
		--則PBic(2)右邊位元歸零
	elsif rising_edge(FD(16)) then
		PBic<=PBic+1;
		--否則隨F1的升緣，PBic計數器遞增
	end if;
end process Debounce;

-- 除頻器----------------------------------------
Freq_Div:process(GCKP31)
begin
	if ROTATEreset='0' then			--系統reset
		FD<=(others=>'0');
	elsif rising_edge(GCKP31) then	--50MHz
		FD<=FD+1;
	end if;
end process Freq_Div;

end Albert;
