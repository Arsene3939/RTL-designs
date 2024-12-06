--����s�X��_�򥻴���
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- ---------------------------------------
entity CH9_ROTATE_ENCODER_3 is 
port(gckP31,rstP99:in std_logic;				 --�t���W�v,�t��reset
	 APi,BPi,PBi:in std_logic;					 --����s�X��
	 LED1_16:buffer std_logic_vector(15 downto 0)--LED���
	);
end entity CH9_ROTATE_ENCODER_3;

-- ---------------------------------------
architecture Albert of CH9_ROTATE_ENCODER_3 is
	signal FD: std_logic_vector(25 downto 0);					--���W��
	signal APic,BPic,PBic:std_logic_vector(2 downto 0):="000";	--���u���p�ƾ�
	signal mode1,mode2:integer range 0 to 3;					--�˪O,�ާ@�Ҧ�
begin

-- ����s�X�������q��----------------------------------------
EncoderInterface:process(APi,PBi,rstP99)
begin
	if rstP99='0' then
		mode2<=0;					--��0�}�l
	elsif rising_edge(PBic(2)) then	-- ������UD�H�����ɽt��
		mode2<=mode2+1;				--�U�@���ܧ�̾�
	end if;

	if rstP99='0' or PBic(2)='0' then
		mode1<=mode2;				--��mode2�ܧ�ﶵ
		if mode1=0 then				--��mode2���J�˪O
			LED1_16<=(others=>'0');
		elsif mode1=1 then
			LED1_16<="1100110011001100";
		elsif mode1=2 then
			LED1_16<="1111000000001111";
		else
			LED1_16<="1010101010101010";
		end if;
	elsif rising_edge(APic(2)) then	--������UD�H�����ɽt��
		case mode1 is 
			when 0=>			
				if BPi='1' then				--����
					LED1_16<=not LED1_16(0)& LED1_16(15 downto 1);
				else						--�k��
					LED1_16<=LED1_16(14 downto 0) & not LED1_16(15);
				end if;
			when 1=>
				if BPi='1' then				--����
					LED1_16<=LED1_16(0)& LED1_16(15 downto 1);
				else						--�k��
					LED1_16<=LED1_16(14 downto 0) & LED1_16(15);
				end if;
			when 2=>
				if BPi='1' then				--�~�V��
					LED1_16<=LED1_16(14 downto 8) & LED1_16(15) & LED1_16(0)& LED1_16(7 downto 1);
				else						--���V�~
					LED1_16<=LED1_16(8)& LED1_16(15 downto 9)&LED1_16(6 downto 0) & LED1_16(7);
				end if;
			when 3=>
				if BPi='1' then				--���Ϭ�
					LED1_16<=not LED1_16(15 downto 8) & LED1_16(7 downto 0);
				else						--�k�Ϭ�
					LED1_16<=LED1_16(15 downto 8) & not LED1_16(7 downto 0);
				end if;
		end case;
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
