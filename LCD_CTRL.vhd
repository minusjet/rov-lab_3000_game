library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LCD_CTRL is
port (
    clk : in std_logic;
    rst_n : in std_logic;
    
    in_LCD  : in std_logic_vector(255 downto 0);
    LCD_EN : out std_logic;
    LCD_A : out std_logic_vector (1 downto 0);
    LCD_D : out std_logic_vector (7 downto 0)
    );
end LCD_CTRL;

architecture Behavioral of LCD_CTRL is
    type T_VRAM is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
    
    subtype T_LCD_INST is integer range 0 to 511;

    signal e_reg : std_logic;
    signal a_reg : std_logic_vector (1 downto 0);
    signal d_reg : std_logic_vector (7 downto 0);
    
    signal in_data : T_VRAM;
    
    constant init_inst : T_VRAM := 
    (( 
            00 => X"38", -- Function set
            01 => X"08", -- Display OFF
            02 => X"01", -- Display clear
            03 => X"06", -- Entry mode set
            04 => X"0C", -- Display ON
            05 => X"40", -- Set CGRAM ADDR
            others => X"00"
    ));

    constant pattern1 : T_VRAM := 
        (( 
            -- user defined pattern 0
            00 => "00011110",
            01 => "00000111",
            02 => "00011110",
            -- user defined pattern 1
            13 => "00011110",
            14 => "00000111",
            15 => "00011110",
            -- user defined pattern 2
            17 => "00001110",
            -- user defined pattern 3
            30 => "00001110",
            others => X"00"
        ));
    constant pattern2 : T_VRAM := 
        (( 
            -- user defined pattern 4
            00 => "00001111",
            01 => "00011100",
            02 => "00001111",
            -- user defined pattern 5
            13 => "00001111",
            14 => "00011100",
            15 => "00001111",
            -- user defined pattern 6
            16 => "00001111",
            17 => "00011100",
            18 => "00001111",

            21 => "00001111",
            22 => "00011100",
            23 => "00001111",
            -- user defined pattern 7
            others => X"00"
        ));

begin
    LCD_EN <= e_reg;
    LCD_A  <= a_reg;
    LCD_D  <= d_reg;	

    ASSIGN_TO_ARR : for i in 0 to 31 generate
        in_data(i) <= in_LCD(255 - 8*i downto 248 - 8*i);
    end generate ASSIGN_TO_ARR;

    LCD_PROC:process(clk, rst_n) 
    variable instPtr : T_LCD_INST;
    variable retPtr : T_LCD_INST;
    
    constant eLCD_INIT  : T_LCD_INST := 0;
    constant eLCD_CHAR  : T_LCD_INST := 24;
    constant eLCD_RET   : T_LCD_INST := 284;
    constant eLCD_WRITE : T_LCD_INST := 361;
    constant eLCD_NL    : T_LCD_INST := 500;

    variable vram : T_VRAM;
    variable lcd_db : std_logic_vector (7 downto 0);

    variable lcd_sleep_cnt : integer range 0 to 1000;
    begin
        if (rst_n = '0') then
            instPtr := eLCD_INIT;
            lcd_sleep_cnt := 0;

            e_reg <= '0';
            a_reg <= "00";
            d_reg <= X"00";

            vram := (others => X"00");
        elsif rising_edge(clk) then
            if(lcd_sleep_cnt = 1000) then
                lcd_sleep_cnt := 0;
                
                case instPtr is
                    -- Initialize LCD
                    when eLCD_INIT to eLCD_INIT + 23 =>
                        case (instPtr mod 4) is
                            when 0 => d_reg <= init_inst(instPtr / 4);
                            when 1 => e_reg <= '1';
                            when 3 => e_reg <= '0';
                            when others => 
                        end case;

                    -- Write User pattern to CGRAM
                    when eLCD_CHAR to eLCD_CHAR + 127 =>
                        case ((instPtr - eLCD_CHAR) mod 4) is
                            when 0 => d_reg <= 
                                pattern1((instPtr - eLCD_CHAR) / 4);
                            when 1 =>
                                e_reg <= '1';
                            when 3 =>
                                e_reg <= '0';
                            when others => 
                        end case;
                    when eLCD_CHAR + 128 to eLCD_CHAR + 255 =>
                        case ((instPtr - eLCD_CHAR) mod 4) is
                            when 0 => d_reg <= 
                                pattern2((instPtr - eLCD_CHAR - 128) / 4);
                            when 1 => e_reg <= '1';
                            when 3 => e_reg <= '0';
                            when others => 
                        end case;

                    -- Set DDRAM ADDR
                    when eLCD_CHAR + 256 => d_reg <= X"80";
                    when eLCD_CHAR + 257 => e_reg <= '1';
                    when eLCD_CHAR + 259 => e_reg <= '0';

                    -- Return to home
                    when eLCD_RET + 0 => d_reg <= X"03";
                    when eLCD_RET + 1 => e_reg <= '1';
                    when eLCD_RET + 41 => e_reg <= '0';

                    -- Write procedure
                    when eLCD_WRITE to eLCD_WRITE + 127 =>
                        case ((instPtr - eLCD_WRITE) mod 4) is
                            when 0 => d_reg <= 
                                vram((instPtr - eLCD_WRITE) / 4);
                            when 1 => e_reg <= '1';
                            when 3 => e_reg <= '0';
                            when others => 
                        end case;

                    -- Change Line
                    when eLCD_NL + 0 => d_reg <=  X"C0"; 
                    when eLCD_NL + 1 => e_reg <= '1';
                    when eLCD_NL + 3 => e_reg <= '0';

                    when others =>	--do nothing
                end case;

                case instPtr is
                    -- Initialize LCD
                    when eLCD_INIT       => a_reg <= "00";
                    -- Write User pattern to CGRAM
                    when eLCD_CHAR       => a_reg <= "01";
                    -- Set DDRAM ADDR
                    when eLCD_CHAR + 256 => a_reg <= "00";
                    -- Return to home
                    when eLCD_RET        => a_reg <= "00";
                    -- Write procedure
                    when eLCD_WRITE      => a_reg <= "01";
                    when eLCD_WRITE + 64 => a_reg <= "01";
                    -- Change Line
                    when eLCD_NL         => a_reg <= "00";
                    --preserve past value
                    when others =>
                end case;

                if (instPtr = eLCD_WRITE - 1) then 
                    vram := in_data;
                end if;

                case instPtr is
                    when eLCD_WRITE +  63 => instPTR := eLCD_NL;
                    when eLCD_WRITE + 127 => instPTR := eLCD_RET;
                    when    eLCD_NL +   3 => instPTR := eLCD_WRITE + 64;
                    when           others => instPtr := instPtr + 1;
                end case; 

            else
                lcd_sleep_cnt := lcd_sleep_cnt + 1;
            end if;

        end if;
    end process LCD_PROC;
end Behavioral;