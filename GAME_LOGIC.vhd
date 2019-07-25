library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity game_logic is
Port
    ( 
------------------------------------------------------------------------------
    clk      : in  std_logic;                      -- P79
    rst_n    : in  std_logic;                      -- P205
    btn      : in  std_logic_vector(6 downto 1);   -- P18,19,20,100,101,102
------------------------------------------------------------------------------
    music_en : out std_logic;                      -- P21
    out_bcd  : out std_logic_vector(23 downto 0);   -- 4-bit * 6 segment
    out_LCD  : out std_logic_vector(255 downto 0)  -- 1byte * 32 char
------------------------------------------------------------------------------
    );
end game_logic;

architecture Behavioral of game_logic is

type T_LCD is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
type T_BCD is array (1 to 6) of integer range 0 to 9;
type T_FIELD is array(0 to 15) of std_logic_vector(3 downto 0);
subtype T_INST is integer range 0 to 31;
subtype T_ENUM is std_logic_vector(2 downto 0);

signal music_en_reg : std_logic;
signal score_arr : T_BCD;
signal LCD_arr   : T_LCD;
signal score_BCD : std_logic_vector(23 downto 0);
signal LCD_vec   : std_logic_vector(255 downto 0);
signal kbd_clr   : std_logic;
signal kbd_buff  : integer range 0 to 6;

begin
    music_en <= music_en_reg;
    out_bcd <= score_BCD;
    score_BCD <=
        std_logic_vector( to_unsigned(score_arr(6), 4) )&
        std_logic_vector( to_unsigned(score_arr(5), 4) )&
        std_logic_vector( to_unsigned(score_arr(4), 4) )&
        std_logic_vector( to_unsigned(score_arr(3), 4) )&
        std_logic_vector( to_unsigned(score_arr(2), 4) )&
        std_logic_vector( to_unsigned(score_arr(1), 4) );

    out_LCD <= LCD_vec;
    LCD_vec <=
        LCD_arr( 0)&LCD_arr( 1)&LCD_arr( 2)&LCD_arr( 3)&
        LCD_arr( 4)&LCD_arr( 5)&LCD_arr( 6)&LCD_arr( 7)&
        LCD_arr( 8)&LCD_arr( 9)&LCD_arr(10)&LCD_arr(11)&
        LCD_arr(12)&LCD_arr(13)&LCD_arr(14)&LCD_arr(15)&
        LCD_arr(16)&LCD_arr(17)&LCD_arr(18)&LCD_arr(19)&
        LCD_arr(20)&LCD_arr(21)&LCD_arr(22)&LCD_arr(23)&
        LCD_arr(24)&LCD_arr(25)&LCD_arr(26)&LCD_arr(27)&
        LCD_arr(28)&LCD_arr(29)&LCD_arr(30)&LCD_arr(31);

--save last input
    KBD_BUFF_CTRL:process(clk, rst_n, btn, kbd_clr)
    begin
        if (rst_n = '0') then
            kbd_buff <= 0;
        elsif rising_edge( clk ) then
            if (kbd_clr = '1') then
                kbd_buff <= 0;
            elsif (btn(1) = '0') then
                kbd_buff <= 1;
            elsif (btn(2) = '0') then
                kbd_buff <= 2;
            elsif (btn(3) = '0') then
                kbd_buff <= 3;
            elsif (btn(4) = '0') then
                kbd_buff <= 4;
            elsif (btn(5) = '0') then
                kbd_buff <= 5;
            elsif (btn(6) = '0') then
                kbd_buff <= 6;
            end if;
        end if;
    end process KBD_BUFF_CTRL;

