library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_to_7seg is
  port (
    bcd_digit   : in  integer range 0 to 9;         -- Valid BCD digit input (0–9)
    segments_n  : out std_logic_vector(6 downto 0)  -- 7-segment outputs (active low)
  );
end entity;

architecture rtl of bcd_to_7seg is
begin
  process(bcd_digit)
  begin
    case bcd_digit is
      when 0 => segments_n <= "1000000"; 
      when 1 => segments_n <= "1111001";
      when 2 => segments_n <= "0100100";
      when 3 => segments_n <= "0110000";
      when 4 => segments_n <= "0011001";
      when 5 => segments_n <= "0010010";
      when 6 => segments_n <= "0000010";
      when 7 => segments_n <= "1111000";
      when 8 => segments_n <= "0000000";
      when 9 => segments_n <= "0011000";
    end case;
  end process;
end architecture;
