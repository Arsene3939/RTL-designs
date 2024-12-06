--Ws2812B RGB_LED �R�E�O1
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckP31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

entity CH3_WS2812B_1 is	
	port(gckP31,rstP99:in std_logic;--�t�ήɯ�,�t�έ��m
		 WS2812Bout:out std_logic);	--WS2812B_Di�H����X(184)
end entity CH3_WS2812B_1;

architecture Albert of CH3_WS2812B_1 is
	--WS2812B�X�ʾ�--------------------
	component WS2812B_Driver is
		port(	WS2812BCLK,WS2812BRESET,loadck:in std_logic;--�ާ@�W�v,���m,���Jck
				LEDGRBdata:in std_logic_vector(23 downto 0);--��m���
				reload,emitter,WS2812Bout:out std_logic		--�n�D���J,�o�g���A,�o�g��X 
			);
	end component;
	signal WS2812BCLK,WS2812BRESET,loadck,reload,emitter:std_logic;
	--�ާ@�W�v,���m,���Jck,�n�D���J,�o�g���A
	signal LEDGRBdata:std_logic_vector(23 downto 0);--��m���

	signal FD:std_logic_vector(24 downto 0);	--�t�ΰ��W��
	signal FD2:std_logic_vector(3 downto 0);	--WS2812B_Driver���W��
	signal SpeedS,WS2812BPCK:std_logic;			--WS2812BP�ާ@�W�v���,WS2812BP�ާ@�W�v
	signal delay:integer range 0 to 127;		--����ɶ�
	signal LED_WS2812B_N:integer range 0 to 127;--WS2812B�Ӽƫ���
	constant NLED:integer range 0 to 127:=29;	--WS2812B�Ӽ�:61��(0~60)
	signal RC,GC,BC:std_logic_vector(7 downto 0);--��,��,�Ŧ�

begin

--WS2812B�X�ʾ�--------------------------
WS2812BN: WS2812B_Driver port map(WS2812BCLK,WS2812BRESET,loadck,LEDGRBdata,reload,emitter,WS2812Bout);
		  WS2812BRESET<=rstP99;	--�t�έ��m

--��m��� ------------------------------
LEDGRBdata<=GC & RC & BC;

--WS2812BP�ާ@�W�v���
WS2812BPCK<=FD(8) when SpeedS='0' else FD(16);--�̺C�t�v

