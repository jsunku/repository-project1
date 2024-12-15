-- ============================================================================
-- STM Anomaly Report Generator
--
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.global_package.all;


library work;
use work.bcc_stm_iface.all;
use work.crc16_package.all;

entity bcc_stm_generation is
   
port ( 
	clk_i			: in	std_logic;
	rst_n_i			: in	std_logic;
    init_done       : in	std_logic;	 --! Initialization done
    PPS             : in    std_logic; 
    REPORT_WINDOW_PAYLOAD_CFIFO_RD_DATA   : in std_logic_vector(31 downto 0);
    REPORT_WINDOW_PAYLOAD_CFIFO_RD_EN     : out std_logic; 
    REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY     : in std_logic;       
    
    REPORT_FILTER_PAYLOAD_CFIFO_RD_DATA   : in std_logic_vector(31 downto 0);
    REPORT_FILTER_PAYLOAD_CFIFO_RD_EN     : out std_logic; 
    REPORT_FILTER_PAYLOAD_CFIFO_EMPTY     : in std_logic;
    
    DFIFO_WDATA       : out   std_logic_vector(C_DFIFO_DATA_LEN-1 downto 0);
    CFIFO_DATA_I_anamoly   : out   std_logic_vector(C_CFIFO_DATA_LEN -1 downto 0);
    DFIFO_WR_EN_anamoly    : out   std_logic;
    CFIFO_WR_EN_anamoly    : out   std_logic;
    DFIFO_AFULL_anamoly    : in    std_logic;
    CFIFO_FULL_anamoly     : in    std_logic;
    DFIFO_WDATA_stm_exc    : out   std_logic_vector(C_DFIFO_DATA_LEN-1 downto 0);
    CFIFO_DATA_IN_stm_exc  : out   std_logic_vector(C_CFIFO_DATA_LEN -1 downto 0);
    DFIFO_WR_EN_stm_exc    : out   std_logic;
    CFIFO_WR_EN_stm_exc    : out   std_logic;
    DFIFO_AFULL_stm_exc    : in    std_logic;
    CFIFO_FULL_stm_exc     : in    std_logic;
	-- input for BCC
	EVENT_TYPE_0_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_1_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_2_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_3_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_4_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_5_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_6_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_7_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_8_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_9_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_10_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_11_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_12_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_13_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_14_I	: in std_logic_vector(7 downto 0);
	EVENT_TYPE_15_I	: in std_logic_vector(7 downto 0);

    --tick              
    tick            : in std_logic
	


);
end entity;
	
architecture behv of bcc_stm_generation is

   
	signal r, rin	: req_type_stm;

