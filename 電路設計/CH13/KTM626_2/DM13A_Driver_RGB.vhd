--RGB16x16´ú¸Õ
--105.11.30ª©
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99
--Creator bye ZHAO_LONG

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	
-- ----------------------------------------------------
entity DM13A_Driver_RGB is
	port(DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:in std_logic;
		 startbit:in integer range 0 to 15;		 
		 LandorRGB:in std_logic_vector(5 downto 0);
		 --mask:0:disable 1:enable,00:load,01:xor:10:or,11:and RGB
		 LED_R,LED_G,LED_B:in std_logic_vector(15 downto 0);
		 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;
		 DM13A_Sendok:out std_logic);
end DM13A_Driver_RGB;

-- -----------------------------------------------------
architecture ZHAO_LONG of DM13A_Driver_RGB is
	signal DM13A_CLK:std_logic;
	signal i:integer range 0 to 31;
	constant databitN:integer range 0 to 31:=16;--16 bit
	signal startbitS:integer range 0 to 15;
	signal R,G,B:std_logic;
-- --------------------------
begin

R<=	LED_R(startbitS) when LandorRGB(5)='0' else	--nop
	LandorRGB(2)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="00" else	--load
	LandorRGB(2)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="00" else	--load
	LandorRGB(2) xor LED_R(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="01" else	--xor
	LandorRGB(2) xor LED_R(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="01" else	--xor
	LandorRGB(2) or  LED_R(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="10" else	--or
	LandorRGB(2) or  LED_R(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="10" else	--or
	LandorRGB(2) and LED_R(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="11" else	--and
	LandorRGB(2) and LED_R(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="11" else	--and
	LED_R(startbitS);
G<=	LED_G(startbitS) when LandorRGB(5)='0' else	--nop
	LandorRGB(1)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="01" else	--load
	LandorRGB(1)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="01" else	--load
	LandorRGB(1) xor LED_G(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="01" else	--xor
	LandorRGB(1) xor LED_G(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="01" else	--xor
	LandorRGB(1) or  LED_G(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="10" else	--or
	LandorRGB(1) or  LED_G(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="10" else	--or
	LandorRGB(1) and LED_G(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="11" else	--and
	LandorRGB(1) and LED_G(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="11" else	--and
	LED_G(startbitS);
B<=	LED_B(startbitS) when LandorRGB(5)='0' else	--nop
	LandorRGB(0)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="01" else	--load
	LandorRGB(0)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="01" else	--load
	LandorRGB(0) xor LED_B(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="01" else	--xor
	LandorRGB(0) xor LED_B(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="01" else	--xor
	LandorRGB(0) or  LED_B(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="10" else	--or
	LandorRGB(0) or  LED_B(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="10" else	--or
	LandorRGB(0) and LED_B(startbitS)	 when BIT_R_L='1' and startbitS>startbit and LandorRGB(4 downto 3)="11" else	--and
	LandorRGB(0) and LED_B(startbitS)	 when BIT_R_L='0' and startbitS<startbit and LandorRGB(4 downto 3)="11" else	--and
	LED_B(startbitS);

DM13ASDI_Ro<=R xor not01;
DM13ASDI_Go<=G xor not01;
DM13ASDI_Bo<=B xor not01;
DM13ACLKo<=DM13A_CLK;
DM13ALEo<=DM13ALE;
DM13AOEo<=DM13AOE;

DM13A_Send:process(DM13ACLK,DM13A_RESET)
begin
	if DM13A_RESET='0' then
		i<=0;
		startbitS<=startbit;
		DM13A_CLK<='0';
		DM13A_Sendok<='0';
	elsif rising_edge(DM13ACLK) then
		if i=databitN then
			DM13A_Sendok<='1';
		else
			if DM13A_CLK='0' then
				DM13A_CLK<='1';
			else
				i<=i+1;
				DM13A_CLK<='0';
				if BIT_R_L='1' then 
					startbitS<=startbitS-1;
				else
					startbitS<=startbitS+1;
				end if;
			end if;
		end if;
	end if;
end Process DM13A_Send;

--------------------------------------------
end ZHAO_LONG;
