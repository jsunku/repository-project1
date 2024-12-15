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
        SUID                            : in std_logic;
        ERROR_H_DFIFO	                : out std_logic; --! Detected hard error (inconsistency in Data-/Control FIFO).
        ERROR_S_DROP	                : out std_logic; --! Detected soft error (Control FIFO: Command: drop (0)).
        ERROR_S_DB_DETECT	            : out std_logic; --! Detected soft error (EDAC: 2-bit error detected).
        ERROR_S_LENG	                : out std_logic; --! Detected soft error (Plausibility check failed: number of read data blocks not equal to the expected data length). 
       
        ERROR_H_DFIFO_AFULL_DETECT_TX	: out std_logic; --! Detected hard error ([Audit Event] Data FIFO dfifo_afull is set)
        ERROR_S_DFIFO_AFULL_DETECT_TX	: out std_logic; --! Detected soft error ([PSTC Ack] / [Int-Clk PSTx] Data FIFO dfifo_afull is set)
        --PPS interface 
        PPS_SYNC                        : in std_logic;              

        -- Internal Clock interface
        CBAND_EN_O                      : out std_logic;
        --Anomaly event data interface
        CB_ANOM_EVENT_DATA_I	        : in slv40_t;
        SB_ANOM_EVENT_DATA_I            : in  slv120_t


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
   
begin

   

end architecture;