--RGB16x16燈號圖形測試
--106.12.30版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- -----------------------------------------------------
entity CH4_RGB16x16_2 is
port(gckP31,rstP99:in std_logic;	--系統頻率,系統reset
	 --DM13A 輸出
	 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;
	 --186,187,189,194,188,185
	 --Scan 輸出
	 Scan_DCBAo:buffer std_logic_vector(3 downto 0)
	 --198,197,196,195
    );
end entity CH4_RGB16x16_2;

-- -----------------------------------------------------
architecture Albert of CH4_RGB16x16_2 is
	component DM13A_Driver_RGB is
	port(--DM13A_Driver_RGB操作頻率,重置,ALE控制,OE控制,方向控制,反相控制
		 DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:in std_logic;
		 startbit:in integer range 0 to 15;		 	--開始操作位元
		 maskRGB:in std_logic_vector(5 downto 0);	--罩蓋操作位元
		 --mask (5):0:disable 1:enable, (4..3)00:load,01:xor:10:or,11:and RGB
		 LED_R,LED_G,LED_B:in std_logic_vector(15 downto 0);	--R G B 圖形位元
		 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;--DM13A 硬體操作位元
		 DM13A_Sendok:out std_logic);	--DM13A_Driver_RGB完成操作位元
	end component;
		 --DM13A_Driver_RGB操作頻率,重置,ALE控制,OE控制,方向控制,反相控制
	signal DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:std_logic;
	signal startbit:integer range 0 to 15;					--開始操作位元
	signal maskRGB:std_logic_vector(5 downto 0):="000000";--罩蓋操作位元
	signal LED_R,LED_G,LED_B:std_logic_vector(15 downto 0);	--R G B 圖形位元
	signal DM13A_Sendok:std_logic;							--DM13A_Driver_RGB完成操作位元

	-- -----------------------------------------------------	
	signal FD:std_logic_vector(24 downto 0);	--系統除頻器
	signal G_step:integer range 0 to 3;			--圖形取樣指標
	signal RGB_point:integer range 0 to 15;		--圖形取樣指標
			--重置					clk						clk				clk
	signal RG,RGB16X16_SCAN_reset,scan_1T,RGB16X16_TP_clk,RGB16X16_P_clk,RGB16X16_SCAN_p_clk:std_logic;
	signal T_runstep:integer range 0 to 7;		--執行階段
	type RGB16x16_T1 is array(0 to 15) of std_logic_vector(15 downto 0);--圖像格式
	signal RGB16x16_R,RGB16x16_G:RGB16x16_T1;			--1維陣列
	--圖像
	type RGB16x16_T2 is array(0 to 3) of RGB16x16_T1;	--2維陣列
	--圖像:請參考小綠人編碼.doc
	constant RGB16x16_GD:RGB16x16_T2:=(	(X"0000",X"0000",X"0000",X"0000",X"0003",X"060F",X"6F3F",X"DFF9",X"DFF0",X"DFFF",X"DF3E",X"6606",X"4004",X"0000",X"0000",X"0000"),
										(X"0000",X"0000",X"0000",X"0180",X"03E3",X"676F",X"D63F",X"DFF9",X"DFF8",X"DFBD",X"69CF",X"40C7",X"40C1",X"0080",X"0000",X"0000"),
										(X"0004",X"018C",X"03CE",X"07E6",X"0E47",X"0C0E",X"6C3C",X"DFF8",X"DFF8",X"DFB9",X"D39B",X"61CF",X"40ED",X"41C1",X"0180",X"0080"),
										(X"0000",X"0000",X"0000",X"0180",X"03E3",X"676F",X"D63F",X"DFF9",X"DFF8",X"DFBD",X"69CF",X"40C7",X"40C1",X"0080",X"0000",X"0000"));
						
-- --------------------------
begin

----DM13A_Driver_RGB
 DM13ACLK<=FD(2);
 U1: DM13A_Driver_RGB 
	port map(	DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01,startbit,maskRGB,
				LED_R,LED_G,LED_B,
				DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo,
				DM13A_Sendok);
 
