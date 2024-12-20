-- note : takes data from g1g_pstc_packet_handling
-- ports: sband_counters, cband_counters, valid/invalid, payload from  g1g_pstc_packet_handling paylod for 0x08,0x09 skip fifo's, use ports  library ieee;

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;
   use work.global_package.all;
   use work.sync_fifo_iface.all;
   use work.stc_pkt_handler_package.all;

entity payload_handler is
   port (
      clk                 : in    std_logic;
      rst_n               : in    std_logic;
      MODE_INFO           : in    std_logic;
      INIT_DONE           : in    std_logic;
      suid                : in    std_logic;
  
     -- sband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
     -- cband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits
      difference_stm_ack    :  in slv2_t;
      ---FROM STC_PACKET HANDLER
      valid_in            : in    slv2_t;
      sband_cband         : in    std_logic;                     -- 0: S-band, 1: C-band
      window_stc_id       : in    std_logic_vector(15 downto 0); -- 0X08
      window_time         : in    std_logic_vector(15 downto 0); -- Units of 100 ms
      filter_stc_id       : in    std_logic_vector(15 downto 0); -- 0X09
      filter_mask_counter : in    std_logic_vector(7 downto 0);
      filter_mask_onoff   : in    std_logic_vector(7 downto 0);

      -- Counters
      --sband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
      --cband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits
      valid_out           : out   slv2_t;
      s_or_cband          : out   std_logic;
      logged_counter      : OUT std_logic_vector(4 downto 0);
     -- sband_cband_o       : out  std_logic ;
      ALL_COUNTER_VALUE   : OUT slv2_t;
      LOGGED_COUNTER_O    : out std_logic_vector(3 downto 0); 
      START_UPDATE_CUNTERS_O : out std_logic;
      REPORT_WINDOW_PAYLOAD_id  : out std_logic_vector(31 downto 0);---0X08
      REPORT_FILTER_PAYLOAD_id  : out std_logic_vector(31 downto 0);--0X09
       STM_ACK_PAYLOAD       : out std_logic_vector(31 downto 0)




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

   signal r, rin :g1g_payload_handling_t ;
   signal window_payload : slv32_t;
   signal filter_pyload : slv32_t;
begin
      --window_payload <= window_stc_id & window_time; --just copy values for stm handler  
      --filter_pyload <= filter_stc_id &  filter_mask_counter & filter_mask_onoff ;     

   comb_proc : process (all)
      variable v           : g1g_payload_handling_t;
   begin
      v := r;

   case r.state is

      when IDLE =>
         v.clk_counter :=  (others => '0');
         v.s_or_cband  :=  '0';
        -- v.valid_invalid_stc  :=  (others => '0');
         v.all_counters_value :=  (others => '0');
         v.start_update_cunters := '0';
             
         -- v.window_stc_id_and_payload :=  (others => '0');
        -- v.filter_stc_id_and_payload := (others => '0');
              if valid_in = "10" then
                if difference_stm_ack = "01" then --if we receive report window stc then sore value of report windoe to update counter 
                                                  --else update then with 100us each time
                   v.clk_counter :=  std_logic_vector(convertto_clk_cycles(window_time));
                   v.payload_for_stm_ack := window_stc_id & window_time ;
                else
                  v.clk_counter :=  std_logic_vector(convertto_clk_cycles(x"0000")); --use counter value AS 100US
                end if;
                  v.state := FILTER_CHECK;
                 --v.valid_invalid_stc := "10"; --valid stc ceate valid pstmack and updata counters based on cband or sband
              elsif valid_in = "11" then --invalid stc
                 v.state := CREATE_INVALID_STM_ACK;
              end if;

      when CREATE_INVALID_STM_ACK =>
          v.valid_invalid_stc := "01";
          --store the current stc_id and paload fot stm ack only 09 can have on valid 
          v.payload_for_stm_ack := filter_stc_id &  filter_mask_counter & filter_mask_onoff ;
          v.state := IDLE;
         
      when FILTER_CHECK =>
     -- v.window_stc_id_and_payload  := window_stc_id & window_time ;
     -- v.filter_stc_id_and_payload  := filter_stc_id &  filter_mask_counter & filter_mask_onoff ;
          if  difference_stm_ack = "11" then
              v.filter_stc_id_and_payload  := filter_stc_id &  filter_mask_counter & filter_mask_onoff ;
          end if;
           if filter_mask_onoff = X"00" then 
               v.all_counters_value := "00";
           elsif filter_mask_onoff = X"01" then
               v.filter_mask_counter_int := to_integer(unsigned(filter_mask_counter(6 downto 0)));
               v.state := WINDOW_REPORT_ST; 
               v.logged_counter_o:= std_logic_vector(to_unsigned(r.filter_mask_counter_int,4));
           end if;
      when WINDOW_REPORT_ST =>
--        if sband_cband = '0' then 
--             v.s_or_cband := '0';
--        else
--            v.s_or_cband := '1';
--        end if;

        v.s_or_cband := sband_cband;

          if r.clk_counter <= 0 then
            v.start_update_cunters := '1';
            v.state := DONE_ST;
          else
            v.clk_counter := r.clk_counter -1 ;
          end if;
      when DONE_ST =>
        v.state := IDLE;
      ---MAY BE NEED A ACKNOWLEDGEMENT FROM stm generator to go back to idle and repeat the procedure 
      when others =>
      v.state := IDLE;
      end case;          

               

   -- update registers 
   rin         <=  v;
   -- update Outputs 
   valid_out                  <= r.valid_invalid_stc;
   s_or_cband                  <= r.s_or_cband;
   ALL_COUNTER_VALUE          <= r.all_counters_value; 
   logged_counter_O           <= r.logged_counter_o;
   START_UPDATE_CUNTERS_O     <= r.start_update_cunters;
   REPORT_WINDOW_PAYLOAD_id   <=  r.window_stc_id_and_payload;
   REPORT_FILTER_PAYLOAD_id   <= r.filter_stc_id_and_payload;
   STM_ACK_PAYLOAD            <= r. filter_stc_id_and_payload;
   end process comb_proc;
   --REPORT_WINDOW_PAYLOAD_id <= window_payload ;
   --REPORT_FILTER_PAYLOAD_id <=  filter_pyload ;
   seq_proc : process (clk, rst_n)
   begin
      if rst_n = '0' then
         r.state       <= IDLE;
         r.clk_counter        <=  (others => '0');
         r.s_or_cband         <= '0';
         r.valid_invalid_stc  <=  (others => '0');
         r.valid_invalid_stc  <=  (others => '0');
         r.all_counters_value <=  (others => '0');
         r.filter_mask_counter_int <= 0;
         r.start_update_cunters  <= '0';
         r.clk_counter <= (others => '0');
         r.payload_for_stm_ack <=  (others => '0');
         r.window_stc_id_and_payload <=  (others => '0');
         r.filter_stc_id_and_payload <= (others => '0');
      elsif rising_edge(clk) then
         r <= rin;
      end if;
   end process seq_proc;

end architecture behavior;



-- note : takes data from g1g_pstc_packet_handling
-- ports: sband_counters, cband_counters, valid/invalid, payload from  g1g_pstc_packet_handling paylod for 0x08,0x09 skip fifo's, use ports  library ieee;

--library ieee;
--   use ieee.std_logic_1164.all;
--   use ieee.numeric_std.all;
--   use work.global_package.all;
--   use work.sync_fifo_iface.all;
--   use work.stc_pkt_handler_package.all;
--
--entity payload_handler is
--   port (
--      clk                 : in    std_logic;
--      rst_n               : in    std_logic;
--      suid                : in    std_logic;
--      -- Control signals
--      start               : in    std_logic;
--
--      sband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
--      cband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits
--
--      ---FROM STC_PACKET HANDLER
--      valid_in            : in    slv2_t;
--      sband_cband         : in    std_logic;                     -- 0: S-band, 1: C-band
--      window_stc_id       : in    std_logic_vector(15 downto 0); -- 0X08
--      window_time         : in    std_logic_vector(15 downto 0); -- Units of 100 ms
--      filter_stc_id       : in    std_logic_vector(15 downto 0); -- 0X09
--      filter_mask_counter : in    std_logic_vector(7 downto 0);
--      filter_mask_onoff   : in    std_logic_vector(7 downto 0);
--
--      -- Counters
--      sband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
--      cband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits
--      valid_out           : out   slv2_t
--
--
--
--
--
--   --      payload_1             : out   slv32_t;
--   --      payload_2             : out   slv32_t;
--   --      -- PPS                             : in std_logic;
--   --      ack                                 : out   std_logic;
--   --      done                                : out   slv2_t;                        --! (10)valid/(11)invalid/(01)internal STC
--   --      count                               : out   natural range 0 to c_max_size;
--   --      ---to stm _handler
--   --
--   --      -- Memory interface
--   --      dfifo_rd_data                       : in    slv18_t;
--   --      dfifo_rd_en                         : out   std_logic;
--   --
--   --      -- STC_EventRepTimeWindow  -- NOTE: remove the fifo'sif not required
--   --
--   --
--   --
--   --      report_window_payload_cfifo_rd_data : out   std_logic_vector(31 downto 0);
--   --      report_window_payload_cfifo_rd_en   : in    std_logic;
--   --      report_window_payload_cfifo_empty   : out   std_logic;
--   --
--   --      report_filter_payload_cfifo_rd_data : out   std_logic_vector(31 downto 0);
--   --      report_filter_payload_cfifo_rd_en   : in    std_logic;
--   --      report_filter_payload_cfifo_empty   : out   std_logic
--   );
--end entity payload_handler;
--
--architecture behavior of payload_handler is
--
--   signal r, rin : g1g_payload_handler_t;
--
--begin
--
--
--   comb_proc : process (all)
--      variable v           : g1g_payload_handling_t;
--   begin
--      v := r;
--
--      if r.clk_counter > 0 then
--         -- Wait
--         v.clk_counter := r.clk_counter - 1;
--      else
--         -- Set new value
--         v.clk_counter := convertto_clk_cycles(window_time);
--
--         if sband_cband = '0' then
--            -- S-band
--
--            if filter_mask_onoff = X"00" then
--               -- Clear all counters
--               sband_data_out := (others => X"00");
--            else
--               filter_mask_counter_int := to_integer(filter_mask_counter(6 downto 0));
--
--               for i in 0 to 15 loop
--                  if i = filter_mask_counter_int then
--                     -- Copy one counter
--                     sband_data_out(i) := sband_data_in(i);
--                  else
--                     -- Clear other counters
--                     sband_data_out(i) := X"00";
--                  end if;
--               end loop;
--
--            end if;
--         else
--         -- C-band
--         end if;
--      end if;
--   end process comb_proc;
--
--   seq_proc : process (clk, rst_n)
--   begin
--      if rst_n = '0' then
--         r.state       <= IDLE_ST;
--         r.sband_data  <= (others => X"00");
--         r.cband_data  <= (others => X"00");
--         r.valid_out   <= "00";
--         r.sband_cband <= '0';
--         r.clk_counter <= (others => '0');
--      elsif rising_edge(clk) then
--         r <= rin;
--      end if;
--   end process seq_proc;
--
--end architecture behavior;
--
--



































