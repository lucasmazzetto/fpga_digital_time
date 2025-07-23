library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signal_debouncer is
  generic (
    CLK_FREQ       : natural;  -- System clock frequency in Hz
    DEBOUNCE_TIME  : natural   -- Debounce time in milliseconds
  );
  port (
    clk   : in  std_logic;     -- System clock
    rst   : in  std_logic;     -- Synchronous reset
    noisy : in  std_logic;     -- Noisy input signal (e.g., from mechanical button)
    clean : out std_logic      -- Debounced clean output signal
  );
end entity;

architecture rtl of signal_debouncer is

  -- Calculate the number of clock cycles corresponding to the debounce time
  constant MAX_COUNT : natural := (CLK_FREQ / 1000) * DEBOUNCE_TIME;

  -- Counter to create a slower clock enable signal for sampling the noisy input
  signal counter : unsigned(27 downto 0) := (others => '0');

  -- Slow clock enable signal goes high every max_count clock cycles
  signal slow_clk_enable : std_logic;

  -- Flip-flop chain to sample the noisy input (shift register)
  signal q0, q1, q2 : std_logic := '0';

begin

  -- Process to generate the slow clock enable signal by counting clock cycles
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= (others => '0');  -- Reset counter
      else
        if MAX_COUNT = 0 then
          -- Bypass counting if debounce time is 0
          counter <= (others => '0');
        elsif counter < to_unsigned(MAX_COUNT - 1, counter'length) then
          counter <= counter + 1;    -- Increment until reaching max_count
        else
          counter <= (others => '0');  -- Reset counter when max_count is reached
        end if;
      end if;
    end if;
  end process;

  -- Slow clock enable is high only at the end of each debounce interval
  -- slow_clk_enable <= '1' when counter = to_unsigned(MAX_COUNT - 1, counter'length) else '0';
  slow_clk_enable <= '1' when (MAX_COUNT = 0) or 
    (counter = to_unsigned(MAX_COUNT - 1, counter'length)) else '0';

  -- Debouncing process: samples the input signal at the slower rate
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q0 <= '0';
        q1 <= '0';
        q2 <= '0';
      elsif slow_clk_enable = '1' then
        -- Shift the sampled values through the flip-flop chain
        q2 <= q1;
        q1 <= q0;
        q0 <= noisy;
      end if;
    end if;
  end process;

  -- Clean output is high only when the last two sampled values indicate a rising edge
  clean <= q1 and not q2;

end architecture;
