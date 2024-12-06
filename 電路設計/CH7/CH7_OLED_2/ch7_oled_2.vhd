--oLED ����:�}���e��(SCL=50,SDA=52)
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH7_OLED_2 is
port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset
	 --oLED SSD1306 128x64
	 oLED_SCL:out std_logic;	--����IO:SCL
	 oLED_SDA:inout std_logic	--����IO:SDA,�������ɹq��
	 );
end entity CH7_OLED_2;

-- -----------------------------------------------------
architecture Albert of CH7_OLED_2 is
	-- ============================================================================
	--oLED SSD1306 Driver --107.01.01��
	component SSD1306_Driver is
		port(I2CCLK,RESET:in std_logic;					--�t�ήɯ�,�t�έ��m
			 SA0:in std_logic;							--�˸m�X��}
		     CoDc:in std_logic_vector(1 downto 0);		--Co & D/C
		     Data_B:in std_logic_vector(7 downto 0);	--��ƿ�J
		     reLOAD:out std_logic;						--���J�X��:0 �i���JData Byte
		     LoadCK:in std_logic;						--���J�ɯ�
		     RWN:in integer range 0 to 15;				--����Ū�g����
		     I2Cok,I2CS:buffer std_logic;				--I2Cok,CS ���A
		     SCL:out std_logic;							--����IO:SCL,�p�������ɹq���ɥi�]��inout
		     SDA:inout std_logic						--SDA��J��X
		   );
	end component SSD1306_Driver;
	signal oLED_I2CCLK,oLED_RESET:std_logic;			--�t�ήɯ�,�t�έ��m
	signal oLED_SA0:std_logic:='0';						--�˸m�X��}
	signal oLED_CoDc:std_logic_vector(1 downto 0);		--Co & D/C
	signal oLED_Data_B:std_logic_vector(7 downto 0);	--��ƿ�J
	signal oLED_reLOAD:std_logic;						--���J�X��:0 �i���JData Byte
	signal oLED_LoadCK:std_logic;						--���J�ɯ�
	signal oLED_RWN:integer range 0 to 15;				--����Ū�g����
	signal oLED_I2Cok,oLED_I2CS:std_logic;				--I2Cok,CS ���A
	
	-- --------------------------------------------------------------------------------
	----oLED���O&��ƪ�榡:
	type oLED_T is array (0 to 38) of std_logic_vector(7 Downto 0);
	signal oLED_RUNT:oLED_T;
	--oLED=0:oLED��l��128x64
	constant oLED_IT:oLED_T:=(	X"26",--0 ����
								X"AE",--1 display off
							
								X"D5",--2 �]�w���W��ή����W�v
								
								X"80",--3 [7:4]�����W�v,[3:0]���W��
								
								X"A8",--4 �]COM N��
								X"3F",--5 1F:32COM(COM0~COM31 N=32),3F:64COM(COM0~COM31 N=64)
								
								X"40",--6 �]�}�l��ܦ�:0(SEG0)
								
						X"E3",--X"A1",--7 non Remap(column 0=>SEG0),A1 Remap(column 127=>SEG0)
								
								X"C8",--8 ���ˤ�V:COM0->COM(N-1) COM31,C8:COM(N-1) COM31->COM0
								
								X"DA",--9 �]COM Pins�t�m
								X"12",--10 02:���t�m(Disable COM L/R remap),12:����t�m(Disable COM L/R remap),22:���t�m(Enable COM L/R remap),32:����t�m(Enable COM L/R remap)
								
								X"81",--11 �]���
								X"EF",--12 �V�j�V�G
								
								X"D9",--13 �]�w�R�q�g��
								X"F1",--14 [7:4]PHASE2,[3:0]PHASE1
								
								X"DB",--15 �]Vcomh��
								X"30",--16 00:0.65xVcc,20:0.77xVcc,30:0.83xVcc
								
								X"A4",--17 A4:��GDDRAM�M�w��ܤ��e,A5:�����G(���ե�)
								
								X"A6",--18 A6:���`���(1�G0���G),A7�Ϭ����(0�G1���G)
								
								X"D3",--19 �]��ܰ����qOffset
								X"00",--20 00
								
						X"E3",--X"20",--21 �]GDDRAM pointer�Ҧ�
						X"E3",--X"02",--22 00:�����Ҧ�,  01:�����Ҧ�,02:���Ҧ�
								
								--���Ҧ�column start address=[higher nibble,lower nibble] [00]
						X"E3",--X"00",--23 ���Ҧ��U�]column start address(lower nibble):0
								
						X"E3",--X"10",--24 ���Ҧ��U�]column start address(higher nibble):0
								
						X"E3",--X"B0",--25 ���Ҧ��U�]Page start address
								
								X"20",--26 �]GDDRAM pointer�Ҧ�
								X"00",--27 00:�����Ҧ�,  01:�����Ҧ�,02:���Ҧ�
								
								X"21",--28 �����Ҧ��U�]��d��:
								X"00",--29 ��}�l��m0(Column start address)
								X"7F",--30 �浲����m127(Column end address)
								
								X"22",--31 �����Ҧ��U�]���d��:
								X"00",--32 ���}�l��m0(Page start address)
								X"07",--33 ��������m3(Page end address)
								
								X"A1",--34 non Remap(column 0=>SEG0),A1 Remap(column 127=>SEG0)
								
								X"8D",--35 �]�R�qPump
								X"14",--36 14:�}��,10:����
								
								X"AF",--37 display on
								X"E3" --38 nop
							);

	signal OLED_COM_POINTER,OLED_COM_POINTERs:integer range 0 to 63;--�R�O�ާ@����
	signal OLED_DATA_POINTER:integer range 0 to 127;	--��X
	signal GDDRAM_i:integer range 0 to 15;				--oled���X
	signal GDDRAMo,GDDRAM6:std_logic_vector(7 downto 0);--�q�D�ϸ�
	
	-- ----------------------------------------------------------------------------------------
	signal FD:std_logic_vector(24 downto 0);		--���W��
	signal oLED_P_RESET,oLED_P_ok:std_logic;		--oLED_P���m�B����
	signal N:integer range 0 to 15;					--�ާ@����
	signal show_N:integer range 0 to 15;			--�\��
	signal OLEDtestM:std_logic_vector(1 downto 0);	--oLED �ϸ�q�D���
	signal OLEDset_P_RESET,OLEDset_P_ok,sw:std_logic;--OLEDset_P���m�B���� ,�����X��
	signal times:integer range 0 to 2047;--����ɶ�
	
	-- ----------------------------------------------------------------------------------------
	----OLED 128*64�}���e��
	type OLED_T1 is array (0 to 127) of std_logic_vector(63 Downto 0);
	constant OLED_screenShow:OLED_T1:=
   (X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0020400000000000",X"0020400000000000",X"0020401FFE000000",
	X"0020401FFE000000",X"0000407FE0000000",X"0000407FE0000000",X"000441FF80000000",X"000441FF80000000",X"000407FE00000000",X"000407FE00000000",X"00001FFE00000000",
	X"00001FFE00000000",X"001FFFFF80000000",X"001FFFFF80000000",X"0019FFFFE0000000",X"0019FFFFE0000000",X"00007FFFE0000000",X"00007FFFF8000000",X"00001FFFF8000000",
	X"00001FFFF8000000",X"00007FFFFE000000",X"00007FFFFE000000",X"001FFFFFFFFFF000",X"001FFFFFFFFFF000",X"001807FFFFFFFC00",X"001807FFFFFFFC00",X"000001FFFFFF9C00",
	X"000001FFFFFF9C00",X"0000403FFFFFFC00",X"0000403FFFFFFC00",X"0000400061FFFC00",X"0000400061FFFC00",X"00004001E19FFC00",X"00004001E19FFC00",X"00004000019FFC00",
	X"00004000019FFC00",X"00004000019FFC00",X"00004000019FFC00",X"00004000001FFC00",X"00004000001FFC00",X"00004000001FF000",X"00104000001FF000",X"0000400000000000",
	X"0000400000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",
	X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0100000000000000",X"0080000000000000",X"0060000000000000",
	X"0018004000000000",X"0808004000000000",X"1000104000001FF0",X"3000004000001FF0",X"1FFF804000001FFC",X"0000804000001FFC",X"0000004000019FFC",X"0008004000019FFC",
	X"0010004000019FFC",X"0060004000019FFC",X"00C0004001E19FFC",X"0180004001E19FFC",X"000000400061FFFC",X"186100400061FFFC",X"0E2100403FFFFFFC",X"003F00403FFFFFFC",
	X"1F118001FFFFFF9C",X"21110001FFFFFF9C",X"20001807FFFFFFFC",X"21451807FFFFFFFC",X"22291FFFFFFFFFF0",X"261F1FFFFFFFFFF0",X"2031007FFFFE0000",X"3C01007FFFFE0000",
	X"103F801FFFF80000",X"0141001FFFF80000",X"0670007FFFF80000",X"0C20007FFFE00000",X"000019FFFFE00000",X"201219FFFFE00000",X"1FD61FFFFF800000",X"055A9FFFFF800000",
	X"1553001FFE000000",X"325A001FFE000000",X"1FD60407FE000000",X"00120407FE000000",X"00000441FF800000",X"1FEF8441FF800000",X"2AAA80407FE00000",X"2AAA00407FE00000",
	X"2AAA20401FFE0000",X"2AAB20401FFE0000",X"203A204000000000",X"3800204000000000",X"007C000000000000",X"0183000000000000",X"0300800000000000",X"0501400000000000",
	X"05F9400000000000",X"0901200000000000",X"0901200000000000",X"09FF200000000000",X"0911200000000000",X"0911200000000000",X"0511400000000000",X"0501400000000000",
	X"0300800000000000",X"0183000000000000",X"007C000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000",X"0000000000000000");
	
begin

--=====================================================================================
--oLED---------------------------
U1: SSD1306_Driver port map(oLED_I2CCLK,oLED_RESET,'0',oLED_CoDc,oLED_Data_B,oLED_reLOAD,oLED_LoadCK,3,oLED_I2Cok,oLED_I2CS,oLED_SCL,oLED_SDA);

-- --------------------------
oLED_test_Main:process(FD(17))		--oLED_test_Main�D�����ާ@�t�v
begin
	if rstP99='0' then			--�t�έ��m
		OLEDtestM<="00";		--oLED �ϸ�q�D�Υ\����
		OLEDset_P_RESET<='0';	--OLEDset_P����X��:���m
		oLED_COM_POINTERs<=1;	--oLED�R�O����:���U�R�O
		N<=0;					--�ާ@���ƹw�]
		show_N<=0;				--�\��0�w�]:���t
		sw<='0';				--����0�w�]
		times<=200;				--����ɶ��w�]
	elsif rising_edge(FD(17)) then
		if OLEDset_P_ok='1' then	--����OLEDset_P����
			OLED_COM_POINTERs<=conv_integer(OLED_RUNT(0))+1;	--oLED�R�O����:���A�U�R�O
			times<=times-1;		--����p��
			if times=0 then		--�p�ɨ�
				OLEDset_P_RESET<='0';	----oLED_P����X��:���m
				case show_N is	--��\��
					when 0 =>
						OLEDtestM<="01";	--���G
						show_N<=1;
						times<=200;	--���]�p��
					when 1 =>	--
						OLEDtestM<="10";	--���`
						show_N<=2;
						times<=200;	--���]�p��
					when 2=>	--
						OLEDtestM<="11";	--�ϥ�
						show_N<=3;
						times<=200;	--���]�p��
					when 3=>	--���G<-->���t
						times<=25;	--���]�p��
						if N=10 then--���Ƶ���
							OLEDtestM<="10";	--���`
							show_N<=4;
							N<=0;				--�����k�s
						else
							N<=N+1;				--���ƻ��W
							sw<=not sw;			--����
							if sw='0' then
								OLEDtestM<="01";--���G
							else
								OLEDtestM<="00";--���t
							end if;
						end if;
					when 4=>	--���`<-->���t
						times<=50;	--���]�p��
						if N=10 then--���Ƶ���
							OLEDtestM<="11";	--�ϥ�
							show_N<=5;
							N<=0;				--�����k�s
						else
							N<=N+1;				--���ƻ��W
							sw<=not sw;			--����
							if sw='0' then
								OLEDtestM<="10";--���`
							else
								OLEDtestM<="00";--���t
							end if;
						end if;
					when 5=>	--�ϥ�<-->���t
						times<=50;	--���]�p��
						if N=10 then--���Ƶ���
							OLEDtestM<="10";	--���`
							show_N<=6;
							N<=0;				--�����k�s
						else
							N<=N+1;				--���ƻ��W
							sw<=not sw;			--����
							if sw='0' then
								OLEDtestM<="11";--�ϥ�
							else
								OLEDtestM<="00";--���t
							end if;
						end if;
					when 6=>	--���`<-->���G
						times<=50;	--���]�p��
						if N=10 then--���Ƶ���
							OLEDtestM<="11";	--�ϥ�
							show_N<=7;
							N<=0;				--�����k�s
						else
							N<=N+1;				--���ƻ��W
							sw<=not sw;			--����
							if sw='0' then
								OLEDtestM<="10";--���`
							else
								OLEDtestM<="01";--���G
							end if;
						end if;
					when 7=>	--�ϥ�<-->���G
						times<=50;	--���]�p��
						if N=10 then--���Ƶ���
							OLEDtestM<="10";	--���`
							show_N<=8;
							N<=0;				--�����k�s
						else
							N<=N+1;				--���ƻ��W
							sw<=not sw;			--����
							if sw='0' then
								OLEDtestM<="11";--�ϥ�
							else
								OLEDtestM<="01";--���G
							end if;
						end if;
					when others =>	--���`<-->�ϥ�
						times<=50;	--���]�p��
						if N=10 then--���Ƶ���
							OLEDtestM<="00";	--���t
							show_N<=0;
							N<=0;				--�����k�s
							times<=200;			--���]�p��
						else
							N<=N+1;				--���ƻ��W
							sw<=not sw;			--����
							if sw='0' then
								OLEDtestM<="10";--���`
							else
								OLEDtestM<="11";--�ϥ�
							end if;
						end if;
				end case;
			end if;
		else
			OLEDset_P_RESET<='1';	--����OLEDset_P
		end if;
	end if;
end process oLED_test_Main;

--=====================================================================================
--oLED��ܾ�
--����ܸ�ƸѽX
--------------------------------------------------------------------------------
GDDRAM6<=OLED_screenShow(oLED_DATA_POINTER)(7 downto 0)   when GDDRAM_i=0 else
		 OLED_screenShow(oLED_DATA_POINTER)(15 downto 8)  when GDDRAM_i=1 else
		 OLED_screenShow(oLED_DATA_POINTER)(23 downto 16) when GDDRAM_i=2 else
		 OLED_screenShow(oLED_DATA_POINTER)(31 downto 24) when GDDRAM_i=3 else
		 OLED_screenShow(oLED_DATA_POINTER)(39 downto 32) when GDDRAM_i=4 else
		 OLED_screenShow(oLED_DATA_POINTER)(47 downto 40) when GDDRAM_i=5 else
		 OLED_screenShow(oLED_DATA_POINTER)(55 downto 48) when GDDRAM_i=6 else
		 OLED_screenShow(oLED_DATA_POINTER)(63 downto 56);

--��ܸ�Ƴq�D���---------------------------------------------------------------	
with oLEDtestM select	
GDDRAMo<="00000000"  when "00",--���t
		 "11111111"  when "01",--���G
		 GDDRAM6	 when "10",--���`
		 not GDDRAM6 when "11";--�ϥ�	  

