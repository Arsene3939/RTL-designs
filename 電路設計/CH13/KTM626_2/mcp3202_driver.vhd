--MCP3202 ADC測試
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99
--MCP3202: MSBF='1'
--MCP3202_CH1_0:00(ch0),01,11(ch1),10->11(自動由ch0轉ch1:接續轉換-同步輸出ADC值) 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MCP3202_Driver is
	port(MCP3202_CLK_D,MCP3202_RESET:in std_logic;	--MCP3202_Driver驅動clk,reset信號
		 MCP3202_AD0,MCP3202_AD1:buffer integer range 0 to 4095;	--MCP3202 AD0,1 ch0,1值
		 MCP3202_try_N:in integer range 0 to 3;		--失敗後再嘗試次數
		 MCP3202_CH1_0:in std_logic_vector(1 downto 0);	--輸入通道
		 MCP3202_SGL_DIFF:in std_logic;				--MCP3202 SGL/DIFF
		 MCP3202_Do:in std_logic;					--MCP3202 do信號
		 MCP3202_Di:out std_logic;					--MCP3202 di信號
		 MCP3202_CLK,MCP3202_CS:buffer std_logic;	--MCP3202 clk,/cs信號
		 MCP3202_ok,MCP3202_S:buffer std_logic);	--Driver完成旗標 ,完成狀態
end MCP3202_Driver;

architecture Albert of MCP3202_Driver is
	signal MCP3202_tryN:integer range 0 to 3;		--失敗後再嘗試次數
	signal MCP3202Dis:std_logic_vector(2 downto 0);	--2:MSBF+1:ODD/SIGN+0:SGL/DIFF
	signal MCP3202_ADs:std_logic_vector(11 downto 0);--轉換值收集
	signal MCP3202_Chs:std_logic_vector(1 downto 0); --ch 0,1
	signal i:integer range 0 to 31;					--操作指標
-- --------------------------
begin

MCP3202:process(MCP3202_CLK_D,MCP3202_RESET)
begin
	if MCP3202_RESET='0' then		--未起始
		MCP3202_CS<='1';					--MCP3202 cs diable
		MCP3202_tryN<=MCP3202_try_N;		--失敗後再嘗試次數(起始後無法再變)
		MCP3202_Chs<=MCP3202_CH1_0;			--通道選擇(起始後無法再變)
		MCP3202_ok<='0';					--重置操作完成旗標
		MCP3202_S<='0';						--重置完成狀態
		MCP3202Dis<='1'&MCP3202_CH1_0(0)&MCP3202_SGL_DIFF;	--2:MSBF+1:ODD/SIGN+0:SGL/DIFF(起始後無法再變)
	elsif rising_edge(MCP3202_CLK_D) then
		if MCP3202_ok='0' then		--未完成操作
			if i=17 then 				--read end
				if MCP3202Dis(1)='0' then
					MCP3202_AD0<=conv_integer(MCP3202_ADs);	--ch0 ADC值
				else
					MCP3202_AD1<=conv_integer(MCP3202_ADs);	--ch1 ADC值
				end if;
				i<=0;						--重置操作指標
				MCP3202_CS<='1';			--MCP3202 cs diable
				MCP3202Dis(1)<='1';			--ch0-->ch1
				MCP3202_ok<=not MCP3202_Chs(1) or MCP3202Dis(1);--自動由ch0轉ch1 or 操作完成,成功完成
			elsif MCP3202_CS='1' then	--未操作
				i<=0;						--重置操作指標
				MCP3202_Di<='1';				--start bit
				MCP3202_CS<='0';			--enable /CS
				MCP3202_CLK<='0';			--重置MCP3202 /CLK
			else						--操作中
				MCP3202_CLK<=not MCP3202_CLK;--MCP3202 /CLK 反向
				if MCP3202_CLK='1' then	--clk H to L:Di out
					if i<3 then				--MCP3202 起始階段
						MCP3202_Di<=MCP3202Dis(i);	--2:MSBF+1:ODD/SIGN+0:SGL/DIFF
						i<=i+1;				--調整操作指標
					end if;
				elsif i>2 then			--clk L to H:Do in --進入接收階段
					i<=i+1;					--調整操作指標
					MCP3202_ADs<=MCP3202_ADs(10 downto 0)&MCP3202_Do;--轉換值收集
					if i=4 and MCP3202_Do='1' then --error
						MCP3202_tryN<=MCP3202_tryN-1;	--失敗後調整再嘗試次數
						if MCP3202_tryN=0 then	--失敗不用再試了
							MCP3202_ok<='1';	--操作完成
							MCP3202_S<='1';		--失敗
						else			--retry
							MCP3202_CS<='1';--MCP3202 cs diable
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
end Process MCP3202;

end Albert;
