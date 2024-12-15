--note : takes data from g1g_pstc_packet_handling
--ports: sband_counters, cband_counters, valid/invalid, payload from  g1g_pstc_packet_handling paylod for 0x08,0x09 skip fifo's, use ports  library ieee;

library ieee;
use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use work.global_package.all;
 use work.sync_fifo_iface.all;
 use work.stc_pkt_handler_package.all;

 entity payload_handler is
    port(
        CLK                             : in std_logic;
        RST_N                           : in std_logic;
        SUID                            : in std_logic;
        -- Control signals              
        START                           : in std_logic;

        sband_data                      : OUT slvt_80t;
        cband_data                      :  out slvt_80t;
        VALID                           : OUT  slv2_t;  ---FROM STC_PACKET HANDLER
       -- PPS                             : in std_logic;
        ACK                             : out std_logic;
        DONE                            : out slv2_t; --! (10)valid/(11)invalid/(01)internal STC
        COUNT                           : out natural range 0 to c_max_size;
       ---to stm _handler 
       PAYLOAD_1                      : out slvt16_t;
       PAYLOAD_2                      : out slvt16_t;
      
        -- Memory interface
        DFIFO_RD_DATA                   : in slv18_t; 
        DFIFO_RD_EN                     : out std_logic;
    
        MASK_COUNTER                    : out std_logic_vector(7 downto 0);
        --STC_EventRepTimeWindow  -- NOTE: remove the fifo'sif not required 


        REPORT_WINDOW_PAYLOAD : out std_logic_vector(31 downto 0);---0X08
        REPORT_FILTER_PAYLOAD : out std_logic_vector(31 downto 0);--0X09


        REPORT_WINDOW_PAYLOAD_CFIFO_RD_DATA   : out std_logic_vector(31 downto 0);
        REPORT_WINDOW_PAYLOAD_CFIFO_RD_EN     : in std_logic; 
        REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY     : out std_logic;
        
        REPORT_FILTER_PAYLOAD_CFIFO_RD_DATA   : out std_logic_vector(31 downto 0);
        REPORT_FILTER_PAYLOAD_CFIFO_RD_EN     : in std_logic; 
        REPORT_FILTER_PAYLOAD_CFIFO_EMPTY     : out std_logic

    );
    end entity;

     architecture behavior of payload_handler is

      begin

       end architecture;
