--中文LCM_4bit_driver(WG14432B5)
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity LCM_4bit_driver is
	port(LCM_CLK,LCM_RESET:in std_logic;			--操作速率,重置
		 RS,RW:in std_logic;						--暫存器選擇,讀寫旗標輸入
		 DBi:in std_logic_vector(7 downto 0);		--LCM_8bit_driver 資料輸入
		 DBo:out std_logic_vector(7 downto 0);		--LCM_8bit_driver 資料輸出
		 DB_io:inout std_logic_vector(3 downto 0);	--LCM DATA BUS介面
		 RSo,RWo,Eo:out std_logic;					--LCM 暫存器選擇,讀寫,致能介面
		 LCMok,LCM_S:out boolean					--LCM_8bit_driver完成,錯誤旗標
		);
end LCM_4bit_driver;

architecture Albert of LCM_4bit_driver is
	signal RWS,BF:std_logic;			--讀寫狀態,busy
	signal LCMruns:std_logic_vector(3 downto 0);	--執行狀態
	signal DBii:std_logic_vector(3 downto 0);		--內部BUS
	signal Timeout:integer range 0 to 256;			--timeout計時器
begin

RWo<=RWS;	--讀寫狀態輸出
DB_io<=DBii when RWS='0' else "ZZZZ";	--LCM data bus 操作

LCM_4BIT_OUT:process(LCM_CLK,LCM_RESET)
begin
	if LCM_RESET='0' then
		DBo<=(DBo'Range=>'0');					--資料輸入歸零
		DBii<=DBi(7 downto 4);					--high nibble
		RSo<=RS;								--暫存器選擇
		BF<='1';
		RWs<=RW;								--讀寫設定
		Eo<='0';								--LCM禁能
		LCMok<=False;							--未完成作業
		LCM_S<=False;							--解除作業失敗
		LCMruns<="0000";						--執行狀態由0開始
		Timeout<=0;								--計時
	elsif Rising_Edge(LCM_CLK) then
		case LCMruns is
			when "0000"=>
				Eo<='1';						--LCM致能
				LCMruns<="0001";				--執行狀態下一步
			when "0001"=>
				Eo<='0';						--LCM禁能
				if RW='1' then					--如是讀取指令
					DBo(7 downto 4)<=DB_io;	--Read Data(high nibble)
				end If;
				LCMruns<="101" & RWS;			--執行狀態下一步
			when "1010"=>						--輸出
				DBii<=DBi(3 downto 0);		--low nibble
				LCMruns<="1011";				--執行狀態下一步
			when "1011"=>
				Eo<='1';						--LCM致能
				LCMruns<="0011";				--執行狀態下一步
			when "0011"=>
				if RW='1' then					--如是讀取指令
					DBo(3 downto 0)<=DB_io;	--Read Data(low nibble)
				end If;
				Eo<='0';						--LCM禁能
				LCMruns<="1000";				--執行狀態下一步
------------------------------------------------------------------------------
			when "1100"=>
				Eo<='1';						--LCM致能
				LCMruns<="0110";				--執行狀態下一步
			when "0110"=>
				Eo<='0';						--LCM禁能
				BF<=DB_io(3);
				LCMruns<="0111";				--執行狀態下一步
			when "0111"=>
				Eo<='1';						--LCM致能
				LCMruns<="1000";				--執行狀態下一步
			when "1000"=>
				Timeout<=Timeout+1;				--timeout計時
				if RS='0' then					--指令採delay模式
					if DBi=1 then				--清除顯示幕指令
						if Timeout=220 then	--220--delay模式結束
							LCMruns<="0100";	--執行狀態下一步
						end if;
					elsif Timeout=2 then	--2--delay模式結束
						LCMruns<="0100";		--執行狀態下一步
					end if;
				elsif Timeout=5 then		--5
					LCM_S<=true;				--作業失敗
					LCMruns<="0100";			--執行狀態下一步
				else
					LCMruns<=BF & "100";	--讀取busy旗標並決定下一步
				end if;
				Eo<='0';						--LCM禁能
				RSo<='0';						--選指令暫存器
				RWS<='1';						--設讀取
			when others=>						--"0100" busy=0時即作業已完成
				LCMok<=True;					--作業已完成
		end case;
	end if;
end process LCM_4BIT_OUT;
--------------------------------------------
end Albert;