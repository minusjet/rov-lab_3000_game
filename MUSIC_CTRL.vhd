library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity MUSIC_CTRL is
Port
    (
    clk      : in  std_logic; -- 4MHz reference clk
    rst_n    : in std_logic; -- Async Reset
    music_en : in std_logic; --enable music
    
    en    : out std_logic; -- buzzer enable
    data  : out std_logic_vector( 4 downto 0 ) -- 5-bit selector
    );
end MUSIC_CTRL;

architecture Behavioral of MUSIC_CTRL is
component MUSIC_ROM is
    Port
    ( 
    clk   : in  std_logic; -- 4MHz reference clk
    rst_n : in  std_logic; -- Async reset
    addr  : in  std_logic_vector( 7 downto 0 ); -- 8-bit address
    data  : out std_logic_vector( 7 downto 0 )  -- 8-bit rom data
    );
end component;

signal addr : std_logic_vector( 7 downto 0 ); 
signal rom_data  : std_logic_vector( 7 downto 0 );
signal ref_tick : integer range 0 to 511;

begin
    ROM1: MUSIC_ROM port map
    (
        clk,
        rst_n,
        addr,
        rom_data
    );
    
    TICK_RESOLUTION : process (rom_data)
    begin
        case  conv_integer(rom_data(2 downto 0)) is
            when      0 => ref_tick <= 2;
            when      1 => ref_tick <= 8; 
            when      2 => ref_tick <= 16;
            when      3 => ref_tick <= 32;
            when      4 => ref_tick <= 64;
            when      5 => ref_tick <= 128;
            when      6 => ref_tick <= 256;
            when others => ref_tick <= 511;
        end case;
    end process TICK_RESOLUTION;

    
    DRIVE : process (clk, rst_n, music_en, rom_data)
    -- count 16000 : 4ms
    
    variable clk1 : integer range 0 to 16000;
    -- tick counter
    variable cnt_tick : integer range 0 to 511;
    -- song ends at state_184
    variable cnt_state : integer range 0 to 187;
    begin
        addr <= std_logic_vector( to_unsigned(cnt_state, addr'length) ); 
        data <= rom_data(7 downto 3);		
        case rom_data(7 downto 3) is
            when "00000" => en <= '0'; -- REST
            when "11111" => en <= '0'; -- INVALID
            when others => en <= '1';
        end case;
        
        if (rst_n ='0') then
            clk1 := 0;
            cnt_state := 0;
        elsif rising_edge(clk) then
            --generate 0.1ms clk
            
            if( clk1 = 16000 ) then
                clk1 := 0;
                if (music_en = '0') then
                    cnt_state := 0;
                end if;
                
                case cnt_state is
                    when 0   => -- begin
                        if (music_en = '1') then
                            cnt_state := cnt_state + 1;
                            cnt_tick  := 0;
                        end if;
                    when 187 => -- finish
                        cnt_state := 0;
                    when others =>
                        if ( cnt_tick = ref_tick ) then
                            cnt_tick  := 0;
                            cnt_state := cnt_state + 1;
                        else 
                            cnt_tick := cnt_tick + 1;
                        end if;
                end case;
            else
                clk1 := clk1 + 1;
            end if;
        end if;
     end process DRIVE;
End Behavioral;