--MCP4822 DAC測試
--107.01.01版
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,rstP99
--MCP4822_CH_BA:00(chA),01,11(chB),10->11(自動由chA轉chB:接續轉換-同步輸出DAC值) 

Library IEEE;						--連結零件庫
Use IEEE.std_logic_1164.all;		--引用套件
Use IEEE.std_logic_unsigned.all;	--引用套件
Use IEEE.std_logic_arith.all;		--引用套件

-- ----------------------------------------------------
entity MCP4822_Driver is
	port(MCP4822_CLK,MCP4822_RESET:in std_logic;	--MCP4822_Driver驅動clk,reset信號
		 MCP4822_DAA,MCP4822_DAB:in integer range 0 to 4095;	--MCP4822 DAC chA0,B1值
		 MCP4822_CHB_A:in std_logic_vector(1 downto 0);	--輸入通道
		 MCP4822_GA_BA:in std_logic_vector(1 downto 0);	--GA 0x2,1x1
		 MCP4822_SHDN_BA:in std_logic_vector(1 downto 0);	--/SHDN
		 MCP4822_SDI,MCP4822_LDAC:out std_logic;		--MCP4822 SDI信號
		 MCP4822_SCK,MCP4822_CS:buffer std_logic;		--MCP4822 SCK,/cs信號
		 MCP4822_ok:buffer std_logic);	--Driver完成旗標 ,完成狀態
end MCP4822_Driver;

-- -----------------------------------------------------
architecture Albert of MCP4822_Driver is
	signal i:integer range 0 to 15;			--操作指標
	signal MCP4822DAx,MCP4822DAB:std_logic_vector(14 downto 0);	--轉換值
	signal MCP4822_Chs:std_logic_vector(1 downto 0); 			--ch 0,1
-- --------------------------
begin

MCP4822:process(MCP4822_CLK,MCP4822_RESET)
begin
	if MCP4822_RESET='0' then		--未起始:準備資料
		MCP4822_CS<='1';					--MCP4822 cs diable
		MCP4822_LDAC<='1';					--MCP4822 ldac diable
		MCP4822DAB<='0'&MCP4822_GA_BA(1)&MCP4822_SHDN_BA(1)&conv_std_logic_vector(MCP4822_DAB,12);		--B:DAC
		if MCP4822_CHB_A(0)='0' then
			MCP4822DAx<='0'&MCP4822_GA_BA(0)&MCP4822_SHDN_BA(0)&conv_std_logic_vector(MCP4822_DAA,12);	--A:DAC
		else
			MCP4822DAx<=MCP4822DAB;		--B:DAC
		end if;
		MCP4822_Chs<=MCP4822_CHB_A;			--通道選擇
		MCP4822_ok<='0';					--重置操作完成旗標
		i<=14;								--重置操作指標
	elsif rising_edge(MCP4822_CLK) then
		if MCP4822_ok='1' then				--未完成操作
			MCP4822_LDAC<='1';					--維持AC值
		elsif i=15 and MCP4822_SCK='1' then --write end
			MCP4822_CS<='1';					--MCP4822 cs diable
			MCP4822_Chs(0)<='1';				--chA-->chB自動由chA轉chB
			MCP4822DAx<=MCP4822DAB;				--B:DAC
			i<=14;								--準備自動由chA轉chB
			if MCP4822_Chs/="10" then			--結束
				MCP4822_LDAC<='0';					--啟動新AC輸出
				MCP4822_ok<='1';					--操作完成
			end if;
		elsif MCP4822_CS='1' then			--未操作
			MCP4822_SDI<=MCP4822_Chs(0);		--CH bit
			MCP4822_CS<='0';					--enable /CS
			MCP4822_SCK<='0';					--重置MCP4822 /SCK
		else								--操作中
			MCP4822_SCK<=not MCP4822_SCK;		--MCP4822 /SCK 反向
			if MCP4822_SCK='1' then	--clk H to L
				i<=i-1;							--調整操作指標
				MCP4822_SDI<=MCP4822DAx(i);		--SDI out
			end if;
		end if;
	end if;
end process MCP4822;

--------------------------------------------
end Albert;
