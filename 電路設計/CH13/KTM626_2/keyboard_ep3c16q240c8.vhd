--��I/O����
--EP3C16Q240C8 50MHz LEs:15,408 PINs:161 ,gckp31 ,SResetp99

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity KEYboard_EP3C16Q240C8 is
port(gckp31,KEYboardreset:in std_logic;				--�t���W�v,�t��reset
	 keyi:in std_logic_vector(3 downto 0);		--��L��J
	 keyo:buffer std_logic_vector(3 downto 0);	--��L��X
	 ksw:out std_logic_vector(2 downto 0) 		--0~7���
	);
end KEYboard_EP3C16Q240C8;

architecture Albert of KEYboard_EP3C16Q240C8 is
	signal FD:std_logic_vector(24 downto 0);--���W��
	signal kn:std_logic_vector(3 downto 0);	--�s���
	signal ks,kok:std_logic;				--��Lreset,��L�������A,��L�������A
	signal i:integer range 0 to 3;			--��L��������

begin
-- ----------------------------------------------

keyboard:process (FD(16))
begin
	if KEYboardreset='0' or kok='1' then	--�t��reset
		keyo<="1110";			--�ǳ���L��X�H��
		kn<="0000";					--��ȥ�0�}�l
		i<=0;					--��L�������Х�0�}�l
		ks<='0';				--�w�]�L���䪬�A
		kok<='0';				--�w�]��L���������A
	elsif (rising_edge(FD(16))) then
		if (ks='1') then		--�����䪬�A
			if keyi=15 then		--�P�_�������}
				kok<='1';		--��L�w�������A
				if kn<8 then
					ksw<=kn(2 downto 0);
				end if;
			end if;
		elsif keyi(i)='0' then	--����������U���A
			ks<='1';			--�]�����䪬�A
			keyo<="0000";		--�]�����Ҧ�����
		else					--�L������U���A
			kn<=kn+1;			--�վ����
			keyo<=keyo(2 downto 0) & keyo(3);--�վ���L��X
			if keyo(3)='0' then	--�O�_�n�վ���L��������
				i<=i+1;			--�վ���L��������
			end if;
		end if;
	end if;
end process keyboard;
	
-- ���W��----------------------------------------
Freq_Div:process(GCKP31)
begin
	if KEYboardreset='0' then			--�t��reset
		FD<=(others=>'0');
	elsif rising_edge(GCKP31) then	--50MHz
		FD<=FD+1;
	end if;
end process Freq_Div;

end Albert;
