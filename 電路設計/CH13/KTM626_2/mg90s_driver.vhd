--MG90S 測試
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity MG90S_Driver is
	port(MG90S_CLK,MG90S_RESET:in std_logic;	--MG90S_Driver驅動clk(6.25MHz),reset信號
		 MG90S_dir0:in std_logic;				--轉動方向0
		 MG90S_deg0:in integer range 0 to 90;	--轉動角度0
		 MG90S_o0:out std_logic;				--Driver輸出1
		 MG90S_dir1:in std_logic;				--轉動方向1
		 MG90S_deg1:in integer range 0 to 90;	--轉動角度1
		 MG90S_o1:out std_logic);				--Driver輸出1
end MG90S_Driver;

architecture Albert of MG90S_Driver is
	signal MG90Servo:integer range 0 to 125000;	--servo pwm產生器
	
	--MG90Servopwm 函數(function(正'0'負'1',值0~90)) 
	function MG90Servopwm(MG90S_dir:in std_logic;MG90S_deg:in integer range 0 to 90) return integer is
		variable MG90Servod:integer range 0 to 6000;--3125; --角度換算值
		variable MG90Servos:integer range 0 to 16000;--12500;--servo pwm比率值
		begin
			--MG90Servod:=347*MG90S_deg/10;	--角度換算值
			
			MG90Servod:=380*MG90S_deg/6;	--角度換算值(經修正後)
			if MG90S_dir='0' then
				MG90Servos:=9375+MG90Servod;--servo pwm比率值
			else
				MG90Servos:=9375-MG90Servod;--servo pwm比率值
			end if;
			return MG90Servos;
	end MG90Servopwm;

-- --------------------------
begin
--servo pwm產生器--------------------------------------------------
MG90S_o0<='1' when MG90Servo<MG90Servopwm(MG90S_dir0,MG90S_deg0) and MG90S_RESET='1' else '0';
MG90S_o1<='1' when MG90Servo<MG90Servopwm(MG90S_dir1,MG90S_deg1) and MG90S_RESET='1' else '0';
MG90S:process(MG90S_CLK,MG90S_RESET)
begin
	if MG90S_RESET='0' then
		MG90Servo<=0;
	elsif rising_edge(MG90S_CLK) then
		MG90Servo<=MG90Servo+1;
		if MG90Servo=124999 then
			MG90Servo<=0;
		end if;
	end if;
end Process MG90S;

end Albert;