--WS2812BP �D���� -----------------------
WS2812BP:process(WS2812BPCK)
variable cc:integer range 0 to 15;				--�ⶥ
variable RGBcase:std_logic_vector(3 downto 0);	--��L����
variable RA,GA,BA:std_logic_vector(1 downto 0);	--��,��,�Žզ⪬�A
begin
	if rstP99='0' then
		LED_WS2812B_N<=NLED;	--�q�Y�}�l
		RGBcase:=(others=>'0');	--��L�����w�]
		cc:=0;					--�ⶥ�w�]
		loadck<='0';			--���ݸ��J
		SpeedS<='1';			--�[�־ާ@�t�v
	elsif rising_edge(WS2812BPCK) then
		if loadck='0' then	--���ݸ��J
			loadck<=reload;	--�O�_���J
		elsif LED_WS2812B_N=NLED then	--��X�ӼƧ���
			SpeedS<='1';			--��C�ާ@�t�v
			if emitter='0' then		--�w����o�g
				if delay/=0 then	--�I�G�ɶ�&�ܤƳt�v
					delay<=delay-1;	--�ɶ�����
				else
					loadck<='0';	--reemitter
					LED_WS2812B_N<=0;--�q�Y�}�l
					SpeedS<='0';	--�[�־ާ@�t�v
					if cc=0 then
						cc:=8;		--8�ⶥ��
						case RGBcase is
							when "0000"=>
								RC<=(others=>'0');	--�����t
								GC<=(others=>'0');	--����t
								BC<=(others=>'0');	--�ť��t
								RA:="10";	--8�q���W
								GA:="00";	--����
								BA:="00";	--����
							when "0001"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="00";	--����
								GA:="10";	--8�q���W
								BA:="00";	--����
							when "0010"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="00";	--����
								GA:="00";	--����
								BA:="10";	--8�q���W
							when "0011"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="10";	--8�q���W
								GA:="10";	--8�q���W
								BA:="00";	--����
							when "0100"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="10";	--8�q���W
								GA:="00";	--����
								BA:="10";	--8�q���W
							when "0101"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="00";	--����
								GA:="10";	--8�q���W
								BA:="10";	--8�q���W
							when "0110"=>
								RC<=(others=>'0');
								GC<=(others=>'0');
								BC<=(others=>'0');
								RA:="10";	--8�q���W
								GA:="10";	--8�q���W
								BA:="10";	--8�q���W
							when "0111"=>
								RC<=(others=>'1');	--�����G
								GC<=(others=>'1');	--����G
								BC<=(others=>'1');	--�ť��G
								RA:="01";	--8�q����
								GA:="00";	--����
								BA:="00";	--����
							when "1000"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="00";	--����
								GA:="01";	--8�q����
								BA:="00";	--����
							when "1001"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="00";	--����
								GA:="00";	--����
								BA:="01";	--8�q����
							when "1010"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="01";	--8�q����
								GA:="01";	--8�q����
								BA:="00";	--����
							when "1011"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="01";	--8�q����
								GA:="00";	--����
								BA:="01";	--8�q����
							when "1100"=>
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="00";	--����
								GA:="01";	--8�q����
								BA:="01";	--8�q����
							when "1101"=>	
								RC<=(others=>'1');
								GC<=(others=>'1');
								BC<=(others=>'1');
								RA:="01";	--8�q����
								GA:="01";	--8�q����
								BA:="01";	--8�q����
							when "1110"=>	
								RC<=(others=>'0');	--�����t
								GC<=(others=>'1');	--�ť��G
								BC<=(others=>'1');	--�ť��G
								RA:="10";	--8�q���W
								GA:="01";	--8�q����
								BA:="01";	--8�q����
							when others=>
								RC<=(others=>'1');	--�ť��G
								GC<=(others=>'0');	--����t
								BC<=(others=>'1');	--�ť��G
								RA:="01";	--8�q����
								GA:="10";	--8�q���W
								BA:="01";	--8�q����
						end case;
						RGBcase:=RGBcase+1;
					else
						if RA="10" then
							RC<=RC(6 downto 0) & '1';	--���W
						elsif RA="01" then
							RC<='0' & RC(7 downto 1);	--����
						end if;
						if GA="10" then
							GC<=GC(6 downto 0) & '1';	--���W
						elsif GA="01" then
							GC<='0' & GC(7 downto 1);	--����
						end if;
						if BA="10" then
							BC<=BC(6 downto 0) & '1';	--���W
						elsif BA="01" then
							BC<='0' & BC(7 downto 1);	--����
						end if;
						cc:=cc-1;	--�ⶥ�� ����
					end if;

				end if;
			end if;
		else
			loadck<='0';
			LED_WS2812B_N<=LED_WS2812B_N+1;	--��X�Ӽƻ��W
			delay<=80;
		end if;

	end if;
end process WS2812BP;

-- ���W��--------------------------------
Freq_Div:process(gckP31)
begin
	if rstP99='0' then		--�t�έ��m
		FD<=(others=>'0');
		FD2<=(others=>'0');
		WS2812BCLK<='0';			--WS2812BN�X���W�v
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--���W��:2�i��W��(+1)�p�ƾ�
		if FD2=9 then				--7~12
			FD2<=(others=>'0');
			WS2812BCLK<=not WS2812BCLK;--50MHz/20=2.5MHz T.=. 0.4us
		else
			FD2<=FD2+1;				--���W��2:2�i��W��(+1)�p�ƾ�
		end if;
	end if;
end process Freq_Div;

end Albert;