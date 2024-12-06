--oLED ����
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH7_OLED_1 is
port(gckP31,rstP99:in std_logic;--�t���W�v,�t��reset
	 --oLED SSD1306 128x64
	 oLED_SCL:out std_logic;	--����IO:SCL(50)
	 oLED_SDA:inout std_logic	--����IO:SDA,�������ɹq��(52)
	 );
end entity CH7_OLED_1;

-- -----------------------------------------------------
architecture Albert of CH7_OLED_1 is
	-- ============================================================================
	--oLED SSD1306 Driver --107.01.01��
	component SSD1306_Driver is
		port(I2CCLK,RESET:in std_logic;					--�t�ήɯ�,�t�έ��m
			 SA0:in std_logic;							--�˸m�X��}
		     CoDc:in std_logic_vector(1 downto 0);		--Co & D/C
		     Data_byte:in std_logic_vector(7 downto 0);	--��ƿ�J
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
	signal oLED_Data_byte:std_logic_vector(7 downto 0);	--��ƿ�J
	signal oLED_reLOAD:std_logic;						--���J�X��:0 �i���JData Byte
	signal oLED_LoadCK:std_logic;						--���J�ɯ�
	signal oLED_RWN:integer range 0 to 15;				--����Ū�g����
	signal oLED_I2Cok,oLED_I2CS:std_logic;				--I2Cok,CS ���A
	
	-- --------------------------------------------------------------------------------
	----oLED���O&��ƪ�榡:
	type oLED_T is array (0 to 38) of std_logic_vector(7 downto 0);
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
	signal OLED_DATA_POINTER:integer range 0 to 127;--��X
	signal GDDRAM_i:integer range 0 to 15;			--oled���X
	signal GDDRAMo,GDDRAMo1,GDDRAM2,GDDRAM3,GDDRAM4,GDDRAM5:std_logic_vector(7 downto 0);--�q�D�ϸ�
	
	-- ----------------------------------------------------------------------------------------
	signal FD:std_logic_vector(24 downto 0);		--���W��
	signal oLED_P_RESET,oLED_P_ok:std_logic;		--oLED_P���m�B����
	signal Vline:integer range 0 to 127;			--�����u��m
	signal Hline:std_logic_vector(63 downto 0);		--�����u�˪O
	signal HN:integer range 0 to 255;				--�����u�ާ@����
	signal OLEDtestM:std_logic_vector(2 downto 0);	--oLED �ϸ�q�D�Υ\����
	signal OLEDset_P_RESET,OLEDset_P_ok,not01,RL:std_logic;--OLEDset_P���m�B���� ,�ϬۡB��V�ާ@�X��
	signal times:integer range 0 to 2047;--����ɶ�

begin

--=====================================================================================
--oLED---------------------------
U1: SSD1306_Driver port map(oLED_I2CCLK,oLED_RESET,'0',oLED_CoDc,oLED_Data_byte,oLED_reLOAD,oLED_LoadCK,3,oLED_I2Cok,oLED_I2CS,oLED_SCL,oLED_SDA);

