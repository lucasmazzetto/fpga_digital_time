library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
  generic (
    CLK_FREQ : integer  -- Clock frequency in Hz (ticks per second)
  );
  port (
    clk            : in  std_logic; -- System clock
    rst            : in  std_logic; -- Synchronous reset (active high)
    hours_offset   : in  integer range 0 to 24 := 0;  -- Hour adjustment offset [0-24]
    minutes_offset : in  integer range 0 to 59 := 0;  -- Minute adjustment offset [0-59]
    hours          : out integer range 0 to 23 := 0;  -- Output: adjusted hours [0-23]
    minutes        : out integer range 0 to 59 := 0;  -- Output: adjusted minutes [0-59]
    seconds        : out integer range 0 to 59 := 0;   -- Output: base seconds [0-59]
    restart        : out std_logic := '0' 
  );
end entity;

architecture rtl of timer is

  ------------------------------------------------------------------------------
  -- Wrap function
  -- Wraps an integer value within the range [0, limit-1].
  -- If value >= limit, subtracts limit to wrap around.
  ------------------------------------------------------------------------------
  function wrap(value : integer; limit : integer) return integer is
  begin
    if value >= limit then
      return value - limit;
    else
      return value;
    end if;
  end function;

  ------------------------------------------------------------------------------
  -- Increment and Wrap Procedure
  -- Increments a time unit value if requested and wraps around at wrap_at.
  -- Sets 'wrapped' flag to true if rollover occurs.
  ------------------------------------------------------------------------------
  procedure increment_and_wrap(
    variable value     : inout integer;
    constant wrap_at   : in integer;
    constant do_inc    : in boolean;
    variable wrapped   : out boolean
  ) is
  begin
    if do_inc then
      if value = wrap_at - 1 then
        value := 0; 
        wrapped := true;
      else
        value := value + 1;
        wrapped := false;
      end if;
    else
      wrapped := false;
    end if;
  end procedure;

begin

  ------------------------------------------------------------------------------
  -- Timer process
  -- Counts clock ticks to generate seconds, minutes, and hours.
  -- Applies user offsets for hours and minutes.
  -- Handles wrap-around and carry between time units.
  ------------------------------------------------------------------------------
  process(clk)
    variable wrapped        : boolean := false;
    variable ticks          : integer := 0;
    variable base_seconds   : integer range 0 to 59 := 0;
    variable base_minutes   : integer range 0 to 59 := 0;
    variable base_hours     : integer range 0 to 23 := 0;
    variable total_minutes  : integer range 0 to 119 := 0;
    variable total_hours    : integer range 0 to 48 := 0; -- base_hours + hours_offset + carry_hours
    variable carry_hours    : integer range 0 to 1 := 0;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Synchronous reset: clear all counters and outputs
        wrapped := false;
        ticks := 0;
        base_seconds := 0;
        base_minutes := 0;
        base_hours := 0;
		    total_minutes := 0;
		    total_hours := 0;
		    carry_hours := 0;
        seconds <= 0;
        minutes <= 0;
        hours <= 0;
        restart <= '0';
      else
        -- Increment tick counter; wraps after CLK_FREQ (1 second)
        increment_and_wrap(ticks, CLK_FREQ, true, wrapped);

        -- If one second elapsed, increment seconds with wrap
        increment_and_wrap(base_seconds, 60, wrapped, wrapped);

        -- If seconds wrapped, increment minutes with wrap
        increment_and_wrap(base_minutes, 60, wrapped, wrapped);

        -- If minutes wrapped, increment hours with wrap
        increment_and_wrap(base_hours, 24, wrapped, wrapped);

        -- Calculate carry from minute offset addition
        -- If minutes_offset pushes minutes past 59, add carry to hours
        total_minutes := base_minutes + minutes_offset;
        carry_hours := total_minutes / 60; -- Integer division
        total_hours := base_hours + hours_offset + carry_hours;

        if total_hours >= 24 then
          base_minutes := 0;
          base_hours := 0;
          total_minutes := 0;
          total_hours := 0;
          carry_hours := 0;
          minutes <= 0;
          hours <= 0;
          restart <= '1';
        else
          -- Assign outputs with wrapping and offsets applied
          seconds <= base_seconds;
          minutes <= wrap(total_minutes, 60);
          hours <= wrap(total_hours, 24);
          restart <= '0';
        end if;

      end if;
    end if;
  end process;

end architecture;
