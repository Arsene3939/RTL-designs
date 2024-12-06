Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity dual_array is
	port(
		clk,rst:in std_logic;
		S,R,G:buffer std_logic_vector(7 downto 0)
	);
end entity dual_array;
architecture main of dual_array is
	signal FD:std_logic_vector(50 downto 0);
	type arr is array(0 to 7) of std_logic_vector(15 downto 0);
	signal data:arr:=(X"7C83",X"20DF",X"10EF",X"08F7",X"04FB",X"44BB",X"44BB",X"38C7");
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	scan:process(FD(10))
		variable i:integer range 0 to 7:=0;
	begin
		if rst='0' then
			S<=X"01";
			i:=0;
		elsif rising_edge(FD(12))then
			R<=data(7-i)(15 downto 8);
			G<=data(7-i)(7 downto 0);
			S<=S(0)&S(7 downto 1);
			i:=i+1;
		end if;
	end process;
end main;

	