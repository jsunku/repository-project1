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

entity tb_g1g_stc_stm_top is
end entity tb_g1g_stc_stm_top;

architecture simulation of tb_g1g_stc_stm_top is

   signal sys_rst_n : std_logic := '0';
   signal clk_32    : std_logic := '1';

   signal mode_info     : std_logic;                       --!  (1-G1G, 0-G2G)
   signal init_done     : std_logic;
   signal suid          : std_logic;
   -- Interface with reading Data Fifo
   signal dfifo_rd_en   : std_logic;
   signal dfifo_rd_data : std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);
   signal dfifo_rd_err  : std_logic;
   signal dfifo_dvld    : std_logic;
   signal dfifo_ecc_err : std_logic;
   signal dfifo_aempty  : std_logic;                       --! Reserved, not used
   -- Interface with reading control FIFO
   signal cfifo_rd_en   : std_logic;
   signal cfifo_rd_ack  : std_logic;
   signal cfifo_full    : std_logic;
   signal cfifo_empty   : std_logic;
   signal cfifo_rd_data : std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);

   -- Error signals
   signal error_s_drop_pstc : std_logic;                   --! Detected soft error (received PSTC packet dropped due to wrong PSTC_PKT format (length/CRC error/parameter out of range)
   signal error_h_dfifo     : std_logic;                   --! Detected hard error (inconsistency in Data-/Control FIFO).
   -- PPS interface
   signal pps_sync          : std_logic;
   -- configuration interface
   signal cband_en_o        : std_logic;
   -- Anmoly_counter Sband
   -- goes to payload handler
   signal s_event_type_0_i  : std_logic_vector(7 downto 0);
   signal s_event_type_1_i  : std_logic_vector(7 downto 0);
   signal s_event_type_2_i  : std_logic_vector(7 downto 0);
   signal s_event_type_3_i  : std_logic_vector(7 downto 0);
   signal s_event_type_4_i  : std_logic_vector(7 downto 0);
   signal s_event_type_5_i  : std_logic_vector(7 downto 0);
   signal s_event_type_6_i  : std_logic_vector(7 downto 0);
   signal s_event_type_7_i  : std_logic_vector(7 downto 0);
   signal s_event_type_8_i  : std_logic_vector(7 downto 0);
   signal s_event_type_9_i  : std_logic_vector(7 downto 0);
   signal s_event_type_12_i : std_logic_vector(7 downto 0);

   -- goes to payload handler
   -- Anomaly counters_cband
   signal c_event_type_0_i : std_logic_vector(7 downto 0);
   signal c_event_type_1_i : std_logic_vector(7 downto 0);
   signal c_event_type_2_i : std_logic_vector(7 downto 0);
   signal c_event_type_4_i : std_logic_vector(7 downto 0); ---check this again

   ---STM- CBAND_SBAND_STM_ACK_ex
   ---cband
   signal c_dfifo_wdata  : std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);
   signal c_cfifo_wdata  : std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);
   signal c_dfifo_wr_en  : std_logic;
   signal c_cfifo_wr_en  : std_logic;
   signal c_dfifo_afull  : std_logic;
   signal c_cfifo_full   : std_logic;
   ---sband
   signal s_dfifo_wdata  : std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);
   signal s_cfifo_wdata  : std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);
   signal s_dfifo_wr_en  : std_logic;
   signal s_cfifo_wr_en  : std_logic;
   signal s_dfifo_afull  : std_logic;
   signal s_cfifo_full   : std_logic;
   -- stm_ack
   signal ac_dfifo_wdata : std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);
   signal ac_cfifo_wdata : std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);
   signal ac_dfifo_wr_en : std_logic;
   signal ac_cfifo_wr_en : std_logic;
   signal ac_dfifo_afull : std_logic;
   signal ac_cfifo_full  : std_logic;

