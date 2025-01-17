--CPLD oR FPGA
--WS2812B_Driver 105.11.30
--WS2812BCLK .=. 0.4us
--WS2812B驅動器

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WS2812B_Driver is
	port(	WS2812BCLK,WS2812BRESET,loadck:in std_logic;--操作頻率,重置,載入ck
			LEDGRBdata:in std_logic_vector(23 downto 0);--色彩資料
			reload,emitter,WS2812Bout:out std_logic		--要求載入,發射狀態,發射輸出 
		);
end;

architecture Albert of WS2812B_Driver is
	signal load_clr,reload1:std_logic:='0';	--載入信號操作
	signal LEDGRBdata0,LEDGRBdata1:std_logic_vector(23 downto 0);--色彩資料載入
	signal DATA01:std_logic_vector(2 downto 0):="000";			 --編碼位元:bit out=>0:100,1:110
	signal DATAn:integer range 0 to 31:=0;	--色彩資料位元指標
	signal bitn:integer range 0 to 3:=0;	--編碼位元發射數
begin

WS2812Bout<=DATA01(2);--LED色彩資料位元輸出
reload<=not (reload1 or load_clr) and WS2812BRESET;--緩衝器要求載入資料脈衝

--預載緩衝器--------------------------------------------
LEDdata_load:
process(loadck,WS2812BRESET)
begin
	if WS2812BRESET='0' or (load_clr='1' and reload1='1') then
		reload1<='0'; --緩衝器空
	elsif rising_edge(loadck) then	--色彩資料載入ck
		LEDGRBdata1<=LEDGRBdata;	--色彩資料載入緩衝器
		reload1<='1';--緩衝器滿
	end if;		
end process LEDdata_load;

WS2812B_Send:--------------------------------------------
process(WS2812BCLK,WS2812BRESET)
begin
	if WS2812BRESET='0' then
		DATA01<="000";	--輸出停止位元
		load_clr<='0';	--允許緩衝器動作
		emitter<='0';	--停止發射
		DATAn<=0;		--等待發射位元數
		bitn<=0;		--編碼位元發射剩0位元
	elsif rising_edge(WS2812BCLK) then
		load_clr<='0';						--允許緩衝器動作
		if bitn/=0 then			--尚有編碼位元未發射
			DATA01<=DATA01(1 downto 0) & "0";--發射位元
			bitn<=bitn-1;					 --編碼位元發射位元減1
		elsif DATAn/=0 then		--尚有資料位元未編碼
			DATA01<='1' & LEDGRBdata0(DATAn-1) & '0';--發射位元編碼(等待發射位元編碼成3位元)
			DATAn<=DATAn-1;				--等待發射位元數減1
			bitn<=2;					--編碼位元發射剩2位元
		elsif reload1='1' then	--緩衝器已有色彩資料進來
			LEDGRBdata0<=LEDGRBdata1;	--色彩資料載入
			DATAn<=23;					--等待發射位元數
			DATA01<='1' & LEDGRBdata1(23) & '0';--發射位元編碼(等待發射位元編碼成3位元)
			bitn<=2;					--編碼位元發射剩2位元
			load_clr<='1';				--已載入發射中,清除緩衝器
			emitter<='1';				--發射中
		else					--緩衝器無色彩資料
			emitter<='0';				--停止發射
		end if;
	end if;
end process WS2812B_Send;

end Albert;
