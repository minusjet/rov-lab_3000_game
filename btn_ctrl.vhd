library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- button input debouncer
entity BTN_DEBOUNCE is
Port
    ( 
    divclk : in  std_logic; -- divide clock to change scan delay
    btn_i  : in  std_logic; -- H/W button input
    btn_o  : out std_logic -- debounced output
    );
end BTN_DEBOUNCE;

architecture Behavioral of BTN_DEBOUNCE is
signal reg1 : std_logic;
signal reg2 : std_logic;
begin
    D_FF1 : process(divclk, btn_i)
    begin
        if rising_edge(divclk) then
            reg1 <= btn_i;
        end if;
    end process D_FF1;
	 
    D_FF2 : process(divclk, reg1)
    begin
        if rising_edge(divclk) then
            reg2 <= reg1;
        end if;
    end process D_FF2;
	 btn_o <= reg1 or reg2;
end Behavioral;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- single pulse generator
entity BTN_ONE is
Port
    ( 
    clk   : in  std_logic; -- 4MHz reference clk
    btn_i : in  std_logic; -- debounced button input
    btn_o : out std_logic  -- single pulse output
    );
end BTN_ONE;

architecture Behavioral of BTN_ONE is

signal wr1  : std_logic;
signal reg1 : std_logic;
begin    
    SINGLE_GEN : process(clk, btn_i)
    variable btn_stat : integer range 0 to 2;
    begin
        if falling_edge(clk) then
            if( btn_i = '1') then
                btn_stat := 0;
                btn_o <= '1';
            else
                case btn_stat is
                    when 0 =>
                        btn_o <= '0';
                        btn_stat := 1;
                    when 1 =>
                        btn_stat := 2;
                    when 2 =>
                        btn_o <= '1';
                end case;
            end if;
        end if;
    end process SINGLE_GEN;
end Behavioral;