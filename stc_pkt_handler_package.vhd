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
 --Your File here

  --Your File here
  library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use ieee.numeric_std.all;


  use work.global_package.all;

  package stc_pkt_handler_package is 
    constant c_max_size             : integer := 31; --! Max 13 bytes on RCC FPGA
    constant c_paramter_ncorrect    : slv8_t  := x"01"; --! as per ICD

    constant c_pps_sync_pulse_4us   : unsigned(31 downto 0) := to_unsigned(128, 32); --4us = 4000ns  : 4000/31.25 = 128 clck cycles
    constant c_pps_sync_pulse_6us   : unsigned(31 downto 0) := to_unsigned(192, 32);
    constant c_pps_sync_pulse_8us   : unsigned(31 downto 0) := to_unsigned(256, 32);
    constant c_pps_sync_pulse_10us   : unsigned(31 downto 0) := to_unsigned(320, 32);

    --! \brief FSM used in g1g_pstc_packet_handling.vhd
    type fsm_packet_handling is (IDLE,CTRL_FIFO_CHECK,FIRST_WORD_AND_PSTC_TYPE_CHECK,ERROR,
        LENGTH_CHECK,STC_GEN_START,STC_GEN_RES, DONE, PSTC_ID
        );
    --! \brief record in g1g_pstc_packet_handling.vhd
    type g1g_packet_handling_t is record
        state                   : fsm_packet_handling;
        ctrl_rd_en              : std_logic;
        rd_en                   : std_logic;
        valid                   : slv2_t;
        drop_reason             : slv8_t;
        bytes_2b_read           : natural range 0 to c_max_size;
        read_count              : natural range 0 to c_max_size;
        expected_len            : slv8_t;
        h_error                 : std_logic;
        stc_type                : slv8_t;
        stc_c_band              : std_logic;
        stc_id                  : std_logic_vector(15 downto 0);  
        start                   : std_logic;
        stc_format_error        : std_logic;
    end record;

    --! \brief record in g1g_stc_mem_interfacer.vhd
    type mi0_t is record  
        count                   : natural range 0 to c_max_size;
        rd_en                   : std_logic;
        ack                     : std_logic;
        done                    : slv2_t;
        cband_en_o              : unsigned(7 downto 0);
        cband_en                : std_logic;
        s_suid                  : std_logic;
        report_window_time_data : slv32_t;
        report_window_time_wr_en: std_logic;
        report_filter_time_data : slv32_t;
        report_filter_time_wr_en  : std_logic;
        tow_bit                 : std_logic;
        to_bit_counter          : unsigned (31 downto 0);    
        valid_ack               : std_logic;   
        filter_counter_value    : std_logic_vector(6 downto 0);
        sp_address_set_cdmu     : slv2_t;
        sp_address_set_plcu     : slv2_t;
        bandwidth_alloc_set     : slv64_t;
        prio_buffer_rate        : slv4_t;      
    end record;
    --! \Address and Length array definition
    --! defined as per ICD
    --! \{
    type address_len_pair is record
        addr : std_logic_vector(octet -1 downto 0);
        len  : std_logic_vector(3 downto 0); -- note: change the size if needed 
    end record;

    type address_len_array is array (natural range <>) of address_len_pair;
    constant c_address_len : address_len_array := (
        (addr => x"B5",len => x"01"), --pus tc -set status c_band_flow
        (addr => x"B7",len => x"01"), ---pustc---onlg in g2g i guess
        (addr => x"BA",len => x"01"), --set ISLdata
        (addr => x"BB",len => x"01"),  -- stc_setspwportvar
        (addr => x"06",len => x"01"), -- stc_reportreq
        (addr => x"08",len => x"01") --
    );
        --! \}

    --! Function declaration that searches for an address match and returns corresponding length
    function check_add_get_len (addr : std_logic_vector( octet - 1 downto 0))
    return std_logic_vector;
  end package stc_pkt_handler_package;

  package body stc_pkt_handler_package is 
    --! \brief Checks if the argument is in the 2D matrix predefined and returns the length else 
    --! returns (others => '1')
    function check_add_get_len(addr : std_logic_vector(octet -1 downto 0)) return std_logic_vector is
    begin
        for i in c_address_len'range loop
            if addr = c_address_len(i).addr then 
                return c_address_len(i).len;
            end if;
        end loop;
        return(others => '1');
    end function;

----funtion to check payload value and return the the time to send update the value of  
    function convertto_clk_cycles(
        payload : slv16_t
    ) return unsigned is 
        --precalculated constants as per system clock
        constant MS_100_count : integer := 3_200_000; --for 100ms = 0.1sec = 1000000000ns so 1000000000/31.25
        constant CYCLE_PER_MS :integer := 32_000_000;-- becase payload numeric +1 is eauel to 0.1sec more 
        variable result : unsigned(15 downto 0);     
    begin
      if payload = x"0000" then
        result  := to_unsigned(MS_100_count,32);
      else
        result := to_unsigned(MS_100_count + (to_integer(unsigned(payload))*CYCLE_PER_MS ),32);
      end if;
      return result;
    end function;
 ---x"0000" := 100ms  -0.1 sec
 ---x"0001" := 200ms  -0.2sec
    
end package body stc_pkt_handler_package;