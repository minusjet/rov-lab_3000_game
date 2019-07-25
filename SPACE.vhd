library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SPACE_BATTLE is
port
    ( 
------------------------------------------------------------------------------
    clk    : in  std_logic;                      -- P79
    rst_n  : in  std_logic;                      -- P205
    btn    : in  std_logic_vector(6 downto 1);   -- P18,19,20,100,101,102
------------------------------------------------------------------------------
    BUZZER : out std_logic;                      -- P21
------------------------------------------------------------------------------
    DIGIT  : out std_logic_vector(6 downto 1);   -- P22,24,26,27,28,29
    SEG_A  : out std_logic;                      -- P31
    SEG_B  : out std_logic;                      -- P33
    SEG_C  : out std_logic;                      -- P34
    SEG_D  : out std_logic;                      -- P35
    SEG_E  : out std_logic;                      -- P36
    SEG_F  : out std_logic;                      -- P37
    SEG_G  : out std_logic;                      -- P39
    SEG_DP : out std_logic;                      -- P48
------------------------------------------------------------------------------
    LCD_A  : out std_logic_vector(1 downto 0);   -- P50,51
    LCD_EN : out std_logic;                      -- P52
    LCD_D  : out std_logic_vector(7 downto 0)    -- P57,58,61,62,63,64,65,67
------------------------------------------------------------------------------
    );
end SPACE_BATTLE;

architecture Behavioral of SPACE_BATTLE is

component BTN_DEBOUNCE is
Port
    ( 
    divclk : in  std_logic; -- divide clock to change scan delay
    btn_i  : in  std_logic; -- H/W button input
    btn_o  : out std_logic -- debounced output
    );
end component BTN_DEBOUNCE;

component BTN_ONE is
port
    ( 
    clk   : in  std_logic; -- 4MHz reference clk
    btn_i : in  std_logic; -- debounced button input
    btn_o : out std_logic  -- single pulse output
    );
end component BTN_ONE;

component MUSIC_CTRL is
port
    ( 
    clk      : in  std_logic; -- 4MHz reference clk
    rst_n    : in std_logic;  -- Async Reset
    music_en : in std_logic;  -- enable music
    
    en       : out std_logic; -- buzzer enable
    data     : out std_logic_vector( 4 downto 0 ) -- 5-bit selector
    );
end component MUSIC_CTRL;

component PWM_GENERATOR is
port
    ( 
    clk   : in std_logic; -- 4MHz reference clk
    rst_n : in std_logic; -- Async Reset
    en    : in std_logic; -- buzzer enable
    data  : in std_logic_vector( 4 downto 0 ); -- 5-bit selector
    buzzer: out std_logic  -- buzzer out
    );
end component PWM_GENERATOR;

component SEG_CTRL is
port ( 
    clk : in std_logic;
    rst_n : in std_logic;
    input_bcd : in std_logic_vector( 23 downto 0); -- 4-bit * 6 segment
    DIGIT : out std_logic_vector( 6 downto 1 );
    SEG_A : out std_logic;
    SEG_B : out std_logic;
    SEG_C : out std_logic;
    SEG_D : out std_logic;
    SEG_E : out std_logic;
    SEG_F : out std_logic;
    SEG_G : out std_logic;
    SEG_DP : out std_logic );
end component SEG_CTRL;

component LCD_CTRL is
port (
    clk : in std_logic;
    rst_n : in std_logic;	
    in_LCD  : in std_logic_vector(255 downto 0);
    
    LCD_EN : out std_logic;
    LCD_A : out std_logic_vector (1 downto 0);
    LCD_D : out std_logic_vector (7 downto 0)
    );
end component LCD_CTRL;

component game_logic is
port
    ( 
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    btn      : in  std_logic_vector(6 downto 1);
    music_en : out std_logic;
    out_bcd  : out std_logic_vector(23 downto 0);
    out_LCD  : out std_logic_vector(255 downto 0)
    );
end component game_logic;

signal db_btn : std_logic_vector(6 downto 1);
signal os_btn : std_logic_vector(6 downto 1);
signal music_en : std_Logic;
signal buzzer_en: std_logic;
signal data : std_logic_vector(4 downto 0);
signal score_BCD : std_logic_vector(23 downto 0);
signal out_LCD  : std_logic_vector(255 downto 0);

signal scan_clk : std_logic;

begin
    SCAN_CLK_GEN : process(clk, rst_n)
	 variable scan_cnt : integer range 0 to 1000000;
	 begin
        if (rst_n = '0') then
            scan_cnt := 0;
            scan_clk <= '0';
        elsif rising_edge(clk) then
            if(scan_cnt = 10000) then
                scan_cnt := 0;
                scan_clk <= not scan_clk;
            else
                scan_cnt := scan_cnt + 1;
            end if;
        end if;
	 end process SCAN_CLK_GEN;
    DEBOUNCE_GEN : for i in 1 to 6 generate
        os_btns  : BTN_DEBOUNCE port map(scan_clk, btn(i), db_btn(i));
    end generate; 
	 
    GEN_BTN: for i in 1 to 6 generate
        os_btns  : BTN_ONE port map(clk, db_btn(i), os_btn(i));
    end generate;
	 
    mctrl  : MUSIC_CTRL    
        port map(clk, rst_n, music_en , buzzer_en, data);
    pwm1   : PWM_GENERATOR 
        port map(clk, rst_n, buzzer_en, data, buzzer);
    lcd1   : LCD_CTRL
        port map(clk, rst_n, out_LCD, LCD_EN, LCD_A, LCD_D);
    seg1   : SEG_CTRL
        port map (clk, rst_n, score_BCD, DIGIT, SEG_A, SEG_B,
                    SEG_C, SEG_D, SEG_E, SEG_F, SEG_G, SEG_DP);
    logic1 : game_logic
        port map(clk, rst_n, os_btn, music_en, score_BCD, out_LCD);
end Behavioral;