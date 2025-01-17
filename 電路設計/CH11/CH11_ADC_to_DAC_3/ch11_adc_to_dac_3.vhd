--MCP3202 ch0_1->MCP4822 chA_B測試+中文LCM顯示
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件
Use IEEE.std_logic_arith.all;		--引用套件

-- -----------------------------------------------------
entity CH11_ADC_to_DAC_3 is
port(gckP31,rstP99:in std_logic;	--系統頻率,系統reset
	 --MCP3202 ADC
	 MCP3202_Di:out std_logic;
	 MCP3202_Do:in std_logic;
	 MCP3202_CLK,MCP3202_CS:buffer std_logic;
	 
	 --MCP4822 DAC
	 MCP4822_SDI,MCP4822_LDAC:out std_logic;	--MCP4822 SDI,LDAC信號
	 MCP4822_SCK,MCP4822_CS:buffer std_logic;	--MCP4822 SCK,/cs信號
	 
	 --LCD 4bit介面
	 DB_io:inout std_logic_vector(3 downto 0);
	 RSo,RWo,Eo:out std_logic
	 
	 );
end entity CH11_ADC_to_DAC_3;

-- -----------------------------------------------------
architecture Albert of CH11_ADC_to_DAC_3 is
	--MCP3202 ADC--------------------------------------------------------------------------
	component MCP3202_Driver is
	port(MCP3202_CLK_D,MCP3202_RESET:in std_logic;	--MCP3202_Driver驅動clk,reset信號
		 MCP3202_AD0,MCP3202_AD1:buffer integer range 0 to 4095;	--MCP3202 AD0,1 ch0,1值
		 MCP3202_try_N:in integer range 0 to 3;		--失敗後再嘗試次數
		 MCP3202_CH1_0:in std_logic_vector(1 downto 0);	--輸入通道
		 MCP3202_SGL_DIFF:in std_logic;				--MCP3202 SGL/DIFF
		 MCP3202_Do:in std_logic;					--MCP3202 do信號
		 MCP3202_Di:out std_logic;					--MCP3202 di信號
		 MCP3202_CLK,MCP3202_CS:buffer std_logic;	--MCP3202 clk,/cs信號
		 MCP3202_ok,MCP3202_S:buffer std_logic);	--Driver完成旗標 ,完成狀態
	end component;
	
	signal MCP3202_CLK_D,MCP3202_RESET:std_logic;	--MCP3202_Driver驅動clk,reset信號
	signal MCP3202_AD0,MCP3202_AD1:integer range 0 to 4095;--MCP3202 AD值
	signal MCP3202_try_N:integer range 0 to 3:=1;	--失敗後再嘗試次數
	signal MCP3202_CH1_0:std_logic_vector(1 downto 0):="01";--ch1
	signal MCP3202_SGL_DIFF:std_logic:='1';			--MCP3202 SGL/DIFF 選SGL
	signal MCP3202_ok,MCP3202_S:std_logic;			--Driver完成旗標 ,完成狀態
	
	--MCP4822 DAC--------------------------------------------------------------------------
	component MCP4822_Driver is
	port(MCP4822_CLK,MCP4822_RESET:in std_logic;		--MCP4822_Driver驅動clk,reset信號
		 MCP4822_DAA,MCP4822_DAB:in integer range 0 to 4095;--MCP4822 DAC chA0,B1值
		 MCP4822_CHB_A:in std_logic_vector(1 downto 0);	--輸入通道
		 MCP4822_GA_BA:in std_logic_vector(1 downto 0);	--/GA 0x2,1x1
		 MCP4822_SHDN_BA:in std_logic_vector(1 downto 0);--/SHDN
		 MCP4822_SDI,MCP4822_LDAC:out std_logic;		--MCP4822 SDI,LDAC信號
		 MCP4822_SCK,MCP4822_CS:buffer std_logic;		--MCP4822 SCK,/cs信號
		 MCP4822_ok:buffer std_logic);					--Driver完成旗標
	end component;
			
	signal MCP4822_CLK,MCP4822_RESET:std_logic;			--MCP4822_Driver驅動clk,reset信號
	signal MCP4822_DAA,MCP4822_DAB:integer range 0 to 4095;	--MCP4822 DAC chA0,B1值
	signal MCP4822_CHB_A:std_logic_vector(1 downto 0);	--輸入通道
	signal MCP4822_GA_BA:std_logic_vector(1 downto 0);	--GA 0x2,1x1
	signal MCP4822_SHDN_BA:std_logic_vector(1 downto 0);--/SHDN
	signal MCP4822_ok:std_logic;						--Driver完成旗標
	---------------------------------------------------------------------------------------
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
	signal FS:integer range 0 to 31;		--頻率選擇
	signal times:integer range 0 to 2047;	--計時器
	
	--------------------------------------------------------------
	----中文LCM指令&資料表格式:
	----(總長,指令數,指令...資料...........
	----英數型LCM 4位元界面,2列顯示

	type LCM_T is array (0 to 20) of std_logic_vector(7 Downto 0);
	constant LCM_IT:LCM_T:=(X"0F",X"06",----中文型LCM 4位元界面
							"00101000","00101000","00101000",--4位元界面
							"00000110","00001100","00000001",--ACC+1顯示幕無移位,顯示幕on無游標無閃爍,清除顯示幕
							X"01",X"48",X"65",X"6C",X"6C",X"6F",X"21",X"20",X"20",X"20",x"20",X"20",X"20");--Hello!
	
	--LCM=1:第一列顯示區");-- -=MCP3202 ADC=-
	signal LCM_1:LCM_T:=(X"15",X"01",						--總長,指令數
							"00000001",						--清除顯示幕
							--第1列顯示資料
							X"20",X"2D",X"3D",X"4D",X"43",X"50",X"33",X"32",X"30",X"32",X"20",X"41",X"44",X"43",X"3D",X"2D",X"20",X"20");-- -=MCP3202 ADC=-

	--LCM=1:第二列顯示區CH0:      CH1:    
	signal LCM_12:LCM_T:=(X"15",X"01",						--總長,指令數
							"10010000",						--設第二列ACC位置
							--第2列顯示資料
							X"43",X"48",X"30",X"3A",X"20",X"20",X"20",X"20",X"20",X"20",X"43",X"48",X"31",X"3A",X"20",X"20",X"20",X"20");--CH0:      CH1:    
	
	--LCM=2:第一列顯示區 資料讀取失敗
	signal LCM_2:LCM_T:=(X"15",X"01",						--總長,指令數
							"00000001",						--清除顯示幕
							--第1列顯示資料
							X"20",X"20",X"20",X"20",X"20",X"20",X"B8",X"EA",X"AE",X"C6",X"C5",X"AA",X"A8",X"FA",X"A5",X"A2",X"B1",X"D1");--
	
	signal LCM_com_data,LCM_com_data2:LCM_T;--LCD表格輸出
	signal LCM_INI:integer range 0 to 31;	--LCD表格輸出指標
	signal LCMP_RESET,LN,LCMPok:std_logic;	--LCM_P重置,輸出列數,LCM_P完成
	signal LCM,LCMx:integer range 0 to 7;	--LCD輸出選項
	
-----------------------------
begin

U1: MCP4822_Driver port map( FD(0),MCP4822_RESET,	--MCP4822_Driver驅動clk,reset信號
							 MCP4822_DAA,MCP4822_DAB,	--MCP4822 DAC chA0,B1值
							 MCP4822_CHB_A,				--輸入通道
							 MCP4822_GA_BA,				--GA 0x2,1x1
							 MCP4822_SHDN_BA,			--/SHDN
							 MCP4822_SDI,MCP4822_LDAC,	--MCP4822 SDI,LDAC信號
							 MCP4822_SCK,MCP4822_CS,	--MCP4822 SCK,/cs信號
							 MCP4822_ok);				--Driver完成旗標

U2: MCP3202_Driver port map(FD(4),MCP3202_RESET,		--MCP3202_Driver驅動clk,reset信號
							MCP3202_AD0,MCP3202_AD1,	--MCP3202 AD值
							MCP3202_try_N,				--失敗後再嘗試次數
							MCP3202_CH1_0,				--輸入通道
							MCP3202_SGL_DIFF,			--SGL/DIFF
							MCP3202_Do,					--MCP3202 do信號
							MCP3202_Di,					--MCP3202 di信號
							MCP3202_CLK,MCP3202_CS,		--MCP3202 clk,/cs信號 
							MCP3202_ok,MCP3202_S);		--Driver完成旗標 ,完成狀態

--中文LCM				  
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);	--LCM模組

