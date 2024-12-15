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


entity g1g_stc_stm_top is
   port (
      sys_rst_n                     : in    std_logic; --!  Asynch. reset, low-active
      clk_32                        : in    std_logic; --!  System clock
      mode_info                     : in    std_logic; --!  (1-G1G, 0-G2G)
      suid                          : in    std_logic;
      error_h_dfifo                 : out   std_logic; --! Detected hard error (inconsistency in Data-/Control FIFO).
      error_s_drop                  : out   std_logic; --! Detected soft error (Control FIFO: Command: drop (0)).
      error_s_db_detect             : out   std_logic; --! Detected soft error (EDAC: 2-bit error detected).
      error_s_leng                  : out   std_logic; --! Detected soft error (Plausibility check failed: number of read data blocks not equal to the expected data length).

      error_h_dfifo_afull_detect_tx : out   std_logic; --! Detected hard error ([Audit Event] Data FIFO dfifo_afull is set)
      error_s_dfifo_afull_detect_tx : out   std_logic; --! Detected soft error ([PSTC Ack] / [Int-Clk PSTx] Data FIFO dfifo_afull is set)
      -- PPS interface
      pps_sync                      : in    std_logic;

      -- Internal Clock interface
      cband_en_o                    : out   std_logic;
      -- Anomaly event data interface
      cb_anom_event_data_i          : in    slv40_t;
      sb_anom_event_data_i          : in    slv120_t


   -- Audit event data interface
   -- INIT_AUDIT_EVENT_DATA_I          : in std_logic; --!  TBD  Audit Event data
   -- STC_STM_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
   -- MUX_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
   -- CBAND_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
   -- SBAND_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
   -- TM_AUDIT_EVENT_DATA_I          : in std_logic; --!  TBD  Audit Event data
   -- IOSCR_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
   );
end entity g1g_stc_stm_top;

architecture rtl of g1g_stc_stm_top is

   signal s_cfifo_rd_en   : std_logic;
   signal s_cfifo_rd_ack  : std_logic;
   signal s_cfifo_rd_data : std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);
   signal s_cfifo_empty   : std_logic;
   signal s_dfifo_rd_en   : std_logic;
   signal s_dfifo_rd_err  : std_logic;
   signal s_dfifo_dvld    : std_logic;
   signal s_dfifo_ecc_err : std_logic;
   signal s_dfifo_rd_data : std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);

begin



end architecture rtl;