begin
	seq: process(rst_n_i, clk_i, init_done)
	begin
		if (rst_n_i = '0' or init_done = '0' ) then
			r.state			<= IDLE;
			r.frame_cnt		<= 0;
            r.cfifo_wr_en_an <= '0';
            r.dfifo_wr_en_an <= '0';
            r.dfifo_wdata_an <= (others => '0');
            r.cfifo_wdata_an <= (others => '0');
            r.cfifo_wr_en_ack <= '0';
            r.dfifo_wr_en_ack <= '0';
            r.dfifo_wdata_ack <= (others => '0');
            r.cfifo_wdata_ack	<= (others => '0');
            r.count         <= 0;
            r.tow_bit       <= '0';
            r.tow_bit_cunter <= 0;
            r.global_mask  <= x"0000";
            r.e_cnt_0       <= (others => '0');
            r.e_cnt_1       <= (others => '0');
            r.e_cnt_2       <= (others => '0');
            r.e_cnt_3       <= (others => '0');
            r.e_cnt_4       <= (others => '0');
            r.e_cnt_5       <= (others => '0');
            r.e_cnt_6       <= (others => '0');
            r.e_cnt_7       <= (others => '0');
            r.e_cnt_8       <= (others => '0');
            r.e_cnt_9       <= (others => '0');
            r.e_cnt_10      <= (others => '0');
            r.e_cnt_11      <= (others => '0');
            r.e_cnt_12      <= (others => '0');
            r.e_cnt_13      <= (others => '0');
            r.e_cnt_14      <= (others => '0');
            r.e_cnt_15      <= (others => '0');

            r.crc_res       <= (others => '1');
			
		elsif rising_edge(clk_i) then
			r			<= rin;
		end if;
	end process seq;
	
	comb: process (all)
	variable v : req_type_stm;
	begin
		v   := r;
		v.dfifo_wr_en_ack	:= '0';
		v.cfifo_wr_en_ack	:= '0';
        v.dfifo_wr_en_an	:= '0';
		v.cfifo_wr_en_an	:= '0';
        v.rd_en_an   := '0';
        v.rd_en_filter := '0';

        if PPS = '1' then 
            --count while input is high 
            if r.tow_bit_cunter < 511 then
                v.tow_bit_cunter := r.tow_bit_cunter +1;
            end if;
            
            if r.tow_bit_cunter >= c_pps_sync_pulse_4us and  r.tow_bit_cunter<= c_pps_sync_pulse_6us then
                v.tow_bit := '0';
            elsif  r.tow_bit_cunter >= c_pps_sync_pulse_8us and  r.tow_bit_cunter<= c_pps_sync_pulse_10us then
                v.tow_bit := '1';
            end if;
        else
            r.tow_bit_cunter <= 0;
        end if;

        
		case r.state is
			when IDLE =>
				
				v.frame_cnt	:= 0;
				v.dfifo_wdata_ack	:= (others => '0');
				v.cfifo_wdata_ack	:= (others => '0');
                v.dfifo_wdata_ack	:= (others => '0');
				v.cfifo_wdata_ack	:= (others => '0');
                v.crc_res       := (others => '1');

                v.e_cnt_0 := event_type_0_i;
                v.e_cnt_1 := event_type_1_i;
                v.e_cnt_2 := event_type_2_i;
                v.e_cnt_3 := event_type_3_i;
                v.e_cnt_4 := event_type_4_i; 
                v.e_cnt_5 := event_type_5_i; 
                v.e_cnt_6 := event_type_6_i; 
                v.e_cnt_7 := event_type_7_i; 
                v.e_cnt_8 := event_type_8_i; 
                v.e_cnt_9 := event_type_9_i; 
                v.e_cnt_10 := event_type_10_i; 
                v.e_cnt_11 := event_type_11_i; 
                v.e_cnt_12 := event_type_12_i; 
                v.e_cnt_13 := event_type_13_i; 
                v.e_cnt_14 := event_type_14_i; 
                v.e_cnt_15 := event_type_15_i; 
     
                    if REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY = '0' and DFIFO_AFULL_anamoly = '0' and CFIFO_FULL_anamoly  = '0'then
                    v.rd_en_filter := '1';
                    v.state := CHECK_FILTER_BIT_FROM_FIFO;
                    else
                    v.state := IDLE;
                    end if; 

                    if REPORT_WINDOW_PAYLOAD_CFIFO_EMPTY = '0' and DFIFO_AFULL_anamoly = '0' and CFIFO_FULL_anamoly = '0' then
                        v.rd_en_filter := '1';
                        v.state := CHECK_FILTER_BIT_FROM_FIFO;
                        else
                        v.state := IDLE;
                        end if; 
                     


                        
                        

				
			when WR_HDR =>	-- write PSTM HDR to data fifo
                if r.frame_cnt = 0 then
                    if stm_wr_i.dfifo_afull = '0' and stm_wr_i.cfifo_full = '0' then	-- check whether data fifo is full
                        v.dfifo_wdata	:= "10" & x"81" & x"2B" ;
                        v.dfifo_wr_en	:= '1';
                        v.crc_res       := update_crc_16bit(x"81" & x"2B", r.crc_res);
                        v.frame_cnt	:= r.frame_cnt + 2;
                    else
						v.state		:= IDLE;
                    end if;
                elsif r.frame_cnt = 2 then	
                    v.dfifo_wdata	:= "00" & x"0000";
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(x"0000", r.crc_res);
                    v.frame_cnt	:= r.frame_cnt + 2;
                elsif r.frame_cnt = 4 then
                    v.dfifo_wdata	:= "00" & x"0000";
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(x"0000", r.crc_res);
                    v.frame_cnt	:= r.frame_cnt + 2;
                elsif r.frame_cnt = 6 then
                    v.dfifo_wdata	:= "00" & x"0000";
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(x"0000", r.crc_res);
                    v.frame_cnt	:= r.frame_cnt + 2;
                elsif r.frame_cnt = 8 then
                    v.dfifo_wdata	:= "00" & x"0010";	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(x"0010", r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
                  
                elsif r.frame_cnt = 10 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_0 & r.e_cnt_1;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_0 & r.e_cnt_1, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;

                elsif r.frame_cnt = 12 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_2 & r.e_cnt_3;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_2 & r.e_cnt_3, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
                
                elsif r.frame_cnt = 14 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_4 & r.e_cnt_5;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_4 & r.e_cnt_5, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
                
                elsif r.frame_cnt = 16 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_6 & r.e_cnt_7;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_6 & r.e_cnt_7, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
                
                elsif r.frame_cnt = 18 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_8 & r.e_cnt_9;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_8 & r.e_cnt_9, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;

                elsif r.frame_cnt = 20 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_10 & r.e_cnt_11;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_10 & r.e_cnt_11, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;

                elsif r.frame_cnt = 22 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_12 & r.e_cnt_13;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_12 & r.e_cnt_13, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
                    
                elsif r.frame_cnt = 24 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_14 & r.e_cnt_15;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_14 & r.e_cnt_15, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
              --note : added from my side
                elsif r.frame_cnt = 26 then
                    v.dfifo_wdata	:= "00" & "0000"& "000" & r.e_cnt_16 & r.e_cnt_17;	--
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit("0000"& "000" & r.e_cnt_16 & r.e_cnt_17, r.crc_res); -- note:cross check again
                    v.frame_cnt		:= r.frame_cnt + 2;
                elsif r.frame_cnt = 28 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_18 & r.e_cnt_19;	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_18 & r.e_cnt_19, r.crc_res);
                    v.frame_cnt		:= r.frame_cnt + 2;
                elsif r.frame_cnt = 30 then
                    v.dfifo_wdata	:= "00" & r.e_cnt_20 & X"00";	
                    v.dfifo_wr_en	:= '1';
                    v.crc_res       := update_crc_16bit(r.e_cnt_20 & X"00", r.crc_res); ---note :cross check again
                    v.frame_cnt		:= r.frame_cnt + 2;
                    v.state         := WR_CFIFO;       
                end if;
			
			when WR_CFIFO =>
				
				v.cfifo_wdata	:= '1' & "000" & conv_std_logic_vector(r.frame_cnt, 12);
				v.cfifo_wr_en	:= '1';
				v.state			:= IDLE;
				
				
			when others =>
				v.state	:= IDLE;
				
				
		end case;		
		rin	<= v;
		-- output signals
        stm_wr_o.dfifo_wdata    <= r.dfifo_wdata;
        stm_wr_o.dfifo_wr_en    <= r.dfifo_wr_en;
        stm_wr_o.cfifo_wdata    <= r.cfifo_wdata;
        stm_wr_o.cfifo_wr_en    <= r.cfifo_wr_en;
	
	end process;

end;
	