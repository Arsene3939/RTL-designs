--DM13A驅動器
--106.12.30版

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件

-- ----------------------------------------------------
entity DM13A_Driver_RGB is
	port(--DM13A_Driver_RGB操作頻率,重置,ALE控制,OE控制,方向控制,反相控制
		 DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:in std_logic;
		 startbit:in integer range 0 to 15;		 	--開始操作位元
		 maskRGB:in std_logic_vector(5 downto 0);	--罩蓋操作位元
		 --mask (5):0:disable 1:enable, (4..3)00:load,01:xor:10:or,11:and RGB
		 LED_R,LED_G,LED_B:in std_logic_vector(15 downto 0);	--R G B 圖形位元
		 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;--DM13A 硬體操作位元
		 DM13A_Sendok:out std_logic);	--DM13A_Driver_RGB完成操作位元
end DM13A_Driver_RGB;

-- -----------------------------------------------------
architecture Albert of DM13A_Driver_RGB is
	signal DM13A_CLK:std_logic;					--DM13A CLK內部操作位元
	signal i:integer range 0 to 31;				--輸出位元數控制
	constant databitN:integer range 0 to 31:=16;--輸出位元數參數:16 bit
	signal startbitS:integer range 0 to 15;		--內部開始操作位元控制
	signal R,G,B:std_logic;						--內部圖形位元取出

-- --------------------------
begin

--R,G,B 圖形位元取出罩蓋運算
R<=	LED_R(startbitS) when maskRGB(5)='0' else	--nop
	maskRGB(2)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="00" else	--load
	maskRGB(2)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="00" else	--load
	maskRGB(2) xor LED_R(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="01" else	--xor
	maskRGB(2) xor LED_R(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="01" else	--xor
	maskRGB(2) or  LED_R(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="10" else	--or
	maskRGB(2) or  LED_R(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="10" else	--or
	maskRGB(2) and LED_R(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="11" else	--and
	maskRGB(2) and LED_R(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="11" else	--and
	LED_R(startbitS);
G<=	LED_G(startbitS) when maskRGB(5)='0' else	--nop
	maskRGB(1)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="00" else	--load
	maskRGB(1)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="00" else	--load
	maskRGB(1) xor LED_G(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="01" else	--xor
	maskRGB(1) xor LED_G(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="01" else	--xor
	maskRGB(1) or  LED_G(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="10" else	--or
	maskRGB(1) or  LED_G(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="10" else	--or
	maskRGB(1) and LED_G(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="11" else	--and
	maskRGB(1) and LED_G(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="11" else	--and
	LED_G(startbitS);
B<=	LED_B(startbitS) when maskRGB(5)='0' else	--nop
	maskRGB(0)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="00" else	--load
	maskRGB(0)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="00" else	--load
	maskRGB(0) xor LED_B(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="01" else	--xor
	maskRGB(0) xor LED_B(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="01" else	--xor
	maskRGB(0) or  LED_B(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="10" else	--or
	maskRGB(0) or  LED_B(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="10" else	--or
	maskRGB(0) and LED_B(startbitS)	 when BIT_R_L='1' and startbitS>startbit and maskRGB(4 downto 3)="11" else	--and
	maskRGB(0) and LED_B(startbitS)	 when BIT_R_L='0' and startbitS<startbit and maskRGB(4 downto 3)="11" else	--and
	LED_B(startbitS);

--DM13A 硬體操作位元輸出
DM13ASDI_Ro<=R xor not01;	--R SDI輸出運算(反相控制)
DM13ASDI_Go<=G xor not01;	--G SDI輸出運算(反相控制)
DM13ASDI_Bo<=B xor not01;	--B SDI輸出運算(反相控制)
DM13ACLKo<=DM13A_CLK;		--CLK	
DM13ALEo<=DM13ALE;			--ALE
DM13AOEo<=DM13AOE;			--OE

DM13A_Send:process(DM13ACLK,DM13A_RESET)
begin
	if DM13A_RESET='0' then	--重置
		i<=0;				--輸出位元數個數預設0
		startbitS<=startbit;--載入開始操作位元
		DM13A_CLK<='0';		--預設Low
		DM13A_Sendok<='0';	--預設未完成
	elsif rising_edge(DM13ACLK) then
		if i=databitN then		--判斷輸出位元數是否完成
			DM13A_Sendok<='1';	--完成
		else
			if DM13A_CLK='0' then
				DM13A_CLK<='1';	--啟動載入CLK
			else
				i<=i+1;			--輸出位元數完成1個
				DM13A_CLK<='0';	--預備載入CLK
				if BIT_R_L='1' then --取樣方向
					startbitS<=startbitS-1;	--向低位元
				else
					startbitS<=startbitS+1;	--向高位元
				end if;
			end if;
		end if;
	end if;
end process DM13A_Send;

--------------------------------------------
end Albert;
