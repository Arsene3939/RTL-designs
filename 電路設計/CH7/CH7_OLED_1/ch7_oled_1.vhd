--oLED 測試
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- -----------------------------------------------------
entity CH7_OLED_1 is
port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
	 --oLED SSD1306 128x64
	 oLED_SCL:out std_logic;	--介面IO:SCL(50)
	 oLED_SDA:inout std_logic	--介面IO:SDA,有接提升電阻(52)
	 );
end entity CH7_OLED_1;

-- -----------------------------------------------------
architecture Albert of CH7_OLED_1 is
	-- ============================================================================
	--oLED SSD1306 Driver --107.01.01版
	component SSD1306_Driver is
		port(I2CCLK,RESET:in std_logic;					--系統時脈,系統重置
			 SA0:in std_logic;							--裝置碼位址
		     CoDc:in std_logic_vector(1 downto 0);		--Co & D/C
		     Data_byte:in std_logic_vector(7 downto 0);	--資料輸入
		     reLOAD:out std_logic;						--載入旗標:0 可載入Data Byte
		     LoadCK:in std_logic;						--載入時脈
		     RWN:in integer range 0 to 15;				--嘗試讀寫次數
		     I2Cok,I2CS:buffer std_logic;				--I2Cok,CS 狀態
		     SCL:out std_logic;							--介面IO:SCL,如有接提升電阻時可設成inout
		     SDA:inout std_logic						--SDA輸入輸出
		   );
	end component SSD1306_Driver;
	signal oLED_I2CCLK,oLED_RESET:std_logic;			--系統時脈,系統重置
	signal oLED_SA0:std_logic:='0';						--裝置碼位址
	signal oLED_CoDc:std_logic_vector(1 downto 0);		--Co & D/C
	signal oLED_Data_byte:std_logic_vector(7 downto 0);	--資料輸入
	signal oLED_reLOAD:std_logic;						--載入旗標:0 可載入Data Byte
	signal oLED_LoadCK:std_logic;						--載入時脈
	signal oLED_RWN:integer range 0 to 15;				--嘗試讀寫次數
	signal oLED_I2Cok,oLED_I2CS:std_logic;				--I2Cok,CS 狀態
	
	-- --------------------------------------------------------------------------------
	----oLED指令&資料表格式:
	type oLED_T is array (0 to 38) of std_logic_vector(7 downto 0);
	signal oLED_RUNT:oLED_T;
	--oLED=0:oLED初始化128x64
	constant oLED_IT:oLED_T:=(	X"26",--0 長度
								X"AE",--1 display off
							
								X"D5",--2 設定除頻比及振盪頻率
								
								X"80",--3 [7:4]振盪頻率,[3:0]除頻比
								
								X"A8",--4 設COM N數
								X"3F",--5 1F:32COM(COM0~COM31 N=32),3F:64COM(COM0~COM31 N=64)
								
								X"40",--6 設開始顯示行:0(SEG0)
								
						X"E3",--X"A1",--7 non Remap(column 0=>SEG0),A1 Remap(column 127=>SEG0)
								
								X"C8",--8 掃瞄方向:COM0->COM(N-1) COM31,C8:COM(N-1) COM31->COM0
								
								X"DA",--9 設COM Pins配置
								X"12",--10 02:順配置(Disable COM L/R remap),12:交錯配置(Disable COM L/R remap),22:順配置(Enable COM L/R remap),32:交錯配置(Enable COM L/R remap)
								
								X"81",--11 設對比
								X"EF",--12 越大越亮
								
								X"D9",--13 設預充電週期
								X"F1",--14 [7:4]PHASE2,[3:0]PHASE1
								
								X"DB",--15 設Vcomh值
								X"30",--16 00:0.65xVcc,20:0.77xVcc,30:0.83xVcc
								
								
								X"A4",--17 A4:由GDDRAM決定顯示內容,A5:全部亮(測試用)
								
								X"A6",--18 A6:正常顯示(1亮0不亮),A7反相顯示(0亮1不亮)
								
								X"D3",--19 設顯示偏移量Offset
								X"00",--20 00
								
						X"E3",--X"20",--21 設GDDRAM pointer模式
						X"E3",--X"02",--22 00:水平模式,  01:垂直模式,02:頁模式
								
								--頁模式column start address=[higher nibble,lower nibble] [00]
						X"E3",--X"00",--23 頁模式下設column start address(lower nibble):0
								
						X"E3",--X"10",--24 頁模式下設column start address(higher nibble):0
								
						X"E3",--X"B0",--25 頁模式下設Page start address
								
								X"20",--26 設GDDRAM pointer模式
								X"00",--27 00:水平模式,  01:垂直模式,02:頁模式
								
								X"21",--28 水平模式下設行範圍:
								X"00",--29 行開始位置0(Column start address)
								X"7F",--30 行結束位置127(Column end address)
								
								X"22",--31 水平模式下設頁範圍:
								X"00",--32 頁開始位置0(Page start address)
								X"07",--33 頁結束位置3(Page end address)
								
								X"A1",--34 non Remap(column 0=>SEG0),A1 Remap(column 127=>SEG0)
								
								X"8D",--35 設充電Pump
								X"14",--36 14:開啟,10:關閉
								
								X"AF",--37 display on
								X"E3" --38 nop
							);

	signal OLED_COM_POINTER,OLED_COM_POINTERs:integer range 0 to 63;--命令操作指標
	signal OLED_DATA_POINTER:integer range 0 to 127;--行碼
	signal GDDRAM_i:integer range 0 to 15;			--oled頁碼
	signal GDDRAMo,GDDRAMo1,GDDRAM2,GDDRAM3,GDDRAM4,GDDRAM5:std_logic_vector(7 downto 0);--通道圖資
	
	-- ----------------------------------------------------------------------------------------
	signal FD:std_logic_vector(24 downto 0);		--除頻器
	signal oLED_P_RESET,oLED_P_ok:std_logic;		--oLED_P重置、完成
	signal Vline:integer range 0 to 127;			--垂直線位置
	signal Hline:std_logic_vector(63 downto 0);		--水平線樣板
	signal HN:integer range 0 to 255;				--水平線操作次數
	signal OLEDtestM:std_logic_vector(2 downto 0);	--oLED 圖資通道及功能選擇
	signal OLEDset_P_RESET,OLEDset_P_ok,not01,RL:std_logic;--OLEDset_P重置、完成 ,反相、方向操作旗標
	signal times:integer range 0 to 2047;--停止時間

