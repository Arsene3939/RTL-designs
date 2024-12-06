--107.01.01版

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ----------------------------------------------------
entity DoReMi_S is
	Port(CLK,Sound_RESET,S_P_N:in std_logic;	--系統時脈,系統重置,輸出預設
		 ToneS:in integer range 0 to 37;		--音階
		 BeatS:in std_logic_vector(9 downto 0);	--節拍
		 Soundend,Do_Re_Mio:out std_logic);		--音完成,音輸出
end DoReMi_S;

-- -----------------------------------------------------
architecture Albert of DoReMi_S is
	signal Ftime:integer range 0 to 500000;				--節拍基準時間
	constant FtimeS:integer range 0 to 500000:=500000;	--節拍預設值
	signal BeatN:std_logic_vector(9 downto 0);	--節拍

	--12bit
	signal Ftone:integer range 0 to 31;			--音階基準時間
	constant FtoneS:integer range 0 to 31:=25;	--音階預設值
	signal DoReMi:integer range 0 to 4095;		--音階計時
	signal Do_Re_Mi:std_logic;					--音輸出
	--音階轉換表 12Bit
	type SFT is array (0 to 37) of integer range 0 to 4095;	--12Bit
	constant Tone:SFT:=(0,--SOUND OFF 
						3817,3610,3401,3215,3030,2865,2703,2551,2410,2273,2155,2024,
						1912,1805,1704,1608,1517,1433,1351,1276,1203,1136,1073,1012,
						 956, 902, 851, 803, 759, 716, 676, 638, 602, 568, 536, 506,
						0);

begin

--音輸出------------------------------------------------------------------
Do_Re_Mio<=Do_Re_Mi;

--------------------------------------------------------------------------
DoReMi_Timer:process(CLK,Sound_RESET)
begin
	if Sound_RESET='0' then
		Ftime<=FtimeS;			--節拍基準時間設定
		BeatN<=BeatS;			--節拍設定
		Ftone<=FtoneS;			--音階預設定
		DoReMi<=Tone(ToneS);	--音階轉換
		Do_Re_Mi<='1' xor S_P_N;--輸出預設
		Soundend<='0';			--音完成旗標預設未完成
	elsif rising_edge(CLK) then
		if BeatN/=0 then		--節拍未完成

			--節拍產生器
			if Ftime=1 then		--Timer:節拍計時
				Ftime<=FtimeS;	--節拍基準時間重設定
				if BeatN=1 then	--節拍完成
					Soundend<='1';--音完成旗標預設完成
				end if;
				BeatN<=BeatN-1;	--數節拍
			else
				Ftime<=Ftime-1;	--節拍計時
			end if;
			
			--音階產生器
			if Ftone=1 then			--音階預除到了
				Ftone<=FtoneS;		--音階預除重設
				if DoReMi/=0 then	--非靜音
					if DoReMi=1 then--音階計時到了
						DoReMi<=Tone(ToneS);	--音階轉換重設
						Do_Re_Mi<=Not Do_Re_Mi;	--輸出反相
					else
						DoReMi<=DoReMi-1;	--數音階
					end if;
				end if;
			else
				Ftone<=Ftone-1;	--音階預除
			end if;

		else
			Soundend<='1';			--音完成旗標預設完成
			Do_Re_Mi<='1' xor S_P_N;--輸出預設
		end if;
	end if;
end Process DoReMi_Timer;

--------------------------------------------
end Albert;
