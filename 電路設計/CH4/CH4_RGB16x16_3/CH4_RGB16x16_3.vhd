--RGB16x16�]���O����
--106.12.30��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH4_RGB16x16_3 is
port(gckP31,rstP99:in std_logic;	--�t���W�v,�t��reset
	 --DM13A ��X
	 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;
	 --186,187,189,194,188,185
	 --Scan ��X
	 Scan_DCBAo:buffer std_logic_vector(3 downto 0)
	 --198,197,196,195
    );
end entity CH4_RGB16x16_3;

-- -----------------------------------------------------
architecture Albert of CH4_RGB16x16_3 is
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
	signal Gspeed:integer range 0 to 3;			--�ϧΨ��˳t��
	signal RGB_point1:integer range 0 to 15;	--�ϧΨ��˫���(���˽d��)
	signal RGB_point0:integer range 0 to 127;	--�ϧΨ��˫���(�_�I)
	signal RGB16X16_SCAN_p_clk:std_logic;		--clk
	type RGB16x16_T1 is array(0 to 127) of std_logic_vector(15 downto 0);--�Ϲ��榡
	--�Ϲ�
	--�Ϲ�:�аѦ�R.docx,G.docx,B.docx  8�Ӧr�ι�
	constant RGB16x16_RD:RGB16x16_T1:=(	X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",--�j
										X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",--�a
										X"FBBF",X"DBB7",X"DB67",X"DACF",X"01FB",X"5BF9",X"DB03",X"DB7F",X"DBEF",X"03F3",X"59DF",X"DAEF",X"9B67",X"D33F",X"FB7F",X"FFFF",--��
										X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",--��
										X"FFFF",X"FFFF",X"C003",X"C003",X"C003",X"C7E3",X"C7E3",X"C663",X"C663",X"C7E3",X"C7E3",X"C003",X"C003",X"C003",X"FFFF",X"FFFF",
										X"0000",X"77DC",X"745C",X"729C",X"0920",X"6440",X"72C8",X"79D8",X"73C8",X"67C0",X"0820",X"701C",X"501C",X"701C",X"0000",X"0000",
										X"FFFE",X"BFFE",X"7FFE",X"A0FE",X"FFFE",X"A0FE",X"7FFE",X"A1FE",X"FFFE",X"A77E",X"7FFE",X"B87E",X"FFFE",X"FFFE",X"FFFE",X"FFFE",
										X"0000",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"7FFC",X"0000");
										
	constant RGB16x16_GD:RGB16x16_T1:=(	X"F7FD",X"F7FD",X"F7FB",X"F7F7",X"F7EF",X"F79F",X"F67F",X"00FF",X"777F",X"F79F",X"F7EF",X"F7F7",X"F7FB",X"E7F9",X"F7FB",X"FFFF",--�j
										X"F7D7",X"8ED7",X"D6B7",X"D5AF",X"D56B",X"52DB",X"94B9",X"D703",X"D77F",X"D6BF",X"D5DF",X"DDDF",X"D7EF",X"8FE7",X"DFEF",X"FFFF",--�a
										X"0440",X"2448",X"2498",X"2530",X"FE04",X"A406",X"24FC",X"2480",X"2410",X"FC0C",X"A620",X"2510",X"6498",X"2CC0",X"0480",X"0000",--��
										X"FFBF",X"BFBF",X"AFBF",X"A8A1",X"AAAB",X"AA2B",X"AAAB",X"0AAB",X"AAAB",X"AA2B",X"AAAB",X"A8A1",X"AFBF",X"BF3F",X"FFBF",X"FFFF",--��
										X"0000",X"7FFE",X"7FFE",X"6006",X"6FF6",X"6816",X"6BD6",X"6A56",X"6A56",X"6BD6",X"6816",X"6FF6",X"6006",X"7FFE",X"7FFE",X"0000",
										X"0000",X"0000",X"2380",X"0100",X"0000",X"638C",X"551C",X"4E3C",X"551C",X"638C",X"0100",X"0280",X"2448",X"07C0",X"0000",X"0000",
										X"C001",X"C001",X"DF7D",X"DF3D",X"DF0D",X"DF0D",X"DF0D",X"DE1D",X"DC7D",X"D8FD",X"D3FD",X"C7FD",X"C001",X"8001",X"3FFF",X"7FFF",
										X"FFFF",X"8003",X"8003",X"BFDB",X"B39B",X"A19B",X"A01B",X"BC3B",X"B83B",X"B01B",X"B19B",X"B3DB",X"BBDB",X"8003",X"8003",X"FFFF");
										
	constant RGB16x16_BD:RGB16x16_T1:=(	X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",X"0000",--�j
										X"0828",X"7128",X"2948",X"2A50",X"2A94",X"AD24",X"6B46",X"28FC",X"2880",X"2940",X"2A20",X"2220",X"2810",X"7018",X"2010",X"0000",--�a
										X"FBBF",X"DBB7",X"DB67",X"DACF",X"01FB",X"5BF9",X"DB03",X"DB7F",X"DBEF",X"03F3",X"59DF",X"DAEF",X"9B67",X"D33F",X"FB7F",X"FFFF",--��
										X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",X"FFFF",--��
										X"0000",X"0000",X"0000",X"1FF8",X"1FF8",X"1FF8",X"1FF8",X"1E78",X"1E78",X"1FF8",X"1FF8",X"1FF8",X"1FF8",X"0000",X"0000",X"0000",
										X"0000",X"07C0",X"0448",X"0280",X"0100",X"038C",X"0154",X"00E4",X"0054",X"000C",X"0000",X"0100",X"2388",X"0000",X"0000",X"0000",
										X"FFFF",X"BFFF",X"7F83",X"A0C3",X"FFF3",X"A0F3",X"7FF3",X"A1E3",X"FF83",X"A703",X"7F83",X"B803",X"FFFF",X"FFFF",X"FFFF",X"FFFF",
										X"FFFC",X"FFFC",X"FFFC",X"FFE4",X"FFE4",X"FFE4",X"FFE4",X"FFC4",X"FFC4",X"FFE4",X"FFE4",X"FFE4",X"FFE4",X"FFFC",X"FFFC",X"FFFC");
										
						
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

