--MCP3202 ch0_1 + USB UART 測試+PC+中文LCM顯示
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件
Use IEEE.std_logic_arith.all;		--引用套件

entity CH13_UART_1 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
	 --RS232(UART)
	 RD:in std_logic;
	 TX:out std_logic;

	 --MCP3202
	 MCP3202_Di:out std_logic;
	 MCP3202_Do:in std_logic;
	 MCP3202_CLK,MCP3202_CS:buffer std_logic;
	 CHs:buffer std_logic;
	 
	 --LCD 4bit介面
	 DB_io:inout std_logic_vector(3 downto 0);
	 RSo,RWo,Eo:out std_logic

	 );
end entity CH13_UART_1;

-- -----------------------------------------------------
architecture Albert of CH13_UART_1 is
	--------------------------------------------------------------------------------------
	--RS232_T1 & RS232_R2
	--RS232_T1
	component RS232_T1 is
	port(clk,Reset:in std_logic;--clk:25MHz
		 DL:in std_logic_vector(1 downto 0);	 --00:5,01:6,10:7,11:8 Bit
		 ParityN:in std_logic_vector(2 downto 0);--000:None,100:Even,101:Odd,110:Space,111:Mark
		 StopN:in std_logic_vector(1 downto 0);	 --0x:1Bit,10:2Bit,11:1.5Bit
		 F_Set:in std_logic_vector(2 downto 0);
		 Status_s:out std_logic_vector(1 downto 0);
		 TX_W:in std_logic;
		 TXData:in std_logic_vector(7 downto 0);
		 TX:out std_logic);
	end component;
	--RS232_R2
	component RS232_R2 is
	port(Clk,Reset:in std_logic;--clk:25MHz
		 DL:in std_logic_vector(1 downto 0);	 --00:5,01:6,10:7,11:8 Bit
		 ParityN:in std_logic_vector(2 downto 0);--0xx:None,100:Even,101:Odd,110:Space,111:Mark
		 StopN:in std_logic_vector(1 downto 0);	 --0x:1Bit,10:2Bit,11:1.5Bit
		 F_Set:in std_logic_vector(2 downto 0);
		 Status_s:out std_logic_vector(2 downto 0);
		 Rx_R:in std_logic;
		 RD:in std_logic;
		 RxDs:out std_logic_vector(7 downto 0));
	end component;

	constant DL:std_logic_vector(1 downto 0):="11";	 	 --00:5,01:6,10:7,11:8 Bit
	constant ParityN:std_logic_vector(2 downto 0):="000";--0xx:None,100:Even,101:Odd,110:Space,111:Mark
	constant StopN:std_logic_vector(1 downto 0):="00";	 --0x>1Bit,10>2Bit,11>1.5Bit
	constant F_Set:std_logic_vector(2 downto 0):="010";	 --1200 BaudRate
	
	signal S_RESET_T:std_logic;						--Rs232 reset傳送
	signal TX_W:std_logic;							--寫入緩衝區
	signal Status_Ts:std_logic_vector(1 downto 0);	--傳送狀態
	signal TXData:std_logic_vector(7 downto 0);		--傳送資料
	
	signal S_RESET_R:std_logic;						--Rs232 reset接收
	signal Rx_R:std_logic;							--讀出緩衝區
	signal Status_Rs:std_logic_vector(2 downto 0);	--接收狀態
	signal RxDs:std_logic_vector(7 downto 0);		--接收資料
	
	signal CMDn,CMDn_R:integer range 0 to 3;		--Rs232傳出數,接收數
	--上傳PC資料(4 byte)
	type pc_up_data_T is array(0 to 3) of std_logic_vector(7 downto 0);
	--命令
	signal pc_up_data:pc_up_data_T:=("00000000","00000000","00000000","00000000");
	

	-- =ADC===========================================================================
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
	signal MCP3202_CH1_0:std_logic_vector(1 downto 0);
	signal MCP3202_SGL_DIFF:std_logic:='1';			--MCP3202 SGL/DIFF 選SGL
	signal MCP3202_ok,MCP3202_S:std_logic;			--Driver完成旗標 ,完成狀態

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
							X"20",X"20",X"20",X"20",X"20",X"20",X"B8",X"EA",X"AE",X"C6",X"C5",X"AA",X"A8",X"FA",X"A5",X"A2",X"B1",X"D1");--LM35 資料讀取失敗
	
	signal LCM_com_data,LCM_com_data2:LCM_T;--LCD表格輸出
	signal LCM_INI:integer range 0 to 31;	--LCD表格輸出指標
	signal LCMP_RESET,LN,LCMPok:std_logic;	--LCM_P重置,輸出列數,LCM_P完成
	signal LCM,LCMx:integer range 0 to 7;	--LCD輸出選項
	
	signal MCP3202_AD:integer range 0 to 4095;--MCP3202 AD值
	
