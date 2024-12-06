--4��Ʊ��˦��@�����C�q��ܾ�
--�Ʀ�q�l��24�p�ɨ�
--106.12.30��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- ---------------------------------------
entity CH5_7SLED_3 is	
	port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset(�k�s)
		 S1,S2,S0:in std_logic;		
		 --��(131),��(128)���W���s,�]�w/�Ȱ�/�ˮɫ��s(117)
		 --4��Ʊ��y����ܾ�
		 SCANo:buffer std_logic_vector(3 downto 0);	--���˾���X
		 Disp7S:buffer std_logic_vector(7 downto 0);--�p�Ʀ�ƸѽX��X
		 Dd:buffer std_logic						--���A���
		 );
end entity CH5_7SLED_3;

-- -----------------------------------------
architecture Albert of CH5_7SLED_3 is
	signal FD:std_logic_vector(26 downto 0);	--�t�ΰ��W��
	signal Scounter:integer range 0 to 390625;	--�b��p�ɾ�
	type Disp7DataT is array(0 to 3) of integer range 0 to 9;--��ܰϮ榡
	signal Disp7Data:Disp7DataT;				--��ܰ�
	signal scanP:integer range 0 to 3;			--���˾�����
	signal S2S,S1S,S0S:std_logic_vector(2 downto 0);--���u���p�ƾ�
	signal H:integer range 0 to 23;				--��
	signal M,S:integer range 0 to 59;			--��,��
	signal Ss,E_Clock_P_clk:std_logic;			--1��,E_Clock_P�ɯ߾ާ@
	signal MSs:std_logic_vector(1 downto 0);	--�]�won/off
begin

Disp7Data(3)<=H/10;			--�ɤQ��
Disp7Data(2)<=H mod 10;		--�ɭӦ�
Disp7Data(1)<=M/10;			--���Q��
Disp7Data(0)<=M mod 10;		--���Ӧ�
Dd<='0' when MSs>0 else Ss;	--�]�w/�Ȱ�:��G,/�p��:��{�{

--�Ʀ�q�l��24�p�ɨ�------------------------
E_Clock_P_clk<=FD(23) when MSs>0 else Ss;	--E_Clock_P �ɯ߿��
E_Clock_P:process(E_Clock_P_clk)
begin
	if rstP99='0' then	--�t�έ��m,�k�s
		M<=0;			--���k�s
		S<=0;			--���k�s
		MSs<="00";		--���A��������
	elsif rising_edge(E_Clock_P_clk) then
		if S0S(2)='1' then			--���A�i�����
			if MSs=0 or MSs=2 then	--�p����]�w or �]�w��p��
				MSs<=MSs+1;			--����
			end if;
		else						--���A�ഫ
			if MSs=1 or MSs=3 then	--�p����]�w or �]�w��p��
				MSs<=MSs+1;			--�ഫ:��i����í�w���A
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
				S<=0;				--���k�s
			end if;
		else
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

--��H�����;� --------------------------
S_G_P:process(FD(5))
begin
	if rstP99='0' or MSs>0 then	--�t�έ��m or ���s�p��
		Ss<='1';
		Scounter<=390625;		--�b��p�ɾ��w�]
	elsif rising_edge(FD(5)) then--781250Hz
		Scounter<=Scounter-1;	--�b��p�ɾ�����
		if Scounter=1 then		--�b���
			Scounter<=390625;	--�b��p�ɾ����]
			Ss<=not Ss;			--1���A
		end if;
	end if;
end process S_G_P;

--4��Ʊ��˾�---------------------------------------------------
scan_P:process(FD(17),rstP99)
begin
	if rstP99='0' then
		scanP<=0;		--��ƨ��ȫ���
		SCANo<="1111";	--���˫H�� all off
	elsif rising_edge(FD(17)) then
		scanP<=scanP+1;	--��ƨ��ȫ��л��W
		SCANo<=SCANo(2 downto 0)&SCANo(3);
		if scanP=3 then		--�̫�@��ƤF
			scanP<=0;		----��ƨ��ȫ��Э��]
			SCANo<="1110";	--���˫H�����]
		end if;
	end if;
end process scan_P;

--BCD�X�Ѧ@�����C�q��ܽXpgfedcba
with Disp7Data(scanP) select --���X��ܭ�
	Disp7S<=
	"11000000" when 0,
	"11111001" when 1,
	"10100100" when 2,
	"10110000" when 3,
	"10011001" when 4,
	"10010010" when 5,
	"10000010" when 6,
	"11111000" when 7,
	"10000000" when 8,
	"10010000" when 9,
	"11111111" when others;	--�����

--���u��----------------------------------
process(FD(17))
begin
	--S0���u��
	if S0='1' then
		S0S<="000";
	elsif rising_edge(FD(17)) then
		S0S<=S0S+ not S0S(2);
	end if;
	--S1���u��
	if S1='1' then
		S1S<="000";
	elsif rising_edge(FD(17)) then
		S1S<=S1S+ not S1S(2);
	end if;
	--S1���u��
	if S2='1' then
		S2S<="000";
	elsif rising_edge(FD(17)) then
		S2S<=S2S+ not S2S(2);
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