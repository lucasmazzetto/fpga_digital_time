library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity button_handler is
  generic (
    CLK_FREQ        : natural;         -- System clock frequency in Hz
    DEBOUNCE_TIME   : natural := 10    -- Button debounce time
  );
  port (
    clk             : in  std_logic;                    -- System clock input
    rst             : in  std_logic;                    -- Synchronous reset (active high)
    btn_n           : in  std_logic_vector(4 downto 1); -- Active-low button inputs

    -- Hour offset output.
    -- The maximum value is 24 because reaching 24 triggers the timer's restart function.
    -- This causes the time counters and offset to reset back to 0.
    hours_offset    : out integer range 0 to 24;        -- Adjusted hour offset output
    minutes_offset  : out integer range 0 to 59         -- Adjusted minute offset output
  );
end entity;

architecture rtl of button_handler is

  -- Internal signals

  signal btn        : std_logic_vector(4 downto 1); -- Buttons active-high (inverted from btn_n)
  signal btn_clean  : std_logic_vector(4 downto 1) := (others => '1');  -- Debounced button signals
  signal btn_q      : std_logic_vector(4 downto 1) := (others => '1');  -- Previous debounced button states (for edge detection)

  procedure increment_hours(
    variable hours_var   : inout integer;
    constant INCREMENT   : in integer
  ) is
  begin
    hours_var := hours_var + INCREMENT;

    if hours_var > 24 then
      hours_var := 24;
    end if;
  end procedure;

  procedure increment_minutes(
    variable minutes_var : inout integer;
    variable hours_var   : inout integer;
    constant INCREMENT   : in integer
  ) is
  begin
    minutes_var := minutes_var + INCREMENT;

    if minutes_var >= 60 then
      minutes_var := minutes_var - 60;
      increment_hours(hours_var, 1);
    end if;
  end procedure;

begin

  ------------------------------------------------------------------------------
  -- Button debouncers: One instance per button to clean noisy input
  ------------------------------------------------------------------------------
  gen_debouncer : for i in 1 to 4 generate
    debouncer : entity work.signal_debouncer
      generic map (
        CLK_FREQ      => CLK_FREQ,
        DEBOUNCE_TIME => DEBOUNCE_TIME
      )
      port map (
        clk   => clk,
        rst   => '0',
        noisy => btn(i),
        clean => btn_clean(i)
      );
  end generate;

  ------------------------------------------------------------------------------
  -- Invert active-low buttons to active-high logic
  ------------------------------------------------------------------------------
  btn <= not btn_n;

  ------------------------------------------------------------------------------
  -- Main process:
  -- Detects rising edges of debounced button inputs, and
  -- increments hours or minutes offsets accordingly.
  ------------------------------------------------------------------------------
  process(clk)
    variable hours_var   : integer range 0 to 24;
    variable minutes_var : integer range 0 to 59;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Reset offsets and flags on reset
        hours_var := 0;
        minutes_var := 0;
        hours_offset <= 0;
        minutes_offset <= 0;
      else
        -- Iterate through each button for edge detection and handling
        for i in 4 downto 1 loop
          -- Detect rising edge: previous clean state low, current clean state high
          if btn_q(i) = '0' and btn_clean(i) = '1' then
            case i is
              when 1 => increment_hours(hours_var, 10); -- Button 1 increments hours by 10
              when 2 => increment_hours(hours_var, 1);  -- Button 2 increments hours by 1
              when 3 => increment_minutes(minutes_var, hours_var, 10); -- Button 3 increments minutes by 10
              when others => increment_minutes(minutes_var, hours_var, 1); -- Button 4 increments minutes by 1
            end case;
          end if;

          -- Update previous button state
          btn_q(i) <= btn_clean(i);
        end loop;

        -- Update output offsets
        hours_offset <= hours_var;
        minutes_offset <= minutes_var;
      end if;
    end if;
  end process;

end architecture;