-- --------------------------
--除頻器
Freq_Div:process(gckP31)			--系統頻率gckP31:50MHz
begin
	if rstP99='0' then	--系統重置
		FD<=(others=>'0');			--除頻器:歸零
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--除頻器:2進制上數(+1)計數器
	end if;
end process Freq_Div;

-----------------------------------------------------------
RGB16X16_TP_clk<=FD(22);--約6Hz ,0.167s

--時間配置管理器
RGB16X16_TP:process(RGB16X16_TP_clk,rstP99)
variable TT:integer range 0 to 511;		--階段計時器
variable T_step:integer range 0 to 7;	--階段
begin
if rstP99='0' then
	RG<='1';			--選圖來源1
	TT:=40;				--階段時間設定
	T_runstep<=0;		--R階段預設0
	T_step:=0;			--R階段
elsif rising_edge(RGB16X16_TP_clk) then
	 TT:=TT-1;						--階段時間倒數
	 if TT=0 then					--階段時間到
		if T_step=6 then			--已完成最後階段
			T_step:=0;				--階段重新開始
		else
			T_step:=T_step+1;		--下一階段
		end if;
		T_runstep<=T_step;			--交付執行階段
		case T_step is		--階段參數設定
			when 0=>		--R
				TT:=40;				--階段時間設定
			when 1=>		--R->G,G靜置
				TT:=25;				--階段時間設定
			when 2=>		--gGgG:正常步行
				RG<='0';			--選圖來源0
				TT:=120;			--階段時間設定
			when 3=>		--gGgG:快步行
				TT:=30;				--階段時間設定
			when 4=>		--gGgG:急步行
				TT:=30;				--階段時間設定
			when 5=>		--G靜置
				RG<='1';			--選圖來源1
				TT:=15;				--階段時間設定
			when others=>	--6:G->R,R靜置
				TT:=15;				--階段時間設定
		end case;
	end if;
end if;
end process RGB16X16_TP;

--RGB16X16_P執行速度變換---------------------------
RGB16X16_P_clk<=FD(7) when T_runstep=4 else	--急步行速度
				FD(8) when T_runstep=3 else	--快步行速度
				FD(9);						--正常步行速度

