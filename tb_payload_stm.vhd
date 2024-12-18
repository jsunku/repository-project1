--------------------------------------------------------------------------------
--!
--! @file g1g_stc_stm_top.vhd <BR>
--!
--! @brief STC STM handling top file <BR>
--!
--! @details  <BR>
--!
--! @attention <Classification: RESTREINT UE/EU RESTRICTED> <BR>
--!
--! @note <This design is used on M2GL150-1FCG1152I FPGA of PFCB EBB-0002.> <BR>
--!
--! @author Jagan mohan , Aerospace Data Security GmbH <BR>
--!
--!
--------------------------------------------------------------------------------
--
-- File location    $URL: blah $
-- Last change in   $Revision: blah $
-- Last change on   $Date: blah $
-- Last change by   $Author: blah $
--
-- see SVN logs for details
--
--------------------------------------------------------------------------------
--

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use work.global_package.all;

entity tb_payload_stm is
end entity tb_payload_stm;

architecture simulation of tb_payload_stm is

   signal clk   : std_logic := '1';
   signal rst_n : std_logic := '0';

   signal mode_info : std_logic;
   signal init_done : std_logic;
   signal suid      : std_logic;

   -- sband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
   -- cband_data_in       : in    counter_vector(15 downto 0);   -- 16 counters of 8 bits
   signal difference_stm_ack  : slv2_t;
   ---FROM STC_PACKET HANDLER
   signal valid_in            : slv2_t;
   signal sband_cband         : std_logic;                          -- 0: S-band, 1: C-band
   signal window_stc_id       : std_logic_vector(15 downto 0);      -- 0X08
   signal window_time         : std_logic_vector(15 downto 0);      -- Units of 100 ms
   signal filter_stc_id       : std_logic_vector(15 downto 0);      -- 0X09
   signal filter_mask_counter : std_logic_vector(7 downto 0);
   signal filter_mask_onoff   : std_logic_vector(7 downto 0);

   -- Counters
   -- sband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
   -- cband_data_out      : out   counter_vector(15 downto 0);   -- 16 counters of 8 bits
   signal valid_out                : slv2_t;
   signal s_or_cband               : std_logic;
   signal logged_counter           : std_logic_vector(4 downto 0);
   -- sband_cband_o       : out  std_logic ;
   signal all_counter_value        : slv2_t;
   signal logged_counter_o         : std_logic_vector(3 downto 0);
   signal start_update_cunters_o   : std_logic;
   signal report_window_payload_id : std_logic_vector(31 downto 0); ---0X08
   signal report_filter_payload_id : std_logic_vector(31 downto 0); -- 0X09
   signal stm_ack_payload          : std_logic_vector(31 downto 0);

begin

   clk   <= not clk after 16 ns;
   rst_n <= '0', '1' after 100 ns;

   -- Generate stimulus
   stim_proc : process
   begin
      -- Default values
      difference_stm_ack  <= (others => '0');
      valid_in            <= (others => '0');
      sband_cband         <= '0';
      window_stc_id       <= (others => '0');
      window_time         <= (others => '0');
      filter_stc_id       <= (others => '0');
      filter_mask_counter <= (others => '0');
      filter_mask_onoff   <= (others => '0');

      wait until rst_n = '1';
      wait until rising_edge(clk);

      -- Test 1 : Invalid STC
      report "Test 1";
      valid_in            <= "11";
      wait until rising_edge(clk);

      valid_in            <= (others => '0');
      wait until rising_edge(clk);


      -- Test 2 :
      report "Test 2";
      valid_in            <= "10";
      difference_stm_ack  <= "01";
      filter_mask_onoff   <= X"01";
      filter_mask_counter <= X"05";
      wait until rising_edge(clk);


      valid_in            <= (others => '0');
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      report "End of test";
      wait;
   end process stim_proc;

   -- Instantiate DUT

   payload_handler : entity work.payload_handler
      port map (
         rst_n                    => rst_n,
         clk                      => clk,
         suid                     => suid,
         mode_info                => mode_info,
         init_done                => init_done,
         sband_cband              => sband_cband,
         valid_in                 => valid_in,
         difference_stm_ack       => difference_stm_ack,
         window_stc_id            => window_stc_id,
         window_time              => window_time,
         filter_stc_id            => filter_stc_id,
         filter_mask_counter      => filter_mask_counter,
         filter_mask_onoff        => filter_mask_onoff,
         valid_out                => valid_out,
         s_or_cband               => s_or_cband,
         logged_counter           => logged_counter,
         report_window_payload_id => report_window_payload_id,
         report_filter_payload_id => report_filter_payload_id,
         start_update_cunters_o   => start_update_cunters_o,
         stm_ack_payload          => stm_ack_payload
      );