-- --------------------------
oLED_test_Main:process(FD(17))		--oLED_test_Main�D�����ާ@�t�v
begin
	if rstP99='0' then			--�t�έ��m
		OLEDtestM<="000";		--oLED �ϸ�q�D�Υ\����
		OLEDset_P_RESET<='0';	--OLEDset_P����X��:���m
		oLED_COM_POINTERs<=1;	--oLED�R�O����:���U�R�O
		not01<='0';				--0:���`
		RL<='0';				--0:��V�w�]
		Vline<=0;				--0:�����u��m�w�]
		Hline<=(others=>'0');	--0:�����u��m�w�]
		HN<=0;					--�����ާ@���ƹw�]
		times<=200;				--����ɶ��w�]
	elsif rising_edge(FD(17)) then
		if OLEDset_P_ok='1' then	--����OLEDset_P����
			OLED_COM_POINTERs<=conv_integer(OLED_RUNT(0))+1;	--oLED�R�O����:���A�U�R�O
			times<=times-1;		--����p��
			if times=0 then		--�p�ɨ�
				OLEDset_P_RESET<='0';	----oLED_P����X��:���m
				case OLEDtestM is	--��\��
					when "000" =>	--000 ���t
						OLEDtestM<="001";	--0001 ���G
						times<=200;
					when "001" =>	--001 ���G
						OLEDtestM<="010";	--0010 Vline:�����u�ާ@�\��
						times<=0;
					when "010"|"011"|"100"=>--0010 011 0100:Vline�����u�ާ@�\��
						times<=0;	--���]�p��
						if Vline=0 and RL='1' then	--�\��Ӥ����F
							RL<='0';--��V���]
							if OLEDtestM="010" then
								OLEDtestM<="011";	--��ܸ�Ƴq�D���
							elsif OLEDtestM="011" then
								OLEDtestM<="100";	--��ܸ�Ƴq�D���
							else
								OLEDtestM<="101";	--��ܸ�Ƴq�D��ܤΤ����u�ާ@�ܴ�
								Hline<=(Hline'range=>'0')+'1';
							end if;
						elsif Vline=127 and RL='0' then	--���ܤ�V�F
							RL<='1';			--��V�ܴ�
						else
							if RL='0' then
								Vline<=Vline+1;	--L->R
							else
								Vline<=Vline-1;	--R->L
							end if;
						end if;
					when "101"=>	--Hline �����u�ާ@
						times<=5;	--���]�p��
						if HN=0 and RL='1' then
							RL<='0';--��V���]
							OLEDtestM<="110";		--�����u�ާ@�ܴ�
						elsif HN=63 and RL='0' then	--���ܤ�V�F
							RL<='1';--��V�ܴ�
							HN<=64;	--�]64��
						else
							if RL='0' then
								Hline<=Hline(62 downto 0) & '0';	--U->D
								HN<=HN+1;
							else
								Hline<='0' & Hline(63 downto 1);	--D->U
								HN<=HN-1;
							end if;
						end if;
					 when others =>
						times<=5;	--���]�p��
						if HN=0 and RL='1' then
							RL<='0';			--��V���]
							OLEDtestM<="000";	--�\�୫��
							not01<=not not01;	--�Ϭ۾ާ@
							times<=200;	--���]�p��
						elsif HN=128 and RL='0' then	--���ܤ�V�F
							RL<='1';	--��V�ܴ�
						else
							if RL='0' then
								Hline<=Hline(62 downto 0) & not Hline(63);	--U->D
								HN<=HN+1;
							else
								Hline<=not Hline(0) & Hline(63 downto 1);	--D->U
								HN<=HN-1;
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
--10�����u �ѽX
GDDRAM2<="11111111" when Vline=oLED_DATA_POINTER else "00000000";
GDDRAM3<="11111111" when Vline>=oLED_DATA_POINTER else "00000000";
GDDRAM4<="11111111" when (127-Vline)<=oLED_DATA_POINTER else "00000000";

--11�����u �ѽX
GDDRAM5<=Hline(7 downto 0) when GDDRAM_i=0 else
		 Hline(15 downto 8) when GDDRAM_i=1 else
		 Hline(23 downto 16) when GDDRAM_i=2 else
		 Hline(31 downto 24) when GDDRAM_i=3 else
		 Hline(39 downto 32) when GDDRAM_i=4 else
		 Hline(47 downto 40) when GDDRAM_i=5 else
		 Hline(55 downto 48) when GDDRAM_i=6 else
		 Hline(63 downto 56);

--��ܸ�Ƴq�D���---------------------------------------------------------------	
with oLEDtestM select	
GDDRAMo1<="00000000" when "000",
		  "11111111" when "001",
		  GDDRAM2	 when "010",
		  GDDRAM3	 when "011",
		  GDDRAM4	 when "100",
		  GDDRAM5	 when others;		  
		  
GDDRAMo<=GDDRAMo1 when not01='0' else not GDDRAMo1; --�Ϭ۸ѽX
	 
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
OLED_Data_byte<=OLED_RUNT(OLED_COM_POINTER) when OLED_CoDc="10" else GDDRAMo;
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
	