--main FSM logic	
    MAIN:process(clk, rst_n, kbd_buff)
    --current instruction and some label constants
    variable instPtr : T_INST;
    variable retPtr  : T_INST;
    
    constant label_LOOP    : T_INST := 0;
    constant label_INIT    : T_INST := 1;
    constant label_START   : T_INST := 2;
    constant label_SELECT  : T_INST := 4;
    constant label_PLAY    : T_INST := 7;
    constant label_END     : T_INST := 11;
    constant label_LOOPEND : T_INST := 14;
    constant func_judge    : T_INST := 20;

    --game state enumerator and variable
    variable eGAME   : T_ENUM;
    constant eINIT   : T_ENUM := "000";
    constant eSTART  : T_ENUM := "001";
    constant eSELECT : T_ENUM := "011";
    constant ePLAY   : T_ENUM := "010";
    constant eEND    : T_ENUM := "110";

    -- selected difficulty 
    variable difficulty : integer range 1 to 3;

    -- enemy movement counter
    variable ene_cnt : integer range 0 to 7;
    variable ref_cnt : integer range 0 to 7;
    
    constant ref_easy : integer range 0 to 7:= 7;
    constant ref_norm : integer range 0 to 7:= 5;
    constant ref_hard : integer range 0 to 7:= 3;
    
    --user and missile position
    variable myposX : integer range 0 to 15;
    variable myposY : integer range 0 to 3;
    variable misposX : integer range 0 to 15;
    variable misposY : integer range 0 to 3;

    -- button name
    constant BTN_NO : integer range 0 to 6 := 0;
    constant BTN_DL : integer range 0 to 6 := 1;
    constant BTN_DM : integer range 0 to 6 := 2;
    constant BTN_DR : integer range 0 to 6 := 3;
    constant BTN_UL : integer range 0 to 6 := 4;
    constant BTN_UM : integer range 0 to 6 := 5;
    constant BTN_UR : integer range 0 to 6 := 6;


    -- int field[16];
    variable field : T_FIELD;
    variable en_pattern : T_FIELD;
    variable next_pattern : integer range 0 to 15;
    
    constant pattern_easy : T_FIELD := (( 
        0 => X"1",
        4 => X"2",
        8 => X"4",
        12 => X"8",
        others => X"0"));

    constant pattern_norm : T_FIELD := (( 
        0 => X"2",
        1 => X"2",
        3 => X"8",
        5 => X"5",
        9 => X"6",
        11 => X"2",
        13 => X"8",
        15 => X"5",
        others => X"0"));
    constant pattern_hard : T_FIELD := ((
        0 => X"F",
        1 => X"1",
        2 => X"2",
        3 => X"4",
        4 => X"8",
        5 => X"3",
        6 => X"6",
        7 => X"C",
        8 => X"8",
        9 => X"8",
        12 => X"7",
        14 => X"D",
        others => X"0"  ));
    
    variable LCD_reg   : T_LCD;
    
    variable music_on : std_logic;
    -- sleep for n ms
    variable sleep_timer : integer range 0 to 1_000_000;
    
    begin
        if(rst_n = '0') then
            score_arr <= (others => 0);
            kbd_clr <= '0';
            music_on := '0';
            instPtr := label_LOOP;
            eGAME := eINIT;
            LCD_ARR <= (others => X"20");
				
            sleep_timer := 0;
        elsif rising_edge(clk) then
            case instPtr is
            
-- LOOP: sleep and jump to proper address ------------------------------------
                when label_LOOP => 
                    if(sleep_timer = 1_000_000) then
                        sleep_timer := 0;
                        case eGAME is 
                            when eINIT   => instPtr := label_INIT;
                            when eSTART  => instPtr := label_START;
                            when eSELECT => instPtr := label_SELECT;
                            when ePLAY   => instPtr := label_PLAY;
                            when eEND    => instPtr := label_END;
                            when others  => instPtr := label_LOOP;
                        end case;
                    else -- sleep for 250 ms
                        sleep_timer := sleep_timer + 1;
                    end if;
------------------------------------------------------------------------------

-- INIT: wait until LCD initialization finished ------------------------------
                when label_INIT =>
                    kbd_clr <= '1';
                    music_on := '1';
                    eGAME := eSTART;
                    instPtr := label_LOOP;
------------------------------------------------------------------------------

-- START: Initialize local variable and wait button input  -------------------
                when label_START =>
                    score_arr <= (others => 0);
                    if (kbd_buff /= 0) then
                        kbd_clr      <= '1';
                        myposX       := 0;
                        myposY       := 0;
                        misposX      := 0;
                        myposY       := 0;
                        difficulty   := 1;
                        next_pattern := 0;
                        ene_cnt      := 0;
                        field := ( (others => "0000") );
                        eGAME := eSELECT;
                    end if;
                    instPtr := instPtr + 1;
                when label_START + 1 =>
                    instPtr := label_LOOPEND;
------------------------------------------------------------------------------

-- SELECT: Select difficulty -------------------------------------------------
                when label_SELECT =>
                    instPtr := instPtr + 1;
                when label_SELECT + 1 =>
                    if (kbd_buff /= 0) then
                        if (kbd_buff = BTN_DL and difficulty > 1) then
                            difficulty := difficulty - 1;
                        elsif (kbd_buff = BTN_DR and difficulty < 3) then
                            difficulty := difficulty + 1;
                        elsif (kbd_buff = BTN_DM) then
                            case (difficulty) is
                                when 2 => 
                                    en_pattern := pattern_norm;
                                    ref_cnt := ref_norm;
                                when 3 => 
                                    en_pattern := pattern_hard;
                                    ref_cnt := ref_hard;
                                when others => 
                                    en_pattern := pattern_easy;
                                    ref_cnt := ref_easy;
                            end case;
                            eGAME := ePLAY;
                        end if;
                        kbd_clr <= '1';
                    end if;
                    instPtr := instPtr + 1;
                when label_SELECT + 2 =>
                    instPtr := label_LOOPEND;
------------------------------------------------------------------------------