--   stm_generator : entity work.bcc_stm_generation
--      port map (
--         clk_i                        => SYS_RST_N,
--         rst_n_i                      => SYS_RST_N,
--         suid                         => SUID,
--         init_done                    => INIT_DONE,
--         tow_bit                      => s_tow_bit,
--         subsecond_cnt_value          => s_subsecond_cnt_value,
--         pps                          => PPS_SYNC,
--         check_sband_cband            => s_or_cband,
--         ack_pyload                   => stm_ack_payload,
--         s_event_type_0_i             => S_EVENT_TYPE_0_I,
--         s_event_type_1_i             => S_EVENT_TYPE_1_I,
--         s_event_type_2_i             => S_EVENT_TYPE_2_I,
--         s_event_type_3_i             => S_EVENT_TYPE_3_I,
--         s_event_type_4_i             => S_EVENT_TYPE_4_I,
--         s_event_type_5_i             => S_EVENT_TYPE_5_I,
--         s_event_type_6_i             => S_EVENT_TYPE_6_I,
--         s_event_type_7_i             => S_EVENT_TYPE_7_I,
--         s_event_type_8_i             => S_EVENT_TYPE_8_I,
--         s_event_type_9_i             => S_EVENT_TYPE_9_I,
--         s_event_type_12_i            => S_EVENT_TYPE_12_I,
--         c_event_type_0_i             => C_EVENT_TYPE_0_I,
--         c_event_type_1_i             => C_EVENT_TYPE_1_I,
--         c_event_type_2_i             => C_EVENT_TYPE_2_I,
--         c_event_type_4_i             => C_EVENT_TYPE_4_I,
--         report_window_payload_and_id => s_o_window_payload,
--         report_filter_payload_and_id => s_o_filter_payload,
--         i_valid_invalid              => s_valid_out,
--         i_start_update_cunters       => s_o_start_counters,
--         c_dfifo_wdata                => C_DFIFO_WDATA,
--         c_cfifo_wdata                => C_CFIFO_WDATA,
--         c_dfifo_wr_en                => C_DFIFO_WR_EN,
--         c_cfifo_wr_en                => C_CFIFO_WR_EN,
--         c_dfifo_afull                => C_DFIFO_AFULL,
--         c_cfifo_full                 => C_CFIFO_FULL,
--         s_dfifo_wdata                => S_DFIFO_WDATA,
--         s_cfifo_wdata                => S_CFIFO_WDATA,
--         s_dfifo_wr_en                => S_DFIFO_WR_EN,
--         s_cfifo_wr_en                => S_CFIFO_WR_EN,
--         s_dfifo_afull                => S_DFIFO_AFULL,
--         s_cfifo_full                 => S_CFIFO_FULL,
--         ac_dfifo_wdata               => AC_DFIFO_WDATA,
--         ac_cfifo_wdata               => AC_CFIFO_WDATA,
--         ac_dfifo_wr_en               => AC_DFIFO_WR_En,
--         ac_cfifo_wr_en               => AC_CFIFO_WR_En,
--         ac_dfifo_afull               => AC_DFIFO_AFULl,
--         ac_cfifo_full                => AC_CFIFO_FULL
--      );

end architecture simulation;

