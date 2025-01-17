--RGB16x16代刚
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RGB16x16_EP3C16Q240C8 is
--port(gckp31,SResetp99:in std_logic;				--╰参繵瞯,╰参reset
port(gckp31,RGB16x16Reset:in std_logic;				--╰参繵瞯,╰参reset
	 --DM13A
	 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;
	 --Scan
	 Scan_DCBAo:buffer std_logic_vector(3 downto 0)
    );
end RGB16x16_EP3C16Q240C8;

architecture Albert of RGB16x16_EP3C16Q240C8 is
	signal FD:std_logic_vector(24 downto 0);
	signal F1:std_logic;
	signal cn:std_logic_vector(10 downto 0);
	signal T:integer range 0 to 2047;
	signal color:integer range 0 to 15;
	signal S:std_logic_vector(4 downto 0);
	signal LED_R1,LED_G1,LED_B1:std_logic_vector(15 downto 0);
	signal LED_R2,LED_G2,LED_B2:std_logic_vector(15 downto 0);

	-- -----------------------------------------------------
	component DM13A_Driver_RGB is
	port(DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:in std_logic;
		 startbit:in integer range 0 to 15;
		 LandorRGB:in std_logic_vector(5 downto 0);
		 --mask:0:disable 1:enable,00:load,01:xor:10:or,11:and RGB
		 LED_R,LED_G,LED_B:in std_logic_vector(15 downto 0);
		 DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo:out std_logic;
		 DM13A_Sendok:out std_logic);
	end component;
	signal DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01:std_logic;
	signal startbit:integer range 0 to 15;
	signal LandorRGB:std_logic_vector(5 downto 0):="000000";
	signal LED_R,LED_G,LED_B:std_logic_vector(15 downto 0);
	signal DM13A_Sendok:std_logic;
	
-- --------------------------
begin
  
 U1: DM13A_Driver_RGB 
	port map(	DM13ACLK,DM13A_RESET,DM13ALE,DM13AOE,BIT_R_L,not01,startbit,LandorRGB,
				LED_R,LED_G,LED_B,
				--GRB test
	--			"1111111111111111","1111111111111111","1111111111111111",
				DM13ACLKo,DM13ASDI_Ro,DM13ASDI_Go,DM13ASDI_Bo,DM13ALEo,DM13AOEo,
				DM13A_Sendok);
	
 
-- --------------------------
--埃繵竟
--Freq_Div:process(gckp31,SResetp99)
Freq_Div:process(gckp31,RGB16x16Reset)
begin
--	if SResetP99='0' then
	if RGB16x16Reset='0' then
		FD<=(others=>'0');
	elsif rising_edge(gckp31) then
		FD<=FD+1;
	end if;
end process Freq_Div;

DM13ACLK<=FD(2);
F1<=FD(0);

-----------------------------
BIT_R_L<=S(1);
not01<=S(2);

--process(F1,SResetp99)
process(F1,RGB16x16Reset)
begin
--if SResetp99='0' then
if RGB16x16Reset='0' then
	Scan_DCBAo<="0000";
	DM13A_RESET<='0';
	DM13ALE<='0';
	DM13AOE<='1';		--DM13A off
	cn<=(others=>'0');
	S<=(others=>'0');
	color<=0;
	startbit<=15;
elsif rising_edge(F1) then
	if DM13ALE='0' and DM13AOE='1' then
		if DM13A_RESET='0' then
			DM13A_RESET<='1';
			Scan_DCBAo<=Scan_DCBAo-1;
		elsif DM13A_Sendok='1' then
			DM13A_RESET<='0';
			DM13ALE<='1';
			LED_R2<=LED_R2(14 downto 0) & LED_R2(15);
			LED_G2<=LED_G2(14 downto 0) & LED_G2(15);
			LED_B2<=LED_B2(14 downto 0) & LED_B2(15);
			if Scan_DCBAo=0 then
				cn<=cn+1;
				if cn=1800 then
					cn<=(others=>'0');
					color<=color+1;
					if color=13 then
						S<=S+1;
						color<=0;
					end if;
					LED_R2<=LED_R1;
					LED_G2<=LED_G1;
					LED_B2<=LED_B1;
				elsif cn(7 downto 0)=0 and S(3)='1' then
					LED_R2<=LED_R2(13 downto 0) & LED_R2(15 downto 14);
					LED_G2<=LED_G2(13 downto 0) & LED_G2(15 downto 14);
					LED_B2<=LED_B2(13 downto 0) & LED_B2(15 downto 14);
				end if;
				if S(4)='1' then
					if cn(7 downto 0)=0 then
						startbit<=startbit+1;
					end if;
				else
					startbit<=15;
				end if;
			end if;
		end if;
		T<=0;
	else
		DM13ALE<='0';
		DM13AOE<='0';
		T<=T+1;
		if T=100 then	--display times157
			DM13AOE<='1';
		end if;	
	end if;
end if;
end process;

LED_R<=LED_R1 when S(0)='0' else LED_R2;
LED_G<=LED_G1 when S(0)='0' else LED_G2;
LED_B<=LED_B1 when S(0)='0' else LED_B2;

with color select
LED_R1<=
"0000000000000000" when 0,--穞
"1111111111111111" when 1,--R
"0000000000000000" when 2,--G
"0000000000000000" when 3,--B
"1111111111111111" when 4,--RG
"1111111111111111" when 5,--RB
"0000000000000000" when 6,--GB
"1111111111111111" when 7,--RGB
"0011000000110000" when 8,--00RRGGBB00RRGGBB
"0000111100001111" when 9, --R0000111100001111
"0101010101010101" when 10,--G0101010101010101
"0101010101010101" when 11,--B0101010101010101
"0011000011110011" when 12,--0011000011110011
"1010101010101010" when others;

with color select
LED_G1<=
"0000000000000000" when 0,--穞
"0000000000000000" when 1,--R
"1111111111111111" when 2,--G
"0000000000000000" when 3,--B
"1111111111111111" when 4,--RG
"0000000000000000" when 5,--RB
"1111111111111111" when 6,--GB
"1111111111111111" when 7,--RGB
"0000110000001100" when 8,--00RRGGBB00RRGGBB
"0101010101010101" when 9, --R0101010101010101
"0000111100001111" when 10,--G0000111100001111
"0011001100110011" when 11,--B0011001100110011
"0000110011001111" when 12,--0000110011001111
"0101010101010101" when others;

with color select
LED_B1<=
"0000000000000000" when 0,--穞
"0000000000000000" when 1,--R
"0000000000000000" when 2,--G
"1111111111111111" when 3,--B
"0000000000000000" when 4,--RG
"1111111111111111" when 5,--RB
"1111111111111111" when 6,--GB
"1111111111111111" when 7,--RGB
"0000001100000011" when 8,--00RRGGBB00RRGGBB
"0011001100110011" when 9, --R0011001100110011
"0011001100110011" when 10,--G0011001100110011
"0000111100001111" when 11,--B0000111100001111
"0000001100111111" when 12,--0000001100111111
"1100110011001100" when others;

end Albert;