begin

-----------------------------
U1: RS232_T1 port map(FD(0),S_RESET_T,DL,ParityN,StopN,F_Set,Status_Ts,TX_W,TXData,TX);			--RS232傳送模組
U2: RS232_R2 port map(FD(0),S_RESET_R,DL,ParityN,StopN,F_Set,Status_Rs,Rx_R,RD,RxDs);			--RS232接收模組						
U3: MCP3202_Driver port map(FD(4),MCP3202_RESET,		--MCP3202_Driver驅動clk,reset信號
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

------------------------------------------------------------------------------------------------------------
--上傳PC資料
TXData<=pc_up_data(CMDn-1);
--(上傳ADC)
MCP3202_AD<=MCP3202_AD0 when CHs='0' else MCP3202_AD1;		--通道選擇
pc_up_data(1)<=conv_std_logic_vector(MCP3202_AD/256,8);		--上傳PC資料high byte
pc_up_data(0)<=conv_std_logic_vector(MCP3202_AD mod 256,8);	--上傳PC資料low byte

-----------------------------
Main:process(FD(17))
begin
	if rstP99='0' then	--系統重置
		Rx_R<='0';			--取消讀取信號
		TX_W<='0';			--取消資料載入信號
		S_RESET_T<='0';		--關閉RS232傳送
		S_RESET_R<='0';		--關閉RS232接收
		CMDn<=2;			--上傳2byte(上傳AD)
		CMDn_R<=1;			--接收數量(1byte)
		
		MCP3202_RESET<='0';		--MCP3202_driver重置
		LCM<=0;					--中文LCM初始化
		LCMP_RESET<='0';		--LCMP重置
		MCP3202_CH1_0<="10";	--CH0->CH1自動轉換同步輸出
		--MCP3202_CH1_0<="00";	--CH0,CH1輪流轉換輪流輸出
	elsif (Rx_R='1' and Status_Rs(2)='0') then	--rs232接收即時處理
		Rx_R<='0';								--即時取消讀取信號
	elsif rising_edge(FD(17)) then
		LCMP_RESET<='1';	--LCMP啟動顯示
		S_RESET_T<='1';		--開啟RS232傳送
		S_RESET_R<='1';		--開啟RS232接收
		if CMDn>0 and S_RESET_T='1' then
			if Status_Ts(1)='0' then	--傳送緩衝區已空
				if TX_W='1' then
					TX_W<='0';			--取消傳送資料載入時脈
					CMDn<=CMDn-1;		--指標指向下一筆資料
				else
					TX_W<='1';			--傳送資料載入時脈
				end if;
			end if;
		-----------------------
		--已接收到PC命令
		elsif Status_Rs(2)='1' then		--已接收到PC命令
			Rx_R<='1';					--讀取信號
			--PC命令解析-------------------
			CHs<=RxDs(0);	--通道選擇			
		elsif LCMPok='1' then	--LCM顯示完成
			if MCP3202_RESET='0' then	--MCP3202_driver尚未啟動
				MCP3202_RESET<='1';			--重新讀取資料
				times<=20;					--設定計時
			elsif MCP3202_ok='1' then	--讀取結束
				times<=times-1;				--計時
				if times=0 then				--時間到
					LCM<=1;						--中文LCM顯示測量值
					LCMP_RESET<='0';			--LCMP重置
					MCP3202_RESET<='0';			--準備重新讀取資料
					--MCP3202_CH1_0(0)<=not MCP3202_CH1_0(0);--CH0,CH1輪流轉換輪流輸出
					CMDn<=2;					--上傳2byte(上傳AD)
				elsif MCP3202_S='1' then	--資料讀取失敗
					LCM<=2;						--中文LCM顯示 資料讀取失敗
				end if;
			end if;
		end if;
	end if;
end process Main;

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

end Albert;