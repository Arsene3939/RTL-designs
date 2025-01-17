--Ws2812B RGB_LED霹靂燈2
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckP31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

entity CH3_WS2812B_2 is	
	port(gckP31,rstP99:in std_logic;--系統重置、系統時脈
		 WS2812Bout:out std_logic);	--WS2812B_Di信號輸出(184)
end entity CH3_WS2812B_2;

architecture Albert of CH3_WS2812B_2 is
	--WS2812B驅動器------------------
	component WS2812B_Driver is
		port(	WS2812BCLK,WS2812BRESET,loadck:in std_logic;--操作頻率,重置,載入ck
				LEDGRBdata:in std_logic_vector(23 downto 0);--色彩資料
				reload,emitter,WS2812Bout:out std_logic		--要求載入,發射狀態,發射輸出 
			);
	end component;
	signal WS2812BCLK,WS2812BRESET,loadck,reload,emitter:std_logic;--操作頻率,重置,載入ck,要求載入,發射狀態
	signal LEDGRBdata:std_logic_vector(23 downto 0);--色彩資料
	
	signal FD:std_logic_vector(24 downto 0);	--系統除頻器
	signal FD2:std_logic_vector(3 downto 0);	--WS2812B_Driver除頻器
	signal SpeedS,WS2812BPCK:std_logic;			--WS2812BP操作頻率選擇,WS2812BP操作頻率
	signal delay:integer range 0 to 127;		--停止時間
	signal LED_WS2812B_N:integer range 0 to 127;--WS2812B個數指標
	constant NLED:integer range 0 to 127:=29;	--WS2812B個數:61個(0~60)
	signal LED_WS2812B_shiftN:integer range 0 to 7;--WS2812B移位個數指標
	signal dir_LR:std_logic_vector(15 downto 0);   --方向控制,WS2812BP操作頻率選擇,
	type LED_T is array(0 to 7) of std_logic_vector(23 downto 0);--圖像格式
	--圖像
	signal LED_WS2812B_T8:LED_T:=(--G       R       B
								"000000001111111100000000",
								"111111110000000000000000",
								"000000000000000011111111",
								"000000000000000000000000",
								"111111111111111100000000",
								"000000001111111111111111",
								"111111110000000011111111",
								"111111111111111111111111"
								);

begin

--WS2812B驅動器-----------------
WS2812BN: WS2812B_Driver port map(WS2812BCLK,WS2812BRESET,loadck,LEDGRBdata,reload,emitter,WS2812Bout);
		  WS2812BRESET<=rstP99;	--系統reset

--色彩資料 ---------------------
LEDGRBdata<=LED_WS2812B_T8((LED_WS2812B_N+LED_WS2812B_shiftN) mod 8);

--WS2812BP操作頻率選擇
WS2812BPCK<=FD(8) when SpeedS='0' else 
			FD(16)when dir_LR(7)='0' else FD(18);--最慢速率

WS2812BP:process(WS2812BPCK)
begin
	if rstP99='0' then
		LED_WS2812B_N<=0;	--從頭開始
		LED_WS2812B_shiftN<=0;--移位0
		dir_LR<=(others=>'0');
		loadck<='0';
		SpeedS<='0';		--加快操作速率
	elsif rising_edge(WS2812BPCK) then
		if loadck='0' then	--等待載入
			loadck<=reload;
		elsif LED_WS2812B_N=NLED then
			SpeedS<='1';			--放慢操作速率
			if emitter='0' then		--已停止發射
				if delay/=0 then	--點亮時間&變化速率
					delay<=delay-1;	--時間遞減
				else
					loadck<='0';	--reemitter
					LED_WS2812B_N<=0;--從頭開始
					dir_LR<=dir_LR+1;--方向控制
					if dir_LR(4)='1' then 
						LED_WS2812B_shiftN<=LED_WS2812B_shiftN+1;--移位遞增
					else
						LED_WS2812B_shiftN<=LED_WS2812B_shiftN-1;--移位遞減
					end if;
					SpeedS<='0';	--加快操作速率
				end if;
			end if;
		else
			loadck<='0';
			LED_WS2812B_N<=LED_WS2812B_N+1;	--調整輸出色彩
			delay<=20;
		end if;
	end if;
end process WS2812BP;

-- 除頻器---------------------
Freq_Div:process(gckP31)
begin
	if rstP99='0' then		--系統重置
		FD<=(others=>'0');
		FD2<=(others=>'0');
		WS2812BCLK<='0';			--WS2812BN驅動頻率
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--除頻器:2進制上數(+1)計數器
		if FD2=9 then				--7~12
			FD2<=(others=>'0');
			WS2812BCLK<=not WS2812BCLK;--50MHz/20=2.5MHz T.=. 0.4us
		else
			FD2<=FD2+1;				--除頻器2:2進制上數(+1)計數器
		end if;
	end if;
end process Freq_Div;


end Albert;