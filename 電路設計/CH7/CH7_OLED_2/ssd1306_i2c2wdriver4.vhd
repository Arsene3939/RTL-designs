--SSD1306_I2C_driver4:I2C���\�઩
--SSD1306_I2C ��C�Ҧ��u�వ�g�J�@�~ Write mode
--Co:--1=word or 0=byte mode,byte mode�ᤣ��A�]�^word mode
--107.01.01��

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��;

--------------------------------------------------------------------------
entity  SSD1306_I2C2Wdriver4 is
   port(  I2CCLK,RESET:in std_logic;				--�t�ήɯ�,�t�έ��m
		  SA0:in std_logic;							--�˸m�X��}
		  CoDc:in std_logic_vector(1 downto 0);		--Co & D/C
		  Data_byte:in std_logic_vector(7 downto 0);--��ƿ�J
		  reLOAD:out std_logic;						--���J�X��:0 �i���JData Byte
		  LoadCK:in std_logic;						--���J�ɯ�
		  RWN:in integer range 0 to 15;				--����Ū�g����
		  I2Cok,I2CS:buffer std_logic;				--I2Cok,CS ���A
		  SCL:out std_logic;						--����IO:SCL,�p�������ɹq���ɥi�]��inout
		  SDA:inout std_logic						--SDA��J��X
		);
end SSD1306_I2C2Wdriver4;

--------------------------------------------------------------------------
architecture Albert of SSD1306_I2C2Wdriver4 is
	signal Wdata:std_logic_vector(29 downto 0);	--�g�R�O��
	signal Data_byte_Bf:std_logic_vector(7 downto 0);	--Data_byte
	signal CoDc_Bf:std_logic_vector(1 downto 0);--CoDo
	signal Co,Buffer_Clr,Buffer_Empty:std_logic;
	signal I2Creset,SCLs,SDAs:std_logic;		--���ѭ���,SCL,SDAs->SDAout,SDAin-->SDA
	signal I:integer range 0 to 2;		 		--�ۦ����
	signal WN:integer range 0 to 29;			--�g�R�O����
	signal PN:integer range 0 to 29;			--���~�Ȱ��ɶ�
	signal RWNS:integer range 0 to 15;			--����Ū�g���ƭp�ƾ�

begin

-----------------------------------
SDA<='0' when SDAs='0' else 'Z';--SDA bus����

SCL<='0' when SCLs='0' else '1'; 
--����IO:SCL,�p�������ɹq���ɥi�]��inout
--SCL<='0' When SCLs='0' Else 'Z';

reLOAD<=Buffer_Empty or Buffer_Clr;

-----------------------------------
Data_in:Process(LoadCK,Reset)
Begin
If reset='0' or Buffer_Clr='1' Then
	Buffer_Empty<='0';
Elsif LoadCK'event and LoadCK='1' Then
	Data_byte_Bf<=Data_byte;
	CoDc_Bf<=CoDc;
	Buffer_Empty<='1';		--Buffer_Empty='1'��ܤw����Ƽg�J(�|���ǥX)
End If;
End Process Data_in;

-----------------------------------
process(I2CCLK,RESET)
begin
	if RESET='0' then
		--      S �˸m�X        ��}  /�g   ack   Control byte      ack   �g�J���    ack    P
		Wdata<='0' & "011110" & SA0 & '0' & '1' & CoDc & "000000" & '1' & Data_byte & '1' & "00";	--(0)�S�Ψ�,�����X
		--�pCo=1,�h��word mode(16bit)=(Control byte +Data byte)+(Control byte +Data byte),
		--�U�@����JWdata(10 downto 3)<=Data_byte,WN�A�q19�_
		--�pCo=0,�h��byte mode(8bit)=Control byte(�u��1��)+ Data byte.....,
		--�U�@����JWdata(10 downto 3)<=Data_byte,WN�A�q10�_
		Co<=CoDc(1);--1=word or 0=byte mode
		
		I<=0;		--�]0�ۦ�
		WN<=29;		--�]�g�J�����I
	
		SCLs<='1';	--�]I2C�����m
		SDAs<='1';	--�]I2C�����m
		I2CS<='0';	--�]�L���A
		I2CoK<='0';	--�]�������X��
		
		RWNS<=RWN;	--����Ū�g����
		PN<=29;		--���~�Ȱ��ɶ�
		I2Creset<='0';	--�M�����s����X��
		Buffer_Clr<='0';
	elsif rising_edge(I2CCLK) then
		Buffer_Clr<='0';
		if I2Cok='0' Then	--�|������
			--���ѦA����
			if I2Creset='1' then	--���s�_�l
				SCLs<='1';			--bus�Ȱ�
				SDAs<='1';			--bus�Ȱ�
				I<=0;WN<=29;		--���~�^�_�����I
				if PN=0 then		--�Ȱ��ɶ�
					PN<=29;			--���]���~�Ȱ��ɶ�
					I2Creset<='0';	--�������s����X��
					RWNS<=RWNS-1;	--���զ���
					if RWNS<=1 then	--���զ��Ƥw�Χ�
						I2Cok<='1';	--����
						I2CS<='1';	--����
					end if;
				else
					PN<=PN-1;		--�Ȱ��ɶ��˼�
				end if;
			else -- RW='0' --OLED��C�Ҧ��u�వ�g�J�@�~
				if WN=0 then 	--�����I
					SDAs<='1';	--Stop
					I2CoK<='1';	--�����g�J(���\)
				else
					I<=I+1;			--�U�@�ۦ�
					case I is
						when 0 =>	--0�ۦ�
							SDAs<=Wdata(WN);--�줸��X
						when 1 =>	--1�ۦ�
							SCLs<='1';	--SCK�԰�
							WN<=WN-1;	--�U�@bit
							if WN=20 or WN=11 or WN=2 then	--��ACK�I
								if WN=20 then		--ACK���J--�Ĥ@���o�{ACK���~�ɤ~���s����
									I2Creset<=SDA;	--ŪSSD1306�o�X��ACK(�C�A:���`,���A:���~)
								elsif SDA='1' then	--ŪSSD1306�o�X��ACK
									I2CoK<='1';	--�����g�J(����)
									I2CS<='1';	--����
								end If;
							end If;
						when oThers =>--2�ۦ�
							SCLs<='0';	--SCK�U��
							I<=0;		--�^0�ۦ�
							if WN=1 then
								if Buffer_Empty='1' then	--�U�@���w�g�i��
									Wdata(10 downto 3)<=Data_byte_Bf;	--�U�@�����J
									Wdata(19 downto 18)<=CoDc_Bf;
									if Co='1' then	--word mode
										Co<=CoDc_Bf(1);
										WN<=19;	--�s�����I
									else			--byte mode
										WN<=10;	--�s�����I
									end if;
									Buffer_Clr<='1';--�M��buffer
								end if;	
							end if;
						end case;
				end if;
			end if;
		end if;
	end if;
end process;

--------------------------------------------------------------
end Albert;