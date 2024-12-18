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
        SYS_RST_N	                    : in std_logic; --!	Asynch. reset, low-active
        CLK_32	                        : in std_logic; --!	System clock
        MODE_INFO	                    : in std_logic; --!	(1-G1G, 0-G2G)
        INIT_DONE                       : in std_logic;
        SUID                            : in std_logic;
      -- Interface with reading Data Fifo 
        DFIFO_RD_EN                     : out std_logic;
        DFIFO_RD_DATA                   : in std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);
        DFIFO_RD_ERR                    : in std_logic;
        DFIFO_DVLD                      : in std_logic;
        DFIFO_ECC_ERR                   : in std_logic;
        DFIFO_AEMPTY                    : in std_logic; --! Reserved, not used
        -- Interface with reading control FIFO
        CFIFO_RD_EN                     : out std_logic;
        CFIFO_RD_ACK                    : in std_logic;
        CFIFO_FULL                      : in std_logic;
        CFIFO_EMPTY                     : in std_logic;
        CFIFO_RD_DATA                   : in std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);

        -- Error signals 
        ERROR_S_DROP_PSTC	            : out std_logic; --! Detected soft error (received PSTC packet dropped due to wrong PSTC_PKT format (length/CRC error/parameter out of range)
        ERROR_H_DFIFO	                : out std_logic; --! Detected hard error (inconsistency in Data-/Control FIFO).
        --PPS interface 
        PPS_SYNC                        : in std_logic; 
        --configuration interface             
        CBAND_EN_O                      : out std_logic;
        -- Anmoly_counter Sband
                                --goes to payload handler
        S_EVENT_TYPE_0_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_1_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_2_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_3_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_4_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_5_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_6_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_7_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_8_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_9_I	: in std_logic_vector(7 downto 0);
	    S_EVENT_TYPE_12_I	: in std_logic_vector(7 downto 0);
	   
                                --goes to payload handler
        --Anomaly counters_cband  
        C_EVENT_TYPE_0_I	: in std_logic_vector(7 downto 0);
	    C_EVENT_TYPE_1_I	: in std_logic_vector(7 downto 0);
	    C_EVENT_TYPE_2_I	: in std_logic_vector(7 downto 0);
        C_EVENT_TYPE_4_I	: in std_logic_vector(7 downto 0); ---check this again
        
        ---STM- CBAND_SBAND_STM_ACK_ex
      ---cband
        C_DFIFO_WDATA       : out   std_logic_vector(C_DFIFO_DATA_LEN-1 downto 0);
        C_CFIFO_WDATA       : out   std_logic_vector(C_CFIFO_DATA_LEN-1 downto 0);
        C_DFIFO_WR_EN       : out   std_logic;
        C_CFIFO_WR_EN       : out   std_logic;
        C_DFIFO_AFULL       : in    std_logic;
        C_CFIFO_FULL        : in    std_logic;
         ---sband
        S_DFIFO_WDATA       : out   std_logic_vector(C_DFIFO_DATA_LEN-1 downto 0);
        S_CFIFO_WDATA       : out   std_logic_vector(C_CFIFO_DATA_LEN-1 downto 0);
        S_DFIFO_WR_EN       : out   std_logic;
        S_CFIFO_WR_EN       : out   std_logic;
        S_DFIFO_AFULL       : in    std_logic;
        S_CFIFO_FULL        : in    std_logic;
        --stm_ack
        AC_DFIFO_WDATA       : out   std_logic_vector(C_DFIFO_DATA_LEN-1 downto 0);
        AC_CFIFO_WDATA       : out   std_logic_vector(C_CFIFO_DATA_LEN-1 downto 0);
        AC_DFIFO_WR_EN       : out   std_logic;
        AC_CFIFO_WR_EN       : out   std_logic;
        AC_DFIFO_AFULL       : in    std_logic;
        AC_CFIFO_FULL        : in    std_logic
        -- Audit event data interface
        -- INIT_AUDIT_EVENT_DATA_I	        : in std_logic; --!	TBD	Audit Event data
        -- STC_STM_AUDIT_EVENT_DATA_I	    : in std_logic; --!	TBD	Audit Event data
        -- MUX_AUDIT_EVENT_DATA_I	    : in std_logic; --!	TBD	Audit Event data
        -- CBAND_AUDIT_EVENT_DATA_I	    : in std_logic; --!	TBD	Audit Event data
        -- SBAND_AUDIT_EVENT_DATA_I	    : in std_logic; --!	TBD	Audit Event data
        -- TM_AUDIT_EVENT_DATA_I	        : in std_logic; --!	TBD	Audit Event data
        -- IOSCR_AUDIT_EVENT_DATA_I	    : in std_logic; --!	TBD	Audit Event data

        
    );
