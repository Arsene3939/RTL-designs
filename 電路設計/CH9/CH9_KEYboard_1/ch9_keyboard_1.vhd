--4x4鍵盤_基本測試:按下放開再處理
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- -----------------------------------------------------
entity CH9_KEYboard_1 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
	 keyi:in std_logic_vector(3 downto 0);			--鍵盤輸入
	 keyo:buffer std_logic_vector(3 downto 0);		--鍵盤輸出
	 LED1_16:buffer std_logic_vector(15 downto 0); 	--LED顯示
	 --4位數掃描式顯示器
	 SCANo:buffer std_logic_vector(3 downto 0);		--掃瞄器輸出
	 Disp7S:buffer std_logic_vector(7 downto 0)		--計數位數解碼輸出
	);
end entity CH9_KEYboard_1;

-- -----------------------------------------------------
architecture Albert of CH9_KEYboard_1 is
	signal FD:std_logic_vector(24 downto 0);--除頻器
	signal kn,kin:integer range 0 to 15;	--新鍵值,原鍵值
	signal kok:std_logic_vector(3 downto 0):="0000";--鍵盤偵測狀態
	signal i:integer range 0 to 3;			--鍵盤輸入偵測指標

begin

--LED_on_off:取用者頻率高於鍵盤操作頻率-----------------------
LED_on_off:process (FD(12))
variable sw:std_logic;
begin
	if rstP99='0' then			--系統reset
		LED1_16<=(others=>'0');	--取消所有燈號
		kin<=0;					--設原鍵值0
		sw:='0';				--可接收新鍵值
	elsif (rising_edge(FD(12))) then
		if (kok=10) and sw='0' then			--鍵盤已完成狀態
			kin<=kn;						--取得新鍵值
			LED1_16(kn)<=not LED1_16(kn);	--新鍵值燈號
			sw:='1';	--停止接收新鍵值
		elsif kok=1 then--鍵盤已重啟
			sw:='0';	--可再接收新鍵值
		end if;
	end if;
end process LED_on_off;	 

--keyboard:鍵盤操作頻率低於取用者頻率-----------------------------
keyboard:process (FD(13))
begin
	if kok=0 or rstP99='0' then	--重置鍵盤,系統reset
		keyo<="1110";			--準備鍵盤輸出信號
		kok<="0001";			--預設鍵盤未完成、無按鍵狀態
		kn<=0;					--鍵值由0開始
		i<=0;					--鍵盤偵測指標由0開始
	elsif (rising_edge(FD(13))) then
		if (kok/=1) then		--有按鍵狀態

			--適當調整kok值可使鍵盤運作順暢
			if keyi=15 then		--判斷按鍵全放開
				if kok<5 then	--初期:鍵盤防彈跳過程狀態
					kok<=kok-1;	--如是雜訊將重啟鍵盤
				else
					kok<=kok+1;	--鍵盤防彈跳過程狀態(後期)
				end if;
			else
				if kok>9 then	--取用了:鍵盤防彈跳過程狀態
					kok<="1011";--(後期)
				elsif kok>4 then--尚未取用:鍵盤防彈跳過程狀態
					kok<="0101";
				else
					kok<=kok+1;	--初期:鍵盤防彈跳過程狀態
				end if;				
			end if;

		elsif keyi(i)='0' then	--偵測按鍵按下狀態
			kok<="0010";		--設有按鍵狀態
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

SCANo<="1110";
--七段顯示器解碼0123456789AbCdEF--pgfedcba
with kin select
Disp7S <=
"11000000" when 0,	--0
"11111001" when 1,	--1
"10100100" when 2,	--2
"10110000" when 3,	--3
"10011001" when 4,	--4
"10010010" when 5,	--5
"10000010" when 6,	--6
"11111000" when 7,	--7
"10000000" when 8,	--8
"10010000" when 9,	--9
"10001000" when 10,	--A
"10000011" when 11,	--b
"11000110" when 12,	--C
"10100001" when 13,	--d
"10000110" when 14,	--E
"10001110" when 15;	--F

----除頻器--------------------------
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
