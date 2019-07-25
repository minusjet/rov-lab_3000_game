library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SEG_CTRL is
Port (
    clk       : in std_logic; 
    rst_n     : in std_logic;
    input_bcd : in std_logic_vector( 23 downto 0); -- 4-bit * 6 segment
    
    DIGIT  : out std_logic_vector( 6 downto 1 );
    SEG_A  : out std_logic;
    SEG_B  : out std_logic;
    SEG_C  : out std_logic;
    SEG_D  : out std_logic;
    SEG_E  : out std_logic;
    SEG_F  : out std_logic;
    SEG_G  : out std_logic;
    SEG_DP : out std_logic );
end SEG_CTRL;

architecture Behavioral of SEG_CTRL is

signal sel  : std_logic_vector(2 downto 0);
signal data : std_logic_vector(3 downto 0);
signal seg  : std_logic_vector(7 downto 0);

begin
    SEGMENT_MUX : process(sel, input_bcd)
    begin
        case sel is
            when "000" => 
                DIGIT <= (1 => '1', others => '0');
                data  <= input_bcd ( 3 downto 0);
            when "001" => 
                DIGIT <= (2 => '1', others => '0');
                data  <= input_bcd ( 7 downto 4);
            when "010" => 
                DIGIT <= (3 => '1', others => '0');
                data  <= input_bcd (11 downto 8);
            when "011" => 
                DIGIT <= (4 => '1', others => '0');
                data  <= input_bcd (15 downto 12);
            when "100" => 
                DIGIT <= (5 => '1', others => '0');
                data  <= input_bcd (19 downto 16);
            when "101" => 
                DIGIT <= (6 => '1', others => '0');
                data  <= input_bcd (23 downto 20);
            when others => 
                DIGIT <= (1 => '1', others => '0');
                data  <=  input_bcd ( 3 downto 0);
        end case;
    end process SEGMENT_MUX;
    
    SEGMENT_SWAP : process(rst_n, clk)
    variable seg_clk_cnt : integer range 0 to 200;
    begin
        if(rst_n = '0') then
            sel <= "000";
            seg_clk_cnt := 0;
        elsif rising_edge( clk ) then
            if(seg_clk_cnt = 200) then
                seg_clk_cnt := 0;
                if(sel = "101") then
                    sel <= "000";
                else
                    sel <= sel + 1;
                end if;
            else
                seg_clk_cnt := seg_clk_cnt + 1;
            end if;
        end if;
    end process SEGMENT_SWAP;
    
    
    SEGMENT_DECODE : process (data)
    begin
        case data is -- dp gfedcba
            when "0000" => seg <= "00111111"; -- 0
            when "0001" => seg <= "00000110"; -- 1 
            when "0010" => seg <= "01011011"; -- 2
            when "0011" => seg <= "01001111"; -- 3  
            when "0100" => seg <= "01100110"; -- 4
            when "0101" => seg <= "01101101"; -- 5
            when "0110" => seg <= "01111101"; -- 6
            when "0111" => seg <= "00000111"; -- 7
            when "1000" => seg <= "01111111"; -- 8
            when "1001" => seg <= "01101111"; -- 9
            when others => seg <= (others => '0');
        end case;
    end process SEGMENT_DECODE;
    
    SEG_A  <= seg(0);
    SEG_B  <= seg(1);
    SEG_C  <= seg(2);
    SEG_D  <= seg(3);
    SEG_E  <= seg(4);
    SEG_F  <= seg(5);
    SEG_G  <= seg(6);
    SEG_DP <= seg(7);
    
End Behavioral;