-------------------------------------------------------------
BIT_R_L<='0';		--��V�ܴ�
startbit<=0;		--�q15�줸�}�l
maskRGB<="000000";--������X

RGB_point1<=15-conv_integer(Scan_DCBAo);--�ഫ�ϧΨ��˫���
LED_R<=RGB16x16_RD(RGB_point1+RGB_point0);		--R �Ϯ׿�ܨ���
LED_G<=RGB16x16_GD(RGB_point1+RGB_point0);		--G �Ϯ׿�ܨ���
LED_B<=RGB16x16_BD(RGB_point1+RGB_point0);		--B �Ϯ׿�ܨ���

--RGB16X16_SCAN_p����t���ܴ�------------------------------------------
RGB16X16_SCAN_p_clk<=FD(8) when Gspeed=0 else
					 FD(7) when Gspeed=1 else
					 FD(6) when Gspeed=2 else
					 FD(5);

RGB16X16_SCAN_p:process(RGB16X16_SCAN_p_clk,rstP99)
variable frame:integer range 0 to 31;	--15~0:1 frame
variable T:integer range 0 to 255;		--�C�@���˰��d�ɶ��p�ɾ�
begin
if rstP99='0' then
	Scan_DCBAo<="0000";	--���˹w�]
	RGB_point0<=0;		--����0
	not01<='0';			--�Ϭ��ܴ�
	DM13A_RESET<='0';	--���mDM13A_Driver_RGB
	DM13ALE<='0';		--�L��s��ƹw�]
	DM13AOE<='1';		--DM13A off
	Gspeed<=0;			--�t�׹w�]
	frame:=0;			--frame�ƹw�]0
elsif rising_edge(RGB16X16_SCAN_p_clk) then
	if DM13ALE='0' and DM13AOE='1' then	--�L��s��ƥB��ܤw����
		if DM13A_RESET='0' then			--�|���Ұ�DM13A_Driver_RGB
			DM13A_RESET<='1';			--�Ұ�DM13A_Driver_RGB
			Scan_DCBAo<=Scan_DCBAo-1;	--�վ㱽��
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
			if Scan_DCBAo=0 then	--����15~0����
				if frame=15 then		--
					frame:=0;		--���s��frame
					RGB_point0<=RGB_point0+1;	--����
					if RGB_point0=127 then
						not01<=not not01;		--�Ϭ��ܴ�
						if not01='1' then
							Gspeed<=Gspeed+1;	--����t��
						end if;
					end if;
				else
					frame:=frame+1;	--����1frame
				end if;
			end if;	
		end if;	
	end if;
end if;
end process RGB16X16_SCAN_p;

end Albert;