Library IEEE;
Use IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.std_logic_arith.all;
entity limited_machine is
	port(
        LED:buffer std_logic_vector(15 downto 0);
		  clk:in std_logic
	);
end entity limited_machine;
architecture main of limited_machine is
	 constant len:integer range 0 to 10 :=6;
    signal FD:std_logic_vector(50 downto 0);
    type arr is array(0 to len) of integer range 0 to 256;
    signal func:arr:=(21,10,6,12,8,11,20);--// 10 + // 11 - // 12 * // 13 % //
							-- 21+6*8-20=
    signal fsm:integer range 0 to 100:=1;
    
	 signal speed:integer range 0 to 50 :=0;
	 shared variable len2:integer range 0 to 11:=len;
begin
    LED(15 downto 12)<=not conv_std_logic_vector(fsm,4);
	 fre:process(clk)
    begin
        if rising_edge(clk)then
            FD<=FD+1;
        end if;
    end process;
	 LED(11 downto 0)<=not conv_std_logic_vector(func(len2-1),12);
    machine:process(FD(speed+1))
        type iarray is array(0 to 10) of integer range 0 to 10;
        variable i:iarray:=(0,0,0,0,0,0,0,0,0,0,0);
        variable sorting:integer:=0;
        variable xmod_flag:std_logic:='0';
        variable plminu:std_logic:='0';
    begin
        if rising_edge(FD(speed+1))then
            case fsm is
                when 0 =>
                when 1 =>--*/ operator
						  speed<=0;
                    if func(i(1))=12 then
                        if xmod_flag='0' then
                            func(i(1))<= (func(i(1)-1))* (func(i(1)+1));
                            func(i(1)-1)<=15;
                            func(i(1)+1)<=15;
                        else
                            func(i(1))<= (func(i(1)+1))*func(i(1)-2);
                            func(i(1)-2)<=15;
                            func(i(1)+1)<=15;
                        end if;
                        xmod_flag:='1';
                    elsif func(i(1))=13 then
                        if xmod_flag='0' then
                            func(i(1))<=(func(i(1)-1))/(func(i(1)+1));
                            func(i(1)-1)<=15;
                            func(i(1)+1)<=15;
                        else
                            func(i(1))<=func(i(1)-2)/func(i(1)+1);
                            func(i(1)-2)<=15;
                            func(i(1)+1)<=15;
                        end if;
                        xmod_flag:='1';
                    elsif func(i(1))=10 or func(i(1))=11 then
                        xmod_flag:='0';
                    end if;
                    if i(1)>=len then
                        fsm<=2;
								len2:=0;
								sorting:=0;
                    end if;
                    i(1):=i(1)+1;
                when 2 => --sort array
						  speed<=0;
                    if func(i(2))=15 then
                        len2:=len2+1;
                    else
                        func(sorting)<=func(i(2));
								sorting:=sorting+1;
                    end if;
                    if i(2)>=len then
                        i(2):=0;
								sorting:=0;
                        len2:=len-len2;
                        fsm<=3;
                    end if;
                    i(2):=i(2)+1;
                when 3 =>
                    if func(i(3))=10 then
                        if plminu='0' then
                            func(i(3))<= (func(i(3)-1)) + (func(i(3)+1));
                        else
                            func(i(3))<= (func(i(3)+1)) + (func(i(3)-2));
                        end if;
                        plminu:='1';
                    elsif func(i(3))=11 then
                        if plminu='0' then
                            func(i(3)) <= (func(i(3)-1)) - (func(i(3)+1));
                        else
                            func(i(3)) <= (func(i(3)-2)) - (func(i(3)+1));
                        end if;
                    end if;
                    if i(3)>=len2 then
                        fsm<=4;
                    end if;
						  
                    i(3):=i(3)+1;
                when 4 =>
                when others =>
                    fsm <= 0;
            end case;
        end if;
    end process;
end main;

	