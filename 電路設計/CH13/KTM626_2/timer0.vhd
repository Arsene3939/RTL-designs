library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity timer0 is
port
	( 	GCKP31,SResetP99,p20s1,p21s2: in std_logic;
		scan:buffer std_logic_vector(3 downto 0);			--掃瞄信號
		D7data:out std_logic_vector(6 downto 0);	--顯示資料
		D7xx_xx:out std_logic						--:
);
end entity timer0;

architecture Albert of timer0 is
	signal FD:std_logic_vector(24 downto 0);
	signal s1,s2:std_logic_vector(2 downto 0);
	signal s,m:integer range 0 to 59;
	signal h:integer range 0 to 23;
	signal fs:integer range 0 to 390625;
	signal scanP:integer range 0 to 3;
	signal d:integer range 0 to 9;
	signal S_1:std_logic;
begin
		
	process (GCKP31)
	begin
		if (p20s1 = '1') then
			s1 <= (others=>'0');
		elsif (rising_edge(FD(17))) then
			s1 <= s1+ not s1(2);
		end if;
		
		if (p21s2 = '1') then
			s2 <= (others=>'0');
		elsif (rising_edge(FD(17))) then
			s2 <= s2+ not s2(2);
		end if;
		
		if (rising_edge(FD(5))) then
			fs<=fs+1;
			if fs=390624 then fs<=0;S_1<=not S_1; end if;
		end if;

		-- 手調整時間
--		if (rising_edge(FD(19))) then
--			if s2(2)='1' then
				--S<=0;
--				if m=59 then m<=0; else m<=m+1; end if;
--			end if;
			
--			if s1(2)='1' then
				--S<=0;
--				if h=23 then h<=0; else h<=h+1; end if;
--			end if;
--		end if;

		if (rising_edge(S_1)) then
			if s=59 or s1(2)='1' or s2(2)='1' then s<=0; else s<=s+1; end if;
		
			if s=59 or s2(2)='1' then
				if m=59 then m<=0; else m<=m+1; end if;
			end if;
			
			if (m=59 and s=59 and s2(2)='0')or s1(2)='1' then
				if h=23 then h<=0; else h<=h+1; end if;
			end if;
		end if;
	end process;	
		
D7xx_xx<=S_1;		
		--4位數掃瞄器
scan_P:process(FD(17))
begin
	if SResetP99='0' then
		scanP<=0;		--位數取值指標
		scan<="1111";	--掃瞄信號
	elsif rising_edge(FD(17)) then
		scanP<=scanP+1;
		scan<=scan(2 downto 0) & scan(3);
		if scanP=3 then
			scanP<=0;
			scan<="1110";	--掃瞄信號
		end if;
	end if;
end process scan_P;

with scanP select
	d	<=h/10 		when 3,
		  h mod 10 	when 2,
		  m/10		when 1,
		  m mod 10 	when 0;

--BCD碼解共陽極七段顯示碼pgfedcba
with d select --取出顯示值
	D7data<=
	"1000000" when 0,
	"1111001" when 1,
	"0100100" when 2,
	"0110000" when 3,
	"0011001" when 4,
	"0010010" when 5,
	"0000010" when 6,
	"1111000" when 7,
	"0000000" when 8,
	"0010000" when 9,
	"1111111" when others;	--不顯示

-- 除頻器----------------------------------------
Freq_Div:process(GCKP31)
begin
	if SResetP99='0' then		--系統reset
		FD<=(others=>'0');
	elsif rising_edge(GCKP31) then	--50MHz
		FD<=FD+1;
	end if;
end process Freq_Div;
	
end Albert;