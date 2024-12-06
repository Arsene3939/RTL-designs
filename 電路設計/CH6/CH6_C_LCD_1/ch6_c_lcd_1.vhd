--中文LCM顯示 使用:LCM_4bit_driver_delay
--106.12.30版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- -----------------------------------------------------
entity CH6_C_LCD_1 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
	  S1,S2:in std_logic;		--向上、向下按鈕
	 --LCD 4bit介面
	 DB_io:inout std_logic_vector(3 downto 0);
	 RSo,RWo,Eo:out std_logic
	 );
end entity CH6_C_LCD_1;

-- -----------------------------------------------------
architecture Albert of CH6_C_LCD_1 is
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
							X"01",X"48",X"65",X"6C",X"6C",X"6F",X"21",X"20",X"20",X"20",x"20",X"20",X"20");--白臉Hello!

	--LCM=21:第一列顯示 夜思　作者：李白
	signal LCM_21:LCM_T:=(X"13",X"01",		--總長,指令數
							"00000001",		--清除顯示幕
							--第1列顯示資料
							X"A9",X"5D",X"AB",X"E4",X"A1",X"40",X"A7",X"40",X"AA",X"CC",X"A1",X"47",X"A7",X"F5",X"A5",X"D5",X"20",X"20");--夜思　作者：李白

	--LCM=22:第二列顯示 床前明月光，
	signal LCM_22:LCM_T:=(X"13",X"01",		--總長,指令數
							"10010000",		--設第二列ACC位置
							--第2列顯示資料
							X"A7",X"C9",X"AB",X"65",X"A9",X"FA",X"A4",X"EB",X"A5",X"FA",X"A1",X"41",X"20",X"20",X"20",x"20",X"20",X"20");--床前明月光?

	--LCM=23:第二列顯示 疑似地上霜
	signal LCM_23:LCM_T:=(X"13",X"01",		--總長,指令數
							"10010000",		--設第二列ACC位置
							--第2列顯示資料
							X"BA",X"C3",X"A6",X"FC",X"A6",X"61",X"A4",X"57",X"C1",X"F7",X"A1",X"41",X"20",X"20",X"20",x"20",X"20",X"20");--疑似地上霜，
	--LCM=24:第二列顯示 舉頭望明月，
	signal LCM_24:LCM_T:=(X"13",X"01",		--總長,指令數
							"10010000",		--設第二列ACC位置
							--第2列顯示資料
							X"C1",X"7C",X"C0",X"59",X"B1",X"E6",X"A9",X"FA",X"A4",X"EB",X"A1",X"41",X"20",X"20",X"20",x"20",X"20",X"20");--舉頭望明月，	

	--LCM=25:第二列顯示 低頭思故鄉。	
	signal LCM_25:LCM_T:=(X"13",X"01",		--總長,指令數
							"10010000",		--設第二列ACC位置
							--第2列顯示資料
							X"A7",X"43",X"C0",X"59",X"AB",X"E4",X"AC",X"47",X"B6",X"6D",X"A1",X"43",X"20",X"20",X"20",x"20",X"20",X"20");--低頭思故鄉。
	
	signal LCM_com_data,LCM_com_data2:LCM_T;--LCD表格輸出
	signal LCM_INI:integer range 0 to 31;	--LCD表格輸出指標
	signal LCMP_RESET,LN,LCMPok:std_logic;	--LCM_P重置,輸出列數,LCM_P完成
	signal LCM,LCMx:integer range 0 to 7;	--LCD輸出選項
	
	signal S2S,S1S:std_logic_vector(2 downto 0);--防彈跳計數器

-----------------------------
begin

--中文LCM--------------------
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);	--LCM模組

-----------------------------
C_LCD_P:process(FD(18))
begin
	if rstP99='0' then	--系統重置
		LCM<=0;				--中文LCM初始化
		LCMP_RESET<='0';	--LCMP重置
	elsif rising_edge(FD(18)) then
		LCMP_RESET<='1';	--LCMP啟動顯示	
		if LCMPok='1' then
			if S1S(2)='1' then		--向上按鈕
				if LCM>1 then	
					LCM<=LCM-1;		--顯示 上一句
				end if;
			elsif S2S(2)='1' then	--向下按鈕
				if LCM<4 then
					LCM<=LCM+1;		--顯示 下一句
				end if;
			end if;
		end if;
	end if;
end process C_LCD_P;

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
		case LCM is						--載入選項表格
			when 0=>
				LCM_com_data<=LCM_IT;	--LCM初始化輸出第一列資料Hello!
			when 1=>
				LCM_com_data<=LCM_21;	--輸出第一列資料
				LCM_com_data2<=LCM_22;	--輸出第二列資料
				LN<='1';				--設定輸出2列
			when 2=>
				LCM_com_data<=LCM_23;	--輸出第二列資料
			when 3=>
				LCM_com_data<=LCM_24;	--輸出第二列資料
			when others =>
				LCM_com_data<=LCM_25;	--輸出第二列資料
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

----防彈跳----------------------------------
process(FD(17))
begin
	--S1防彈跳--向上按鈕
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	--S1防彈跳--向下按鈕
	if S2='1' then
		S2S<="000";
	elsif rising_edge(FD(17)) then
		S2S<=S2S+ not S2S(2);
	end if;
end process;


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
