--DHT11溫濕度感測器測試:1 wire+中文LCM顯示
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件
use ieee.std_logic_arith.all;		--引用套件

-- -----------------------------------------------------
entity CH10_DHT11_1 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
	 --DHT11
	 DHT11_D_io:inout std_logic;	--DHT11 i/o
	 
	 --LCD 4bit介面
	 DB_io:inout std_logic_vector(3 downto 0);
	 RSo,RWo,Eo:out std_logic
	 );
end entity CH10_DHT11_1;

-- -----------------------------------------------------
architecture Albert of CH10_DHT11_1 is
	-- ============================================================================
	--DHT11_driver
	--Data format:
	--DHT11_DBo(std_logic_vector:8bit):由DHT11_RDp選取輸出項
	--RDp=5:chK_SUM
	--RDp=4							   3							   2								1								  0					
	--The 8bit humidity integer data + 8bit the Humidity decimal data +8 bit temperature integer data + 8bit fractional temperature data +8 bit parity bit.
	--直接輸出濕度(DHT11_DBoH)及溫度(DHT11_DBoT):integer(0~255:8bit)
	--107.01.01版
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
		
	--------------------------------------------------------------------------------------
	--中文LCM 4bit driver(WG14432B5)
	component LCM_4bit_driver is
	port(LCM_CLK,LCM_RESET:in std_logic;			--操作速率,重置
		 RS,RW:in std_logic;						--暫存器選擇,讀寫旗標輸入
		 DBi:in std_logic_vector(7 downto 0);		--LCM_4bit_driver 資料輸入
		 DBo:out std_logic_vector(7 downto 0);		--LCM_4bit_driver 資料輸出
		 DB_io:inout std_logic_vector(3 downto 0);	--LCM DATA BUS介面
		 RSo,RWo,Eo:out std_logic;					--LCM 暫存器選擇,讀寫,致能介面
		 LCMok,LCM_S:out boolean					--LCM_4bit_driver完成,錯誤旗標
		 );
	end component;

	signal LCM_RESET,RS,RW:std_logic;				--LCM_4bit_driver重置,LCM暫存器選擇,讀寫旗標
	signal DBi,DBo:std_logic_vector(7 downto 0);	--LCM_4bit_driver命令或資料輸入及輸出
	signal LCMok,LCM_S:boolean;						--LCM_4bit_driver完成作業旗標,錯誤信息

	-- ============================================================================
	signal FD:std_logic_vector(24 downto 0);--除頻器
	signal times:integer range 0 to 2047;	--計時器
	
	--------------------------------------------------------------
	----中文LCM指令&資料表格式:
	----(總長,指令數,指令...資料...........
	----英數型LCM 4位元界面,2列顯示

	type LCM_T is array (0 to 20) of std_logic_vector(7 downto 0);
	constant LCM_IT:LCM_T:=(X"0F",X"06",----中文型LCM 4位元界面
							"00101000","00101000","00101000",--4位元界面
							"00000110","00001100","00000001",--ACC+1顯示幕無移位,顯示幕on無游標無閃爍,清除顯示幕
							X"01",X"48",X"65",X"6C",X"6C",X"6F",X"21",X"20",X"20",X"20",x"20",X"20",X"20");--Hello!
	
	--LCM=1:第一列顯示區DHT11 測濕度  %RH
	signal LCM_1:LCM_T:=(X"15",X"01",			--總長,指令數
							"00000001",			--清除顯示幕
							--第1列顯示資料
							X"44",X"48",X"54",X"31",X"31",X"20",X"B4",X"FA",X"C0",X"E3",X"AB",X"D7",X"3D",X"30",X"30",X"25",X"52",X"48");--DHT11 測濕度  %RH

	--LCM=1:第二列顯示區DHT11 測溫度  ℃
	signal LCM_12:LCM_T:=(X"15",X"01",			--總長,指令數
							"10010000",			--設第二列ACC位置
							--第2列顯示資料
							X"44",X"48",X"54",X"31",X"31",X"20",X"B4",X"FA",X"B7",X"C5",X"AB",X"D7",X"3D",X"30",X"30",X"20",X"A2",X"4A");--DHT11 測溫度  ℃
	
	--LCM=2:第一列顯示區DHT11 資料讀取失敗
	signal LCM_2:LCM_T:=(X"15",X"01",			--總長,指令數
							"00000001",			--清除顯示幕
							--第1列顯示資料
							X"44",X"48",X"54",X"31",X"31",X"20",X"B8",X"EA",X"AE",X"C6",X"C5",X"AA",X"A8",X"FA",X"A5",X"A2",X"B1",X"D1");--DHT11 資料讀取失敗
	
	signal LCM_com_data,LCM_com_data2:LCM_T;
	signal LCM_INI:integer range 0 to 31;
	signal LCMP_RESET,LN,LCMPok:std_logic;
	signal LCM,LCMx:integer range 0 to 7;

begin

-----------------------------
DHT11_CLK<=FD(5);	--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))操作速率
U2: DHT11_driver port map(DHT11_CLK,DHT11_RESET,--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))操作速率,重置
						  DHT11_D_io,			--DHT11 i/o
						  DHT11_DBo,			--DHT11_driver 資料輸出
						  DHT11_RDp,			--資料讀取指標
						  DHT11_tryN,			--錯誤後嘗試幾次
						  DHT11_ok,DHT11_S,DHT11_DBoH,DHT11_DBoT);	--DHT11_driver完成作業旗標,錯誤信息,直接輸出濕度及溫度