--OLEDset_P---------------------------------------------------
--OLED���˺ޱ�
OLEDset_P:process(gckP31)
begin
	if OLEDset_P_RESET='0' then	--OLED���˺ޱ����m
		OLED_P_RESET<='0';	--OLED_P���m
		OLEDset_P_ok<='0';	--OLED���˺ޱ��|������
	elsif rising_edge(gckP31) then
		if OLEDset_P_ok='0' then		--OLED���˺ޱ��|������
			if OLED_P_RESET='1' then	--OLED_P�w�Ұ�
				if OLED_P_ok='1' then	--OLED_P�w����
					OLEDset_P_ok<='1';	--OLED���˺ޱ��w����
				end if;
			else
				OLED_P_RESET<='1';	--�Ұ�OLED_P
			end if;
		end if;
	end if;
end process OLEDset_P;

--OLED_P------------------------------------------------------------------------------
--				�R�O                                               ��ܸ��
OLED_Data_B<=OLED_RUNT(OLED_COM_POINTER) when OLED_CoDc="10" else GDDRAMo;
OLED_I2CCLK<=FD(3);	--OLED�ާ@�t�v

OLED_P:process(gckP31,OLED_P_RESET)
	variable SW:Boolean;				--���A����X��
begin
	if OLED_P_RESET='0' then
		OLED_RESET<='0';				--SSD1306_I2C2Wdriver2���m
		OLED_RUNT<=OLED_IT;				----OLED��l�Ƴ]�w��
		OLED_COM_POINTER<=OLED_COM_POINTERs;--�R�O�_�I
		OLED_DATA_POINTER<=0;
		GDDRAM_i<=0;					--GDDRAM ����i
		OLED_P_ok<='0';					--OLED_P ��������
		SW:=true;						--���J���A�X��
		OLED_CoDc<="10";	--word mode ,command
	elsif rising_edge(gckP31) then
		OLED_LoadCK<='0';
		if OLED_RUNT(0)>=OLED_COM_POINTER then	--�ǰe�R�O
			if OLED_RESET='0' then
				OLED_RESET<='1';		--�Ұ� SSD1306_I2C2Wdriver2
			elsif SW=true then
				OLED_COM_POINTER<=OLED_COM_POINTER+1;
				SW:=false;
			elsif OLED_reLOAD='0' then 	--���J
				OLED_LoadCK<='1';
				SW:=true;
			end if;
		elsif OLED_CoDc="10" then	--������byte�Ҧ�,�s��ǰe��ܸ��
			OLED_CoDc<="01";		--byte mode,display data
			SW:=true;
		elsif GDDRAM_i<8 then		--�ǰe��ܸ��(�e����s)
			if OLED_RESET='0' then	--�|���Ұ� SSD1306_I2C2Wdriver2
				OLED_RESET<='1';	--�Ұ� SSD1306_I2C2Wdriver2
				SW:=false;
			else
				if OLED_reLOAD='0' then
					if SW then	--���J
						OLED_LoadCK<='1';
						SW:=false;
					else
						OLED_DATA_POINTER<=OLED_DATA_POINTER+1;	--�U�@��
						if OLED_DATA_POINTER=127 then			--��ƴ���
							GDDRAM_i<=GDDRAM_i+1;
						end if;
						SW:=true;
					end if;
				end if;
			end if;
		else
			OLED_P_ok<=OLED_I2Cok;
		end if;
	end if;
end process OLED_P;

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
end  Albert;
	
