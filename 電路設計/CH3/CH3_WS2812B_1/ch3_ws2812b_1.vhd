--Ws2812B RGB_LED 霹靂燈1
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckP31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

entity CH3_WS2812B_1 is	
	port(gckP31,rstP99:in std_logic;--系統時脈,系統重置
		 WS2812Bout:out std_logic);	--WS2812B_Di信號輸出(184)
end entity CH3_WS2812B_1;

architecture Albert of CH3_WS2812B_1 is
	--WS2812B驅動器--------------------
	component WS2812B_Driver is
		port(	WS2812BCLK,WS2812BRESET,loadck:in std_logic;--操作頻率,重置,載入ck
				LEDGRBdata:in std_logic_vector(23 downto 0);--色彩資料
				reload,emitter,WS2812Bout:out std_logic		--要求載入,發射狀態,發射輸出 
			);
	end component;
	signal WS2812BCLK,WS2812BRESET,loadck,reload,emitter:std_logic;
	--操作頻率,重置,載入ck,要求載入,發射狀態
	signal LEDGRBdata:std_logic_vector(23 downto 0);--色彩資料

	signal FD:std_logic_vector(24 downto 0);	--系統除頻器
	signal FD2:std_logic_vector(3 downto 0);	--WS2812B_Driver除頻器
	signal SpeedS,WS2812BPCK:std_logic;			--WS2812BP操作頻率選擇,WS2812BP操作頻率
	signal delay:integer range 0 to 127;		--停止時間
	signal LED_WS2812B_N:integer range 0 to 127;--WS2812B個數指標
	constant NLED:integer range 0 to 127:=29;	--WS2812B個數:61個(0~60)
	signal RC,GC,BC:std_logic_vector(7 downto 0);--紅,綠,藍色

begin

--WS2812B驅動器--------------------------
WS2812BN: WS2812B_Driver port map(WS2812BCLK,WS2812BRESET,loadck,LEDGRBdata,reload,emitter,WS2812Bout);
		  WS2812BRESET<=rstP99;	--系統重置

--色彩資料 ------------------------------
LEDGRBdata<=GC & RC & BC;

--WS2812BP操作頻率選擇
WS2812BPCK<=FD(8) when SpeedS='0' else FD(16);--最慢速率

--WS2812BP 主控器 -----------------------
WS2812BP:process(WS2812BPCK)
variable cc:integer range 0 to 15;				--色階
variable RGBcase:std_logic_vector(3 downto 0);	--色盤種類
variable RA,GA,BA:std_logic_vector(1 downto 0);	--紅,綠,藍調色狀態
begin
	if rstP99='0' then
		LED_WS2812B_N<=NLED;	--從頭開始
		RGBcase:=(others=>'0');	--色盤種類預設
		cc:=0;					--色階預設
		loadck<='0';			--等待載入
		SpeedS<='1';			--加快操作速率
	elsif rising_edge(WS2812BPCK) then
		if loadck='0' then	--等待載入
			loadck<=reload;	--是否載入
		elsif LED_WS2812B_N=NLED then	--輸出個數完成
			SpeedS<='1';			--放慢操作速率
			if emitter='0' then		--已停止發射
				if delay/=0 then	--點亮時間&變化速率
					delay<=delay-1;	--時間遞減
				else
					loadck<='0';	--reemitter
					LED_WS2812B_N<=0;--從頭開始
					SpeedS<='0';	--加快操作速率
					if cc=0 then
						cc:=8;		--8色階數
						case RGBcase is
							when "0000"=>
								RC<=(others=>'0');	--紅全暗
								GC<=(others=>'0');	--綠全暗
								BC<=(others=>'0');	--藍全暗
								RA:="10";	--8段遞增
								GA:="00";	--不變
								BA:="00";	--不變
							when "0001"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="00";	--不變
								GA:="10";	--8段遞增
								BA:="00";	--不變
							when "0010"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="00";	--不變
								GA:="00";	--不變
								BA:="10";	--8段遞增
							when "0011"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="10";	--8段遞增
								GA:="10";	--8段遞增
								BA:="00";	--不變
							when "0100"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="10";	--8段遞增
								GA:="00";	--不變
								BA:="10";	--8段遞增
							when "0101"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="00";	--不變
								GA:="10";	--8段遞增
								BA:="10";	--8段遞增
							when "0110"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="10";	--8段遞增
								GA:="10";	--8段遞增
								BA:="10";	--8段遞增
							when "0111"=>
								RC<=(others=>'1');	--紅全亮
								GC<=(others=>'1');	--綠全亮
								BC<=(others=>'1');	--藍全亮
								RA:="01";	--8段遞減
								GA:="00";	--不變
								BA:="00";	--不變
							when "1000"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="00";	--不變
								GA:="01";	--8段遞減
								BA:="00";	--不變
							when "1001"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="00";	--不變
								GA:="00";	--不變
								BA:="01";	--8段遞減
							when "1010"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="01";	--8段遞減
								GA:="01";	--8段遞減
								BA:="00";	--不變
							when "1011"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="01";	--8段遞減
								GA:="00";	--不變
								BA:="01";	--8段遞減
							when "1100"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="00";	--不變
								GA:="01";	--8段遞減
								BA:="01";	--8段遞減
							when "1101"=>	
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="01";	--8段遞減
								GA:="01";	--8段遞減
								BA:="01";	--8段遞減
							when "1110"=>	
								RC<=(others=>'0');	--紅全暗
								GC<=(others=>'1');	--藍全亮
								BC<=(others=>'1');	--藍全亮
								RA:="10";	--8段遞增
								GA:="01";	--8段遞減
								BA:="01";	--8段遞減
							when others=>
								RC<=(others=>'1');	--藍全亮
								GC<=(others=>'0');	--綠全暗
								BC<=(others=>'1');	--藍全亮
								RA:="01";	--8段遞減
								GA:="10";	--8段遞增
								BA:="01";	--8段遞減
						end case;
						RGBcase:=RGBcase+1;
					else
						if RA="10" then
							RC<=RC(6 downto 0) & '1';	--遞增
						elsif RA="01" then
							RC<='0' & RC(7 downto 1);	--遞減
						end if;
						if GA="10" then
							GC<=GC(6 downto 0) & '1';	--遞增
						elsif GA="01" then
							GC<='0' & GC(7 downto 1);	--遞減
						end if;
						if BA="10" then
							BC<=BC(6 downto 0) & '1';	--遞增
						elsif BA="01" then
							BC<='0' & BC(7 downto 1);	--遞減
						end if;
						cc:=cc-1;	--色階數 遞減
					end if;

				end if;
			end if;
		else
			loadck<='0';
			LED_WS2812B_N<=LED_WS2812B_N+1;	--輸出個數遞增
			delay<=80;
		end if;

	end if;
end process WS2812BP;

-- 除頻器--------------------------------
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