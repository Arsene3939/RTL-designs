--RS232TX
Library IEEE;
Use IEEE.std_logic_1164.all;
Use IEEE.std_logic_unsigned.all;
-- ----------------------------------------------------
entity RS232_T1 is
	port(Clk,Reset:in std_logic;--clk:25MHz
		 DL:in std_logic_vector(1 downto 0);	 --00:5,01:6,10:7,11:8 Bit
		 ParityN:in std_logic_vector(2 downto 0);--0xx:None,100:Even,101:Odd,110:Space,111:Mark
		 StopN:in std_logic_vector(1 downto 0);	 --0x:1Bit,10:2Bit,11:1.5Bit
		 F_Set:in std_logic_vector(2 downto 0);
		 Status_s:out std_logic_vector(1 downto 0);
		 TX_W:in std_logic;
		 TXData:in std_logic_vector(7 downto 0);
		 TX:out std_logic);
end RS232_T1;

architecture Albert of RS232_T1 is
signal StopNn:std_logic_vector(2 downto 0);
signal Tx_B_Empty,Tx_B_Clr,TxO_W:std_logic;

signal Tx_f,T_Half_f,TX_P_NEOSM:std_logic;
signal TXDs_Bf,TXD2_Bf:std_logic_vector(7 downto 0);
signal Tsend_DLN,DLN:std_logic_vector(3 downto 0);
signal Tx_s:std_logic_vector(2 downto 0);
signal TX_BaudRate:integer range 0 to 20832;
signal BaudRate1234:std_logic_vector(1 downto 0);

begin
Status_s<=Tx_B_Empty & TxO_W;

TxWP:process(TX_W,Reset)
begin
if reset='0' or Tx_B_Clr='1' then
	Tx_B_Empty<='0';
	TxO_W<='0';
elsif rising_edge(Tx_W) then
	TXD2_Bf<=TXData;
	Tx_B_Empty<='1';		--Tx_B_Empty='1'表示已有資料寫入(尚未傳出)
	TxO_W<=Tx_B_Empty;		--TxO_W='1'表示資料未傳出又寫入資料(覆寫)
end if;
end process TxWP;

TxP:process(Tx_f,Reset)
begin
if Reset='0' then
	Tx_s<="000";
	TX<='1';
	Tx_B_Clr<='0';
elsif rising_edge(Tx_f) then
	if Tx_s=0 and Tx_B_Empty='1' then--start bit
		TXDs_Bf<=TXD2_Bf;
		TX<='0';					--start bit
		Tsend_DLN<="0000";
		TX_P_NEOSM<=ParityN(0);		--Even,Odd,Space or Mark
		Tx_B_Clr<='1';
		T_Half_f<='0';
		Tx_s<="001";
	elsif Tx_s/=0 then
		Tx_B_Clr<='0';
		T_Half_f<=not T_Half_f;
		case Tx_s is
			when "001" =>
				if T_Half_f='1' then
					if Tsend_DLN=DLN then
						if ParityN(2)='0' then 	--None Parity Bit
							Tx_s<=StopNn;
							TX<='1';			--Stop Bit
						else
							TX<=TX_P_NEOSM;		--Parity Bit
							Tx_s<="010";
						end if;
					else
						if ParityN(1)='0' then
							TX_P_NEOSM<=TX_P_NEOSM xor TXDs_Bf(0);--Even or Odd
						end if;
						TX<=TXDs_Bf(0);			--Send Data:Bit 0..7
						TXDs_Bf<=TXDs_Bf(0) & TXDs_Bf(7 downto 1);
						Tsend_DLN<=Tsend_DLN+1;
					end if;
				end if;
			when "011" =>
				Tx_s<=StopNn;
				TX<='1';	--Stop Bit
			when others=>
				Tx_s<=Tx_s+1;
		end case;
	end if;
end if;
end process TxP;

TxBaudP:process(clk,Reset)
variable f_Div:integer range 0 to 20832;
begin
	if Reset='0' then
		f_Div:=0;Tx_f<='0';
		BaudRate1234<="00";
	elsif rising_edge(clk) then
		if f_Div=TX_BaudRate then
			f_Div:=0;
			Tx_f<=not Tx_f;
			BaudRate1234<=BaudRate1234+1;
		else
			f_Div:=f_Div+1;
		end if;
	end if;
end process TxBaudP;

with (F_Set & BaudRate1234) select
  TX_BaudRate<=	--Baud Rate Set 依Clk=25MHz設定
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
----------------------------------
with DL select				--Data Length 
  DLN<= "0101" when "00",   --5bit 
        "0110" when "01",	--6bit
        "0111" when "10",	--7bit
        "1000" when "11",	--8bit
        "0000" when others;
----------------------------------        
with StopN select			--Stop Bit
  StopNn<="101" when "10",	--2Bit
          "110" when "11",	--1.5Bit
          "111" when others;--1Bit
---------------------------------------------------------------
end Albert;
