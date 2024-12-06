--����s�X��+MG90S ����
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��
Use IEEE.std_logic_arith.all;		--�ޥήM��

-- -----------------------------------------------------
entity CH12_MG90S_2 is
port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset

	 --MG90S--
	 MG90S_o0:out std_logic;
	 MG90S_o1:out std_logic;

	 APi,BPi,PBi:in std_logic;	 --����s�X��
	 LED1_2:buffer std_logic_vector(1 downto 0)--LED���
	 );
end entity CH12_MG90S_2;

-- -----------------------------------------------------
architecture Albert of CH12_MG90S_2 is
	--MG90S-------------------------------------------------------------------------------
	component MG90S_Driver2 is
	port(MG90S_CLK,MG90S_RESET:in std_logic;		--MG90S_Driver�X��clk(25MHz),reset�H��
		 MG90S_deg:in integer range 0 to 180;		--��ʨ���
		 MG90S_o:out std_logic);					--Driver��X
	end component;
	signal MG90S_CLK,MG90S_RESET:std_logic;			--MG90S_Driver�X��clk(25MHz),reset�H��
	signal MG90S_deg0,MG90S_deg1:integer range 0 to 180:=90;	--��ʨ���

	-- ============================================================================
	signal FD:std_logic_vector(24 downto 0);--���W��
	signal times:integer range 0 to 2047;	--�p�ɾ�
	signal APic,BPic,PBic:std_logic_vector(2 downto 0):="000";	--���u���p�ƾ�
	signal clrPC,set90,HV:std_logic;		--�M�����s����,�]90��,�b�V
	signal PC:integer range 0 to 3;			--���s����

-----------------------------
begin

U1: MG90S_Driver2 port map(FD(0),MG90S_RESET,--MG90S_Driver�X��clk(25MHz),reset�H��
						  MG90S_deg0,		 --��ʨ���
						  MG90S_o0);		 --Driver��X
						
U12: MG90S_Driver2 port map(FD(0),MG90S_RESET,--MG90S_Driver�X��clk(25MHz),reset�H��
						  MG90S_deg1,		  --��ʨ���
						  MG90S_o1);		 --Driver��X
						  
LED1_2<=HV & not HV;

--����s�X�����s�ʱ�-----------------------------
--�b�V�ܴ�,�]90��
process(FD(17),rstP99)
begin
	if rstP99='0' then
		HV<='0';	--��0�}�l
		set90<='0';	--���]90�� 
		clrPC<='0';	--���M�����s����
		times<=0;	--�p���k�s
		MG90S_RESET<='0';		--MG90S_Driver2 off
	elsif rising_edge(FD(17)) then	-- ������UD�H�����ɽt��
		MG90S_RESET<='1';		--MG90S_Driver2 on
		if PC/=0 then
			times<=times+1;		--�p��
			if times=75 then	--�p�ɨ�
				if PC=1 then	--���
					HV<=not HV;	--�����b�V
				else			--����
					set90<='1';	--�]90�� 
				end if;
				clrPC<='1';		--�M�����s����
			end if;
		else
			times<=0;			--�p���k�s
			set90<='0';			--�M���]90�� 
			clrPC<='0';			--�M���M�����s����
		end if;
	end if;
end process;

--����s�X�����s�����q---------------------------
--��� ����
process(PBic(2),rstP99,clrPC)
begin
	if rstP99='0' or clrPC='1' then
		PC<=0;	--���s���� 0
	elsif rising_edge(PBic(2)) then	-- ������UD�H�����ɽt��
		if PC<2 then 
			PC<=PC+1;				--���s����
		end if;
	end if;
end process;

--����s�X�����श���q��----------------------------------------
--�����ܴ� 0~180
EncoderInterface:process(APi,PBi,rstP99,set90)
begin
	if rstP99='0' or set90='1' then
		MG90S_deg0<=90;
		MG90S_deg1<=90;
	elsif rising_edge(APic(2)) then	--������UD�H�����ɽt��
		if HV='0' then
			if BPi='1' then				--�k��
				if MG90S_deg0<180 then
					MG90S_deg0<=MG90S_deg0+1;--�[1��
				end if;
			else						--����
				if MG90S_deg0>0 then
					MG90S_deg0<=MG90S_deg0-1;--��1��
				end if;
			end if;
		else
			if BPi='0' then				--����
				if MG90S_deg1<180 then
					MG90S_deg1<=MG90S_deg1+1;--�[1��
				end if;
			else						--�k��
				if MG90S_deg1>0 then
					MG90S_deg1<=MG90S_deg1-1;--��1��
				end if;
			end if;				
		end if;
	end if;
end process EncoderInterface;

---------------------------------------------------------------
-- ���u���q��
Debounce:process(FD(8))	--����s�X�����u���W�v
begin
	--APi���u���P���T
	if APi=APic(2) then	--�YAPi����APic�̥���줸
		APic<=APic(2) & "00";
		--�hAPi����APic(2)�k��줸�k�s
	elsif rising_edge(FD(8)) then	
		APic<=APic+1;
		--�_�h�HF1���ɽt�AAPic�p�ƾ����W
	end if;

	--BPi���u���P���T
	if BPi=BPic(2) then	--�YBPi����BPic�̥���줸
		BPic<=BPic(2)& "00";	
		--�hBPi����BPic(2)�k��줸�k�s
	elsif rising_edge(FD(8)) then 
		BPic<=BPic+1;
		--�_�h�HF1���ɽt�ABPic�p�ƾ����W
	end if;

	--PBi���u���P���T
	if PBi=PBic(2) then	--�YPBi����PBic�̥���줸
		PBic<=PBic(2)& "00";
		--�hPBic(2)�k��줸�k�s
	elsif rising_edge(FD(16)) then
		PBic<=PBic+1;
		--�_�h�HF1���ɽt�APBic�p�ƾ����W
	end if;
end process Debounce;

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
