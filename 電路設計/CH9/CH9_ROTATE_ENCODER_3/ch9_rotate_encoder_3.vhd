--旋轉編碼器_基本測試
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ---------------------------------------
entity CH9_ROTATE_ENCODER_3 is 
port(gckP31,rstP99:in std_logic;				 --系統頻率,系統reset
	 APi,BPi,PBi:in std_logic;					 --旋轉編碼器
	 LED1_16:buffer std_logic_vector(15 downto 0)--LED顯示
	);
end entity CH9_ROTATE_ENCODER_3;

-- ---------------------------------------
architecture Albert of CH9_ROTATE_ENCODER_3 is
	signal FD: std_logic_vector(25 downto 0);					--除頻器
	signal APic,BPic,PBic:std_logic_vector(2 downto 0):="000";	--防彈跳計數器
	signal mode1,mode2:integer range 0 to 3;					--樣板,操作模式
begin

-- 旋轉編碼器介面電路----------------------------------------
EncoderInterface:process(APi,PBi,rstP99)
begin
	if rstP99='0' then
		mode2<=0;					--由0開始
	elsif rising_edge(PBic(2)) then	-- 偵測到UD信號的升緣時
		mode2<=mode2+1;				--下一次變更依據
	end if;

	if rstP99='0' or PBic(2)='0' then
		mode1<=mode2;				--依mode2變更選項
		if mode1=0 then				--依mode2載入樣板
			LED1_16<=(others=>'0');
		elsif mode1=1 then
			LED1_16<="1100110011001100";
		elsif mode1=2 then
			LED1_16<="1111000000001111";
		else
			LED1_16<="1010101010101010";
		end if;
	elsif rising_edge(APic(2)) then	--偵測到UD信號的升緣時
		case mode1 is 
			when 0=>			
				if BPi='1' then				--左旋
					LED1_16<=not LED1_16(0)& LED1_16(15 downto 1);
				else						--右旋
					LED1_16<=LED1_16(14 downto 0) & not LED1_16(15);
				end if;
			when 1=>
				if BPi='1' then				--左旋
					LED1_16<=LED1_16(0)& LED1_16(15 downto 1);
				else						--右旋
					LED1_16<=LED1_16(14 downto 0) & LED1_16(15);
				end if;
			when 2=>
				if BPi='1' then				--外向內
					LED1_16<=LED1_16(14 downto 8) & LED1_16(15) & LED1_16(0)& LED1_16(7 downto 1);
				else						--內向外
					LED1_16<=LED1_16(8)& LED1_16(15 downto 9)&LED1_16(6 downto 0) & LED1_16(7);
				end if;
			when 3=>
				if BPi='1' then				--左反相
					LED1_16<=not LED1_16(15 downto 8) & LED1_16(7 downto 0);
				else						--右反相
					LED1_16<=LED1_16(15 downto 8) & not LED1_16(7 downto 0);
				end if;
		end case;
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
