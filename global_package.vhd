
--------------------------------------------------------------------------------
--! \file global_package.vhd
--! \brief Package for every module
--! \details  Contains critical definitions which could introduce a bug 
--! \attention Check the definitions before sythesis, Could cause bugs
--! \author    Jagan Mohan sunku, Aerospace Data Security GmbH  <BR>
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package global_package is 


    subtype slv32_t is std_logic_vector(31 downto 0);
    -- subtype slv16_t is std_logic_vector(15 downto 0);
    subtype slv120_t is std_logic_vector(79 downto 0);
    subtype slv40_t is std_logic_vector(39 downto 0);
    subtype slv80_t is std_logic_vector(79 downto 0);
    subtype slv50_t is std_logic_vector(49 downto 0);
    subtype slv8_t is std_logic_vector(7 downto 0);
    subtype slv4_t is std_logic_vector(3 downto 0);
    subtype slv16_t is std_logic_vector(15 downto 0);
    subtype slv2_t is std_logic_vector(1 downto 0);
    subtype slv3_t is std_logic_vector(2 downto 0);
    subtype slv5_t is std_logic_vector(4 downto 0);
    subtype slv20_t is std_logic_vector(19 downto 0);
    subtype slv12_t is std_logic_vector(11 downto 0);
    subtype slv64_t is std_logic_vector(63 downto 0);
    subtype slv10_t is std_logic_vector(9 downto 0);
    subtype slv18_t is std_logic_vector(17 downto 0);
    subtype slv96_t is std_logic_vector(95 downto 0);
    constant CRC_STATUS     : string := "NOT TESTED";
    --! \todo remove from sband_tc_package, so no redundant constants, add global package
    --! to all modules
    constant C_SCID_LEN         : integer := 10;
    constant C_CLCW_PART_LEN    : integer := 30;
    constant C_DFIFO_DATA_LEN   : integer := 18;
    constant C_CFIFO_DATA_LEN   : integer := 16;
    constant C_CLCW_LEN         : integer := 32;
    constant C_SOF_FRAME           : std_logic_vector(2 downto 0) := "110";
    constant C_EOF_FRAME           : std_logic_vector(2 downto 0) := "101";
    constant C_ERR_FRAME           : std_logic_vector(2 downto 0) := "100";
    constaNt C_DATA_FRAME          : std_logic_vector(2 downto 0) := "000";
    constant c_CADU_DATA_BYTES      : integer := 1275;
    constant C_BYTELENGTH          : integer := 8;    --! 1 Octet
    --! \todo remove from mux_package, so no redundant constants, add global package
    --! to all modules
    constant octet 		            : integer	:= 8;
    constant first_word             : std_logic_vector(1 downto 0):=  "10";
    constant c_aof                  : std_logic_vector(1 downto 0) := "00"; 
    constant C_VERSION_NO           : std_logic_vector(1 downto 0) := "00"; -- is version number for idle frame generation
    constant C_Virtual_CH_ID        : std_logic_vector(2 downto 0) := "111";
    constant C_OP_CTR_FEILD_FLAG    : std_logic := '1';
    constant c_padding_bytes        : std_logic_vector(octet-1 downto 0) := (others => '0');
    constant C_FRAME_HDR            : std_logic_vector((2*octet)-1 downto 0) := (others => '0');
    constant C_FIRST_WORD_to_BRAM   : std_logic_vector(C_DFIFO_DATA_LEN-1 downto 0) := first_word & C_FRAME_HDR;
    constant C_TM_SCND_FLAG         : std_logic := '0';
    constant C_TM_SYNC_FLAG         : std_logic := '0';
    constant C_TM_PKT_ODR_FLG       : std_logic := '0';
    constant C_TM_SEG_LEN           : std_logic_vector(1 downto 0) := "11";

    constant c_hdr_ptr_bit_len      : integer := 11;
    constant C_mstr_channel_max,c_VC7_buffer_max    :  integer := 256; --!(1 byte as per activity diagram)



    -- Memory interface constants 
    constant c_ctrl_fifo_depth              : integer := 3;
    constant c_one_bram_aw                  : integer := 10; --! infers 1 BRAM
    constant c_two_bram_aw                  : integer := 11; --! infers 2 BRAM
    constant c_af_threshold_cband           : integer := 257; --! 512 position one complete frame is written , so from 231th position Almost full flag goes high
    constant c_af_threshold_sband           : integer := 513; --! (1024(address space required for 2 frames) / 2 ) + 1
    constant c_af_threshold_islrx           : integer := 513; --! (1024(address space required for 2 frames) / 2 ) + 1
    constant c_af_threshold_isltx           : integer := 513; --! (1024(address space required for 2 frames) / 2 ) + 1
    constant c_af_threshold_tm              : integer := 560; --! (1117(address space required for 2 frames) / 2 ) + 1)
    
    
    constant C_DSLINK_LEN                   : integer := 10;
    constant C_DSLINK_TIMEOUT               : integer := 4;
    constant C_SOF		                    : std_logic_vector(3 downto 0):= X"C";						--! Start of Frame 
    constant C_EOF		                    : std_logic_vector(3 downto 0):= X"A";						--! End of Frame
    constant C_ERR		                    : std_logic_vector(3 downto 0):= X"9";						--! Error in frame 

end package;