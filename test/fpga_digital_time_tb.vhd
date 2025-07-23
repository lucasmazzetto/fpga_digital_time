library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpga_digital_time_tb is
end entity;

architecture sim of fpga_digital_time_tb is

  -- Constants
  constant CLK_PERIOD : time := 100 ms;
  constant CLK_FREQ   : natural := integer(1 sec / CLK_PERIOD);

  -- DUT signals
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '0';
  signal btn_n        : std_logic_vector(3 downto 0) := (others => '1');
  signal seg_n        : std_logic_vector(6 downto 0);
  signal led_n        : std_logic_vector(3 downto 0);
  signal dig_enable_n : std_logic_vector(3 downto 0);

begin

  ----------------------------------------------------------------
  -- Clock generation
  ----------------------------------------------------------------
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  ----------------------------------------------------------------
  -- DUT instantiation
  ----------------------------------------------------------------
  fpga_digital_time: entity work.fpga_digital_time
    generic map (
      CLK_FREQ => CLK_FREQ
    )
    port map (
      clk          => clk,
      rst          => rst,
      btn_n        => btn_n,
      seg_n        => seg_n,
      led_n        => led_n,
      dig_enable_n => dig_enable_n
    );

  ----------------------------------------------------------------
  -- Stimulus process
  ----------------------------------------------------------------
  stimulus: process

    -- Helper procedure to press a button
    procedure press_button(index : integer; press_time : time := CLK_PERIOD * 10) is
    begin
      btn_n(index) <= '0'; -- press
      wait for press_time;
      btn_n(index) <= '1'; -- release
      wait for press_time; -- debounce gap
    end procedure;

  begin

    wait for 100 ms;

    ----------------------------------------------------------------
    -- Test Case 1: +23h offset, +1h button wraparound
    ----------------------------------------------------------------
    report "Test Case 1: +23h offset, +1h button wraparound" severity note;
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';

    for i in 1 to 2 loop
      press_button(0); -- +10h x2 = 20h
    end loop;

    for i in 1 to 3 loop
      press_button(1); -- +1h x3 = 23h
    end loop;

    press_button(1);   -- +1h = 00h

    ----------------------------------------------------------------
    -- Test Case 2: Base 3h + 23h offset +10h
    ----------------------------------------------------------------
    report "Test Case 2: 3h + 20h offset +10h" severity note;
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';

    for i in 1 to 3 loop
      press_button(1); -- +1h x3 = 3h
    end loop;

    for i in 1 to 2 loop
      press_button(0); -- +10h x2 = 20h -> total 23h
    end loop;
    
    press_button(0);   -- +10h
    press_button(1);   -- +1h

    ----------------------------------------------------------------
    -- Test Case 3: Minute Carry
    ----------------------------------------------------------------
    report "Test Case 3: minute carry" severity note;
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';

    for i in 1 to 5 loop
      press_button(2); -- +10m each
    end loop;
    
    for i in 1 to 9 loop
      press_button(3); -- +1m each
    end loop;

    wait for 1 min;

    press_button(3); -- +1m

    wait for 1 min;

    ----------------------------------------------------------------
    -- Test Case 4: 20:30 + 10h
    ----------------------------------------------------------------
    report "Test Case 4: 20:35 + 10h" severity note;
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';

    for i in 1 to 2 loop
      press_button(0); -- +10h x2 = 20h
    end loop;
    for i in 1 to 3 loop
      press_button(2); -- +10m x3 = 30m
    end loop;
    press_button(0);   -- +10h

    ----------------------------------------------------------------
    -- Test Case 5: 23:59 +1m => 00:00
    ----------------------------------------------------------------
    report "Test Case 5: 23:59 + 1m" severity note;
    rst <= '1';
    wait for CLK_PERIOD;
    rst <= '0';

    for i in 1 to 2 loop
      press_button(0); -- +10h x2 = 20h
    end loop;
    
    for i in 1 to 3 loop
      press_button(1); -- +1h x3 = 23h
    end loop;

    for i in 1 to 5 loop
      press_button(2); -- +10m x5 = 50m
    end loop;

    for i in 1 to 9 loop
      press_button(3); -- +1m x9 = 59m
    end loop;

    press_button(3);   -- +1m => 00:00

    ----------------------------------------------------------------
    -- End of test
    ----------------------------------------------------------------
    report "Test completed" severity note;
    assert false report "End of simulation" severity failure;

  end process;

end architecture;