begin

   clk_32    <= not clk_32 after 16 ns; -- period = 32 ns, frequency approx 32 MHz.
   sys_rst_n <= '0', '1' after 100 ns;

   -- Generate stimulus (STC format)
   --

   stim_proc : process
      --

      procedure add_frame (
         frame : std_logic_vector
      ) is
      begin
         --
         while CFIFO_RD_EN /= '1' loop
            wait until rising_edge(clk_32);
         end loop;

         CFIFO_RD_ACK  <= '0';
         CFIFO_FULL    <= '0';
         CFIFO_EMPTY   <= '0';
         CFIFO_RD_DATA <= to_stdlogicvector(frame'length, C_CFIFO_DATA_LEN);
         wait until rising_edge(clk_32);

         for i in 0 to frame'length / 16 loop
            --
            while DFIFO_RD_EN /= '1' loop
               wait until rising_edge(clk_32);
            end loop;

            DFIFO_RD_DATA <= "10" & frame(16 * i + 15 downto 16 * i);
            DFIFO_RD_ERR  <= '0';
            DFIFO_DVLD    <= '1';
            DFIFO_ECC_ERR <= '0';
            DFIFO_AEMPTY  <= '1';
            wait until rising_edge(clk_32);
         end loop;

      --
      end procedure add_frame;

   --
   begin
      -- First test
      add_frame(X"4008_0000_0000_0000_0000"); -- STC frame
   end process stim_proc;

   dut_inst : entity work.g1g_stc_stm_top
      port map (
         sys_rst_n         => sys_rst_n,
         clk_32            => clk_32,
         mode_info         => mode_info,
         init_done         => init_done,
         suid              => suid,
         dfifo_rd_en       => dfifo_rd_en,
         dfifo_rd_data     => dfifo_rd_data,
         dfifo_rd_err      => dfifo_rd_err,
         dfifo_dvld        => dfifo_dvld,
         dfifo_ecc_err     => dfifo_ecc_err,
         dfifo_aempty      => dfifo_aempty,
         cfifo_rd_en       => cfifo_rd_en,
         cfifo_rd_ack      => cfifo_rd_ack,
         cfifo_full        => cfifo_full,
         cfifo_empty       => cfifo_empty,
         cfifo_rd_data     => cfifo_rd_data,
         error_s_drop_pstc => error_s_drop_pstc,
         error_h_dfifo     => error_h_dfifo,
         pps_sync          => pps_sync,
         cband_en_o        => cband_en_o,
         s_event_type_0_i  => s_event_type_0_i,
         s_event_type_1_i  => s_event_type_1_i,
         s_event_type_2_i  => s_event_type_2_i,
         s_event_type_3_i  => s_event_type_3_i,
         s_event_type_4_i  => s_event_type_4_i,
         s_event_type_5_i  => s_event_type_5_i,
         s_event_type_6_i  => s_event_type_6_i,
         s_event_type_7_i  => s_event_type_7_i,
         s_event_type_8_i  => s_event_type_8_i,
         s_event_type_9_i  => s_event_type_9_i,
         s_event_type_12_i => s_event_type_12_i,
         c_event_type_0_i  => c_event_type_0_i,
         c_event_type_1_i  => c_event_type_1_i,
         c_event_type_2_i  => c_event_type_2_i,
         c_event_type_4_i  => c_event_type_4_i,
         c_dfifo_wdata     => c_dfifo_wdata,
         c_cfifo_wdata     => c_cfifo_wdata,
         c_dfifo_wr_en     => c_dfifo_wr_en,
         c_cfifo_wr_en     => c_cfifo_wr_en,
         c_dfifo_afull     => c_dfifo_afull,
         c_cfifo_full      => c_cfifo_full,
         s_dfifo_wdata     => s_dfifo_wdata,
         s_cfifo_wdata     => s_cfifo_wdata,
         s_dfifo_wr_en     => s_dfifo_wr_en,
         s_cfifo_wr_en     => s_cfifo_wr_en,
         s_dfifo_afull     => s_dfifo_afull,
         s_cfifo_full      => s_cfifo_full,
         ac_dfifo_wdata    => ac_dfifo_wdata,
         ac_cfifo_wdata    => ac_cfifo_wdata,
         ac_dfifo_wr_en    => ac_dfifo_wr_en,
         ac_cfifo_wr_en    => ac_cfifo_wr_en,
         ac_dfifo_afull    => ac_dfifo_afull,
         ac_cfifo_full     => ac_cfifo_full
      );

end architecture simulation;

