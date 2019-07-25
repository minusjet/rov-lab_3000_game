library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity MUSIC_ROM is
Port
    ( 
    clk   : in  std_logic; -- 4MHz reference clk
    rst_n : in  std_logic; -- Async reset
    addr  : in  std_logic_vector( 7 downto 0 ); -- 8-bit address
    data  : out std_logic_vector( 7 downto 0 )  -- 8-bit rom data
    );
end MUSIC_ROM;

architecture Behavioral of MUSIC_ROM is

type T_ROM is array(0 to 127) of std_logic_vector( 7 downto 0 );
subtype T_MUS is std_logic_vector( 4 downto 0 ); -- 5-bit precision
subtype T_BEAT is std_logic_vector( 2 downto 0 );-- 3-bit precision

begin	
    -- decode 4-bit scale to 12-bit period[us]
    ROM_PROC : process(clk, rst_n, addr)
    
    --variable int_data : integer range 0 to 31;
    constant RES : T_MUS := std_logic_vector( to_unsigned( 0, T_MUS'length) );
    
    constant C5  : T_MUS := std_logic_vector( to_unsigned( 1, T_MUS'length) );
    constant C5S : T_MUS := std_logic_vector( to_unsigned( 2, T_MUS'length) );
    constant D5  : T_MUS := std_logic_vector( to_unsigned( 3, T_MUS'length) );
    constant D5S : T_MUS := std_logic_vector( to_unsigned( 4, T_MUS'length) );
    constant E5  : T_MUS := std_logic_vector( to_unsigned( 5, T_MUS'length) );
    constant F5  : T_MUS := std_logic_vector( to_unsigned( 6, T_MUS'length) );
    constant F5S : T_MUS := std_logic_vector( to_unsigned( 7, T_MUS'length) );
    constant G5  : T_MUS := std_logic_vector( to_unsigned( 8, T_MUS'length) );
    constant G5S : T_MUS := std_logic_vector( to_unsigned( 9, T_MUS'length) );
    constant A6  : T_MUS := std_logic_vector( to_unsigned(10, T_MUS'length) );
    constant A6S : T_MUS := std_logic_vector( to_unsigned(11, T_MUS'length) );
    constant B6  : T_MUS := std_logic_vector( to_unsigned(12, T_MUS'length) );

    constant C6  : T_MUS := std_logic_vector( to_unsigned(13, T_MUS'length) );
    constant C6S : T_MUS := std_logic_vector( to_unsigned(14, T_MUS'length) );
    constant D6  : T_MUS := std_logic_vector( to_unsigned(15, T_MUS'length) );
    constant D6S : T_MUS := std_logic_vector( to_unsigned(16, T_MUS'length) );
    constant E6  : T_MUS := std_logic_vector( to_unsigned(17, T_MUS'length) );
    constant F6  : T_MUS := std_logic_vector( to_unsigned(18, T_MUS'length) );
    constant F6S : T_MUS := std_logic_vector( to_unsigned(19, T_MUS'length) );
    constant G6  : T_MUS := std_logic_vector( to_unsigned(20, T_MUS'length) );
    constant G6S : T_MUS := std_logic_vector( to_unsigned(21, T_MUS'length) );
    constant A7  : T_MUS := std_logic_vector( to_unsigned(22, T_MUS'length) );
    constant A7S : T_MUS := std_logic_vector( to_unsigned(23, T_MUS'length) );
    constant B7  : T_MUS := std_logic_vector( to_unsigned(24, T_MUS'length) );

    -- 1/INF
    constant T0 : T_BEAT := std_logic_vector( to_unsigned(0, T_BEAT'length) );
    -- 1/16
    constant T1 : T_BEAT := std_logic_vector( to_unsigned(1, T_BEAT'length) );
    -- 1/8
    constant T2 : T_BEAT := std_logic_vector( to_unsigned(2, T_BEAT'length) );
    -- 1/4
    constant T3 : T_BEAT := std_logic_vector( to_unsigned(3, T_BEAT'length) );
    -- 1/2
    constant T4 : T_BEAT := std_logic_vector( to_unsigned(4, T_BEAT'length) );
    -- 1/1
    constant T5 : T_BEAT := std_logic_vector( to_unsigned(5, T_BEAT'length) );
    -- 2/1
    constant T6 : T_BEAT := std_logic_vector( to_unsigned(6, T_BEAT'length) );
    -- 4/1
    constant T7 : T_BEAT := std_logic_vector( to_unsigned(7, T_BEAT'length) );


    -- 0.1ms base clock, reference 80 tick 
    -- count 4 > 1us, count 400 > 0.1ms
    constant song_table : T_ROM := ((
----------------------
-- http://easymusic.altervista.org/wp-content/uploads/2015/12/KOROBEINIKI-TETRIS-THEME-A.gif
----------------------1 ,3
            01 => A6  & T5,
            02 => RES & T0,
        
            03 => E5  & T4,
            04 => F5  & T4,
            05 => RES & T0,
             
            06 => G5  & T4,
            07 => A6  & T3,
            08 => G5  & T3,
            09 => RES & T0,
             
            10 => F5  & T4,
            11 => E5  & T4,
            12 => RES & T0,
-----------------------
            13 => D5  & T5,
            14 => RES & T0,
             
            15 => D5  & T4,
            16 => F5  & T4,
            17 => RES & T0,
             
            18 => A6  & T5,
            19 => RES & T0,
             
            20 => G5  & T4,
            21 => F5  & T4,
            22 => RES & T0,
-----------------------
            23 => E5  & T5,
            24 => E5  & T4,
            25 => RES & T0,
             
            26 => F5  & T4,
            27 => RES & T0,
             
            28 => G5  & T5,
            29 => RES & T0,
             
            30 => A6  & T5,
            31 => RES & T0,
-----------------------
            32 => F5  & T5,
            33 => RES & T0,
             
            34 => D5  & T5,
            35 => RES & T0,
             
            36 => D5  & T6,
            37 => RES & T0,
-----------------------2 ,4
            38 => RES & T4,
            39 => RES & T0,
            
            40 => G5  & T5,
            41 => RES & T0, 
            
            42 => A6S & T4,
            43 => RES & T0,
            
            44 => D6  & T5,
            45 => RES & T0,
            
            46 => C6  & T4,
            47 => A6S & T4,
            48 => RES & T0,
-----------------------
            49 => A6  & T5,
            50 => A6  & T4,
            51 => RES & T0,
            
            52 => F5  & T4,
            53 => RES & T0,
            
            54 => A6  & T5,
            55 => RES & T0,
            
            56 => G5  & T4,
            57 => F5  & T4,
            58 => RES & T0,
-----------------------
            59 => E5  & T5,
            60 => RES & T0,
            
            61 => E5  & T4,
            62 => F5  & T4,
            63 => RES & T0,
            
            64 => G5  & T5,
            65 => RES & T0,
            
            66 => A6  & T5,
            67 => RES & T0,
-----------------------
            68 => F5  & T5,
            69 => RES & T0,
            
            70 => D5  & T5,
            71 => RES & T0,
            
            72 => D5  & T5,
            73 => RES & T0,
             
            74 => RES & T5,
            75 => RES & T0,
-----------------------5
            76 => A6  & T6,
            77 => RES & T0,
            78 => F5  & T6,
            79 => RES & T0,
            
            80 => G5  & T6,
            81 => RES & T0,
            82 => E5  & T6,
            83 => RES & T0,
            
            84 => F5  & T6,
            85 => RES & T0,
            86 => D5  & T6,
            87 => RES & T0,
            
            88 => C5S & T6,
            89 => RES & T0,
            90 => E5& T6,
            91 => RES & T0,
            
            92 => A6 & T6,
            93 => RES & T0,
            94 => F5 & T6,
            95 => RES & T0,
            
            96 => G5 & T6,
            97 => RES & T0,
            98 => E5 & T6,
            99 => RES & T0,
            
            100 => F5 & T5,
            101 => RES & T0,
            102 => A6  & T5,
            103 => RES & T0,
            104 => D6  & T6,
            105 => RES & T0,
            
            106 => C6S & T7,
            107 => RES & T0,
            
            108 => RES & T0,
            109 => RES & T0,
            110 => RES & T0,
-----------------------END
              0 => (others => '1'), -- just for remove warning
        others => (others => '0') ));  --//default

variable int_addr : integer range 0 to 255;
variable restricted_addr : integer range 0 to 127; --restrict index range

    begin
        int_addr := conv_integer(addr);
        data <= song_table ( restricted_addr );
        if (rst_n = '0') then
            restricted_addr := 0;
        elsif rising_edge(clk) then
            if  int_addr < 76  then
                restricted_addr := int_addr ;
            elsif  int_addr < 185  then  -- 107 +75 = 182
                restricted_addr := int_addr - 75;
            else 
                restricted_addr := 1;
            end if;
        end if;
    end process ROM_PROC;
End Behavioral;