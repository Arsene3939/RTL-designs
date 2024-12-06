--RS232RX
Library IEEE;
Use IEEE.std_logic_1164.all;
Use IEEE.std_logic_unsigned.all;

entity RS232_R2 is
	port(Clk,Reset:in std_logic;				--clk:25MHz
		 DL:in std_logic_vector(1 downto 0);	 --00:5,01:6,10:7,11:8 Bit
		 ParityN:in std_logic_vector(2 downto 0);--0xx:None,100:Even,101:Odd,110:Space,111:Mark
		 StopN:in std_logic_vector(1 downto 0);	 --0x:1Bit,10:2Bit,11:1.5Bit
		 F_Set:in std_logic_vector(2 downto 0);
		 Status_s:out std_logic_vector(2 downto 0);
		 Rx_R:in std_logic;
		 RD:in std_logic;
		 RxDs:out std_logic_vector(7 downto 0));
end RS232_R2;

architecture Albert of RS232_R2 is
signal StopNn:std_logic_vector(2 downto 0);
signal Rx_B_Empty,Rx_P_Error,Rx_OW,Rx_R2:std_logic;

signal RDf,Rx_f,Rx_PEOSM,R_Half_f:std_logic;
signal RxD,RxDB:std_logic_vector(7 downto 0);
signal Rsend_RDLNs,RDLN:std_logic_vector(3 downto 0);
signal Rc:std_logic_vector(2 downto 0);
signal Rx_s,Rff,BaudRate1234:std_logic_vector(1 downto 0);
signal RX_BaudRate:integer range 0 to 20832;

begin
Status_s<=Rx_B_Empty & Rx_P_Error & Rx_OW;
RDf<=clk when (Rx_s(0) = Rx_s(1)) else Rx_f;
-------------------------------------------
RxP:Process(RDf,Reset)
begin
if Reset='0' then
	Rx_OW<='0';
	Rx_B_Empty<='0';
	Rx_P_Error<='0';
	Rx_R2<=Rx_R;
	Rx_s<="00";
elsif falling_edge(RDf) then
	if Rx_R2/=Rx_R and Rsend_RDLNs/=RDLN then
		if Rx_R='1' then
			Rx_OW<='0';
			Rx_B_Empty<='0';
			Rx_P_Error<='0';
		end if;
		Rx_R2<=Rx_R;
	end if;
	if Rx_s=0 then
		if RD='0' then	--Start Bit
			Rx_s<="01";
			R_Half_f<='1';
			Rx_PEOSM<=ParityN(0);
		end if;
		Rsend_RDLNs<="0000";
	elsif Rx_s="11" then--Stop Bit
		Rx_s<=not (RD & RD);
	else
		R_Half_f<=not R_Half_f;
		if R_Half_f='1' then
			if Rsend_RDLNs=RDLN then
				RxDs<=RxDB;
				Rx_B_Empty<='1';			--Rx Buffer Full
				Rx_OW<=Rx_B_Empty; 			--Rx Buffer Over Write
				if ParityN(2)='1' then		--Now is Parity Bit
					if RD/=Rx_PEOSM then
						Rx_P_Error<='1';	--Parity Error
					end if;					
					Rx_s<="11";
				else						--Now is Stop Bit
					Rx_s<="00";
				end if;
			else							--Now is Start or Data Bit
				RxD<=RD & RxD(7 downto 1);
				Rx_PEOSM<=Rx_PEOSM xor RD;
				Rsend_RDLNs<=Rsend_RDLNs+1;	--含Start Bit
			end if;
		end if;
	end if;
end if;
end process RxP;

RxBaudP:process(clk,Rx_s)
variable F_Div:integer range 0 to 20832;
begin
	if Rx_s(0)=Rx_s(1) then
		F_Div:=0;Rx_f<='1';
		BaudRate1234<="00";
	elsif rising_edge(clk) then
		if F_Div=RX_BaudRate then
			F_Div:=0;
			Rx_f<=not Rx_f;
			BaudRate1234<=BaudRate1234+1;
		else
			F_Div:=F_Div+1;
		end if;
	end if;
end process RxBaudP;
------------------------------------------
with (F_Set & BaudRate1234) select
  RX_BaudRate<=	--Baud Rate Set 依Clk=25MHz設定
		20832 when "00000",--300:25000000/((20832+1)*4)=300.0048001
		20832 when "00001",--300
		20832 when "00010",--300
		20832 when "00011",--300
        10416 when "00100",--600
        10416 when "00101",--600
        10416 when "00110",--600
        10416 when "00111",--600
        5207  when "01000",--1200
        5207  when "01001",--1200
        5207  when "01010",--1200
        5207  when "01011",--1200
        2603  when "01100",--2400
        2603  when "01101",--2400
        2603  when "01110",--2400
        2603  when "01111",--2400
        1301  when "10000",--4800
        1301  when "10001",--4800
        1301  when "10010",--4800
        1301  when "10011",--4800
        650   when "10100",--9600
        650   when "10101",--9600
        650   when "10110",--9600
        650   when "10111",--9600
        324   when "11000",--19200
        325   when "11001",--19200校正頻率
        324   when "11010",--19200
        325   when "11011",--19200校正頻率
        162   when "11100",--38400
        162   when "11101",--38400
        161   when "11110",--38400校正頻率
        162   when "11111",--38400
        0 	  when others;
-------------------------------
with DL select	--Data Length 含Start Bit
  RDLN<="0110" when "00",   --5bit 
        "0111" when "01",	--6bit
        "1000" when "10",	--7bit
        "1001" when "11",	--8bit
        "0000" when others;
-------------------------------
with DL select	--Data Length 
  RxDB<="000" & RxD(7 downto 3) when "00",	--5bit 
        "00" & RxD(7 downto 2) when "01",	--6bit
        "0" & RxD(7 downto 1) when "10",	--7bit
        RxD 				 when "11",		--8bit
        "11111111" 			when others;
-------------------------------
with StopN select
  StopNn<="101" when "10",--2bit
          "110" when "11",--1.5bit
          "111" when others; --1bit
----------------------------------------------------
end Albert;
