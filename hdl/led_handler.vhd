library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_handler is
  generic (
    LED_COUNT : positive := 4  -- Number of LEDs to control (default is 4)
  );
  port (
    clk     : in  std_logic;                             -- System clock
    rst     : in  std_logic;                             -- Synchronous reset
    seconds : in  integer range 0 to 59;                 -- Current seconds [0–59]
    led_n   : out std_logic_vector(LED_COUNT-1 downto 0) -- LED outputs (active-low)
  );
end entity;

architecture rtl of led_handler is
begin

  ------------------------------------------------------------------------------
  -- LED Rotation Logic
  -- Rotates the LED pattern to the left whenever `seconds` changes
  -- This creates a simple animation that updates once per second.
  -- Uses internal variables for previous second and current LED pattern.
  ------------------------------------------------------------------------------
  process(clk)
    -- Holds the last value of `seconds` to detect when it changes
    variable prev_seconds  : integer range 0 to 59 := 0;

    -- LED pattern (active-low): 1 = off, 0 = on
    -- Initially, only the first LED is on
    variable led_n_pattern : std_logic_vector(LED_COUNT-1 downto 0) := 
                              (0 => '0', others => '1');
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Reset LED pattern: turn on first LED only
        prev_seconds   := 0;
        led_n_pattern  := (0 => '0', others => '1');

      elsif seconds /= prev_seconds then
        -- Detect change in seconds to trigger rotation
        prev_seconds := seconds;

        -- Rotate pattern left by 1 bit
        led_n_pattern := led_n_pattern(LED_COUNT-2 downto 0) & 
                         led_n_pattern(LED_COUNT-1);
      end if;

      -- Synchronously update output
      led_n <= led_n_pattern;
    end if;
  end process;

end architecture;
