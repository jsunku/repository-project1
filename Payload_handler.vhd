-- note : takes data from g1g_pstc_packet_handling
-- ports: sband_counters, cband_counters, valid/invalid, payload from  g1g_pstc_packet_handling paylod for 0x08,0x09 skip fifo's, use ports  library ieee;

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use work.global_package.all;
   use work.sync_fifo_iface.all;
   use work.stc_pkt_handler_package.all;

entity payload_handler is
   port (
      clk                 : in    std_logic;
      rst_n               : in    std_logic;
      suid                : in    std_logic;
      -- Control signals
      start               : in    std_logic;

      sband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
      cband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits

      ---FROM STC_PACKET HANDLER
      valid_in            : in    slv2_t;
      sband_cband         : in    std_logic;                     -- 0: S-band, 1: C-band
      window_stc_id       : in    std_logic_vector(15 downto 0); -- 0X08
      window_time         : in    std_logic_vector(15 downto 0); -- Units of 100 ms
      filter_stc_id       : in    std_logic_vector(15 downto 0); -- 0X09
      filter_mask_counter : in    std_logic_vector(7 downto 0);
      filter_mask_onoff   : in    std_logic_vector(7 downto 0);

      -- Counters
      sband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
      cband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits
      valid_out           : out   slv2_t





   --      payload_1             : out   slv32_t;
   --      payload_2             : out   slv32_t;
   --      -- PPS                             : in std_logic;
   --      ack                                 : out   std_logic;
   --      done                                : out   slv2_t;                        --! (10)valid/(11)invalid/(01)internal STC
   --      count                               : out   natural range 0 to c_max_size;
   --      ---to stm _handler
   --
   --      -- Memory interface
   --      dfifo_rd_data                       : in    slv18_t;
   --      dfifo_rd_en                         : out   std_logic;
   --
   --      -- STC_EventRepTimeWindow  -- NOTE: remove the fifo'sif not required
   --
   --
   --
   --      report_window_payload_cfifo_rd_data : out   std_logic_vector(31 downto 0);
   --      report_window_payload_cfifo_rd_en   : in    std_logic;
   --      report_window_payload_cfifo_empty   : out   std_logic;
   --
   --      report_filter_payload_cfifo_rd_data : out   std_logic_vector(31 downto 0);
   --      report_filter_payload_cfifo_rd_en   : in    std_logic;
   --      report_filter_payload_cfifo_empty   : out   std_logic
   );
end entity payload_handler;

architecture behavior of payload_handler is

   signal r, rin : g1g_payload_handler_t;

begin


   comb_proc : process (all)
      variable v           : g1g_payload_handling_t;
   begin
      v := r;

      if r.clk_counter > 0 then
         -- Wait
         v.clk_counter := r.clk_counter - 1;
      else
         -- Set new value
         v.clk_counter := convertto_clk_cycles(window_time);

         if sband_cband = '0' then
            -- S-band

            if filter_mask_onoff = X"00" then
               -- Clear all counters
               sband_data_out := (others => X"00");
            else
               filter_mask_counter_int := to_integer(filter_mask_counter(6 downto 0));

               for i in 0 to 15 loop
                  if i = filter_mask_counter_int then
                     -- Copy one counter
                     sband_data_out(i) := sband_data_in(i);
                  else
                     -- Clear other counters
                     sband_data_out(i) := X"00";
                  end if;
               end loop;

            end if;
         else
         -- C-band
         end if;
      end if;
   end process comb_proc;

   seq_proc : process (clk, rst_n)
   begin
      if rst_n = '0' then
         r.state       <= IDLE_ST;
         r.sband_data  <= (others => X"00");
         r.cband_data  <= (others => X"00");
         r.valid_out   <= "00";
         r.sband_cband <= '0';
         r.clk_counter <= (others => '0');
      elsif rising_edge(clk) then
         r <= rin;
      end if;
   end process seq_proc;

end architecture behavior;

