--RGB16x16�O���ϧδ���
--106.12.30��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH4_RGB16x16_2 is
port(gckP31,rstP99:in std_logic;	--�t���W�v,�t��reset
	 --DM13A ��X
	 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;
	 --186,187,189,194,188,185
	 --Scan ��X
	 Scan_DCBAo:buffer std_logic_vector(3 downto 0)
	 --198,197,196,195
    );
end entity CH4_RGB16x16_2;

-- -----------------------------------------------------
architecture Albert of CH4_RGB16x16_2 is
	component DM13A_Driver_RGB is
	port(--DM13A_Driver_RGB�ާ@�W�v,���m,ALE����,OE����,��V����,�Ϭ۱���
		 DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:in std_logic;
		 startbit:in integer range 0 to 15;		 	--�}�l�ާ@�줸
		 maskRGB:in std_logic_vector(5 downto 0);	--�n�\�ާ@�줸
		 --mask (5):0:disable 1:enable, (4..3)00:load,01:xor:10:or,11:and RGB
		 LED_R,LED_G,LED_B:in std_logic_vector(15 downto 0);	--R G B �ϧΦ줸
		 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;--DM13A �w��ާ@�줸
		 DM13A_Sendok:out std_logic);	--DM13A_Driver_RGB�����ާ@�줸
	end component;
		 --DM13A_Driver_RGB�ާ@�W�v,���m,ALE����,OE����,��V����,�Ϭ۱���
	signal DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:std_logic;
	signal startbit:integer range 0 to 15;					--�}�l�ާ@�줸
	signal maskRGB:std_logic_vector(5 downto 0):="000000";--�n�\�ާ@�줸
	signal LED_R,LED_G,LED_B:std_logic_vector(15 downto 0);	--R G B �ϧΦ줸
	signal DM13A_Sendok:std_logic;							--DM13A_Driver_RGB�����ާ@�줸

	-- -----------------------------------------------------	
	signal FD:std_logic_vector(24 downto 0);	--�t�ΰ��W��
	signal G_step:integer range 0 to 3;			--�ϧΨ��˫���
	signal RGB_point:integer range 0 to 15;		--�ϧΨ��˫���
			--���m					clk						clk				clk
	signal RG,RGB16X16_SCAN_reset,scan_1T,RGB16X16_TP_clk,RGB16X16_P_clk,RGB16X16_SCAN_p_clk:std_logic;
	signal T_runstep:integer range 0 to 7;		--���涥�q
	type RGB16x16_T1 is array(0 to 15) of std_logic_vector(15 downto 0);--�Ϲ��榡
	signal RGB16x16_R,RGB16x16_G:RGB16x16_T1;			--1���}�C
	--�Ϲ�
	type RGB16x16_T2 is array(0 to 3) of RGB16x16_T1;	--2���}�C
	--�Ϲ�:�аѦҤp��H�s�X.doc
	constant RGB16x16_GD:RGB16x16_T2:=(	(X"0000",X"0000",X"0000",X"0000",X"0003",X"060F",X"6F3F",X"DFF9",X"DFF0",X"DFFF",X"DF3E",X"6606",X"4004",X"0000",X"0000",X"0000"),
										(X"0000",X"0000",X"0000",X"0180",X"03E3",X"676F",X"D63F",X"DFF9",X"DFF8",X"DFBD",X"69CF",X"40C7",X"40C1",X"0080",X"0000",X"0000"),
										(X"0004",X"018C",X"03CE",X"07E6",X"0E47",X"0C0E",X"6C3C",X"DFF8",X"DFF8",X"DFB9",X"D39B",X"61CF",X"40ED",X"41C1",X"0180",X"0080"),
										(X"0000",X"0000",X"0000",X"0180",X"03E3",X"676F",X"D63F",X"DFF9",X"DFF8",X"DFBD",X"69CF",X"40C7",X"40C1",X"0080",X"0000",X"0000"));
						
-- --------------------------
begin

----DM13A_Driver_RGB
 DM13ACLK<=FD(2);
 U1: DM13A_Driver_RGB 
	port map(	DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01,startbit,maskRGB,
				LED_R,LED_G,LED_B,
				DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo,
				DM13A_Sendok);
 
