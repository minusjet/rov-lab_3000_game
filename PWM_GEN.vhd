library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity PWM_GENERATOR is
Port
    ( 
    clk   : in std_logic; -- 4MHz reference clk
    rst_n : in std_logic; -- Async Reset
    en    : in std_logic; -- buzzer enable
    data  : in std_logic_vector( 4 downto 0 ); -- 5-bit selector
    buzzer: out std_logic  -- buzzer out
    );
end PWM_GENERATOR;

architecture Behavioral of PWM_GENERATOR is

type T_PERIOD is array(0 to 31) of integer range 0 to 2000;
     
signal period : std_logic_vector(10 downto 0);
signal pwm_out : std_logic;

begin	
    -- decode 4-bit scale to 12-bit period[us]
    OCTAVE_DECODE : process(data)

    variable int_data : integer range 0 to 31;
    
    constant ptable : T_PERIOD := ((
        1  => 1911, --  C5  //  523.251[hz]
        2  => 1804, --  C5S //  554.365[hz]
        3  => 1703, --  D5  //  587.330[hz]
        4  => 1607, --  D5S //  622.254[hz]
        5  => 1517, --  E5  //  659.255[hz]
        6  => 1432, --  F5  //  698.456[hz]
        7  => 1351, --  F5S //  739.989[hz]
        8  => 1276, --  G5  //  783.991[hz]
        9  => 1204, --  G5S //  830.609[hz]
        10 => 1136, --  A6  //  880.000[hz]
        11 => 1073, --  A6S //  932.328[hz]
        12 => 1012, --  B6  //  987.766[hz]

        13 => 956,  --  C6  // 1046.502[hz]
        14 => 902,  --  C6S // 1108.731[hz]
        15 => 851,  --  D6  // 1174.659[hz]
        16 => 804,  --  C6S // 1244.508[hz]
        17 => 758,  --  E6  // 1318.510[hz]
        18 => 716,  --  F6  // 1396.913[hz]
        19 => 676,  --  C6S // 1479.978[hz]
        20 => 638,  --  G6  // 1567.982[hz]
        21 => 602,  --  C6S // 1661.219[hz]
        22 => 568,  --  A7  // 1760.000[hz]
        23 => 536,  --  A7S // 1864.655[hz]
        24 => 506,  --  B7  // 1975.533[hz]
        
        others => 1911));  --//default
    
    begin
        int_data := conv_integer(data);
        period <= std_logic_vector( to_unsigned( ptable( int_data ), period'length ) );
    end process OCTAVE_DECODE;
     
    -- generate PWM signal from 4Mhz reference clock and 12-bit period
    PWM_GEN:process (clk, rst_n, period)
    variable clk_cnt : integer range 0 to 3;
    variable ref_period : std_logic_vector( 10 downto 0 );
    variable period_cnt : integer range 0 to 2000;
    begin
        if( rst_n = '0' ) then  --reset
            pwm_out <= '0';
            period_cnt := 0;
            clk_cnt := 0;
            ref_period := period;
        
        elsif rising_edge ( clk ) then
            clk_cnt := clk_cnt + 1;
            if(clk_cnt = 3) then -- generate 1us reference period
                clk_cnt := 0;
                period_cnt := period_cnt + 1;
                
                --peroid cycle finished
                if( period_cnt = conv_integer(ref_period) ) then 
                    period_cnt := 0;
                    --set new period
                    ref_period := period;
                    pwm_out <= '1'; --pwm on
                --25% duty
                elsif( period_cnt = conv_integer( period(10 downto 2) ) ) then
                    pwm_out <= '0'; --pwm off
                end if;
            end if;
        end if;
    end process PWM_GEN;
    
    buzzer <= pwm_out and en;
End Behavioral;