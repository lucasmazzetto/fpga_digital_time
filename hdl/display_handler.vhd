library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_handler is
  generic (
    DIGIT_COUNT  : positive; -- Number of digits to control (e.g., 4 for HH:MM)
    CLK_FREQ     : natural;  -- System clock frequency in Hz
    REFRESH_RATE : natural   -- Display refresh rate (Hz)
  );
  port (
    clk          : in  std_logic;                               -- System clock
    rst          : in  std_logic;                               -- Synchronous reset
    hours        : in  integer range 0 to 23;                   -- Input hours [0-23]
    minutes      : in  integer range 0 to 59;                   -- Input minutes [0-59]
    segments_n   : out std_logic_vector(6 downto 0);            -- 7-segment outputs (active-low)
    dig_enable_n : out std_logic_vector(DIGIT_COUNT-1 downto 0) -- Digit enable lines (active-low)
  );
end entity;

architecture rtl of display_handler is

  -- Array to hold BCD digits for the display (0–9)
  type bcd_array is array (0 to DIGIT_COUNT - 1) of unsigned(3 downto 0);
  signal digit_values : bcd_array;

  -- Digit selection counter (2 bits = 4 digits max)
  signal mux_counter   : unsigned(1 downto 0) := (others => '0');

  -- Refresh counter to control digit multiplexing speed
  signal refresh_cnt   : unsigned(15 downto 0) := (others => '0');

  -- Currently selected BCD digit (converted to integer)
  signal current_digit : integer range 0 to 9 := 0;

  -- Internal outputs
  signal int_segments_n   : std_logic_vector(6 downto 0);
  signal int_dig_enable_n : std_logic_vector(DIGIT_COUNT - 1 downto 0);

begin

  ------------------------------------------------------------------------------
  -- 7-Segment Decoder
  -- Converts BCD digit to 7-segment active-low pattern
  ------------------------------------------------------------------------------
  seg7 : entity work.bcd_to_7seg
    port map (
      bcd_digit  => current_digit,
      segments_n => int_segments_n
    );

  ------------------------------------------------------------------------------
  -- Digit Extraction Logic
  -- Extracts individual digits from hours and minutes for display
  ------------------------------------------------------------------------------
  digit_extract : process(hours, minutes)
  begin
    digit_values(0) <= to_unsigned(minutes mod 10, 4); -- Units of minutes
    digit_values(1) <= to_unsigned(minutes / 10, 4);   -- Tens of minutes
    digit_values(2) <= to_unsigned(hours mod 10, 4);   -- Units of hours
    digit_values(3) <= to_unsigned(hours / 10, 4);     -- Tens of hours
  end process;

  ------------------------------------------------------------------------------
  -- Digit Multiplexer
  -- Selects the current digit to be displayed on the active digit position
  ------------------------------------------------------------------------------
  multiplexer : process(mux_counter, digit_values)
  begin
    current_digit <= to_integer(digit_values(to_integer(mux_counter)));
  end process;

  ------------------------------------------------------------------------------
  -- Digit Enable Generator
  -- Enables one digit at a time (active-low logic)
  ------------------------------------------------------------------------------
  gen_enables : process(mux_counter)
  begin
    for i in 0 to DIGIT_COUNT - 1 loop
      if i = to_integer(mux_counter) then
        int_dig_enable_n(i) <= '0'; -- Active digit
      else
        int_dig_enable_n(i) <= '1'; -- Inactive digits
      end if;
    end loop;
  end process;

  ------------------------------------------------------------------------------
  -- Refresh Process
  -- Controls timing for digit multiplexing using a refresh counter
  ------------------------------------------------------------------------------
  refresh : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        mux_counter <= (others => '0');
        refresh_cnt <= (others => '0');
      else
        if refresh_cnt = REFRESH_RATE then
          refresh_cnt <= (others => '0');
          mux_counter <= mux_counter + 1;
        else
          refresh_cnt <= refresh_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Output Assignments
  -- Drive display and digit enables; blank display when reset is active
  ------------------------------------------------------------------------------
  segments_n   <= (others => '1') when rst = '1' else int_segments_n;
  dig_enable_n <= (others => '1') when rst = '1' else int_dig_enable_n;

end architecture;