-- --------------------------
--���W��
Freq_Div:process(gckP31)			--�t���W�vgckP31:50MHz
begin
	if rstP99='0' then	--�t�έ��m
		FD<=(others=>'0');			--���W��:�k�s
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--���W��:2�i��W��(+1)�p�ƾ�
	end if;
end process Freq_Div;

-----------------------------------------------------------
RGB16X16_TP_clk<=FD(22);--��6Hz ,0.167s

--�ɶ��t�m�޲z��
RGB16X16_TP:process(RGB16X16_TP_clk,rstP99)
variable TT:integer range 0 to 511;		--���q�p�ɾ�
variable T_step:integer range 0 to 7;	--���q
begin
if rstP99='0' then
	RG<='1';			--��Ϩӷ�1
	TT:=40;				--���q�ɶ��]�w
	T_runstep<=0;		--R���q�w�]0
	T_step:=0;			--R���q
elsif rising_edge(RGB16X16_TP_clk) then
	 TT:=TT-1;						--���q�ɶ��˼�
	 if TT=0 then					--���q�ɶ���
		if T_step=6 then			--�w�����̫ᶥ�q
			T_step:=0;				--���q���s�}�l
		else
			T_step:=T_step+1;		--�U�@���q
		end if;
		T_runstep<=T_step;			--��I���涥�q
		case T_step is		--���q�ѼƳ]�w
			when 0=>		--R
				TT:=40;				--���q�ɶ��]�w
			when 1=>		--R->G,G�R�m
				TT:=25;				--���q�ɶ��]�w
			when 2=>		--gGgG:���`�B��
				RG<='0';			--��Ϩӷ�0
				TT:=120;			--���q�ɶ��]�w
			when 3=>		--gGgG:�֨B��
				TT:=30;				--���q�ɶ��]�w
			when 4=>		--gGgG:��B��
				TT:=30;				--���q�ɶ��]�w
			when 5=>		--G�R�m
				RG<='1';			--��Ϩӷ�1
				TT:=15;				--���q�ɶ��]�w
			when others=>	--6:G->R,R�R�m
				TT:=15;				--���q�ɶ��]�w
		end case;
	end if;
end if;
end process RGB16X16_TP;

--RGB16X16_P����t���ܴ�---------------------------
RGB16X16_P_clk<=FD(7) when T_runstep=4 else	--��B��t��
				FD(8) when T_runstep=3 else	--�֨B��t��
				FD(9);						--���`�B��t��

