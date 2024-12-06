Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
entity arm is
	port(
		rst,clk:in std_logic;
		s0:buffer std_logic;
		s1:buffer std_logic;
		s2:buffer std_logic;
		s3:buffer std_logic;
		SW8:in std_logic;
		dipsw:in std_logic
	);
end entity arm;
architecture main of arm is
	component servo is
		port(
			clk,rst:in std_logic;
			sig:buffer std_logic;
			degree:in integer range 0 to 180;
			judge:in std_logic;
			enable:in std_logic
		);
	end component;
	signal FD:std_logic_vector(50 downto 0);
	signal forward,yaw,raise,turn:integer range 0 to 180;
begin
	fre:process(rst,clk)
	begin
		if rst='0' then
			FD<=(others=>'0');
		elsif rising_edge(clk)then
			FD<=FD+1;
		end if;
	end process fre;
	forward<=70 when FD(26)='1' else 110;
	yaw<=70 when FD(26)='1' else 110;
	raise<=70 when FD(26)='1' else 110;
	turn<=70 when FD(26)='1' else 110;
	u0:servo
		port map(
			clk=>clk,
			rst=>rst,
			sig=>s0,
			degree=>forward,
			judge=>not SW8,
			enable=>dipsw
		);
	u1:servo
		port map(
			clk=>clk,
			rst=>rst,
			sig=>s1,
			degree=>raise,
			judge=>not SW8,
			enable=>dipsw
		);
	u2:servo
		port map(
			clk=>clk,
			rst=>rst,
			sig=>s2,
			degree=>yaw,
			judge=>not SW8,
			enable=>dipsw
		);
	u3:servo
		port map(
			clk=>clk,
			rst=>rst,
			sig=>s3,
			degree=>turn,
			judge=>not SW8,
			enable=>dipsw
		);
end main;

	