end entity;

architecture rtl of g1g_stc_stm_top is
signal s_cfifo_rd_en    : std_logic;
signal s_cfifo_rd_ack   : std_logic;
signal s_cfifo_rd_data  : std_logic_vector(C_CFIFO_DATA_LEN -1 downto 0);
signal s_cfifo_empty    : std_logic;
signal s_dfifo_rd_en    : std_logic;
signal s_dfifo_rd_err   : std_logic;
signal s_dfifo_dvld     : std_logic;
signal s_dfifo_ecc_err  : std_logic;
signal s_dfifo_rd_data  : std_logic_vector(C_DFIFO_DATA_LEN -1 downto 0);
signal s_sband_cband    : std_logic; 
signal s_drop_reason    : slv8_t; 
signal s_valid    : slv2_t; 
signal s_ack    : std_logic;
signal s_stc_id  : slv16_t;
signal s_window_payload : slv32_t;
signal s_filter_payload : slv32_t;
signal s_o_window_payload : slv32_t;
signal s_o_filter_payload : slv32_t;
signal s_valid_out  : slv2_t;
signal s_or_cband  : std_logic;
signal s_logged_counter : std_logic_vector(4 downto 0);
 signal s_o_start_counters  : std_logic;
 signal s_stm_ack_differntiator  : slv2_t;
 signal s_payload_ack : slv32_t;
 signal  s_tow_bit: std_logic;
 signal s_subsecond_cnt_value: slv16_t;


begin  
STC_PACKETHANDLER: entity work.g1g_pstc_packet_handling

    port map(
        RST_N                         => SYS_RST_N, 
        CLK_32                        => CLK_32,    
        MODE_INFO                     => MODE_INFO, 
        INIT_DONE                     => INIT_DONE ,
        SUID                          => SUID, 
        ACK                           =>  s_ack,
        ERROR_S_DROP_PSTC             => ERROR_S_DROP_PSTC,
        ERROR_H_DFIFO	              => ERROR_H_DFIFO,
        DFIFO_RD_EN                   => DFIFO_RD_EN  ,                 
        DFIFO_RD_DATA                 => DFIFO_RD_DATA,                
        DFIFO_RD_ERR                  => DFIFO_RD_ERR ,                
        DFIFO_DVLD                    => DFIFO_DVLD   ,                
        DFIFO_ECC_ERR                 => DFIFO_ECC_ERR,                 
        DFIFO_AEMPTY                  => DFIFO_AEMPTY,
        CFIFO_RD_EN                   =>  CFIFO_RD_EN,
        CFIFO_RD_ACK                  =>  CFIFO_RD_ACK,
        CFIFO_FULL                    => CFIFO_FULL,
        CFIFO_EMPTY                   => CFIFO_EMPTY,
        CFIFO_RD_DATA                 => CFIFO_RD_DATA,
        VALID                         => s_valid,
        PSTC_ID_O                     => s_stc_id,             
        DROP_REASON                   => s_drop_reason,
        CBAND_EN                      => CBAND_EN_O,
        CBAND_SBAND_DIFF              => s_sband_cband ,
        REPORT_WINDOW_PAYLOAD        => s_window_payload,
        REPORT_FILTER_PAYLOAD        => s_filter_payload,
        FILTER_OR_WINDOW           => s_stm_ack_differntiator


    );

