--基本I/O測試
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity KEYboard_EP3C16Q240C8 is
port(gckp31,KEYboardreset:in std_logic;				--系統頻率,系統reset
	 keyi:in std_logic_vector(3 downto 0);		--鍵盤輸入
	 keyo:buffer std_logic_vector(3 downto 0);	--鍵盤輸出
	 ksw:out std_logic_vector(2 downto 0) 		--0~7顯示
	);
end KEYboard_EP3C16Q240C8;

architecture Albert of KEYboard_EP3C16Q240C8 is
	signal FD:std_logic_vector(24 downto 0);--除頻器
	signal kn:std_logic_vector(3 downto 0);	--新鍵值
	signal ks,kok:std_logic;				--鍵盤reset,鍵盤偵測狀態,鍵盤完成狀態
	signal i:integer range 0 to 3;			--鍵盤偵測指標

begin
-- ----------------------------------------------

keyboard:process (FD(16))
begin
	if KEYboardreset='0' or kok='1' then	--系統reset
		keyo<="1110";			--準備鍵盤輸出信號
		kn<="0000";					--鍵值由0開始
		i<=0;					--鍵盤偵測指標由0開始
		ks<='0';				--預設無按鍵狀態
		kok<='0';				--預設鍵盤未完成狀態
	elsif (rising_edge(FD(16))) then
		if (ks='1') then		--有按鍵狀態
			if keyi=15 then		--判斷按鍵全放開
				kok<='1';		--鍵盤已完成狀態
				if kn<8 then
					ksw<=kn(2 downto 0);
				end if;
			end if;
		elsif keyi(i)='0' then	--偵測按鍵按下狀態
			ks<='1';			--設有按鍵狀態
			keyo<="0000";		--設偵測所有按鍵
		else					--無按鍵按下狀態
			kn<=kn+1;			--調整鍵值
			keyo<=keyo(2 downto 0) & keyo(3);--調整鍵盤輸出
			if keyo(3)='0' then	--是否要調整鍵盤偵測指標
				i<=i+1;			--調整鍵盤偵測指標
			end if;
		end if;
	end if;
end process keyboard;
	
-- 除頻器----------------------------------------
Freq_Div:process(GCKP31)
begin
	if KEYboardreset='0' then			--系統reset
		FD<=(others=>'0');
	elsif rising_edge(GCKP31) then	--50MHz
		FD<=FD+1;
	end if;
end process Freq_Div;

end Albert;
