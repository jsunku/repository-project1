
--------------------------------------------------------------------------------
--!
--! @file g1g_stc_mem_interfacer.vhd <BR>
--!
--! @brief Reads and writes into memory depending on the STC type <BR>
--!
--! @details <File detailed description> <BR>
--!
--! @attention <Classification: RESTREINT UE/EU RESTRICTED> <BR>
--!
--! @note <This design is used on M2GL150-1FCG1152I FPGA of PFCB EBB-0002.> <BR>
--!
--! @author Jithin Raj, Aerospace Data Security GmbH <BR> 
--!
--! @image html <image name> 
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

 entity g1g_stc_mem_interfacer is
    port(
        CLK                             : in std_logic;
        RST_N                           : in std_logic;
        SUID                            : in std_logic;
        -- Control signals              
        START                           : in std_logic;
       -- PPS                             : in std_logic;
        ACK                             : out std_logic;
        DONE                            : out slv2_t; --! (10)valid/(11)invalid/(01)internal STC
        COUNT                           : out natural range 0 to c_max_size;
       
        -- STC data
        STC_TYPE                        : in slv8_t;
        STC_ID                          : in std_logic_vector(15 downto 0);
    
        -- Memory interface
        DFIFO_RD_DATA                   : in slv18_t; 
        DFIFO_RD_EN                     : out std_logic;
        --cband_en..
        CBAND_EN                        : out std_logic;
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

architecture behavior of g1g_stc_mem_interfacer is
    signal r, rin : mi0_t;
    signal s_an_re_full, s_an_filter_full, s_an_re_rd_ack,s_an_fil_rd_ack : std_logic;
begin

    seq: process(CLK,RST_N)
    begin
        if RST_N = '0' then 
           
--r.spw_confg_wr_en       <= '0';
            r.cband_en_o           <= (others => '0');
          
            r.report_window_time_data          <= (others => '0');
            r.report_window_time_wr_en <= '0';
            r.report_filter_time_data          <= (others => '0');
            r.report_filter_time_wr_en <= '0';
            r.tow_bit               <= '0';   
            r.filter_counter_value  <= (others => '0');
           
            r.count                 <= 0;
            r.rd_en                 <= '0';
          
        elsif rising_edge(CLK) then 
            r   <= rin;
        end if;
    end process seq;

    MEM_IFER: process(all)
        variable v : mi0_t;
    begin
       
        v.rd_en                 := '0';

        if START = '1' and r.done = "00" then 
            v.ack   := '1';
            case(STC_TYPE) is 

              --  when x"06" => --STC_REPORTREQ attention not included currently
                              -- stm audit log use for next version

                when x"08" => -- TSTC_EventRepTimeWindow_TIMEREQ i have to check 3rd and 4th byte of payload
                    v.rd_en     := '1';
                    v.count     := r.count + 2;
                       -- if r.count = 2  and s_an_re_full  = '0' then
                            if r.count = 2  then
                            v.report_window_time_data := STC_ID & (DFIFO_RD_DATA(15 downto 0)); -- first 2 bytes of payload
                            v.report_window_time_wr_en := '1';                                                          --note: 
                            v.done                 := "10"; 
                        end if; 
                when x"09" => --STC_EventTypeFilter
                       
                        if r.count = 0  and s_an_filter_full = '0' then  -- first word fall through so data of 2 bytes available already
                            if DFIFO_RD_DATA(0) = '1' and unsigned(DFIFO_RD_DATA(1 to 7))  <= 15  and  DFIFO_RD_DATA(15 downto 8) = X"00" OR  X"01" then     
                                v.report_filter_time_data := STC_ID & (DFIFO_RD_DATA(15 downto 0)); --first two bytes
                                v.report_filter_time_wr_en := '1';
                                v.filter_counter_value := DFIFO_RD_DATA(1 to 7);  ---it can be checked in payload handler or here does not matter 
                                v.done                     := "10"; ---to differntiate  valid or invalid
                            else
                                v.done :=  (others => '1');
                            end if;

                        end if;
                when x"B5" => -- internal PSTC --- cband_en_o = PSTC Payload  just tske this value and sens out the cband en_value to c band sbs blobk
                        if r.count = 0 then
                            v.cband_en_o :=   unsigned (DFIFO_RD_DATA(7 downto 0)); -- first 1st byte of payload 
                                if r.cband_en_o = X"01" then
                                    v.cband_en := '1';
                                elsif r.cband_en_o = X"00" then
                                    v.cband_en := '0';
                                end if;
                        end if;
              end case; 
        else 
            v.count                 := 0;
            v.done                  := (others => '0');

        end if;

        -- update registers
        rin                         <= v;
        -- update output 
        COUNT                       <= r.count;
        ACK                         <= r.ack;
        DONE                        <= r.done;
        CBAND_EN                    <= r.cband_en;
        REPORT_WINDOW_PAYLOAD       <= r.report_window_time_data;
        REPORT_FILTER_PAYLOAD       <= r.report_filter_time_data;
        MASK_COUNTER                <=r.filter_counter_value;
    end process MEM_IFER;


--EPORT_WINDOW : entity work.sync_fifo                 
--   generic map (                                      
--       WIDTH			=>	32,      --STC ID+ STC                                          
--       DEPTH			=>  c_ctrl_fifo_depth,
--       AFULL_THRES		=>	2,                    
--       AEMPTY_THRES	=>	1,                         
--       DOUT_RST_TYPE	=>  SF_DOUT_RST_ASYNC         
--   )                                                  
--   port map (                                         
--       rst_n	=>	RST_N,                           
--       clk		=>	CLK,                             
--       wr_en	=>	r.report_window_time_wr_en,          
--       wdata	=>	r.report_window_time_data,                
--       rd_en	=>	REPORT_WINDOW_PAYLOAD_CFIFO_RD_EN,
--       rdata	=>	REPORT_WINDOW_PAYLOAD_CFIFO_RD_DATA,
--       wr_ack	=>	open,                
--       rd_ack	=>s_an_re_rd_ack,                   
--       full	=> s_an_re_full,   
--       afull	=>	open,             
--       empty	=>	REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY,       
--       aempty	=>	open,                            
--       count	=>	open                    
--   );
--
--   FILTER_FIFO : entity work.sync_fifo                 
--   generic map (                                      
--       WIDTH			=>	32,                                               
--       DEPTH			=>  c_ctrl_fifo_depth,
--       AFULL_THRES		=>	2,                    
--       AEMPTY_THRES	=>	1,                         
--       DOUT_RST_TYPE	=>  SF_DOUT_RST_ASYNC         
--   )                                                  
--   port map (                                         
--       rst_n	=>	RST_N,                           
--       clk		=>	CLK,                             
--       wr_en	=>	r.report_filter_time_wr_en,          
--       wdata	=>	r.report_filter_time_data,                
--       rd_en	=>	REPORT_FILTER_PAYLOAD_CFIFO_RD_EN,
--       rdata	=>	REPORT_FILTER_PAYLOAD_CFIFO_RD_DATA,
--       wr_ack	=>	open,                
--       rd_ack	=> s_an_fil_rd_ack,                   
--       full	=> s_an_filter_full,   
--       afull	=>	open,             
--       empty	=>	REPORT_FILTER_PAYLOAD_CFIFO_EMPTY,       
--       aempty	=>	open,                            
--       count	=>	open                    
--   );

end architecture;