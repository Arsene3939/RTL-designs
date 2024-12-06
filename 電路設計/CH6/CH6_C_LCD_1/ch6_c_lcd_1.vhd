--����LCM��� �ϥ�:LCM_4bit_driver_delay
--106.12.30��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH6_C_LCD_1 is
port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset
	  S1,S2:in std_logic;		--�V�W�B�V�U���s
	 --LCD 4bit����
	 DB_io:inout std_logic_vector(3 downto 0);
	 RSo,RWo,Eo:out std_logic
	 );
end entity CH6_C_LCD_1;

-- -----------------------------------------------------
architecture Albert of CH6_C_LCD_1 is
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

	-- ============================================================================
	signal FD:std_logic_vector(24 downto 0);--���W��
	signal times:integer range 0 to 2047;	--�p�ɾ�

	--------------------------------------------------------------
	----����LCM���O&��ƪ�榡:
	----(�`��,���O��,���O...���...........
	----�^�ƫ�LCM 4�줸�ɭ�,2�C���

	type LCM_T is array (0 to 20) of std_logic_vector(7 downto 0);
	constant LCM_IT:LCM_T:=(X"0F",X"06",----���嫬LCM 4�줸�ɭ�
							"00101000","00101000","00101000",--4�줸�ɭ�
							"00000110","00001100","00000001",--ACC+1��ܹ��L����,��ܹ�on�L��еL�{�{,�M����ܹ�
							X"01",X"48",X"65",X"6C",X"6C",X"6F",X"21",X"20",X"20",X"20",x"20",X"20",X"20");--���yHello!

	--LCM=21:�Ĥ@�C��� �]��@�@�̡G����
	signal LCM_21:LCM_T:=(X"13",X"01",		--�`��,���O��
							"00000001",		--�M����ܹ�
							--��1�C��ܸ��
							X"A9",X"5D",X"AB",X"E4",X"A1",X"40",X"A7",X"40",X"AA",X"CC",X"A1",X"47",X"A7",X"F5",X"A5",X"D5",X"20",X"20");--�]��@�@�̡G����

	--LCM=22:�ĤG�C��� �ɫe������A
	signal LCM_22:LCM_T:=(X"13",X"01",		--�`��,���O��
							"10010000",		--�]�ĤG�CACC��m
							--��2�C��ܸ��
							X"A7",X"C9",X"AB",X"65",X"A9",X"FA",X"A4",X"EB",X"A5",X"FA",X"A1",X"41",X"20",X"20",X"20",x"20",X"20",X"20");--�ɫe�����?

	--LCM=23:�ĤG�C��� �æ��a�W��
	signal LCM_23:LCM_T:=(X"13",X"01",		--�`��,���O��
							"10010000",		--�]�ĤG�CACC��m
							--��2�C��ܸ��
							X"BA",X"C3",X"A6",X"FC",X"A6",X"61",X"A4",X"57",X"C1",X"F7",X"A1",X"41",X"20",X"20",X"20",x"20",X"20",X"20");--�æ��a�W���A
	--LCM=24:�ĤG�C��� �|�Y�����A
	signal LCM_24:LCM_T:=(X"13",X"01",		--�`��,���O��
							"10010000",		--�]�ĤG�CACC��m
							--��2�C��ܸ��
							X"C1",X"7C",X"C0",X"59",X"B1",X"E6",X"A9",X"FA",X"A4",X"EB",X"A1",X"41",X"20",X"20",X"20",x"20",X"20",X"20");--�|�Y�����A	

	--LCM=25:�ĤG�C��� �C�Y��G�m�C	
	signal LCM_25:LCM_T:=(X"13",X"01",		--�`��,���O��
							"10010000",		--�]�ĤG�CACC��m
							--��2�C��ܸ��
							X"A7",X"43",X"C0",X"59",X"AB",X"E4",X"AC",X"47",X"B6",X"6D",X"A1",X"43",X"20",X"20",X"20",x"20",X"20",X"20");--�C�Y��G�m�C
	
	signal LCM_com_data,LCM_com_data2:LCM_T;--LCD����X
	signal LCM_INI:integer range 0 to 31;	--LCD����X����
	signal LCMP_RESET,LN,LCMPok:std_logic;	--LCM_P���m,��X�C��,LCM_P����
	signal LCM,LCMx:integer range 0 to 7;	--LCD��X�ﶵ
	
	signal S2S,S1S:std_logic_vector(2 downto 0);--���u���p�ƾ�

-----------------------------
begin

--����LCM--------------------
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);	--LCM�Ҳ�

-----------------------------
C_LCD_P:process(FD(18))
begin
	if rstP99='0' then	--�t�έ��m
		LCM<=0;				--����LCM��l��
		LCMP_RESET<='0';	--LCMP���m
	elsif rising_edge(FD(18)) then
		LCMP_RESET<='1';	--LCMP�Ұ����	
		if LCMPok='1' then
			if S1S(2)='1' then		--�V�W���s
				if LCM>1 then	
					LCM<=LCM-1;		--��� �W�@�y
				end if;
			elsif S2S(2)='1' then	--�V�U���s
				if LCM<4 then
					LCM<=LCM+1;		--��� �U�@�y
				end if;
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
				LCM_com_data<=LCM_21;	--��X�Ĥ@�C���
				LCM_com_data2<=LCM_22;	--��X�ĤG�C���
				LN<='1';				--�]�w��X2�C
			when 2=>
				LCM_com_data<=LCM_23;	--��X�ĤG�C���
			when 3=>
				LCM_com_data<=LCM_24;	--��X�ĤG�C���
			when others =>
				LCM_com_data<=LCM_25;	--��X�ĤG�C���
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

----���u��----------------------------------
process(FD(17))
begin
	--S1���u��--�V�W���s
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	--S1���u��--�V�U���s
	if S2='1' then
		S2S<="000";
	elsif rising_edge(FD(17)) then
		S2S<=S2S+ not S2S(2);
	end if;
end process;


----���W��--------------------------
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