begin

--=====================================================================================
--oLED---------------------------
U1: SSD1306_Driver port map(oLED_I2CCLK,oLED_RESET,'0',oLED_CoDc,oLED_Data_byte,oLED_reLOAD,oLED_LoadCK,3,oLED_I2Cok,oLED_I2CS,oLED_SCL,oLED_SDA);

-- --------------------------
oLED_test_Main:process(FD(17))		--oLED_test_Main主控器操作速率
begin
	if rstP99='0' then			--系統重置
		OLEDtestM<="000";		--oLED 圖資通道及功能選擇
		OLEDset_P_RESET<='0';	--OLEDset_P控制旗標:重置
		oLED_COM_POINTERs<=1;	--oLED命令指標:重下命令
		not01<='0';				--0:正常
		RL<='0';				--0:方向預設
		Vline<=0;				--0:垂直線位置預設
		Hline<=(others=>'0');	--0:水平線位置預設
		HN<=0;					--水平操作次數預設
		times<=200;				--停止時間預設
	elsif rising_edge(FD(17)) then
		if OLEDset_P_ok='1' then	--等待OLEDset_P完成
			OLED_COM_POINTERs<=conv_integer(OLED_RUNT(0))+1;	--oLED命令指標:不再下命令
			times<=times-1;		--停止計時
			if times=0 then		--計時到
				OLEDset_P_RESET<='0';	----oLED_P控制旗標:重置
				case OLEDtestM is	--選功能
					when "000" =>	--000 全暗
						OLEDtestM<="001";	--0001 全亮
						times<=200;
					when "001" =>	--001 全亮
						OLEDtestM<="010";	--0010 Vline:垂直線操作功能
						times<=0;
					when "010"|"011"|"100"=>--0010 011 0100:Vline垂直線操作功能
						times<=0;	--重設計時
						if Vline=0 and RL='1' then	--功能該切換了
							RL<='0';--方向重設
							if OLEDtestM="010" then
								OLEDtestM<="011";	--顯示資料通道選擇
							elsif OLEDtestM="011" then
								OLEDtestM<="100";	--顯示資料通道選擇
							else
								OLEDtestM<="101";	--顯示資料通道選擇及水平線操作變換
								Hline<=(Hline'range=>'0')+'1';
							end if;
						elsif Vline=127 and RL='0' then	--該變方向了
							RL<='1';			--方向變換
						else
							if RL='0' then
								Vline<=Vline+1;	--L->R
							else
								Vline<=Vline-1;	--R->L
							end if;
						end if;
					when "101"=>	--Hline 水平線操作
						times<=5;	--重設計時
						if HN=0 and RL='1' then
							RL<='0';--方向重設
							OLEDtestM<="110";		--水平線操作變換
						elsif HN=63 and RL='0' then	--該變方向了
							RL<='1';--方向變換
							HN<=64;	--設64次
						else
							if RL='0' then
								Hline<=Hline(62 downto 0) & '0';	--U->D
								HN<=HN+1;
							else
								Hline<='0' & Hline(63 downto 1);	--D->U
								HN<=HN-1;
							end if;
						end if;
					 when others =>
						times<=5;	--重設計時
						if HN=0 and RL='1' then
							RL<='0';			--方向重設
							OLEDtestM<="000";	--功能重來
							not01<=not not01;	--反相操作
							times<=200;	--重設計時
						elsif HN=128 and RL='0' then	--該變方向了
							RL<='1';	--方向變換
						else
							if RL='0' then
								Hline<=Hline(62 downto 0) & not Hline(63);	--U->D
								HN<=HN+1;
							else
								Hline<=not Hline(0) & Hline(63 downto 1);	--D->U
								HN<=HN-1;
							end if;
						end if;
				end case;
			end if;
		else
			OLEDset_P_RESET<='1';	--重啟OLEDset_P
		end if;
	end if;
end process oLED_test_Main;

--=====================================================================================
--oLED顯示器
--頁顯示資料解碼
--------------------------------------------------------------------------------
--10垂直線 解碼
GDDRAM2<="11111111" when Vline=oLED_DATA_POINTER else "00000000";
GDDRAM3<="11111111" when Vline>=oLED_DATA_POINTER else "00000000";
GDDRAM4<="11111111" when (127-Vline)<=oLED_DATA_POINTER else "00000000";

--11水平線 解碼
GDDRAM5<=Hline(7 downto 0) when GDDRAM_i=0 else
		 Hline(15 downto 8) when GDDRAM_i=1 else
		 Hline(23 downto 16) when GDDRAM_i=2 else
		 Hline(31 downto 24) when GDDRAM_i=3 else
		 Hline(39 downto 32) when GDDRAM_i=4 else
		 Hline(47 downto 40) when GDDRAM_i=5 else
		 Hline(55 downto 48) when GDDRAM_i=6 else
		 Hline(63 downto 56);

--顯示資料通道選擇---------------------------------------------------------------	
with oLEDtestM select	
GDDRAMo1<="00000000" when "000",
		  "11111111" when "001",
		  GDDRAM2	 when "010",
		  GDDRAM3	 when "011",
		  GDDRAM4	 when "100",
		  GDDRAM5	 when others;		  
		  
GDDRAMo<=GDDRAMo1 when not01='0' else not GDDRAMo1; --反相解碼
	 
--OLEDset_P---------------------------------------------------
--OLED掃瞄管控
OLEDset_P:process(gckP31)
begin
	if OLEDset_P_RESET='0' then	--OLED掃瞄管控重置
		OLED_P_RESET<='0';	--OLED_P重置
		OLEDset_P_ok<='0';	--OLED掃瞄管控尚未完成
	elsif rising_edge(gckP31) then
		if OLEDset_P_ok='0' then		--OLED掃瞄管控尚未完成
			if OLED_P_RESET='1' then	--OLED_P已啟動
				if OLED_P_ok='1' then	--OLED_P已完成
					OLEDset_P_ok<='1';	--OLED掃瞄管控已完成
				end if;
			else
				OLED_P_RESET<='1';	--啟動OLED_P
			end if;
		end if;
	end if;
end process OLEDset_P;

--OLED_P------------------------------------------------------------------------------
--				命令                                               顯示資料
OLED_Data_byte<=OLED_RUNT(OLED_COM_POINTER) when OLED_CoDc="10" else GDDRAMo;
OLED_I2CCLK<=FD(3);	--OLED操作速率

OLED_P:process(gckP31,OLED_P_RESET)
	variable SW:Boolean;				--狀態控制旗標
begin
	if OLED_P_RESET='0' then
		OLED_RESET<='0';				--SSD1306_I2C2Wdriver2重置
		OLED_RUNT<=OLED_IT;				----OLED初始化設定表
		OLED_COM_POINTER<=OLED_COM_POINTERs;--命令起點
		OLED_DATA_POINTER<=0;
		GDDRAM_i<=0;					--GDDRAM 指標i
		OLED_P_ok<='0';					--OLED_P 完成指標
		SW:=true;						--載入狀態旗標
		OLED_CoDc<="10";	--word mode ,command
	elsif rising_edge(gckP31) then
		OLED_LoadCK<='0';
		if OLED_RUNT(0)>=OLED_COM_POINTER then	--傳送命令
			if OLED_RESET='0' then
				OLED_RESET<='1';		--啟動 SSD1306_I2C2Wdriver2
			elsif SW=true then
				OLED_COM_POINTER<=OLED_COM_POINTER+1;
				SW:=false;
			elsif OLED_reLOAD='0' then 	--載入
				OLED_LoadCK<='1';
				SW:=true;
			end if;
		elsif OLED_CoDc="10" then	--切換成byte模式,連續傳送顯示資料
			OLED_CoDc<="01";		--byte mode,display data
			SW:=true;
		elsif GDDRAM_i<8 then		--傳送顯示資料(畫面更新)
			if OLED_RESET='0' then	--尚未啟動 SSD1306_I2C2Wdriver2
				OLED_RESET<='1';	--啟動 SSD1306_I2C2Wdriver2
				SW:=false;
			else
				if OLED_reLOAD='0' then
					if SW then	--載入
						OLED_LoadCK<='1';
						SW:=false;
					else
						OLED_DATA_POINTER<=OLED_DATA_POINTER+1;	--下一行
						if OLED_DATA_POINTER=127 then			--資料換頁
							GDDRAM_i<=GDDRAM_i+1;
						end if;
						SW:=true;
					end if;
				end if;
			end if;
		else
			OLED_P_ok<=OLED_I2Cok;
		end if;
	end if;
end process OLED_P;

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
end  Albert;
	
