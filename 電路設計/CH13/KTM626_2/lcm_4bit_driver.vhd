--����LCM_4bit_driver(WG14432B5)
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity LCM_4bit_driver is
	port(LCM_CLK,LCM_RESET:in std_logic;			--�ާ@�t�v,���m
		 RS,RW:in std_logic;						--�Ȧs�����,Ū�g�X�п�J
		 DBi:in std_logic_vector(7 downto 0);		--LCM_8bit_driver ��ƿ�J
		 DBo:out std_logic_vector(7 downto 0);		--LCM_8bit_driver ��ƿ�X
		 DB_io:inout std_logic_vector(3 downto 0);	--LCM DATA BUS����
		 RSo,RWo,Eo:out std_logic;					--LCM �Ȧs�����,Ū�g,�P�श��
		 LCMok,LCM_S:out boolean					--LCM_8bit_driver����,���~�X��
		);
end LCM_4bit_driver;

architecture Albert of LCM_4bit_driver is
	signal RWS,BF:std_logic;			--Ū�g���A,busy
	signal LCMruns:std_logic_vector(3 downto 0);	--���檬�A
	signal DBii:std_logic_vector(3 downto 0);		--����BUS
	signal Timeout:integer range 0 to 256;			--timeout�p�ɾ�
begin

RWo<=RWS;	--Ū�g���A��X
DB_io<=DBii when RWS='0' else "ZZZZ";	--LCM data bus �ާ@

LCM_4BIT_OUT:process(LCM_CLK,LCM_RESET)
begin
	if LCM_RESET='0' then
		DBo<=(DBo'Range=>'0');					--��ƿ�J�k�s
		DBii<=DBi(7 downto 4);					--high nibble
		RSo<=RS;								--�Ȧs�����
		BF<='1';
		RWs<=RW;								--Ū�g�]�w
		Eo<='0';								--LCM�T��
		LCMok<=False;							--�������@�~
		LCM_S<=False;							--�Ѱ��@�~����
		LCMruns<="0000";						--���檬�A��0�}�l
		Timeout<=0;								--�p��
	elsif Rising_Edge(LCM_CLK) then
		case LCMruns is
			when "0000"=>
				Eo<='1';						--LCM�P��
				LCMruns<="0001";				--���檬�A�U�@�B
			when "0001"=>
				Eo<='0';						--LCM�T��
				if RW='1' then					--�p�OŪ�����O
					DBo(7 downto 4)<=DB_io;	--Read Data(high nibble)
				end If;
				LCMruns<="101" & RWS;			--���檬�A�U�@�B
			when "1010"=>						--��X
				DBii<=DBi(3 downto 0);		--low nibble
				LCMruns<="1011";				--���檬�A�U�@�B
			when "1011"=>
				Eo<='1';						--LCM�P��
				LCMruns<="0011";				--���檬�A�U�@�B
			when "0011"=>
				if RW='1' then					--�p�OŪ�����O
					DBo(3 downto 0)<=DB_io;	--Read Data(low nibble)
				end If;
				Eo<='0';						--LCM�T��
				LCMruns<="1000";				--���檬�A�U�@�B
------------------------------------------------------------------------------
			when "1100"=>
				Eo<='1';						--LCM�P��
				LCMruns<="0110";				--���檬�A�U�@�B
			when "0110"=>
				Eo<='0';						--LCM�T��
				BF<=DB_io(3);
				LCMruns<="0111";				--���檬�A�U�@�B
			when "0111"=>
				Eo<='1';						--LCM�P��
				LCMruns<="1000";				--���檬�A�U�@�B
			when "1000"=>
				Timeout<=Timeout+1;				--timeout�p��
				if RS='0' then					--���O��delay�Ҧ�
					if DBi=1 then				--�M����ܹ����O
						if Timeout=220 then	--220--delay�Ҧ�����
							LCMruns<="0100";	--���檬�A�U�@�B
						end if;
					elsif Timeout=2 then	--2--delay�Ҧ�����
						LCMruns<="0100";		--���檬�A�U�@�B
					end if;
				elsif Timeout=5 then		--5
					LCM_S<=true;				--�@�~����
					LCMruns<="0100";			--���檬�A�U�@�B
				else
					LCMruns<=BF & "100";	--Ū��busy�X�ШèM�w�U�@�B
				end if;
				Eo<='0';						--LCM�T��
				RSo<='0';						--����O�Ȧs��
				RWS<='1';						--�]Ū��
			when others=>						--"0100" busy=0�ɧY�@�~�w����
				LCMok<=True;					--�@�~�w����
		end case;
	end if;
end process LCM_4BIT_OUT;
--------------------------------------------
end Albert;