RGB16X16_P:process(RGB16X16_P_clk,rstP99)
variable frames:integer range 0 to 31;	--停留時間控制
variable i:integer range 0 to 31;		--紅轉綠次數
begin
if rstP99='0' then
	RGB16X16_SCAN_reset<='0';--掃瞄off
	--靜止圖形預設:請參考小紅人編碼.doc
	RGB16x16_R<=(X"0000",X"0000",X"0001",X"07C1",X"0FF3",X"6FEF",X"F81F",X"DAB8",X"DAB8",X"F81F",X"6FEF",X"0FF3",X"07C1",X"0001",X"0000",X"0000");
	RGB16x16_G<=((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),
				 (others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),
				 (others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'));
elsif rising_edge(RGB16X16_P_clk) then
	RGB16X16_SCAN_reset<='1';	--啟動掃瞄
	case T_runstep is	--階段執行
		when 0=>	--紅靜置
			i:=16;			--紅轉綠次數預設
			frames:=3;		--停留時間預設
		when 1=>	--紅轉綠
			if i=0 then		--綠靜置
				G_step<=0;				--步行圖0
				frames:=10;				--停留時間預設
			elsif scan_1T='1' then		--RGB16X16_SCAN_p回信號
				frames:=frames-1;		--停留時間次數遞減
				if frames=0 then		--frame停留時間到
					RGB16x16_R(i-1)<=RGB16x16_G(i-1);--左至右轉換
					RGB16x16_G(i-1)<=RGB16x16_R(i-1);
					frames:=3;			--停留時間預設
					i:=i-1;				--紅轉綠次數遞減
				end if;
			end if;			
		when 2|3|4=>--動畫
			if scan_1T='1' then			--RGB16X16_SCAN_p回信號
				frames:=frames-1;		--掃瞄frame次數遞減
				if frames=0 then		--frame停留時間到
					G_step<=G_step+1;		--調整步行圖0123
					if T_runstep=2 then		--正常步行
						frames:=10;			--停留時間預設
					elsif T_runstep=3 then	--快步行
						frames:=10;			--停留時間預設
					else					--急步行
						frames:=10;			--停留時間預設
					end if;
				end if;
			end if;
		when 5=>	--綠靜置
			frames:=3;		--停留時間預設
		when others=>--綠轉紅
			if i=16 then	--紅靜置
				null;
			elsif scan_1T='1' then	--RGB16X16_SCAN_p回信號
				frames:=frames-1;	--停留時間次數遞減
				if frames=0 then	--frame停留時間到
					RGB16x16_R(i+1)<=RGB16x16_G(i+1);--右至左轉換
					RGB16x16_G(i+1)<=RGB16x16_R(i+1);
					frames:=3;		--停留時間預設
					i:=i+1;			--綠轉紅次數遞增
				end if;
			end if;
	end case;
end if;
end process;

-------------------------------------------------------------
BIT_R_L<='0';		--方向變換
not01<='0';			--反相變換
startbit<=0;		--從15位元開始
maskRGB<="000000";--直接輸出

RGB_point<=conv_integer(Scan_DCBAo);	--轉換圖形取樣指標
LED_G<=RGB16x16_G(RGB_point) when RG='1' else RGB16x16_GD(G_step)(RGB_point);	--G 圖案選擇取圖
LED_R<=RGB16x16_R(RGB_point) when RG='1' else (others=>'0');					--R 圖案選擇取圖
LED_B<=(others=>'0');															--B 圖案選擇取圖

--RGB16X16_SCAN_p執行速度變換------------------------------------------
RGB16X16_SCAN_p_clk<=FD(6) when T_runstep=4 else	--急步行速度
					 FD(7) when T_runstep=3 else	--快步行速度
					 FD(8);							--正常步行速度

RGB16X16_SCAN_p:process(RGB16X16_SCAN_p_clk,RGB16X16_SCAN_reset)
variable frame:integer range 0 to 15;	--15~0:1 frame
variable T:integer range 0 to 255;		--每一掃瞄停留時間計時器
begin
if RGB16X16_SCAN_reset='0' then
	Scan_DCBAo<="0000";	--掃瞄預設
	DM13A_RESET<='0';	--重置DM13A_Driver_RGB
	DM13ALE<='0';		--無更新資料預設
	DM13AOE<='1';		--DM13A off
	frame:=0;			--frame數預設0
	scan_1T<='0';		--未完成1次掃瞄
elsif rising_edge(RGB16X16_SCAN_p_clk) then
	if DM13ALE='0' and DM13AOE='1' then	--無更新資料且顯示已關閉
		if DM13A_RESET='0' then			--尚未啟動DM13A_Driver_RGB
			DM13A_RESET<='1';			--啟動DM13A_Driver_RGB
			Scan_DCBAo<=Scan_DCBAo-1;	--調整掃瞄
			scan_1T<='0';
		elsif DM13A_Sendok='1' then		--傳送完成
			DM13A_RESET<='0';			--重置DM13A_Driver_RGB
			DM13ALE<='1';				--更新顯示資料
		end if;
		T:=0;							--顯示計時歸零
	else
		DM13ALE<='0';				--顯示資料不更新
		DM13AOE<='0';				--顯示
		T:=T+1;						--顯示計時
		if T=50 then				--顯示計時到
			DM13AOE<='1';			--不顯示
		elsif T=49 then
			if Scan_DCBAo=0 then	--完成15~0掃瞄
				if frame=4 then		--
					scan_1T<='1';	--完成5frame
					frame:=0;		--重新數frame
				else
					frame:=frame+1;	--完成1frame
				end if;
			end if;	
		end if;	
	end if;
end if;
end process RGB16X16_SCAN_p;

end Albert;