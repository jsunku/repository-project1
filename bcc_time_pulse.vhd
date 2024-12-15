-- ============================================================================
-- time pulse for STM Anomaly Report Generator
-- ============================================================================

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.ALL;

entity bcc_time_pulse is
generic (
   PREDIV    : integer := 1600 -- CLKFREQ_HZ/100us
);
Port (
   CLK_I         : in  std_logic;
   RST_I         : in  std_logic;
   PULSE_100us_O : out std_logic;
   PULSE_1ms_O   : out std_logic
);
end bcc_time_pulse;

architecture BEHAVIOR of bcc_time_pulse is

   signal clken100us, clken1ms : std_logic;

begin

   PULSE_100us_O <= clken100us;
   PULSE_1ms_O <= clken1ms;

   -- Pre-divider generates 100 us clken from CLK_I
   p_100us : process(CLK_I,RST_I)
      variable cnt : integer range 0 to PREDIV-1;
   begin
      if RST_I = '1' then
         clken100us <= '0';
         cnt := 0;
      elsif CLK_I'event and CLK_I = '1' then
         clken100us <= '0';
         if cnt >= PREDIV-1 then
            clken100us <= '1';
            cnt := 0;
         else
            cnt := cnt + 1;
         end if;
      end if;
   end process;

   -- 1ms = 10 * clken100us
   p_1ms : process(CLK_I,RST_I)
       variable cnt : std_logic_vector(3 downto 0);
   begin
      if RST_I = '1' then
         clken1ms <= '0';
		 cnt := "0000";
      elsif CLK_I'event and CLK_I = '1' then
         clken1ms <= '0';
         if clken100us = '1' then
		     if cnt >= "1001" then
                 clken1ms <= '1';
                 cnt := "0000";
             else
                 cnt := cnt + 1;
             end if;
		 end if;  	 
      end if;
   end process;

end BEHAVIOR;
