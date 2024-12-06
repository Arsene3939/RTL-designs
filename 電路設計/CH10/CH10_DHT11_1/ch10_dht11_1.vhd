--DHT11����׷P��������:1 wire+����LCM���
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��
use ieee.std_logic_arith.all;		--�ޥήM��

-- -----------------------------------------------------
entity CH10_DHT11_1 is
port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset
	 --DHT11
	 DHT11_D_io:inout std_logic;	--DHT11 i/o
	 
	 --LCD 4bit����
	 DB_io:inout std_logic_vector(3 downto 0);
	 RSo,RWo,Eo:out std_logic
	 );
end entity CH10_DHT11_1;

-- -----------------------------------------------------
architecture Albert of CH10_DHT11_1 is
	-- ============================================================================
	--DHT11_driver
	--Data format:
	--DHT11_DBo(std_logic_vector:8bit):��DHT11_RDp�����X��
	--RDp=5:chK_SUM
	--RDp=4							   3							   2								1								  0					
	--The 8bit humidity integer data + 8bit the Humidity decimal data +8 bit temperature integer data + 8bit fractional temperature data +8 bit parity bit.
	--������X���(DHT11_DBoH)�ηū�(DHT11_DBoT):integer(0~255:8bit)
	--107.01.01��
	component DHT11_driver is
		port(DHT11_CLK,DHT11_RESET:in std_logic;		--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))�ާ@�t�v,���m
			 DHT11_D_io:inout std_logic;				--DHT11 i/o
			 DHT11_DBo:out std_logic_vector(7 downto 0);--DHT11_driver ��ƿ�X
			 DHT11_RDp:in integer range 0 to 7;			--���Ū������
			 DHT11_tryN:in integer range 0 to 7;		--���~����մX��
			 DHT11_ok,DHT11_S:buffer std_logic;			--DHT11_driver�����@�~�X��,���~�H��
			 DHT11_DBoH,DHT11_DBoT:out integer range 0 to 255);--������X��פηū�
	end component DHT11_driver;

	signal DHT11_CLK,DHT11_RESET:std_logic;	--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))�ާ@�t�v,���m
	signal DHT11_DBo:std_logic_vector(7 downto 0);--DHT11_driver ��ƿ�X
	signal DHT11_RDp:integer range 0 to 7;		--���Ū������5~0
	signal DHT11_tryN:integer range 0 to 7:=3;	--���~����մX��
	signal DHT11_ok,DHT11_S:std_logic;			--DHT11_driver�����@�~�X��,���~�H��	
	signal DHT11_DBoH,DHT11_DBoT:integer range 0 to 255;--������X��פηū�
		
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
							X"01",X"48",X"65",X"6C",X"6C",X"6F",X"21",X"20",X"20",X"20",x"20",X"20",X"20");--Hello!
	
	--LCM=1:�Ĥ@�C��ܰ�DHT11 �����  %RH
	signal LCM_1:LCM_T:=(X"15",X"01",			--�`��,���O��
							"00000001",			--�M����ܹ�
							--��1�C��ܸ��
							X"44",X"48",X"54",X"31",X"31",X"20",X"B4",X"FA",X"C0",X"E3",X"AB",X"D7",X"3D",X"30",X"30",X"25",X"52",X"48");--DHT11 �����  %RH

	--LCM=1:�ĤG�C��ܰ�DHT11 ���ū�  �J
	signal LCM_12:LCM_T:=(X"15",X"01",			--�`��,���O��
							"10010000",			--�]�ĤG�CACC��m
							--��2�C��ܸ��
							X"44",X"48",X"54",X"31",X"31",X"20",X"B4",X"FA",X"B7",X"C5",X"AB",X"D7",X"3D",X"30",X"30",X"20",X"A2",X"4A");--DHT11 ���ū�  �J
	
	--LCM=2:�Ĥ@�C��ܰ�DHT11 ���Ū������
	signal LCM_2:LCM_T:=(X"15",X"01",			--�`��,���O��
							"00000001",			--�M����ܹ�
							--��1�C��ܸ��
							X"44",X"48",X"54",X"31",X"31",X"20",X"B8",X"EA",X"AE",X"C6",X"C5",X"AA",X"A8",X"FA",X"A5",X"A2",X"B1",X"D1");--DHT11 ���Ū������
	
	signal LCM_com_data,LCM_com_data2:LCM_T;
	signal LCM_INI:integer range 0 to 31;
	signal LCMP_RESET,LN,LCMPok:std_logic;
	signal LCM,LCMx:integer range 0 to 7;

begin

-----------------------------
DHT11_CLK<=FD(5);	--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))�ާ@�t�v
U2: DHT11_driver port map(DHT11_CLK,DHT11_RESET,--DHT11_CLK:781250Hz(50MHz/2^6:1.28us:FD(5))�ާ@�t�v,���m
						  DHT11_D_io,			--DHT11 i/o
						  DHT11_DBo,			--DHT11_driver ��ƿ�X
						  DHT11_RDp,			--���Ū������
						  DHT11_tryN,			--���~����մX��
						  DHT11_ok,DHT11_S,DHT11_DBoH,DHT11_DBoT);	--DHT11_driver�����@�~�X��,���~�H��,������X��פηū�
--����LCM				  
LCMset: LCM_4bit_driver port map(FD(7),LCM_RESET,RS,RW,DBi,DBo,DB_io,RSo,RWo,Eo,LCMok,LCM_S);	--LCM�Ҳ�

-----------------------------
DHT11P_Main:process(FD(17))
begin
	if rstP99='0' then	--�t�έ��m
		DHT11_RESET<='0';	--DHT11�ǳƭ��sŪ�����
		LCM<=0;				--����LCM��l��
		LCMP_RESET<='0';	--LCMP���m
	elsif rising_edge(FD(17)) then
		LCMP_RESET<='1';	--LCMP�Ұ����	
		if LCMPok='1' then
			if DHT11_RESET='0' then	--DHT11_driver�|���Ұ�
				DHT11_RESET<='1';	--DHT11���Ū��
				times<=400;			--�]�w�p��
			elsif DHT11_ok='1' then	--DHT11Ū������
				times<=times-1;			--�p��
				if times=0 then			--�ɶ���
					LCM<=1;				--����LCM��ܴ��q��
					LCMP_RESET<='0';	--LCMP���m
					DHT11_RESET<='0';	--DHT11�ǳƭ��sŪ�����
				elsif DHT11_S='1' then	--���Ū������
					LCM<=2;			--����LCM���DHT11 ���Ū������
				end if;
			end if;
		end if;
	end if;
end process DHT11P_Main;

------------------------------------------------------------
--DHT11 LCM���
LCM_1(17)<="0011" & conv_std_logic_vector(DHT11_DBoH mod 10,4);		-- �^���Ӧ��
LCM_1(16)<="0011" & conv_std_logic_vector((DHT11_DBoH/10)mod 10,4);	-- �^���Q���
LCM_12(17)<="0011" & conv_std_logic_vector(DHT11_DBoT mod 10,4);	-- �^���Ӧ��
LCM_12(16)<="0011" & conv_std_logic_vector((DHT11_DBoT/10)mod 10,4);-- �^���Q���

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
		case LCM is
			when 0=>
				LCM_com_data<=LCM_IT;	--LCM��l�ƿ�X�Ĥ@�C���Hello!
			when 1=>
				LCM_com_data<=LCM_1;	--��X�Ĥ@�C���
				LCM_com_data2<=LCM_12;	--��X�ĤG�C���
				LN<='1';				--�]�w��X2�C
			when others =>
				LCM_com_data<=LCM_2;	--��X�Ĥ@�C���
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
