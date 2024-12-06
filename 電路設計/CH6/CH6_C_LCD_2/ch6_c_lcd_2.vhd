--����LCM �ϥ�:LCM_4bit_driver
--�Ʀ�q�l��24�p�ɨ�
--106.12.30��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- ---------------------------------------
entity CH6_C_LCD_2 is	
	port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset(�k�s)
		 S1,S2,S3,S8:in std_logic;	--��,��,���W���s,�]�w/�Ȱ�/�p�ɫ��s
		 --LCD 4bit����
		 DB_io:inout std_logic_vector(3 downto 0);
		 RSo,RWo,Eo:out std_logic
		 );
end entity CH6_C_LCD_2;

-- -----------------------------------------
architecture Albert of CH6_C_LCD_2 is
	--------------------------------------------------------------------------------------
	--����LCM 4bit driver(WG14432B5)
	component LCM_4bit_driver is
	port(LCM_CLK,LCM_RESET:in std_logic;			--�ާ@�t�v,���m
		 RS,RW:in std_logic;						--�Ȧs�����,Ū�g�X�п�J
		 DBi:in std_logic_vector(7 downto 0);		--LCM_4bit_driver ��ƿ�J
		 DBo:out std_logic_vector(7 downto 0);		--LCM_4bit_driver ��ƿ�X
		 DB_io:inout std_logic_vector(3 downto 0);	--LCM DATA BUS����
		 RSo,RWo,Eo:out std_logic;					--LCM �Ȧs�����,Ū�g,�P�श��
		 LCMok,LCM_S:out boolean					--LCM_4bit_driver����,���~�X��
		 );
	end component;

	signal LCM_RESET,RS,RW:std_logic;				--LCM_4bit_driver���m,LCM�Ȧs�����,Ū�g�X��
	signal DBi,DBo:std_logic_vector(7 downto 0);	--LCM_4bit_driver�R�O�θ�ƿ�J�ο�X
	signal LCMok,LCM_S:boolean;						--LCM_4bit_driver�����@�~�X��,���~�H��
	
	--------------------------------------------------------------
	----����LCM���O&��ƪ�榡:
	----(�`��,���O��,���O...���...........
	----�^�ƫ�LCM 4�줸�ɭ�,2�C���

	type LCM_T is array (0 to 20) of std_logic_vector(7 downto 0);
	constant LCM_IT:LCM_T:=(X"0F",X"06",----���嫬LCM 4�줸�ɭ�
							"00101000","00101000","00101000",--4�줸�ɭ�
							"00000110","00001100","00000001",--ACC+1��ܹ��L����,��ܹ�on�L��еL�{�{,�M����ܹ�
							X"01",X"48",X"65",X"6C",X"6C",X"6F",X"21",X"20",X"20",X"20",x"20",X"20",X"20");--���yHello!

	--LCM=11:�Ĥ@�C��� �����{�b�ɶ�����
	signal LCM_11:LCM_T:=(X"13",X"01",		--�`��,���O��
							"00000001",		--�M����ܹ�
							--��1�C��ܸ��
							X"A1",X"B8",X"A1",X"B9",X"B2",X"7B",X"A6",X"62",X"AE",X"C9",X"B6",X"A1",X"A1",X"B9",X"A1",X"B8",X"20",X"20");--�����{�b�ɶ�����

	--LCM=12:�Ĥ@�C��� �����վ�ɶ�����
	signal LCM_12:LCM_T:=(X"13",X"01",		--�`��,���O��
							"00000001",		--�M����ܹ�
							--��2�C��ܸ��
							X"A1",X"BF",X"A1",X"B5",X"BD",X"D5",X"BE",X"E3",X"AE",X"C9",X"B6",X"A1",X"A1",X"BE",X"A1",X"B6",X"20",X"20");--�����վ�ɶ�����

	--LCM=21:�ĤG�C��� hh:mm:ss
	signal LCM_21:LCM_T:=(X"13",X"01",		--�`��,���O��
							"10010000",		--�]�ĤG�CACC��m
							--��2�C��ܸ��			7	  8		9	  10	11	  12	13	  14	15	  16	17	  18
							X"20",X"20",X"20",X"20",X"48",X"48",X"3A",X"4D",X"4D",X"3A",X"53",X"53",X"20",X"20",X"20",X"20",X"20",X"20");--    hh:mm:ss
	--LCM=22:�ĤG�C��� �֢֡G�ۢۡG���
	signal LCM_22:LCM_T:=(X"13",X"01",		--�`��,���O��
							"10010000",		--�]�ĤG�CACC��m
							--��2�C��ܸ��	
						--	3	  4	    5     6     7	  8	    9	  10	11	  12    13    14    15    16    17	  18
							X"A2",X"AF",X"A2",X"AF",X"A1",X"47",X"A2",X"AF",X"A2",X"AF",X"A1",X"47",X"A2",X"AF",X"A2",X"AF",X"20",X"20");--�֢֡G�ۢۡG���

	type N_T is array (0 to 9) of std_logic_vector(7 downto 0);
	constant N0_9_1:N_T:=(X"30",X"31",X"32",X"33",X"34",X"35",X"36",X"37",X"38",X"39");--0123456789
	constant N0_9_2:N_T:=(X"AF",X"B0",X"B1",X"B2",X"B3",X"B4",X"B5",X"B6",X"B7",X"B8");--��������������������

	signal LCM_com_data,LCM_com_data2:LCM_T;--LCD����X
	signal LCM_INI:integer range 0 to 31;	--LCD����X����
	signal LCMP_RESET,LN,LCMPok:std_logic;	--LCM_P���m,��X�C��,LCM_P����
	signal LCM,LCMx:integer range 0 to 7;	--LCD��X�ﶵ

	--------------------------------------------
	signal FD:std_logic_vector(26 downto 0);		--�t�ΰ��W��
	signal Scounter:integer range 0 to 390625;		--0.25��p�ɾ�
	signal S3S,S2S,S1S,S8S:std_logic_vector(2 downto 0);--���u���p�ƾ�
	signal H,HHH:integer range 0 to 23;				--��
	signal M,MMM,S,SSS:integer range 0 to 59;		--��,��
	signal Ss,SS1,E_Clock_P_clk:std_logic;			--0.5,1��,E_Clock_P�ɯ߾ާ@
	signal MSs,MSs2:std_logic_vector(1 downto 0);	--�]�won/off

--------------------------------------------
begin

--����LCM-----------------------------------				  
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);	--LCM�Ҳ�

--��s��ܮɶ�------------------------------------------
--0123456789
LCM_21(7)<=N0_9_1(H/10);		--�ɤQ��
LCM_21(8)<=N0_9_1(H mod 10);	--�ɭӦ�
LCM_21(10)<=N0_9_1(M/10);		--���Q��
LCM_21(11)<=N0_9_1(M mod 10);	--���Ӧ�
LCM_21(13)<=N0_9_1(S/10);		--��Q��
LCM_21(14)<=N0_9_1(S mod 10);	--��Ӧ�
----��������������������
LCM_22(4)<=N0_9_2(H/10);		--�ɤQ��
LCM_22(6)<=N0_9_2(H mod 10);	--�ɭӦ�
LCM_22(10)<=N0_9_2(M/10);		--���Q��
LCM_22(12)<=N0_9_2(M mod 10);	--���Ӧ�
LCM_22(16)<=N0_9_2(S/10);		--��Q��
LCM_22(18)<=N0_9_2(S mod 10);	--��Ӧ�

--�Ʀ�q�l��24�p�ɨ�--------------------------------------
E_Clock_P_clk<=FD(23) when MSs>0 else Ss;	--E_Clock_P �ɯ߿��
E_Clock_P:process(E_Clock_P_clk)
begin
	if rstP99='0' then	--�t�έ��m,�k�s
		M<=0;			--���k�s
		S<=0;			--���k�s
		MSs<="00";		--���A��������
		SS1<='0';		--��
	elsif rising_edge(E_Clock_P_clk) then
		SS1<=not SS1;	--��
		if S8S(2)='1' then			--���A�i�����
			if MSs=0 or MSs=2 then	--�p����]�w or �]�w��p��
				MSs<=MSs+1;			--����
			end if;
		else						--���A�ഫ
			if MSs=1 or MSs=3 then	--�p����]�w or �]�w��p��
				MSs<=MSs+1;			--�ഫ:��i����í�w���A
				SS1<='0';			--���s�p��
			end if;
		end if;
		if MSs>0 then	--���A��
			if MSs=2 then	--�i�]�w	
				if S1S(2)='1' then	--�վ��
					if H=23 then
						H<=0;
					else
						H<=H+1;
					end if;
				end if;
				if S2S(2)='1' then	--�վ��
					if M=59 then
						M<=0;
					else
						M<=M+1;
					end if;
				end if;
				if S3S(2)='1' then	--�վ��
					if S=59 then
						S<=0;
					else
						S<=S+1;
					end if;
				end if;
			end if;
		elsif SS1='1' then			--1���
			if S/=59 then			--��p��
				S<=S+1;
			else
				S<=0;				
				if M/=59 then		--���p��
					M<=M+1;
				else
					M<=0;
					if H/=23 then	--�ɭp��
						H<=H+1;
					else
						H<=0;
					end if;
				end if;
			end if;
		end if;				
	end if;
end process E_Clock_P;

--0.5��H�����;� --------------------------
S_G_P:process(FD(4))--1S:5,0.5S:4
begin
	if rstP99='0' or MSs>0 then	--�t�έ��m or ���s�p��
		Ss<='1';
		Scounter<=390625;		--0.25��p�ɾ��w�]
	elsif rising_edge(FD(4)) then--4:1562500Hz,5:781250Hz
		Scounter<=Scounter-1;	--0.25��p�ɾ�����
		if Scounter=1 then		--0.25���
			Scounter<=390625;	--0.25��p�ɾ����]
			Ss<=not Ss;			--0.5���A
		end if;
	end if;
end process S_G_P;

-----------------------------
--����LCM�������
C_LCD_P:process(FD(8))
begin
	if rstP99='0' then	--�t�έ��m
		LCM<=0;				--����LCM��l��
		LCMP_RESET<='0';	--LCMP���m
		HHH<=0;				--�ɤ��
		MMM<=0;				--�����
		SSS<=0;				--����
		MSs2<=(others=>'0');--�Ҧ����
	elsif rising_edge(FD(8)) then
		LCMP_RESET<='1';	--LCMP�Ұ����	
		if LCMPok='1' then	--LCM_P�w����
			if LCM=0 then	--��������
				LCM<=1;		--�����������:�p�ɼҦ�
			elsif MSs2/=MSs then--�Ҧ��w����
				MSs2<=MSs;
				if MSs(1)='0' then
					LCM<=1;	--�������:�p�ɼҦ�
				else
					LCM<=2;	--�������:�վ�Ҧ�
				end if;
				LCMP_RESET<='0';	--LCMP���m
			elsif HHH/=H or MMM/=M or SSS/=S then	--�ɶ��w����
				HHH<=H; MMM<=M; SSS<=S;
				if MSs(1)='0' then
					LCM<=3;	--�p�����
				else
					LCM<=4;	--�վ����
				end if;
				LCMP_RESET<='0';	--LCMP���m
			end if;
		end if;
	end if;
end process C_LCD_P;

--����LCM��ܾ�---------------------------------------------------
--����LCM��ܾ�
--���O&��ƪ�榡: 
--(�`��,���O��,���O...���..........
LCM_P:process(FD(0))
	variable SW:Boolean;				--�R�O�θ�ƳƧ��X��
begin
	if LCM/=LCMx or LCMP_RESET='0' then
		LCMx<=LCM;						--�O���ﶵ
		LCM_RESET<='0';					--LCM���m
		LCM_INI<=2;						--�R�O�θ�Ư��޳]���_�I
		LN<='0';						--�]�w��X1�C
		case LCM is						--���J�ﶵ���
			when 0=>
				LCM_com_data<=LCM_IT;	--LCM��l�ƿ�X�Ĥ@�C���Hello!
			when 1=>
				LCM_com_data<=LCM_11;	--��X�Ĥ@�C���
				LCM_com_data2<=LCM_22;	--��X�ĤG�C���
				LN<='1';				--�]�w��X2�C
			when 2=>
				LCM_com_data<=LCM_12;	--��X�Ĥ@�C���
				LCM_com_data2<=LCM_21;	--��X�ĤG�C���
				LN<='1';				--�]�w��X2�C
			when 3=>
				LCM_com_data<=LCM_22;	--��X�ĤG�C���
			when others =>
				LCM_com_data<=LCM_21;	--��X�ĤG�C���
		end case;
		LCMPok<='0';					--���������H��
		SW:=False;						--�R�O�θ�ƳƧ��X��
	elsif rising_edge(FD(0)) then
		if SW then						--�R�O�θ�ƳƧ���
			LCM_RESET<='1';				--�Ұ�LCM_4bit_driver_delay
			SW:=False;					--���m�X��
		elsif LCM_RESET='1' then		--LCM_4bit_driver_delay�Ұʤ�
			if LCMok then				--����LCM_4bit_driver_delay�����ǰe
				LCM_RESET<='0';			--������LCM���m
			end if;
		elsif LCM_INI<LCM_com_data(0) and LCM_INI<LCM_com_data'length then	--�R�O�θ�Ʃ|���ǧ�
			if LCM_INI<=(LCM_com_data(1)+1) then--��R�O�θ�ƼȦs��
				RS<='0';	--Instruction reg
			else
				RS<='1';	--Data reg
			end if;
			RW<='0';		--LCM�g�J�ާ@
			DBi<=LCM_com_data(LCM_INI);	--���J�R�O�θ��
			LCM_INI<=LCM_INI+1;			--�R�O�θ�Ư��ޫ���U�@��
			SW:=True;					--�R�O�θ�Ƥw�Ƨ�
		else
			if LN='1' then				--�]�w��X2�C
				LN<='0';					--�]�w��X2�C����
				LCM_INI<=2;					--�R�O�θ�Ư��޳]���_�I
				LCM_com_data<=LCM_com_data2;--LCM��X�ĤG�C���
			else
				LCMPok<='1';				--���槹��
			end if;
		end if;
	end if;
end process LCM_P;

--���u��----------------------------------
process(FD(17))
begin
	--S8���u��--�p��/�վ�
	if S8='1' then
		S8S<="000";
	elsif rising_edge(FD(17)) then
		S8S<=S8S+ not S8S(2);
	end if;
	--S1���u��--��
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	--S2���u��--��
	if S2='1' then
		S2S<="000";
	elsif rising_edge(FD(17)) then
		S2S<=S2S+ not S2S(2);
	end if;
	--S3���u��--��
	if S3='1' then
		S3S<="000";
	elsif rising_edge(FD(17)) then
		S3S<=S3S+ not S3S(2);
	end if;
end process;

--���W�� --------------------------
Freq_Div:process(gckP31)			--�t���W�vgckP31:50MHz
begin
	if rstP99='0' then				--�t�έ��m
		FD<=(others=>'0');			--���W��:�k�s
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--���W��:2�i��W��(+1)�p�ƾ�
	end if;
end process Freq_Div;

-- ----------------------------------------
end Albert;