RGB16X16_P:process(RGB16X16_P_clk,rstP99)
variable frames:integer range 0 to 31;	--���d�ɶ�����
variable i:integer range 0 to 31;		--����񦸼�
begin
if rstP99='0' then
	RGB16X16_SCAN_reset<='0';--����off
	--�R��ϧιw�]:�аѦҤp���H�s�X.doc
	RGB16x16_R<=(X"0000",X"0000",X"0001",X"07C1",X"0FF3",X"6FEF",X"F81F",X"DAB8",X"DAB8",X"F81F",X"6FEF",X"0FF3",X"07C1",X"0001",X"0000",X"0000");
	RGB16x16_G<=((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),
				 (others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),
				 (others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'));
elsif rising_edge(RGB16X16_P_clk) then
	RGB16X16_SCAN_reset<='1';	--�Ұʱ���
	case T_runstep is	--���q����
		when 0=>	--���R�m
			i:=16;			--����񦸼ƹw�]
			frames:=3;		--���d�ɶ��w�]
		when 1=>	--�����
			if i=0 then		--���R�m
				G_step<=0;				--�B���0
				frames:=10;				--���d�ɶ��w�]
			elsif scan_1T='1' then		--RGB16X16_SCAN_p�^�H��
				frames:=frames-1;		--���d�ɶ����ƻ���
				if frames=0 then		--frame���d�ɶ���
					RGB16x16_R(i-1)<=RGB16x16_G(i-1);--���ܥk�ഫ
					RGB16x16_G(i-1)<=RGB16x16_R(i-1);
					frames:=3;			--���d�ɶ��w�]
					i:=i-1;				--����񦸼ƻ���
				end if;
			end if;			
		when 2|3|4=>--�ʵe
			if scan_1T='1' then			--RGB16X16_SCAN_p�^�H��
				frames:=frames-1;		--����frame���ƻ���
				if frames=0 then		--frame���d�ɶ���
					G_step<=G_step+1;		--�վ�B���0123
					if T_runstep=2 then		--���`�B��
						frames:=10;			--���d�ɶ��w�]
					elsif T_runstep=3 then	--�֨B��
						frames:=10;			--���d�ɶ��w�]
					else					--��B��
						frames:=10;			--���d�ɶ��w�]
					end if;
				end if;
			end if;
		when 5=>	--���R�m
			frames:=3;		--���d�ɶ��w�]
		when others=>--�����
			if i=16 then	--���R�m
				null;
			elsif scan_1T='1' then	--RGB16X16_SCAN_p�^�H��
				frames:=frames-1;	--���d�ɶ����ƻ���
				if frames=0 then	--frame���d�ɶ���
					RGB16x16_R(i+1)<=RGB16x16_G(i+1);--�k�ܥ��ഫ
					RGB16x16_G(i+1)<=RGB16x16_R(i+1);
					frames:=3;		--���d�ɶ��w�]
					i:=i+1;			--��������ƻ��W
				end if;
			end if;
	end case;
end if;
end process;

-------------------------------------------------------------
BIT_R_L<='0';		--��V�ܴ�
not01<='0';			--�Ϭ��ܴ�
startbit<=0;		--�q15�줸�}�l
maskRGB<="000000";--������X

RGB_point<=conv_integer(Scan_DCBAo);	--�ഫ�ϧΨ��˫���
LED_G<=RGB16x16_G(RGB_point) when RG='1' else RGB16x16_GD(G_step)(RGB_point);	--G �Ϯ׿�ܨ���
LED_R<=RGB16x16_R(RGB_point) when RG='1' else (others=>'0');					--R �Ϯ׿�ܨ���
LED_B<=(others=>'0');															--B �Ϯ׿�ܨ���

--RGB16X16_SCAN_p����t���ܴ�------------------------------------------
RGB16X16_SCAN_p_clk<=FD(6) when T_runstep=4 else	--��B��t��
					 FD(7) when T_runstep=3 else	--�֨B��t��
					 FD(8);							--���`�B��t��

RGB16X16_SCAN_p:process(RGB16X16_SCAN_p_clk,RGB16X16_SCAN_reset)
variable frame:integer range 0 to 15;	--15~0:1 frame
variable T:integer range 0 to 255;		--�C�@���˰��d�ɶ��p�ɾ�
begin
if RGB16X16_SCAN_reset='0' then
	Scan_DCBAo<="0000";	--���˹w�]
	DM13A_RESET<='0';	--���mDM13A_Driver_RGB
	DM13ALE<='0';		--�L��s��ƹw�]
	DM13AOE<='1';		--DM13A off
	frame:=0;			--frame�ƹw�]0
	scan_1T<='0';		--������1������
elsif rising_edge(RGB16X16_SCAN_p_clk) then
	if DM13ALE='0' and DM13AOE='1' then	--�L��s��ƥB��ܤw����
		if DM13A_RESET='0' then			--�|���Ұ�DM13A_Driver_RGB
			DM13A_RESET<='1';			--�Ұ�DM13A_Driver_RGB
			Scan_DCBAo<=Scan_DCBAo-1;	--�վ㱽��
			scan_1T<='0';
		elsif DM13A_Sendok='1' then		--�ǰe����
			DM13A_RESET<='0';			--���mDM13A_Driver_RGB
			DM13ALE<='1';				--��s��ܸ��
		end if;
		T:=0;							--��ܭp���k�s
	else
		DM13ALE<='0';				--��ܸ�Ƥ���s
		DM13AOE<='0';				--���
		T:=T+1;						--��ܭp��
		if T=50 then				--��ܭp�ɨ�
			DM13AOE<='1';			--�����
		elsif T=49 then
			if Scan_DCBAo=0 then	--����15~0����
				if frame=4 then		--
					scan_1T<='1';	--����5frame
					frame:=0;		--���s��frame
				else
					frame:=frame+1;	--����1frame
				end if;
			end if;	
		end if;	
	end if;
end if;
end process RGB16X16_SCAN_p;

end Albert;