--107.01.01��

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- ----------------------------------------------------
entity DoReMi_S is
	Port(CLK,Sound_RESET,S_P_N:in std_logic;	--�t�ήɯ�,�t�έ��m,��X�w�]
		 ToneS:in integer range 0 to 37;		--����
		 BeatS:in std_logic_vector(9 downto 0);	--�`��
		 Soundend,Do_Re_Mio:out std_logic);		--������,����X
end DoReMi_S;

-- -----------------------------------------------------
architecture Albert of DoReMi_S is
	signal Ftime:integer range 0 to 500000;				--�`���Ǯɶ�
	constant FtimeS:integer range 0 to 500000:=500000;	--�`��w�]��
	signal BeatN:std_logic_vector(9 downto 0);	--�`��

	--12bit
	signal Ftone:integer range 0 to 31;			--������Ǯɶ�
	constant FtoneS:integer range 0 to 31:=25;	--�����w�]��
	signal DoReMi:integer range 0 to 4095;		--�����p��
	signal Do_Re_Mi:std_logic;					--����X
	--�����ഫ�� 12Bit
	type SFT is array (0 to 37) of integer range 0 to 4095;	--12Bit
	constant Tone:SFT:=(0,--SOUND OFF 
						3817,3610,3401,3215,3030,2865,2703,2551,2410,2273,2155,2024,
						1912,1805,1704,1608,1517,1433,1351,1276,1203,1136,1073,1012,
						 956, 902, 851, 803, 759, 716, 676, 638, 602, 568, 536, 506,
						0);

begin

--����X------------------------------------------------------------------
Do_Re_Mio<=Do_Re_Mi;

--------------------------------------------------------------------------
DoReMi_Timer:process(CLK,Sound_RESET)
begin
	if Sound_RESET='0' then
		Ftime<=FtimeS;			--�`���Ǯɶ��]�w
		BeatN<=BeatS;			--�`��]�w
		Ftone<=FtoneS;			--�����w�]�w
		DoReMi<=Tone(ToneS);	--�����ഫ
		Do_Re_Mi<='1' xor S_P_N;--��X�w�]
		Soundend<='0';			--�������X�йw�]������
	elsif rising_edge(CLK) then
		if BeatN/=0 then		--�`�祼����

			--�`�粣�;�
			if Ftime=1 then		--Timer:�`��p��
				Ftime<=FtimeS;	--�`���Ǯɶ����]�w
				if BeatN=1 then	--�`�秹��
					Soundend<='1';--�������X�йw�]����
				end if;
				BeatN<=BeatN-1;	--�Ƹ`��
			else
				Ftime<=Ftime-1;	--�`��p��
			end if;
			
			--�������;�
			if Ftone=1 then			--�����w����F
				Ftone<=FtoneS;		--�����w�����]
				if DoReMi/=0 then	--�D�R��
					if DoReMi=1 then--�����p�ɨ�F
						DoReMi<=Tone(ToneS);	--�����ഫ���]
						Do_Re_Mi<=Not Do_Re_Mi;	--��X�Ϭ�
					else
						DoReMi<=DoReMi-1;	--�ƭ���
					end if;
				end if;
			else
				Ftone<=Ftone-1;	--�����w��
			end if;

		else
			Soundend<='1';			--�������X�йw�]����
			Do_Re_Mi<='1' xor S_P_N;--��X�w�]
		end if;
	end if;
end Process DoReMi_Timer;

--------------------------------------------
end Albert;
