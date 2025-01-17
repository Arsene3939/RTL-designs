--DoReMi、音樂IC 測試
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ----------------------------------------------------
entity CH8_SOUND_1 is
	Port(gckP31,rstP99:in std_logic;--系統頻率,系統reset
		 S1,S2:in std_logic;		--音樂IC按鈕、外激式蜂鳴器按鈕
		 --音樂IC、外激式蜂鳴器輸出
		 MusicIC,Do_Re_Mio:out std_logic
		 );
end entity CH8_SOUND_1;

-- ----------------------------------------------------
architecture Albert of CH8_SOUND_1 is
	--DoReMi_S Driver----------------------------------
	component DoReMi_S is
	Port(CLK,Sound_RESET,S_P_N:in std_logic;	--系統時脈,系統重置
		 ToneS:in integer range 0 to 37;		--音階
		 BeatS:in std_logic_vector(9 downto 0);	--節拍
		 Soundend,Do_Re_Mio:out std_logic);		--音完成,音輸出
	end component;

	signal Sound_RESET,Soundend:std_logic;--重置,音完成
	signal S_WAIT:integer range 0 to 3;			 --等待音結束
	signal BeatS:std_logic_vector(9 downto 0);	 --節拍
	signal ToneS:integer range 0 to 37;			 --音階

	---------------------------------------------------
	signal FD:std_logic_vector(24 downto 0);	--除頻器
	signal UpDn,S_L_UD:std_logic;				--升降音階、節拍
	signal S_L:std_logic_vector(4 downto 0);	--節拍調整倍率
	signal S1S,S2S:std_logic_vector(2 downto 0);--防彈跳計數器
	signal MusicIC_on,Sound_main_reset,S2_off:std_logic:='0';--音樂IC輸出控制,Sound_main重置,S2控制
	
begin

--DoReMi_S Driver--------------------------------------------
U1: DoReMi_S port map(gckp31,Sound_RESET,'1',ToneS,BeatS,Soundend,Do_Re_Mio);

MusicIC<=MusicIC_on;--S1S(2);--音樂IC輸出

--節拍--------------------------------------------
BeatS<="0000001010" + S_L * "00101";	--0.1s~1.65s節拍調整

--按鈕操作------------------------------------
process(FD(18))
begin
	--音樂IC按鈕
	if rising_edge(FD(18)) then
		if S1S(2)='1' then
			--音樂IC輸出控制
			MusicIC_on<=not MusicIC_on;
		end if;
	end if;
	--外激式蜂鳴器按鈕
	if S2S=0 then					--S2按鈕放開
		Sound_main_reset<=S2_off;	--Sound_main on_off控制
	elsif rising_edge(FD(18)) then
		if S2S(2)='1' then
			--Sound_main on_off控制
			Sound_main_reset<=not Sound_main_reset;
		end if;
	end if;
end process;

--Sound_main-----------------------------------------
Sound_main:process(FD(0))
begin
	if Sound_main_reset='0' then
		ToneS<=0;			--音階預設:0
		S_L<="00000";		--節拍調整倍率預設:0
		UpDn<='1';			--升降音階預設:升
		S_L_UD<='1';		--升降節拍預設:升
		Sound_RESET<='0';	--DoReMi_S重置
		S2_off<='0';		--控制Sound_main_reset
	elsif rising_edge(FD(0)) then
		if S_L/="10000" then
			S2_off<='1';			--維持啟動Sound_main_reset
			if Soundend='1' then	--DoReMi_S 音結束了
				Sound_RESET<='0';	--DoReMi_S重置
				if UpDn='1' then	--升音階
					ToneS<=ToneS+1;	--升音階
					if ToneS=36 then--最高一個了
						UpDn<='0';	--改降音階
					end if;
				else	--降音階
					ToneS<=ToneS-1;			--降音階
					if ToneS=1 then			--最低一個了
						UpDn<='1';			--改升音階
						if S_L_UD='1' then	--升節拍(加長)
							S_L<=S_L+1;		--加長
							if S_L=3 then	--最長了
								S_L_UD<='0';--改降節拍(變短)
							end if;
						else				--降節拍
							S_L<=S_L-1;		--變短
							if S_L=1 then	--最短了
								--Sound_main結束了
								S_L<="10000";--防S2按鈕未放開
								--回控Sound_main_reset
								S2_off<='0';
							end if;
						end if;
					end if;
				end if;
			else
				Sound_RESET<='1';	--啟動DoReMi_S
			end if;
		end if;
	end if;
end process Sound_main;

--防彈跳----------------------------------
process(FD(17))
begin
	--S1防彈跳--音樂IC按鈕
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	--S2防彈跳--外激式蜂鳴器按鈕
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