PAYLOAD_HANDLER: entity work.payload_handler
port map(
    RST_N                         => SYS_RST_N, 
    CLK                           => CLK_32,
    SUID                          => SUID,    
    MODE_INFO                     => MODE_INFO, 
    INIT_DONE                     => INIT_DONE,
    SBAND_CBAND                   => s_sband_cband,
    VALID_IN                      => s_valid,
    DIFFERENCE_STM_ACK            => s_stm_ack_differntiator,
    WINDOW_STC_ID                 => s_window_payload(15 downto 0),
    WINDOW_TIME                   => s_window_payload(31 downto 16),
    FILTER_STC_ID                 => s_filter_payload(15 downto 0),
    FILTER_MASK_COUNTER           => s_filter_payload(16 downto 8),
    FILTER_MASK_ONOFF             => s_filter_payload(7 downto 0),
    valid_out                     => s_valid_out,
    s_or_cband                   => s_or_cband,
    logged_counter                => s_logged_counter,
    REPORT_WINDOW_PAYLOAD_id      => s_o_window_payload,    
    REPORT_FILTER_PAYLOAD_id      => s_o_filter_payload,
    START_UPDATE_CUNTERS_O        => s_o_start_counters,
    STM_ACK_PAYLOAD               => s_payload_ack

);

STM_GENERATOR  : entity work.bcc_stm_generation
port map(
CLK_I	                     => SYS_RST_N, 		
RST_N_I	                     => SYS_RST_N, 
SUID                         => SUID,   
INIT_DONE                    => INIT_DONE, 
tow_bit                      => s_tow_bit,
SUBSECOND_CNT_VALUE          => s_subsecond_cnt_value,
PPS                          =>  PPS_SYNC,
CHECK_SBAND_CBAND           => s_or_cband,
ACK_PYLOAD           => s_payload_ack,
S_EVENT_TYPE_0_I  => S_EVENT_TYPE_0_I,
S_EVENT_TYPE_1_I  => S_EVENT_TYPE_1_I,
S_EVENT_TYPE_2_I  => S_EVENT_TYPE_2_I,
S_EVENT_TYPE_3_I  => S_EVENT_TYPE_3_I,
S_EVENT_TYPE_4_I  => S_EVENT_TYPE_4_I,
S_EVENT_TYPE_5_I  => S_EVENT_TYPE_5_I,
S_EVENT_TYPE_6_I  => S_EVENT_TYPE_6_I,
S_EVENT_TYPE_7_I  => S_EVENT_TYPE_7_I,
S_EVENT_TYPE_8_I  => S_EVENT_TYPE_8_I,
S_EVENT_TYPE_9_I  => S_EVENT_TYPE_9_I,
S_EVENT_TYPE_12_I => S_EVENT_TYPE_12_I,

C_EVENT_TYPE_0_I  => C_EVENT_TYPE_0_I,
C_EVENT_TYPE_1_I  => C_EVENT_TYPE_1_I,
C_EVENT_TYPE_2_I  => C_EVENT_TYPE_2_I,
C_EVENT_TYPE_4_I  => C_EVENT_TYPE_4_I,
REPORT_WINDOW_PAYLOAD_and_id => s_o_window_payload,
REPORT_FILTER_PAYLOAD_and_id => s_o_filter_payload,
I_valid_invalid              => s_valid_out,
I_START_UPDATE_CUNTERS       => s_o_start_counters,

C_DFIFO_WDATA               => C_DFIFO_WDATA,
C_CFIFO_WDATA               => C_CFIFO_WDATA,
C_DFIFO_WR_EN               => C_DFIFO_WR_EN,
C_CFIFO_WR_EN               => C_CFIFO_WR_EN,
C_DFIFO_AFULL               => C_DFIFO_AFULL,
C_CFIFO_FULL                => C_CFIFO_FULL,
 ---sband
S_DFIFO_WDATA               => S_DFIFO_WDATA,
S_CFIFO_WDATA               => S_CFIFO_WDATA,
S_DFIFO_WR_EN               => S_DFIFO_WR_EN,
S_CFIFO_WR_EN               => S_CFIFO_WR_EN,
S_DFIFO_AFULL               => S_DFIFO_AFULL,
S_CFIFO_FULL                => S_CFIFO_FULL,
--stm_ack
AC_DFIFO_WDATA              => AC_DFIFO_WDATA,
AC_CFIFO_WDATA              => AC_CFIFO_WDATA,
AC_DFIFO_WR_EN              => AC_DFIFO_WR_En,
AC_CFIFO_WR_EN              => AC_CFIFO_WR_En,
AC_DFIFO_AFULL              => AC_DFIFO_AFULl,
AC_CFIFO_FULL               => AC_CFIFO_FULL
  


);
end architecture;






