-- PLAY: play game -----------------------------------------------------------
                -- process button input  
                when label_PLAY =>
                    if (kbd_buff /= 0) then
                        if    (kbd_buff = BTN_DL and myposY > 0) then
                            myposY := myposY - 1;
                        elsif (kbd_buff = BTN_DM and myposY < 3) then
                            myposY := myposY + 1;
                        elsif (kbd_buff = BTN_UL and myposX > 0) then
                            myposX := myposX - 1;
                        elsif (kbd_buff = BTN_UM and myposX < 13) then
                            myposX := myposX + 1;
                        elsif (kbd_buff = BTN_DR and misposX = 0) then
                            misposY := myposY;
                            misposX := myposX + 1;
                        elsif (kbd_buff = BTN_UR) then
                            music_on := not music_on;
                        end if;
                        kbd_clr <= '1';
                    end if;
                    instPtr := instPtr + 1;
                -- update misile position
                when label_PLAY + 1 =>
                    if (misposX > 14) then
                        misposX := 0;
                    elsif (misposX > 0) then
                        misposX := misposX + 1;
                    end if;
                    retPtr := label_PLAY + 2;
                    instPtr := func_judge;
                --update enemy position
                when label_PLAY + 2 =>
                    if( ene_cnt = ref_cnt ) then
                        ene_cnt := 0;
                        field_shift : for i in 0 to 14  loop
                            field(i) := field(i + 1);
                        end loop field_shift;
                        field(15) := en_pattern(next_pattern);
                        if (next_pattern = 15) then
                            next_pattern := 0;
                        else
                            next_pattern := next_pattern + 1;
                        end if;
                        --increase score
                        if (score_arr(6) = 9) then
                            score_arr(6) <= 0;
                            if (score_arr(5) = 9) then
                                score_arr(5) <= 0;
                                if (score_arr(4) = 9) then
                                    score_arr(4) <= 0;
                                else 
                                    score_arr(4) <= score_arr(4) + 1; 
                                end if;
                            else 
                                score_arr(5) <= score_arr(5) + 1; 
                            end if;	
                        else 
                            score_arr(6) <= score_arr(6) + 1; 
                        end if;

                    else
                        ene_cnt := ene_cnt + 1;
                    end if; 
                    retPtr := label_PLAY + 3;
                    instPtr := func_judge;
                --colision judgement
                when label_PLAY + 3 =>
                    if (field(0) /= "0000") then
                        eGAME := eEND;
                    else
                        case myposY is
                            when 0 to 1 =>
                                if (field(myposX)(0) = '1' or
                                    field(myposX)(1) = '1') then
                                    eGAME := eEND;
                                end if;  
                            when 2 to 3 =>
                                if (field(myposX)(2) = '1' or 
                                    field(myposX)(3) = '1') then
                                    eGAME := eEND;
                                end if;
                        end case;	
                    end if;
                    instPtr := label_LOOPEND;
------------------------------------------------------------------------------

-- END: wait button input ----------------------------------------------------
                when label_END =>
                    if (kbd_buff /= 0) then
                        kbd_clr <= '1';
                        eGAME := eSTART;
                        instPtr := instPtr + 1;
                    else
                        instPtr := label_LOOPEND;
                    end if;
                when label_END + 1 => -- wait sufficient clock for kbd_clr
                    instPtr := instPtr + 1;
                when label_END + 2 =>
                    instPtr := label_LOOPEND;
------------------------------------------------------------------------------

