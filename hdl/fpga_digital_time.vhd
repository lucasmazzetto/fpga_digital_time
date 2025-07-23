library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpga_digital_time is
  generic (
    CLK_FREQ     : natural := 50_000_000; -- Clock frequency in Hz
    REFRESH_RATE : natural := 50000       -- Display refresh rate in Hz
  );
  port (
    clk          : in  std_logic; -- System clock
    rst          : in  std_logic := '0'; -- External reset
    btn_n        : in  std_logic_vector(3 downto 0) := "1111";    -- 4 active-low buttons
    seg_n        : out std_logic_vector(6 downto 0) := "1111111"; -- 7-segment segment outputs
    led_n        : out std_logic_vector(3 downto 0) := "1111";    -- LED outputs (seconds indicator)
    dig_enable_n : out std_logic_vector(3 downto 0) := "1111"     -- Digit enable lines for display
  );
end entity;

architecture rtl of fpga_digital_time is

  -- Time signals
  signal hours          : integer range 0 to 23 := 0;
  signal minutes        : integer range 0 to 59 := 0;
  signal seconds        : integer range 0 to 59 := 0;

  -- Offset values (modified via buttons)
  signal hours_offset   : integer range 0 to 24 := 0; -- Max value is 24 to trigger restart
  signal minutes_offset : integer range 0 to 59 := 0;

  signal restart        : std_logic := '0';
  signal rst_or_restart : std_logic := '0';
begin
  
  rst_or_restart <= rst or restart;

  ------------------------------------------------------------------------------
  -- Display Handler
  -- Drives 4-digit 7-segment display based on current hours and minutes
  ------------------------------------------------------------------------------
  display_handler : entity work.display_handler
    generic map (
      DIGIT_COUNT  => 4,
      CLK_FREQ     => CLK_FREQ,
      REFRESH_RATE => REFRESH_RATE
    )
    port map (
      clk          => clk,
      rst          => rst_or_restart,
      hours        => hours,
      minutes      => minutes,
      segments_n   => seg_n,
      dig_enable_n => dig_enable_n
    );

  ------------------------------------------------------------------------------
  -- LED Handler
  -- Updates LED states based on the current second value
  ------------------------------------------------------------------------------
  led_handler : entity work.led_handler
    port map (
      clk     => clk,
      rst     => rst,
      seconds => seconds,
      led_n   => led_n
    );

  ------------------------------------------------------------------------------
  -- Timer
  -- Maintains base time and applies user-provided offsets
  ------------------------------------------------------------------------------
  timer : entity work.timer
    generic map (
      CLK_FREQ => CLK_FREQ
    )
    port map (
      clk            => clk,
      rst            => rst,
      hours_offset   => hours_offset,
      minutes_offset => minutes_offset,
      hours          => hours,
      minutes        => minutes,
      seconds        => seconds,
      restart        => restart
    );

  ------------------------------------------------------------------------------
  -- Button Handler
  -- Debounces input buttons, and applies hour/minute offsets
  ------------------------------------------------------------------------------
  button_handler : entity work.button_handler
    generic map (
      CLK_FREQ      => CLK_FREQ,
      DEBOUNCE_TIME => 10
    )
    port map (
      clk             => clk,
      rst             => rst_or_restart,
      btn_n           => btn_n,
      hours_offset    => hours_offset,
      minutes_offset  => minutes_offset
    );

end architecture;