----------------------------------------------------------------------------------
----!
----! @file g1g_stc_stm_top.vhd <BR>
----!
----! @brief STC STM handling top file <BR>
----!
----! @details  <BR>
----!
----! @attention <Classification: RESTREINT UE/EU RESTRICTED> <BR>
----!
----! @note <This design is used on M2GL150-1FCG1152I FPGA of PFCB EBB-0002.> <BR>
----!
----! @author Jagan mohan , Aerospace Data Security GmbH <BR>
----!
----!
----------------------------------------------------------------------------------
----
---- File location    $URL: blah $
---- Last change in   $Revision: blah $
---- Last change on   $Date: blah $
---- Last change by   $Author: blah $
----
---- see SVN logs for details
----
----------------------------------------------------------------------------------
----
--
--library ieee;
--   use ieee.std_logic_1164.all;
--   use ieee.numeric_std.all;
--   use work.global_package.all;
--
--
--entity g1g_stc_stm_top is
--   port (
--      sys_rst_n                     : in    std_logic; --!  Asynch. reset, low-active
--      clk_32                        : in    std_logic; --!  System clock
--      mode_info                     : in    std_logic; --!  (1-G1G, 0-G2G)
--      suid                          : in    std_logic;
--      error_h_dfifo                 : out   std_logic; --! Detected hard error (inconsistency in Data-/Control FIFO).
--      error_s_drop                  : out   std_logic; --! Detected soft error (Control FIFO: Command: drop (0)).
--      error_s_db_detect             : out   std_logic; --! Detected soft error (EDAC: 2-bit error detected).
--      error_s_leng                  : out   std_logic; --! Detected soft error (Plausibility check failed: number of read data blocks not equal to the expected data length).
--
--      error_h_dfifo_afull_detect_tx : out   std_logic; --! Detected hard error ([Audit Event] Data FIFO dfifo_afull is set)
--      error_s_dfifo_afull_detect_tx : out   std_logic; --! Detected soft error ([PSTC Ack] / [Int-Clk PSTx] Data FIFO dfifo_afull is set)
--      -- PPS interface
--      pps_sync                      : in    std_logic;
--
--      -- Internal Clock interface
--      cband_en_o                    : out   std_logic;
--      -- Anomaly event data interface
--      cb_anom_event_data_i          : in    slv40_t;
--      sb_anom_event_data_i          : in    slv120_t
--
--
--   -- Audit event data interface
--   -- INIT_AUDIT_EVENT_DATA_I          : in std_logic; --!  TBD  Audit Event data
--   -- STC_STM_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
--   -- MUX_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
--   -- CBAND_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
--   -- SBAND_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
--   -- TM_AUDIT_EVENT_DATA_I          : in std_logic; --!  TBD  Audit Event data
--   -- IOSCR_AUDIT_EVENT_DATA_I      : in std_logic; --!  TBD  Audit Event data
--   );
--end entity g1g_stc_stm_top;
--
--architecture rtl of g1g_stc_stm_top is
--
--   signal s_cfifo_rd_en   : std_logic;
--   signal s_cfifo_rd_ack  : std_logic;
--   signal s_cfifo_rd_data : std_logic_vector(C_CFIFO_DATA_LEN - 1 downto 0);
--   signal s_cfifo_empty   : std_logic;
--   signal s_dfifo_rd_en   : std_logic;
--   signal s_dfifo_rd_err  : std_logic;
--   signal s_dfifo_dvld    : std_logic;
--   signal s_dfifo_ecc_err : std_logic;
--   signal s_dfifo_rd_data : std_logic_vector(C_DFIFO_DATA_LEN - 1 downto 0);
--
--begin
--
--
--
--end architecture rtl;
--