-- LOOPEND: process module output and return to LOOP -------------------------
                -- music on/off				
                when label_LOOPEND =>
                    case eGAME is
                        when ePLAY => music_en_reg <= music_on;
                        when others => music_en_reg <= '0';
                    end case;
                    instPtr := instPtr + 1;
                
                -- build dipslay (except gameplay)
                when label_LOOPEND + 1=>
                    case eGAME is
                        when eSTART =>
                            LCD_reg := 
                                (
                                2  => X"53", --S
                                3  => X"50", --P
                                4  => X"41", --A
                                5  => X"43", --C
                                6  => X"45", --E

                                8  => X"42", --B
                                9  => X"41", --A
                                10 => X"54", --T
                                11 => X"54", --T
                                12 => X"4C", --L
                                13 => X"45", --E
                                
                                18 => X"70", --p
                                19 => X"72", --r
                                20 => X"65", --e
                                21 => X"73", --s
                                22 => X"73", --s
                                
                                24 => X"61", --a
                                25 => X"6E", --n
                                26 => X"79", --y

                                28 => X"6B", --k
                                29 => X"65", --e
                                30 => X"79", --y
                                
                                others => X"20"
                                );
                        
                        when eSELECT =>
                            LCD_reg(0 to 15) := 
                                (
                                3  => X"44", --D
                                4  => X"49", --I
                                5  => X"46", --F
                                6  => X"46", --F
                                7  => X"49", --I
                                8  => X"43", --C
                                9  => X"55", --U
                                10 => X"4C", --L
                                11 => X"54", --T
                                12 => X"59", --Y
                                others => X"20"
                                );
                            case difficulty is 
                                when 1 => LCD_reg(16 to 31) :=
                                    (
                                    22 => X"45", --E
                                    23 => X"41", --A
                                    24 => X"53", --S
                                    25 => X"59", --Y

                                    31 => X"3E", -->
                                    others => X"20"
                                    );
                                when 2 => LCD_reg(16 to 31) :=
                                    (
                                    16 => X"3C", --<
                                    
                                    21 => X"4E", --N
                                    22 => X"4F", --O
                                    23 => X"52", --R
                                    24 => X"4D", --M
                                    25 => X"41", --A
                                    26 => X"4C", --L

                                    31 => X"3E", -->
                                    others => X"20"
                                    );
                                when 3 => LCD_reg(16 to 31) :=
                                    (
                                    16 => X"3C", --<
                                    
                                    22 => X"48", --H
                                    23 => X"41", --A
                                    24 => X"52", --R
                                    25 => X"44", --D
                                    
                                    others => X"20"
                                    );
                                when others => LCD_reg(16 to 31) :=
                                    (others => X"20");
                            end case;
                        
                        when eEND => 
                            LCD_reg := 
                                (
                                3  => X"47", --G
                                6  => X"41", --A
                                9  => X"4D", --M
                                12 => X"45", --E

                                19 => X"4F", --O
                                22 => X"56", --V
                                25 => X"45", --E
                                28 => X"52", --R

                                others => X"20"
                                );
                        when others => 
                            LCD_reg := (others => X"20");
                    end case;
                    instPtr := instPtr + 1;
                -- build dipslay (enemy position)
                when label_LOOPEND + 2 =>
                if (eGAME = ePLAY) then
                    ene_gen : for i in 1 to 15  loop
                        case field(i)(1 downto 0) is
                            when "01" => LCD_reg(i) := X"04";
                            when "10" => LCD_reg(i) := X"05";
                            when "11" => LCD_reg(i) := X"06";
                            when others => LCD_reg(i) := X"20";
                        end case; 
                        
                        case field(i)(3 downto 2) is
                            when "01" => LCD_reg(i + 16) := X"04";
                            when "10" => LCD_reg(i + 16) := X"05";
                            when "11" => LCD_reg(i + 16) := X"06";
                            when others => LCD_reg(i + 16) := X"20";
                        end case; 
                    end loop ene_gen;
                end if;
                instPtr := instPtr + 1;
                -- build dipslay (my position and missile position)
                when label_LOOPEND + 3 =>
                    if (eGAME = ePLAY) then
                        case myposY is
                            when 0 => LCD_reg(myposX) := X"00";
                            when 1 => LCD_reg(myposX) := X"01";
                            when 2 => LCD_reg(myposX + 16) := X"00";
                            when 3 => LCD_reg(myposX + 16) := X"01";
                        end case;

                        if(misposX > 0) then
                            case misposY is
                                when 0 => LCD_reg(misposX) := X"02";
                                when 1 => LCD_reg(misposX) := X"03";
                                when 2 => LCD_reg(misposX + 16) := X"02";
                                when 3 => LCD_reg(misposX + 16) := X"03";
                            end case;
                        end if;
                    end if;
                    instPtr := instPtr + 1;
                --move from LCD register to LCD buffer
                when label_LOOPEND + 4 =>
                    LCD_arr <= LCD_reg;
                    instPtr := instPtr + 1;
                when label_LOOPEND + 5 =>
                    kbd_clr <= '0';
                    instPtr := label_LOOP;
------------------------------------------------------------------------------

-- subroutine judgement() ----------------------------------------------------
                when func_judge =>
                    -- missile hit
                    if ( misposX /= 0 and field(misposX)(misposY) ='1' ) then
                        -- remove enemy and reload missile
                        field(misposX)(misposY) :='0';
                        misposX := 0;
                        --increase score
                        if (score_arr(3) = 9) then
                            score_arr(3) <= 0;
                            if (score_arr(2) = 9) then
                                score_arr(2) <= 0;
                                if (score_arr(1) = 9) then
                                    score_arr(1) <= 0;
                                else 
                                    score_arr(1) <= score_arr(1) + 1; 
                                end if;
                            else 
                                score_arr(2) <= score_arr(2) + 1; 
                            end if;	
                        else 
                            score_arr(3) <= score_arr(3) + 1; 
                        end if;
                    end if;
                    --return to procedure
                    instPtr := retPtr;
------------------------------------------------------------------------------
                when others =>
                    instPtr := label_LOOP;
            end case;
        end if;
    end process MAIN;
end Behavioral;