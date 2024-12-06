Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity motor is
	port(
		clk:in std_logic;
		Button0,Button1,Button2,Button3:in std_logic;
		outpin:buffer std_logic_vector(1 downto 0)
	);
end entity motor;
architecture main of motor is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 1)of integer range 0 to 255;
	shared variable state:arr:=(0,0);
begin
	fre:process(clk)
	begin
		if rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	pwm:process(FD(15))
		variable n:integer range 0 to 255:=0;
	begin
		if rising_edge(FD(3)) then
			if state(0)>n then
				outpin(0)<='0';
			else
				outpin(0)<='1';
			end if;
			if state(1)>n then
				outpin(1)<='0';
			else
				outpin(1)<='1';
			end if;
			n:=n+1;
		end if;
	end process;
	mainloop:process(FD(18))
	begin
		if rising_edge(FD(18))then
			if Button0='0' then
				state(0):=state(0)+1;
			end if;
			if Button1='0' then
				state(1):=state(1)+1;
			end if;
			if Button2='0' then
				state(0):=state(0)-1;
			end if;
			if Button3='0' then
				state(1):=state(1)-1;
			end if;
		end if;
	end process;
end main;

	