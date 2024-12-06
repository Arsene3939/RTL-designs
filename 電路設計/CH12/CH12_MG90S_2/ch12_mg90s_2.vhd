--旋轉編碼器+MG90S 測試
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件
Use IEEE.std_logic_arith.all;		--引用套件

-- -----------------------------------------------------
entity CH12_MG90S_2 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset

	 --MG90S--
	 MG90S_o0:out std_logic;
	 MG90S_o1:out std_logic;

	 APi,BPi,PBi:in std_logic;	 --旋轉編碼器
	 LED1_2:buffer std_logic_vector(1 downto 0)--LED顯示
	 );
end entity CH12_MG90S_2;

-- -----------------------------------------------------
architecture Albert of CH12_MG90S_2 is
	--MG90S-------------------------------------------------------------------------------
	component MG90S_Driver2 is
	port(MG90S_CLK,MG90S_RESET:in std_logic;		--MG90S_Driver驅動clk(25MHz),reset信號
		 MG90S_deg:in integer range 0 to 180;		--轉動角度
		 MG90S_o:out std_logic);					--Driver輸出
	end component;
	signal MG90S_CLK,MG90S_RESET:std_logic;			--MG90S_Driver驅動clk(25MHz),reset信號
	signal MG90S_deg0,MG90S_deg1:integer range 0 to 180:=90;	--轉動角度

	-- ============================================================================
	signal FD:std_logic_vector(24 downto 0);--除頻器
	signal times:integer range 0 to 2047;	--計時器
	signal APic,BPic,PBic:std_logic_vector(2 downto 0):="000";	--防彈跳計數器
	signal clrPC,set90,HV:std_logic;		--清除按鈕紀錄,設90度,軸向
	signal PC:integer range 0 to 3;			--按鈕紀錄

-----------------------------
begin

U1: MG90S_Driver2 port map(FD(0),MG90S_RESET,--MG90S_Driver驅動clk(25MHz),reset信號
						  MG90S_deg0,		 --轉動角度
						  MG90S_o0);		 --Driver輸出
						
U12: MG90S_Driver2 port map(FD(0),MG90S_RESET,--MG90S_Driver驅動clk(25MHz),reset信號
						  MG90S_deg1,		  --轉動角度
						  MG90S_o1);		 --Driver輸出
						  
LED1_2<=HV & not HV;

--旋轉編碼器按鈕監控-----------------------------
--軸向變換,設90度
process(FD(17),rstP99)
begin
	if rstP99='0' then
		HV<='0';	--由0開始
		set90<='0';	--不設90度 
		clrPC<='0';	--不清除按鈕紀錄
		times<=0;	--計時歸零
		MG90S_RESET<='0';		--MG90S_Driver2 off
	elsif rising_edge(FD(17)) then	-- 偵測到UD信號的升緣時
		MG90S_RESET<='1';		--MG90S_Driver2 on
		if PC/=0 then
			times<=times+1;		--計時
			if times=75 then	--計時到
				if PC=1 then	--單按
					HV<=not HV;	--切換軸向
				else			--雙按
					set90<='1';	--設90度 
				end if;
				clrPC<='1';		--清除按鈕紀錄
			end if;
		else
			times<=0;			--計時歸零
			set90<='0';			--清除設90度 
			clrPC<='0';			--清除清除按鈕紀錄
		end if;
	end if;
end process;

--旋轉編碼器按鈕介面電---------------------------
--單按 雙按
process(PBic(2),rstP99,clrPC)
begin
	if rstP99='0' or clrPC='1' then
		PC<=0;	--按鈕紀錄 0
	elsif rising_edge(PBic(2)) then	-- 偵測到UD信號的升緣時
		if PC<2 then 
			PC<=PC+1;				--按鈕紀錄
		end if;
	end if;
end process;

--旋轉編碼器旋轉介面電路----------------------------------------
--角度變換 0~180
EncoderInterface:process(APi,PBi,rstP99,set90)
begin
	if rstP99='0' or set90='1' then
		MG90S_deg0<=90;
		MG90S_deg1<=90;
	elsif rising_edge(APic(2)) then	--偵測到UD信號的升緣時
		if HV='0' then
			if BPi='1' then				--右旋
				if MG90S_deg0<180 then
					MG90S_deg0<=MG90S_deg0+1;--加1度
				end if;
			else						--左旋
				if MG90S_deg0>0 then
					MG90S_deg0<=MG90S_deg0-1;--減1度
				end if;
			end if;
		else
			if BPi='0' then				--左旋
				if MG90S_deg1<180 then
					MG90S_deg1<=MG90S_deg1+1;--加1度
				end if;
			else						--右旋
				if MG90S_deg1>0 then
					MG90S_deg1<=MG90S_deg1-1;--減1度
				end if;
			end if;				
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
