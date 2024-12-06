--LED�R�E�O2:�j�ͭp�ƾ��t��k
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckP31 ,rstP99

Library IEEE;						--�s���s��w
Use IEEE.std_logic_1164.all;		--�ޥήM��
Use IEEE.std_logic_unsigned.all;	--�ޥήM��

-- -----------------------------------------------------
entity CH2_LED_2 is
port(gckP31,rstP99:in std_logic;	-- �t�ήɯߡB�t�έ��m
	 LEDs:buffer std_logic_vector(15 downto 0) 	--LED
	 -- 87,93,95,94,100,101,102,103 
	 -- 106,107,108,110,111,112,113,114
	);
end entity CH2_LED_2;

-- -----------------------------------------------------
architecture Albert of CH2_LED_2 is
	signal FD:std_logic_vector(24 downto 0);--���W��
	
-- --------------------------
begin

--LED_P �D����----------------------------------------------
LED_P:process (FD(16))
variable N:integer range 0 to 127;			--���榸��
variable LED_point:integer range 0 to 15;	--LED_����
variable dir_LR,set10,incDec:std_logic;	--��V,���],LED_����_���W����
begin
	if rstP99='0' then			--�t�έ��m
		N:=64;					--���ƥ�64�}�l
		LED_point:=0;			--LED_���Х�0�}�l
		dir_LR:='0';			--��V:�V�k
		set10:='0';				--���]0
		incDec:='1';			--���W
		LEDs<=(others=>'0'); 	--LED���G
	elsif rising_edge(FD(21)) then			--��12Hz
		if N=0 then	--���Ƥw����
			if LEDs/=(LEDs'range=>set10) then	--��_�쪬
				if dir_LR='0' then	--��V:�V�k
					LEDs<=set10 & LEDs(15 downto 1);--��V:�V�k
				else				--��V:�V��
					LEDs<=LEDs(14 downto 0) & set10;--��V:�V��
				end if;
			else	--���]�Ѽ�
				N:=64;						--���ƥ�64�}�l
				if LED_point=0 and incDec='0' then
					dir_LR:=not dir_LR;		--��V:�V��
					incDec:='1';			--���л��W
					set10:=set10 xor dir_LR;--���]:0<-->1
				elsif  LED_point=15 and incDec='1' then
					incDec:='0';			--���л���
				elsif incDec='1' then	--���W
					LED_point:=LED_point+1;	--LED_���л��W
				else					--����
					LED_point:=LED_point-1;	--LED_���л���
				end if;
				LEDs<=(others=>set10); --LED���G
			end if;
		else		--���ƥ�����
			if dir_LR='0' then	--��V:�V�k
				LEDs<=not LEDs(LED_point) & LEDs(15 downto 1);--��V:�V�k
			else				--��V:�V��
				LEDs<=LEDs(14 downto 0) & not LEDs(LED_point);--��V:�V��
			end if;
			N:=N-1;	--����-1
		end if;
	end if;
end process LED_P;
	
-- ���W��----------------------------------------
Freq_Div:process(gckP31)			--�t���W�vgckP31:50MHz
begin
	if rstP99='0' then				--�t�έ��m
		FD<=(others=>'0');			--���W��:�k�s
	elsif rising_edge(gckP31) then	--50MHz
		FD<=FD+1;					--���W��:2�i��W��(+1)�p�ƾ�
	end if;
end process Freq_Div;

end Albert;
