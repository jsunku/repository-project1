--------------------------------------------------------------------------------
--!
--! @file g1g_pstc_packet_handling.vhd <BR>
--!
--! @brief Performs PSTC Payload extraction <BR>
--!
--! @details Verify the PSTC_TYPE , Length and prepare the PSTM packet bytes <BR>
--!          CRC to be removed <BR> 
--!          Interfaces with FWFT Data BRAM and SYNC FIFO <BR> 
--! 
--! @attention <Classification: RESTREINT UE/EU RESTRICTED> <BR>
--!
--! @note <This design is used on M2GL150-1FCG1152I FPGA of PFCB EBB-0002.> <BR>
--!
--! @author Jagan mohan sunku, Aerospace Data Security GmbH <BR> 
--!
--! @image html <image name> "jagan mohan"
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

 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use work.global_package.all;
 use work.sync_fifo_iface.all;
 use work.stc_pkt_handler_package.all;

 entity g1g_pstc_packet_handling is 
    port (
        CLK                             : in std_logic;
        RST_N                           : in std_logic;
        MODE_INFO                       : in std_logic;
        SUID                            : in std_logic;
        -- Error signals 
        ERROR_S_DROP_PSTC	            : out std_logic; --! Detected soft error (received PSTC packet dropped due to wrong PSTC_PKT format (length/CRC error/parameter out of range)
        ERROR_H_DFIFO	                : out std_logic; --! Detected hard error (inconsistency in Data-/Control FIFO).
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
        -- Communication I/F with STM handler
        DROP_REASON                     : out slv8_t; --! Reason for dropping to be communicated with STM handler
        VALID                           : out slv2_t; --! Inform the STM handler to Drop(11)/accept(10)/(01) STM not required
        ACK                             : in std_logic;
        PSTC_ID_O                       : out std_logic_vector(15 downto 0);
        CBAND_SBAND_DIFF                : out std_logic;
        REPORT_WINDOW_PAYLOAD : out std_logic_vector(31 downto 0);---0X08
        REPORT_FILTER_PAYLOAD : out std_logic_vector(31 downto 0);--0X09
        -- SPW Signal
        BL_PORT_GET_CFG_I	            : in slv5_t; --!	SpW node get configuration signals:
                                                    --! Bit 0: AutoStart: 0b0 = disabled, 0b1 = enabled Bit 1: LinkStart: 0b0 = no action, 0b1 = start link
                                                    --! Bit 2: LinkDisable: 0b0 = link enabled, 0b1 = link  disabled
                                                    --! Bit 3: PortReset: 0b0 = no action, 0b1 = reset port
                                                    --! Bit 4: LinkSpeed: 0b0 = slow (10 Mbit/s), 0b1 = fast (port dependent)
                                                    --! Note: received from SpW Node
         -- Configuration settings
         REPORT_WINDOW_PAYLOAD_CFIFO_RD_DATA   : out std_logic_vector(31 downto 0);
         REPORT_WINDOW_PAYLOAD_CFIFO_RD_EN     : in std_logic; 
         REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY     : out std_logic;
                 
         REPORT_FILTER_PAYLOAD_CFIFO_RD_DATA   : out std_logic_vector(31 downto 0);
         REPORT_FILTER_PAYLOAD_CFIFO_RD_EN     : in std_logic; 
         REPORT_FILTER_PAYLOAD_CFIFO_EMPTY     : out std_logic

    );
    end entity g1g_pstc_packet_handling;

architecture behavior of g1g_pstc_packet_handling is
    signal r, rin : g1g_packet_handling_t;
    subtype slv16_t is std_logic_vector(15 downto 0);
    signal s_ack, s_rd_en    : std_logic;
    signal s_done   : slv2_t;
    signal s_count  : natural range 0 to c_max_size;
begin
    seq: process(CLK, RST_N)
    begin
        if RST_N = '0' and MODE_INFO = '0' then 
            r.state                 <= IDLE;
            r.ctrl_rd_en            <= '0';
            r.rd_en                 <= '0';
            r.valid                 <= (others => '0');
            r.drop_reason           <= x"00";
            r.bytes_2b_read         <= 0;
            r.read_count            <= 0;
            r.expected_len          <= (others => '0');
            r.stc_type              <= (others => '0');
            r.stc_c_band            <= '0'; 
            r.stc_id                <= (others => '0');
            r.stc_format_error      <= '0';
            r.start                 <= '0';
        elsif rising_edge(CLK) then 
            r    <= rin;
           
        end if;
    end process seq;
    
    packet_handling: process(all)
        variable v : g1g_packet_handling_t;
        variable t : slv16_t;
    begin
        v                       := r;
        v.rd_en                 := '0';
        v.ctrl_rd_en            := '0';
        

        case r.state is 
        
            when IDLE => 
                v.bytes_2b_read         := 0;
                v.read_count            := 0;
                v.expected_len          := (others => '0');
                v.stc_format_error      := '0';
                v.stc_c_band            := '0';
                v.stc_type              := (others => '0');
                v.stc_format_error      := '0';
                v.valid                 := (others => '0');
                v.drop_reason           := (others => '0');
                v.start                 := '0';
                -- when cfifo on iif_stc has something AND there is space in memory to write then 
                -- read out the entry
                if CFIFO_EMPTY = '0' then --todo to include the full flag on the other side
                    v.ctrl_rd_en := '1';
                    v.state := CTRL_FIFO_CHECK;
                else 
                    v.state := IDLE;
                end if;
            
            when CTRL_FIFO_CHECK => 
                -- read the control fifo entry and the data in there implies the complete length
                -- of the frame including the CRC
                if CFIFO_RD_ACK = '1' then 
                    v.bytes_2b_read := to_integer(unsigned(CFIFO_RD_DATA(11 downto 0)));
                    if CFIFO_RD_DATA(CFIFO_RD_DATA'high) = '1' then
                        if DFIFO_DVLD = '1' then 
                            v.rd_en := '1';
                            v.state := FIRST_WORD_AND_PSTC_TYPE_CHECK;
                            v.read_count    := r.read_count + 2;
                        end if;
                    else
                        v.state := DONE;
                        v.valid  := (others => '1');
                        v.drop_reason := c_paramter_ncorrect; -- CRC error
                    end if;
                else -- todo ? 
                    v.state := CTRL_FIFO_CHECK;
                end if;

            when FIRST_WORD_AND_PSTC_TYPE_CHECK => 
                -- check if the start marker is correct and check if the STC ID is 
                -- defined already then transition to either checking the STC ID or dropping the frame
                -- dropping the frame => read out the STC from fifo and write an INvalid stc response as STM 
                -- which is generated using the control signals valid and drop reason
                if DFIFO_RD_DATA(DFIFO_RD_DATA'high downto DFIFO_RD_DATA'high -1) = first_word then 
                    v.stc_type     := check_add_get_len(DFIFO_RD_DATA(15 downto 8));
                    v.expected_len := v.stc_type;
                    v.stc_c_band   := DFIFO_RD_DATA(5); --extract the Cband information
                    
                    if v.expected_len /= (r.expected_len'range => '1') then -- ensures that the stc is defined for FPGA
                        v.rd_en := '1';
                        v.read_count := r.read_count + 2;
                        v.state := PSTC_ID;
                    else 
                        v.stc_format_error := '1';
                        v.valid := (others => '1');
                        v.state := DONE;
                        v.drop_reason := c_paramter_ncorrect;
                    end if;
                else
                    v.state := ERROR;
                end if;
            
            when PSTC_ID => 
                
                v.rd_en := '1';
                v.stc_id := DFIFO_RD_DATA(15 downto 0);
                v.read_count := r.read_count + 2;
                v.state := LENGTH_CHECK;

            when LENGTH_CHECK => 
                
                v.rd_en := '1';
                v.read_count := r.read_count + 2;
                if r.read_count = 12 then -- at this point the length field should be available
                    if x"00" & r.expected_len = DFIFO_RD_DATA(15 downto 0) then 
                        v.state := STC_GEN_START;
                    else 
                        v.stc_format_error := '1';
                        v.valid := (others => '1');
                        v.state := DONE;
                        v.drop_reason := c_paramter_ncorrect;
                    end if;
                end if;

            when STC_GEN_START => 

               v.start := '1';
               if s_ack = '1' then 
                v.state := STC_GEN_RES;
               end if;

               when STC_GEN_RES => 
                
               v.start := '0';
               if s_done = "11" then 
                   v.stc_format_error := '1';
                   v.valid := (others => '1');
                   v.state := DONE;
                   v.drop_reason := c_paramter_ncorrect;
               elsif s_done = "10" or s_done = "01" then
                   v.valid := s_done;
                   v.state := DONE;
               else 
                    v.state := STC_GEN_RES;
               end if;

            when DONE => 

                if r.read_count + s_count >= r.bytes_2b_read then 
                    v.state := IDLE;
                else 
                    v.rd_en := '1';
                    v.read_count := r.read_count + 2;
                end if;

            when ERROR => 
                
                v.h_error := '1';


        end case;
        -- update registers 
        rin         <=  v;
        -- update Outputs 
        CFIFO_RD_EN                 <= r.ctrl_rd_en;
        DFIFO_RD_EN                 <= r.rd_en when s_ack ='0' else 
                                       s_rd_en;
        VALID                       <= r.valid;
        DROP_REASON                 <= r.drop_reason;
        ERROR_S_DROP_PSTC           <= r.stc_format_error;
        ERROR_H_DFIFO               <= r.h_error;
        PSTC_ID_O                   <= r.stc_id;
        CBAND_SBAND_DIFF            <= r.stc_c_band;  --BIT INFORMS TO UPDATA SBAND OR CBAND COUNTERS
    end process packet_handling;

   memif0 : entity work.g1g_stc_mem_interfacer 
       port map (
           CLK                         => CLK,
           RST_N                       => RST_N,
           SUID                       => SUID,
           START                       => r.start,
           ACK                         => s_ack,
           DONE                        => s_done,
           COUNT                       => s_count,
           STC_TYPE                    => r.stc_type,
           STC_ID                      => r.stc_id,
           DFIFO_RD_DATA               => DFIFO_RD_DATA,
           DFIFO_RD_EN                 => s_rd_en,
           REPORT_WINDOW_PAYLOAD_CFIFO_RD_DATA  =>REPORT_WINDOW_PAYLOAD_CFIFO_RD_DATA,
           REPORT_WINDOW_PAYLOAD_CFIFO_RD_EN    =>REPORT_WINDOW_PAYLOAD_CFIFO_RD_EN,
           REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY    =>REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY,
           
           REPORT_FILTER_PAYLOAD_CFIFO_RD_DATA  =>REPORT_FILTER_PAYLOAD_CFIFO_RD_DATA,
           REPORT_FILTER_PAYLOAD_CFIFO_RD_EN    =>REPORT_FILTER_PAYLOAD_CFIFO_RD_EN,
           REPORT_FILTER_PAYLOAD_CFIFO_EMPTY    =>REPORT_FILTER_PAYLOAD_CFIFO_EMPTY

        REPORT_WINDOW_PAYLOAD : out std_logic_vector(31 downto 0);---0X08
        REPORT_FILTER_PAYLOAD : out std_logic_vector(31 downto 0);--0X09
         	
       );


end architecture;