--中文LCM				  
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);	--LCM模組

-----------------------------
DHT11P_Main:process(FD(17))
begin
	if rstP99='0' then	--系統重置
		DHT11_RESET<='0';	--DHT11準備重新讀取資料
		LCM<=0;				--中文LCM初始化
		LCMP_RESET<='0';	--LCMP重置
	elsif rising_edge(FD(17)) then
		LCMP_RESET<='1';	--LCMP啟動顯示	
		if LCMPok='1' then
			if DHT11_RESET='0' then	--DHT11_driver尚未啟動
				DHT11_RESET<='1';	--DHT11資料讀取
				times<=400;			--設定計時
			elsif DHT11_ok='1' then	--DHT11讀取結束
				times<=times-1;			--計時
				if times=0 then			--時間到
					LCM<=1;				--中文LCM顯示測量值
					LCMP_RESET<='0';	--LCMP重置
					DHT11_RESET<='0';	--DHT11準備重新讀取資料
				elsif DHT11_S='1' then	--資料讀取失敗
					LCM<=2;			--中文LCM顯示DHT11 資料讀取失敗
				end if;
			end if;
		end if;
	end if;
end process DHT11P_Main;

------------------------------------------------------------
--DHT11 LCM顯示
LCM_1(17)<="0011" & conv_std_logic_vector(DHT11_DBoH mod 10,4);		-- 擷取個位數
LCM_1(16)<="0011" & conv_std_logic_vector((DHT11_DBoH/10)mod 10,4);	-- 擷取十位數
LCM_12(17)<="0011" & conv_std_logic_vector(DHT11_DBoT mod 10,4);	-- 擷取個位數
LCM_12(16)<="0011" & conv_std_logic_vector((DHT11_DBoT/10)mod 10,4);-- 擷取十位數

--中文LCM顯示器---------------------------------------------------
--中文LCM顯示器
--指令&資料表格式: 
--(總長,指令數,指令...資料..........
LCM_P:process(FD(0))
	variable SW:Boolean;				--命令或資料備妥旗標
begin
	if LCM/=LCMx or LCMP_RESET='0' then
		LCMx<=LCM;						--記錄選項
		LCM_RESET<='0';					--LCM重置
		LCM_INI<=2;						--命令或資料索引設為起點
		LN<='0';						--設定輸出1列
		case LCM is
			when 0=>
				LCM_com_data<=LCM_IT;	--LCM初始化輸出第一列資料Hello!
			when 1=>
				LCM_com_data<=LCM_1;	--輸出第一列資料
				LCM_com_data2<=LCM_12;	--輸出第二列資料
				LN<='1';				--設定輸出2列
			when others =>
				LCM_com_data<=LCM_2;	--輸出第一列資料
		end case;
		LCMPok<='0';					--取消完成信號
		SW:=False;						--命令或資料備妥旗標
	elsif rising_edge(FD(0)) then
		if SW then						--命令或資料備妥後
			LCM_RESET<='1';				--啟動LCM_4bit_driver_delay
			SW:=False;					--重置旗標
		elsif LCM_RESET='1' then		--LCM_4bit_driver_delay啟動中
			if LCMok then				--等待LCM_4bit_driver_delay完成傳送
				LCM_RESET<='0';			--完成後LCM重置
			end if;
		elsif LCM_INI<LCM_com_data(0) and LCM_INI<LCM_com_data'length then	--命令或資料尚未傳完
			if LCM_INI<=(LCM_com_data(1)+1) then--選命令或資料暫存器
				RS<='0';	--Instruction reg
			else
				RS<='1';	--Data reg
			end if;
			RW<='0';		--LCM寫入操作
			DBi<=LCM_com_data(LCM_INI);	--載入命令或資料
			LCM_INI<=LCM_INI+1;			--命令或資料索引指到下一筆
			SW:=True;					--命令或資料已備妥
		else
			if LN='1' then				--設定輸出2列
				LN<='0';					--設定輸出2列取消
				LCM_INI<=2;					--命令或資料索引設為起點
				LCM_com_data<=LCM_com_data2;--LCM輸出第二列資料
			else
				LCMPok<='1';				--執行完成
			end if;
		end if;
	end if;
end process LCM_P;

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
