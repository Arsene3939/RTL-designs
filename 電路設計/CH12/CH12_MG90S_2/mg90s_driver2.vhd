--MG90S ����
--107.01.01��
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP9

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- ----------------------------------------------------
entity MG90S_Driver2 is
	port(MG90S_CLK,MG90S_RESET:in std_logic;		--MG90S_Driver�X��clk(25MHz),reset�H��
		 MG90S_deg:in integer range 0 to 180;		--��ʨ���
		 MG90S_o:out std_logic);					--Driver��X
end entity MG90S_Driver2;

-- -----------------------------------------------------
architecture Albert of MG90S_Driver2 is
	signal MG90Servd:integer range 0 to 50010;	--���״����
	signal MG90Servs:integer range 0 to 63000;	--servo pwm��v��
	signal MG90Serv:integer range 0 to  500000;	--servo pwm���;�

-- --------------------------
begin

--���״����--0~180--------------------
MG90Servd<=2778*MG90S_deg/10;	--���״����0~50000
MG90Servs<=12500+MG90Servd;

--servo pwm���;�--------------------------------------------------
MG90S_o<='1' when MG90Serv<MG90Servs and MG90S_RESET='1' else '0';

--50Hz���;�
MG90S:process(MG90S_CLK,MG90S_RESET)
begin
	if MG90S_RESET='0' then
		MG90Serv<=0;
	elsif rising_edge(MG90S_CLK) then
		--20ms
		MG90Serv<=MG90Serv+1;
		if MG90Serv=499999 then	--50Hz
			MG90Serv<=0;
		end if;
	end if;
end process MG90S;

--------------------------------------------
end Albert;
