--------------------------------------------------------------------------------
--!
--! @file stc_pkt_handler_package.vhd <BR>
--!
--! @brief Package for STC packets <BR>
--!
--! @details <File detailed description> <BR>
--!
--! @attention <Classification: RESTREINT UE/EU RESTRICTED> <BR>
--!
--! @note <This design is used on M2GL150-1FCG1152I FPGA of PFCB EBB-0002.> <BR>
--!
--! @author <jagan mohan sunku>, Aerospace Data Security GmbH <BR>
--!
--! @image html <image name> "<Author Name>"
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
-- Your File here

-- Your File here

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use work.global_package.all;

package stc_payload_handler_package is

   --! \brief FSM used in g1g_pstc_packet_handling.vhd
   type fsm_packet_handling is (
      IDLE, CTRL_FIFO_CHECK, FIRST_WORD_AND_PSTC_TYPE_CHECK, ERROR,
      LENGTH_CHECK, STC_GEN_START, STC_GEN_RES, DONE, PSTC_ID
   );
   --! \brief record in g1g_pstc_packet_handling.vhd
   type g1g_payload_handling_t is record
      state       : fsm_packet_handling;
      sband_data  : counter_vector(15 downto 0); -- 16 counters of 8 bits (counter_vector defined in stc_pkt_handler_package)
      cband_data  : counter_vector(15 downto 0); -- 16 counters of 8 bits
      valid_out   : slv2_t;
      sband_cband : std_logic;                   -- 0: S-band, 1: C-band
   end record g1g_payload_handling_t;

end package stc_pkt_handler_package;