MCP4822_DAA<=MCP3202_AD0;--CH0:ADC to DAC
MCP4822_DAB<=MCP3202_AD1;--CH1:ADC to DAC

-----------------------------
ADC_DAC_Main:process(FD(17))
begin
	if rstP99='0' then	--系統重置
		MCP3202_RESET<='0';		--MCP3202_driver重置
		LCM<=0;					--中文LCM初始化
		LCMP_RESET<='0';		--LCMP重置
		MCP3202_CH1_0<="10";	--CH0->CH1自動轉換同步輸出
		--MCP3202_CH1_0<="00";	--CH0,CH1輪流轉換輪流輸出
		MCP4822_RESET<='0';
		MCP4822_CHB_A<="10";	--CHA->CHB自動轉換同步輸出
		MCP4822_GA_BA<="11";	--A:x1 B:x1
		MCP4822_SHDN_BA<="11";	--/SHUTDOWN off
		FS<=0;					--頻率選擇
	elsif rising_edge(FD(FS)) then
		LCMP_RESET<='1';	--LCMP啟動顯示
		if LCMPok='1' then	--LCM顯示完成
			if MCP3202_RESET='0' then	--MCP3202_driver尚未啟動
				MCP3202_RESET<='1';			--重新讀取資料
				times<=40;					--設定計時
				FS<=0;						--頻率選擇
			elsif MCP3202_ok='1' then	--讀取結束
				if MCP4822_RESET='0' then
					MCP4822_RESET<='1';		--啟動DAC轉換
				elsif MCP4822_ok='1' then
					FS<=17;					--頻率選擇
					times<=times-1;			--計時
					if times=0 then			--時間到
						LCM<=1;					--中文LCM顯示測量值
						LCMP_RESET<='0';		--LCMP重置
						MCP3202_RESET<='0';		--準備重新讀取資料
						--MCP3202_CH1_0(0)<=not MCP3202_CH1_0(0);--CH0,CH1輪流轉換輪流輸出
						MCP4822_RESET<='0';
					elsif MCP3202_S='1' then	--資料讀取失敗
						LCM<=2;						--中文LCM顯示 資料讀取失敗
					end if;
				end if;
			end if;
		end if;
	end if;
end process ADC_DAC_Main;

------------------------------------------------------------
--LCM顯示
LCM_12(10)<="0011" & conv_std_logic_vector(MCP3202_AD0 mod 10,4);		-- 擷取個位數
LCM_12(9)<="0011" & conv_std_logic_vector((MCP3202_AD0/10)mod 10,4);	-- 擷取十位數
LCM_12(8)<="0011" & conv_std_logic_vector((MCP3202_AD0/100) mod 10,4);	-- 擷取百位數
LCM_12(7)<="0011" & conv_std_logic_vector(MCP3202_AD0/1000,4);			-- 擷取千位數

LCM_12(20)<="0011" & conv_std_logic_vector(MCP3202_AD1 mod 10,4);		-- 擷取個位數
LCM_12(19)<="0011" & conv_std_logic_vector((MCP3202_AD1/10)mod 10,4);	-- 擷取十位數
LCM_12(18)<="0011" & conv_std_logic_vector((MCP3202_AD1/100) mod 10,4);	-- 擷取百位數
LCM_12(17)<="0011" & conv_std_logic_vector(MCP3202_AD1/1000,4);			-- 擷取千位數

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
