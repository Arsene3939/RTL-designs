--DHT11溫濕度感測器測試:1 wire
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件
Use IEEE.numeric_std.all;			--引用套件

-- -----------------------------------------------------
entity CH10_DHT11_2 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
     sw8_1,sw8_2:in std_logic_vector(7 downto 0);	--指撥開關輸入:溫度設定,濕度設定
	 --DHT11
	 DHT11_D_io:inout std_logic;	--DHT11 i/o
	 
	 --DHT11 七段顯示器顯示輸出
	 DHT11_scan:buffer unsigned(3 downto 0);	--掃瞄信號
	 D7data:out std_logic_vector(7 downto 0);	--顯示資料
	 D7xx_xx:out std_logic;	--:
	 
	 --蜂鳴器輸出
	 sound1,sound2:buffer std_logic
    );
end entity CH10_DHT11_2;

-- -----------------------------------------------------
architecture Albert of CH10_DHT11_2 is
	-- ============================================================================
	--DHT11_driver
	--Data format:
	--DHT11_DBo(std_logic_vector:8bit):由DHT11_RDp選取輸出項
	--RDp=5:chK_SUM
	--RDp=4							   3							   2								1								  0					
	--The 8bit humidity integer data + 8bit the Humidity decimal data +8 bit temperature integer data + 8bit fractional temperature data +8 bit parity bit.
	--直接輸出濕度(DHT11_DBoH)及溫度(DHT11_DBoT):integer(0~255:8bit)
	--105.11.30版
	component DHT11_driver is
		port(DHT11_CLK,DHT11_RESET:in std_logic;		--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))操作速率,重置
			 DHT11_D_io:inout std_logic;				--DHT11 i/o
			 DHT11_DBo:out std_logic_vector(7 downto 0);--DHT11_driver 資料輸出
			 DHT11_RDp:in integer range 0 to 7;			--資料讀取指標
			 DHT11_tryN:in integer range 0 to 7;		--錯誤後嘗試幾次
			 DHT11_ok,DHT11_S:buffer std_logic;			--DHT11_driver完成作業旗標,錯誤信息
			 DHT11_DBoH,DHT11_DBoT:out integer range 0 to 255);--直接輸出濕度及溫度
	end component DHT11_driver;
	signal DHT11_CLK,DHT11_RESET:std_logic;	--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))操作速率,重置
	signal DHT11_DBo:std_logic_vector(7 downto 0);--DHT11_driver 資料輸出
	signal DHT11_RDp:integer range 0 to 7;		--資料讀取指標5~0
	signal DHT11_tryN:integer range 0 to 7:=3;	--錯誤後嘗試幾次
	signal DHT11_ok,DHT11_S:std_logic;			--DHT11_driver完成作業旗標,錯誤信息	
	signal DHT11_DBoH,DHT11_DBoT:integer range 0 to 255;--直接輸出濕度及溫度

	-- ============================================================================
	signal FD:std_logic_vector(24 downto 0);--除頻器
	signal scanP:integer range 0 to 3;		--位數取值指標
	signal HL,TL:std_logic;					--濕度、溫度狀態
	signal D7sp:std_logic;					--小數點
	signal Disp7S:std_logic_vector(6 downto 0);	--顯示解碼

	type D7_data_T is array (0 to 3) of integer range 0 to 15;--DHT11顯示值格式
	signal D7_data:D7_data_T:=(0,0,0,0);	--DHT11顯示值
	signal times:integer range 0 to 2047;	--計時器

begin
-----------------------------
DHT11_CLK<=FD(5);	--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))操作速率
U2: DHT11_driver port map(DHT11_CLK,DHT11_RESET,--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))操作速率,重置
						  DHT11_D_io,			--DHT11 i/o
						  DHT11_DBo,			--DHT11_driver 資料輸出
						  DHT11_RDp,			--資料讀取指標
						  DHT11_tryN,			--錯誤後嘗試幾次
						  DHT11_ok,DHT11_S,DHT11_DBoH,DHT11_DBoT);	--DHT11_driver完成作業旗標,錯誤信息,直接輸出濕度及溫度

-----------------------------
DHT11P_Main:process(FD(17))
begin
	if rstP99='0' then	--系統重置
		DHT11_RESET<='0';		--DHT11準備重新讀取資料
		D7xx_xx<='1';			--:不亮
	elsif rising_edge(FD(17)) then
		if DHT11_RESET='0' then	--DHT11_driver尚未啟動
			DHT11_RESET<='1';		--DHT11資料讀取
			D7xx_xx<='0';			--:亮 (DHT11資料讀取)
			times<=1400;			--設定計時
		elsif DHT11_ok='1' then	--DHT11讀取結束
			D7xx_xx<='1';			--:不亮 (DHT11讀取結束)
			times<=times-1;			--計時
			if times=0 then		--時間到
				DHT11_RESET<='0';	--DHT11準備重新讀取資料
			end if;
		end if;
	end if;
end process DHT11P_Main;

------------------------------------------------------------
--蜂鳴器輸出
--濕度警報聲
HL<='0' when DHT11_DBoH>(conv_integer(sw8_2(7 downto 4))*10+conv_integer(sw8_2(3 downto 0))) else '1';
sound1<=FD(22)and FD(16)and not HL;
--溫度警報聲
TL<='0' when DHT11_DBoT>(conv_integer(sw8_1(7 downto 4))*10+conv_integer(sw8_1(3 downto 0))) else '1';
sound2<=not TL;

--DHT11 顯示
D7_data(0)<=DHT11_DBoH mod 10;		-- 濕度擷取個位數
D7_data(1)<=(DHT11_DBoH/10)mod 10;	-- 濕度擷取十位數
D7_data(2)<=DHT11_DBoT mod 10;		-- 溫度擷取個位數
D7_data(3)<=(DHT11_DBoT/10)mod 10;	-- 溫度擷取十位數

--4位數掃瞄器----------------------------------------
scan_P:process(FD(17))
begin
	if rstP99='0' then
		scanP<=0;		--位數取值指標
		DHT11_scan<="1111";	--掃瞄信號
	elsif rising_edge(FD(17)) then
		scanP<=scanP+1;
		DHT11_scan<=DHT11_scan rol 1; --DHT11_scan 必須為unsigned
		--DHT11_scan<=DHT11_scan(2 downto 0) & DHT11_scan(3);-- DHT11_scan 可為unsigned或std_logic_vector
		if scanP=3 then
			scanP<=0;
			DHT11_scan<="1110";	--掃瞄信號
		end if;
	end if;
end process scan_P;

--小數點控制(閃爍表示超出設定)
with scanP select
	D7sp<=
	HL when 0,--濕度
	HL when 1,--濕度
	TL when 2,--溫度
	TL when 3;--溫度

D7data<=(D7sp or FD(24)) & Disp7S;--七段顯示碼整合輸出

--BCD碼解共陽極七段顯示碼pgfedcba
with D7_data(scanP) select --取出顯示值
	Disp7S<=
	"1000000" when 0,
	"1111001" when 1,
	"0100100" when 2,
	"0110000" when 3,
	"0011001" when 4,
	"0010010" when 5,
	"0000010" when 6,
	"1111000" when 7,
	"0000000" when 8,
	"0010000" when 9,
	"1111111" when others;	--不顯示

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
