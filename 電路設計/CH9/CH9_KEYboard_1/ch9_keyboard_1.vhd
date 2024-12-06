--4x4��L_�򥻴���:���U��}�A�B�z
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH9_KEYboard_1 is
port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset
	 keyi:in std_logic_vector(3 downto 0);			--��L��J
	 keyo:buffer std_logic_vector(3 downto 0);		--��L��X
	 LED1_16:buffer std_logic_vector(15 downto 0); 	--LED���
	 --4��Ʊ��y����ܾ�
	 SCANo:buffer std_logic_vector(3 downto 0);		--���˾���X
	 Disp7S:buffer std_logic_vector(7 downto 0)		--�p�Ʀ�ƸѽX��X
	);
end entity CH9_KEYboard_1;

-- -----------------------------------------------------
architecture Albert of CH9_KEYboard_1 is
	signal FD:std_logic_vector(24 downto 0);--���W��
	signal kn,kin:integer range 0 to 15;	--�s���,�����
	signal kok:std_logic_vector(3 downto 0):="0000";--��L�������A
	signal i:integer range 0 to 3;			--��L��J��������

begin

--LED_on_off:���Ϊ��W�v������L�ާ@�W�v-----------------------
LED_on_off:process (FD(12))
variable sw:std_logic;
begin
	if rstP99='0' then			--�t��reset
		LED1_16<=(others=>'0');	--�����Ҧ��O��
		kin<=0;					--�]�����0
		sw:='0';				--�i�����s���
	elsif (rising_edge(FD(12))) then
		if (kok=10) and sw='0' then			--��L�w�������A
			kin<=kn;						--���o�s���
			LED1_16(kn)<=not LED1_16(kn);	--�s��ȿO��
			sw:='1';	--������s���
		elsif kok=1 then--��L�w����
			sw:='0';	--�i�A�����s���
		end if;
	end if;
end process LED_on_off;	 

--keyboard:��L�ާ@�W�v�C����Ϊ��W�v-----------------------------
keyboard:process (FD(13))
begin
	if kok=0 or rstP99='0' then	--���m��L,�t��reset
		keyo<="1110";			--�ǳ���L��X�H��
		kok<="0001";			--�w�]��L�������B�L���䪬�A
		kn<=0;					--��ȥ�0�}�l
		i<=0;					--��L�������Х�0�}�l
	elsif (rising_edge(FD(13))) then
		if (kok/=1) then		--�����䪬�A

			--�A��վ�kok�ȥi����L�B�@���Z
			if keyi=15 then		--�P�_�������}
				if kok<5 then	--���:��L���u���L�{���A
					kok<=kok-1;	--�p�O���T�N������L
				else
					kok<=kok+1;	--��L���u���L�{���A(���)
				end if;
			else
				if kok>9 then	--���ΤF:��L���u���L�{���A
					kok<="1011";--(���)
				elsif kok>4 then--�|������:��L���u���L�{���A
					kok<="0101";
				else
					kok<=kok+1;	--���:��L���u���L�{���A
				end if;				
			end if;

		elsif keyi(i)='0' then	--����������U���A
			kok<="0010";		--�]�����䪬�A
			keyo<="0000";		--�]�����Ҧ�����
		else					--�L������U���A
			kn<=kn+1;			--�վ����
			keyo<=keyo(2 downto 0) & keyo(3);--�վ���L��X
			if keyo(3)='0' then	--�O�_�n�վ���L��������
				i<=i+1;			--�վ���L��������
			end if;
		end if;
	end if;
end process keyboard;

SCANo<="1110";
--�C�q��ܾ��ѽX0123456789AbCdEF--pgfedcba
with kin select
Disp7S <=
"11000000" when 0,	--0
"11111001" when 1,	--1
"10100100" when 2,	--2
"10110000" when 3,	--3
"10011001" when 4,	--4
"10010010" when 5,	--5
"10000010" when 6,	--6
"11111000" when 7,	--7
"10000000" when 8,	--8
"10010000" when 9,	--9
"10001000" when 10,	--A
"10000011" when 11,	--b
"11000110" when 12,	--C
"10100001" when 13,	--d
"10000110" when 14,	--E
"10001110" when 15;	--F

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
