-- ============================================================================
-- STM Anomaly Report Generator
--
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.global_package.all;
use work.stc_pkt_handler_package.all;


library work;
use work.bcc_stm_iface.all;
use work.crc16_package.all;

entity bcc_stm_generation is
   
port ( 
	clk_i			        : in	std_logic;
	rst_n_i			        : in	std_logic;
    suid                    : in    std_logic;
    init_done               : in	std_logic;	 --! Initialization done
    PPS                     : in    std_logic; 
    I_valid_invalid         : in    slv2_t;
    I_START_UPDATE_CUNTERS  : in    std_logic;
    tow_bit                 : in    std_logic;
    SUBSECOND_CNT_VALUE     : in    std_logic_vector(15 downto 0); 
    CHECK_SBAND_CBAND       : in std_logic;

    REPORT_WINDOW_PAYLOAD_and_id   : in std_logic_vector(31 downto 0); 
    REPORT_FILTER_PAYLOAD_and_id   : in std_logic_vector(31 downto 0);
    ACK_PYLOAD              : std_logic_vector(31 downto 0); 

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
 

);
end entity;
	
architecture behv of bcc_stm_generation is

   
	signal r, rin	: req_type_stm;

begin
	seq: process(rst_n_i, clk_i, init_done)
	begin
		if (rst_n_i = '0' or init_done = '0' ) then
			r.state			<= IDLE;
			r.frame_cnt_ack		<= 0;
            r.frame_cnt_an		<= 0;
           
            r.c_cfifo_wr_en_an <= '0';
            r.c_dfifo_wr_en_an <= '0';
            r.c_dfifo_wdata_an <= (others => '0');
            r.c_cfifo_wdata_an <= (others => '0');

            r.s_cfifo_wr_en_an <= '0';
            r.s_dfifo_wr_en_an <= '0';
            r.s_dfifo_wdata_an <= (others => '0');
            r.s_cfifo_wdata_an <= (others => '0');
            
            r.ack_cfifo_wr_en <= '0';
            r.ack_dfifo_wr_en <= '0';
            r.ack_dfifo_wdata <= (others => '0');
            r.ack_cfifo_wdata <= (others => '0');
            
            r.count         <= 0;
            r.tow_bit       <= '0';
            r.tow_bit_cunter <= 0;
            r.subsecond_counter <= 0;
            r.global_mask  <= x"0000";
           
            r.e_s_cnt_0       <= (others => '0');
            r.e_s_cnt_1       <= (others => '0');
            r.e_s_cnt_2       <= (others => '0');
            r.e_s_cnt_3       <= (others => '0');
            r.e_s_cnt_4       <= (others => '0');
            r.e_s_cnt_5       <= (others => '0');
            r.e_s_cnt_6       <= (others => '0');
            r.e_s_cnt_7       <= (others => '0');
            r.e_s_cnt_8       <= (others => '0');
            r.e_s_cnt_9       <= (others => '0');
            r.e_s_cnt_10      <= (others => '0');
            r.e_s_cnt_11      <= (others => '0');
            r.e_s_cnt_12      <= (others => '0');
            r.e_s_cnt_13      <= (others => '0');
            r.e_s_cnt_14      <= (others => '0');
            r.e_s_cnt_15      <= (others => '0');

            r.e_c_cnt_0       <= (others => '0');
            r.e_c_cnt_1       <= (others => '0');
            r.e_c_cnt_2       <= (others => '0');
            r.e_c_cnt_3       <= (others => '0');
            r.e_c_cnt_4       <= (others => '0');
            r.e_c_cnt_5       <= (others => '0');
            r.e_c_cnt_6       <= (others => '0');
            r.e_c_cnt_7       <= (others => '0');
            r.e_c_cnt_8       <= (others => '0');
            r.e_c_cnt_9       <= (others => '0');
            r.e_c_cnt_10      <= (others => '0');
            r.e_c_cnt_11      <= (others => '0');
            r.e_c_cnt_12      <= (others => '0');
            r.e_c_cnt_13      <= (others => '0');
            r.e_c_cnt_14      <= (others => '0');
            r.e_c_cnt_15      <= (others => '0');

            r.sub_second_value <= (others => '0');

            r.crc_res       <= (others => '1');
			
		elsif rising_edge(clk_i) then
			r			<= rin;
		end if;
	end process seq;
	
	comb: process (all)
	variable v : req_type_stm;
	begin
		v   := r;
		v.c_cfifo_wr_en_an:= '0';
		v.c_dfifo_wr_en_an:= '0';
        v.s_cfifo_wr_en_an:= '0';
		v.s_cfifo_wr_en_an:= '0';
        

       --if PPS = '1' then   ----this concept needs to moved another module
       --if lpps is not changed from 0 to 1 subsecond counter keeps increase start setting tow_bit to 0 once it reaches 
       --ffff then changed to 1 incase in the middle lpps is received means 0 to then reset sub second counter valur to 0 and increease lpps counter
       ---lpps counter value is betweemn 4 to 6 us seconds then set to 0 means pulse width, idf the the vlaue is 8 to 10us then set tow bit to 1.
       --when lpps is high then take tow bit value from lpps counter 
       --conclusion : for pstm ack and anomoly counters pstm we need subsecond counter value and the tow bit .we just take value of two bit whatever it is 
       --at that moment  
       --    --count while input is high 
       --    if r.tow_bit_cunter < 511 then
       --        v.tow_bit_cunter := r.tow_bit_cunter +1;
       --    end if;
       --    
       --    if r.tow_bit_cunter >= c_pps_sync_pulse_4us and  r.tow_bit_cunter<= c_pps_sync_pulse_6us then
       --        v.tow_bit := '0';
       --    elsif  r.tow_bit_cunter >= c_pps_sync_pulse_8us and  r.tow_bit_cunter<= c_pps_sync_pulse_10us then
       --        v.tow_bit := '1';
       --    end if;
       --else
       --    r.tow_bit_cunter <= 0;
       --end if;

       -- v.subsecond_counter := r.

        
		case r.state is
			when IDLE =>
				
				
                v.crc_res       := (others => '1');

                v.e_s_cnt_0 := s_event_type_0_i;
                v.e_s_cnt_1 := s_event_type_1_i;
                v.e_s_cnt_2 := s_event_type_2_i;
                v.e_s_cnt_3 := s_event_type_3_i;
                v.e_s_cnt_4 := s_event_type_4_i; 
                v.e_s_cnt_5 := s_event_type_5_i; 
                v.e_s_cnt_6 := s_event_type_6_i; 
                v.e_s_cnt_7 := s_event_type_7_i; 
                v.e_s_cnt_8 := s_event_type_8_i; 
                v.e_s_cnt_9 := s_event_type_9_i; 
                v.e_s_cnt_10 := X"00"; 
                v.e_s_cnt_11 := X"00"; 
                v.e_s_cnt_12 := s_event_type_12_i; 
                v.e_s_cnt_13 := X"00"; 
                v.e_s_cnt_14 := X"00";
                v.e_s_cnt_15 := X"00";
  
                v.e_c_cnt_0 := c_event_type_0_i;
                v.e_c_cnt_1 := c_event_type_1_i;
                v.e_c_cnt_2 := c_event_type_2_i;
                v.e_c_cnt_3 := X"00";
                v.e_c_cnt_4 := c_event_type_4_i;
                v.e_c_cnt_5 := X"00";
                v.e_c_cnt_6 := X"00";
                v.e_c_cnt_7 := X"00";
                v.e_c_cnt_8 := X"00";
                v.e_c_cnt_9 := X"00";
                v.e_c_cnt_10 := X"00"; 
                v.e_c_cnt_11 := X"00"; 
                v.e_c_cnt_12 := X"00"; 
                v.e_c_cnt_14 := X"00";
                v.e_c_cnt_15 := X"00";
  
                    if I_valid_invalid = "10"  then 
                        v.state := WR_ACK_FOR_VALID;
                    elsif I_valid_invalid = "11" then
                        v.state := WR_ACK_FOR_INVALID;
                   end if;

                   --copy subsecond value 

            When WR_ACK_FOR_INVALID => --write PSTM HDR to data fifo + payload+ crc
                   if r.frame_cnt_ack = 0 then
                        if AC_DFIFO_AFULL = '0' and AC_CFIFO_FULL = '0' then ---NOTE WHAT SHOULD WE DO HERE
                            v.ack_dfifo_wdata	:= "10" & x"81" & x"02" ; --is it 2b or 
                            v.ack_dfifo_wr_en   := '1';
                            v.crc_res       := update_crc_16bit(x"81" & x"02", r.crc_res); --02 stm_ack
                            v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                        else
                            v.state		:= IDLE;
                        end if;
                    elsif r.frame_cnt_ack = 2 then	
                        v.ack_dfifo_wdata	:= "00" & ACK_PYLOAD(15 downto 0); --stc id;
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(ACK_PYLOAD(15 downto 0), r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 4 then	
                        v.ack_dfifo_wdata	:= "00" & x"000" & "000" & tow_bit; --weekno:always set to zero 15bits and for LSB take towbit 
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(x"000" & "000" & tow_bit, r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 6 then	
                        v.ack_dfifo_wdata	:= "00"  & SUBSECOND_CNT_VALUE; --sub second value 
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(SUBSECOND_CNT_VALUE, r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 8 then	---add sub_second count value ---for in valid we send the payload(drop reason what we mentione below)
                        v.ack_dfifo_wdata	:= "00" & x"0001";
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(x"0001", r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 10 then	   --drop reason WE USED 0X05--0x05: other execution error
                        v.ack_dfifo_wdata	:= "00" & x"0005";  --WE USED 15 downto 8 is just to 00
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(x"0005", r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 12 then	 ----send crc
                        v.ack_dfifo_wdata	:= "00" & r.crc_res;
                        v.ack_dfifo_wr_en	:= '1';
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                        v.state := WR_CFIFO_ACK_invalid;
                    end if;

            when WR_ACK_FOR_VALID =>  --for valid we dont send paload saying what is the drop reason soin PSTM_LEN JUST SET X0000     

                    if r.frame_cnt_ack = 0 then
                        if AC_DFIFO_AFULL = '0' and AC_CFIFO_FULL = '0' then ---NOTE WHAT SHOULD WE DO HERE
                            v.ack_dfifo_wdata	:= "10" & x"81" & x"02" ; --is it 2b or 
                            v.ack_dfifo_wr_en   := '1';
                            v.crc_res       := update_crc_16bit(x"81" & x"02", r.crc_res); --02 stm_ack
                            v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                        else
                            v.state		:= IDLE;
                        end if;
                    elsif r.frame_cnt_ack = 2 then	
                        v.ack_dfifo_wdata	:= "00" & ACK_PYLOAD(15 downto 0); --stc id;
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(ACK_PYLOAD(15 downto 0), r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 4 then	
                        v.ack_dfifo_wdata	:= "00" & x"000" & "000" & tow_bit; --weekno:always set to zero 15bits and for LSB take towbit 
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(x"000" & "000" & tow_bit, r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 6 then	
                        v.ack_dfifo_wdata	:= "00"  & SUBSECOND_CNT_VALUE; --sub second value 
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(SUBSECOND_CNT_VALUE, r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 8 then	---add sub_second count value ---for in valid we send the payload(drop reason what we mentione below)
                        v.ack_dfifo_wdata	:= "00" & x"0001";
                        v.ack_dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(x"0000", r.crc_res);
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                    elsif r.frame_cnt_ack = 12 then	 ----send crc
                        v.ack_dfifo_wdata	:= "00" & r.crc_res;
                        v.ack_dfifo_wr_en	:= '1';
                        v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                        v.state := WR_CFIFO_ACK_valid;
                    end if;
             
            when WR_CFIFO_ACK_INVALID =>
				
				v.ack_cfifo_wdata	:= '1' & "000" & conv_std_logic_vector(r.frame_cnt_ack, 12);
				v.ack_cfifo_wr_en	:= '1';
				v.state			:= IDLE;
			
			when WR_CFIFO_ACK_VALID =>
				
				v.ack_cfifo_wdata	:= '1' & "000" & conv_std_logic_vector(r.frame_cnt_ack, 12);
				v.ack_cfifo_wr_en	:= '1';
				
                if CHECK_SBAND_CBAND = '0' then
                    v.state := WR_CBAND_COUNTERS;
                elsif CHECK_SBAND_CBAND ='1' then
                    v.state := WR_sBAND_COUNTERS;
                end if;
                 
            when WR_CBAND_COUNTERS =>

            if r.frame_cnt_ack = 0 then
                if C_DFIFO_AFULL = '0' and C_CFIFO_FULL = '0' then  ---NOTE WHAT SHOULD WE DO HERE
                    v.c_dfifo_wdata_an	:= "10" & '1'& '0' & CHECK_SBAND_CBAND & "00001" & x"2B" ; --x"2b" for for anomoly reports 
                    v.ack_dfifo_wr_en   := '1';
                    v.crc_res       := update_crc_16bit("10" & '1'& '0' & CHECK_SBAND_CBAND & "00001" & x"2B" , r.crc_res); --02 stm_ack
                    v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                else
                    v.state		:= IDLE;
                end if;
            elsif r.frame_cnt_ack = 2 then	
                v.ack_dfifo_wdata	:= "00" & REPORT_WINDOW_PAYLOAD_and_id(15 downto 0); --stc id;
                v.ack_dfifo_wr_en	:= '1';
                v.crc_res       := update_crc_16bit(REPORT_WINDOW_PAYLOAD_and_id(15 downto 0), r.crc_res);
                v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
            elsif r.frame_cnt_ack = 4 then	
                v.ack_dfifo_wdata	:= "00" & x"000" & "000" & tow_bit; --weekno:always set to zero 15bi
                v.ack_dfifo_wr_en	:= '1';
                v.crc_res       := update_crc_16bit(x"000" & "000" & tow_bit, r.crc_res);
                v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
            elsif r.frame_cnt_ack = 6 then	
                v.ack_dfifo_wdata	:= "00"  & SUBSECOND_CNT_VALUE; --sub second value 
                v.ack_dfifo_wr_en	:= '1';
                v.crc_res       := update_crc_16bit(SUBSECOND_CNT_VALUE, r.crc_res);
                v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
            elsif r.frame_cnt_ack = 8 then	---add sub_second count value ---for in valid we send the pa
                v.ack_dfifo_wdata	:= "00" & x"0001";
                v.ack_dfifo_wr_en	:= '1';
                v.crc_res       := update_crc_16bit(x"0000", r.crc_res);
                v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
            elsif r.frame_cnt_ack = 12 then	 ----send crc
                v.ack_dfifo_wdata	:= "00" & r.crc_res;
                v.ack_dfifo_wr_en	:= '1';
                v.frame_cnt_ack	:= r.frame_cnt_ack + 2;
                v.state := WR_CFIFO_ACK_valid;
            end if;

				
			when others =>
				v.state	:= IDLE;
				
				
		end case;		
		rin	<= v;
		-- output signals
        C_DFIFO_WDATA    <= r.c_cfifo_wdata_an;
        C_CFIFO_WDATA    <= r.c_dfifo_wdata_an;
        C_DFIFO_WR_EN    <= r.c_dfifo_wr_en_an;
        C_CFIFO_WR_EN    <= r.c_cfifo_wr_en_an;
        S_DFIFO_WDATA    <= r.s_cfifo_wdata_an;
        S_CFIFO_WDATA    <= r.s_dfifo_wdata_an;
        S_DFIFO_WR_EN    <= r.s_dfifo_wr_en_an;
        S_CFIFO_WR_EN    <= r.s_cfifo_wr_en_an;
        AC_DFIFO_WDATA    <= r.ack_cfifo_wdata;
        AC_CFIFO_WDATA    <= r.ack_dfifo_wdata;
        AC_DFIFO_WR_EN    <= r.ack_dfifo_wr_en;
        AC_CFIFO_WR_EN    <= r.ack_cfifo_wr_en;
	
	end process;

end;
	

--5.1.3.2	PSTM_PKT
--Table 5 2: PSTM Packet Fields
--Group	Field Name	Offset (Bit)	Length (Bit)	Description
--PSTM Header	PSTC/PSTM	0 (MSB)	1	Always set to 1 (PSTM)
--	INT_EXT	1	1	Always set to 0 (external STM)
--	C_BAND	2	1	0x0: PFCU S-Band or PLCU, 0x1: PFCU C-Band
--	TARGET	3	5	Always set to 0x01 (IF FPGA)
--STM Header	PSTM_TYPE	8	8	Types of PSTM are defined in the STC/STM ICD
--	PSTM_ID	16	16	PSTM Source ID, set to received PSTC_ID when triggered by PSTC;
--set to 0x0000 for asynchronously generated PSTM
--	WEEK_NO	32	12	Week number in GST, always set to 0x0000. Field will be filled in by IF FPGA for external STM.
--	TOW	44	4	Time of Week in seconds, set the LSB; upper Bits will be expanded to 20 Bits and filled in by IF FPGA for external STM.
--	SUBSECOND	48	16	Time of Second in units of 2-16 seconds
--	PSTM_LEN	64	16	Length of the following Payload field in Bytes
--PSTM Payload	DATA	80	= 8*PSTM_LEN (max 951 878 bytes)	Payload format is defined in the STC/STM ICD.
--Packet Error Control	CRC16	80 + 8*PSTM_ LEN	16	CRC according to [RD03] of the whole PSTM packet excluding the CRC16 field
--
