-- ============================================================================
-- Package for STM Anomaly Report Generator
-- ============================================================================

library ieee;							-- IEEE library
use ieee.std_logic_1164.all;			-- basic std_logic data types and a few functions
use ieee.numeric_std.all;

-- ============================================================================

package bcc_stm_iface is

  constant SOF	: std_logic_vector(8 downto 0)	:= "110000000";
	constant EOF	: std_logic_vector(8 downto 0)	:= "101000000";
	constant ERR	: std_logic_vector(8 downto 0)	:= "100100000";
	constant c_pps_sync_pulse_4us   : natural := 128; --4us = 4000ns  : 4000/31.25 = 128 clck cycles
	constant c_pps_sync_pulse_6us   : natural := 192;
	constant c_pps_sync_pulse_8us   : natural := 256;
	constant c_pps_sync_pulse_10us  : natural := 320;

	type wr_fifo is record
		dfifo_wr_en	: std_logic;
		dfifo_wdata	: std_logic_vector(17 downto 0);
		cfifo_wr_en	: std_logic;
		cfifo_wdata	: std_logic_vector(15 downto 0);
	end record;
    
    type wr_full_fifo is record
        dfifo_afull	: std_logic;
        cfifo_full	: std_logic;
	end record;

	type states_stm_gen is (IDLE, WR_CFIFO_ACK_valid,WR_CFIFO_ACK_invalid,WR_CBAND_COUNTERS,WR_SBAND_COUNTERS, WR_CFIFO_SBAND,WR_CFIFO_CBAND,WR_ACK_FOR_VALID,WR_ACK_FOR_INVALID, WR_HDR, WR_CFIFO);

	type req_type_stm is record
			state		: states_stm_gen;
			
			c_cfifo_wr_en_an	: std_logic;
			c_dfifo_wr_en_an	: std_logic;
			c_dfifo_wdata_an	: std_logic_vector(17 downto 0);
			c_cfifo_wdata_an	: std_logic_vector(15 downto 0);

			s_cfifo_wr_en_an	: std_logic;
			s_dfifo_wr_en_an	: std_logic;
			s_dfifo_wdata_an	: std_logic_vector(17 downto 0);
			s_cfifo_wdata_an	: std_logic_vector(15 downto 0);

			ack_cfifo_wr_en	: std_logic;
			ack_dfifo_wr_en	: std_logic;
			ack_dfifo_wdata	: std_logic_vector(17 downto 0);
			ack_cfifo_wdata	: std_logic_vector(15 downto 0);

			rd_en_an   : std_logic;
			rd_en_filter : std_logic;

			tow_bit   : std_logic;
			tow_bit_cunter : integer range 0 to 511; --128,192,256,320(4,6,8,10) s11 is just avoid overflow
	    subsecond_counter : integer range 0 to 2**16 -1;
			global_mask   : std_logic_vector(15 downto 0);
			stc_id       : std_logic_vector(15 downto 0);
			payload_value :  std_logic_vector(15 downto 0); 
			frame_cnt_ack	: natural range 0 to 28;
			frame_cnt_an	: natural range 0 to 28;
			count       : integer;  

			sub_second_value  : std_logic_vector(15 downto 0);
			e_s_cnt_0     : std_logic_vector(7 downto 0);
			e_s_cnt_1     : std_logic_vector(7 downto 0);
			e_s_cnt_2     : std_logic_vector(7 downto 0);
			e_s_cnt_3     : std_logic_vector(7 downto 0);
			e_s_cnt_4     : std_logic_vector(7 downto 0);
			e_s_cnt_5     : std_logic_vector(7 downto 0); 
			e_s_cnt_6     : std_logic_vector(7 downto 0); 
			e_s_cnt_7     : std_logic_vector(7 downto 0); 
			e_s_cnt_8     : std_logic_vector(7 downto 0); 
			e_s_cnt_9     : std_logic_vector(7 downto 0); 
			e_s_cnt_10    : std_logic_vector(7 downto 0);
			e_s_cnt_11    : std_logic_vector(7 downto 0);
			e_s_cnt_12    : std_logic_vector(7 downto 0);
			e_s_cnt_13    : std_logic_vector(7 downto 0);
			e_s_cnt_14    : std_logic_vector(7 downto 0);
			e_s_cnt_15    : std_logic_vector(7 downto 0);

			e_c_cnt_0     : std_logic_vector(7 downto 0);
			e_c_cnt_1     : std_logic_vector(7 downto 0);
			e_c_cnt_2     : std_logic_vector(7 downto 0);
			e_c_cnt_3     : std_logic_vector(7 downto 0);
			e_c_cnt_4     : std_logic_vector(7 downto 0);
			e_c_cnt_5     : std_logic_vector(7 downto 0); 
			e_c_cnt_6     : std_logic_vector(7 downto 0); 
			e_c_cnt_7     : std_logic_vector(7 downto 0); 
			e_c_cnt_8     : std_logic_vector(7 downto 0); 
			e_c_cnt_9     : std_logic_vector(7 downto 0); 
			e_c_cnt_10    : std_logic_vector(7 downto 0);
			e_c_cnt_11    : std_logic_vector(7 downto 0);
			e_c_cnt_12    : std_logic_vector(7 downto 0);
			e_c_cnt_13    : std_logic_vector(7 downto 0);
			e_c_cnt_14    : std_logic_vector(7 downto 0);
			e_c_cnt_15    : std_logic_vector(7 downto 0);
			crc_res     : std_logic_vector(15 downto 0);
			
end record;

    	
	type rd_fifo is record
        dfifo_rerr		: std_logic;
        dfifo_dvld		: std_logic;
        dfifo_rdata		: std_logic_vector(17 downto 0);
        dfifo_ecc_err	: std_logic;
        dfifo_aempty	: std_logic;
        cfifo_rdata		: std_logic_vector(15 downto 0);
        cfifo_rd_ack	: std_logic;
        cfifo_empty		: std_logic;
	end record;
    
    type rd_en_fifo is record
		dfifo_rd_en	: std_logic;
        cfifo_rd_en	: std_logic;
	end record;
	

	-- ### components ###
	component bcc_stm_generation
		generic(
			COUNT : natural := 100
		);
		port ( 
			clk_i			: in	std_logic;
			rst_n_i			: in	std_logic;
            init_done       : in	std_logic;					    --! Initialization done
			-- to STM Handling fifo
			stm_wr_o		: out	wr_fifo;
			stm_wr_i		: in	wr_full_fifo;
			-- input for BCC
			---sband
			event_type_0_i	: in std_logic_vector(7 downto 0);		
			event_type_1_i	: in std_logic_vector(7 downto 0);		
			event_type_2_i	: in std_logic_vector(7 downto 0);
			event_type_3_i	: in std_logic_vector(7 downto 0);
			event_type_4_i	: in std_logic_vector(7 downto 0);
			event_type_5_i	: in std_logic_vector(7 downto 0);
			event_type_6_i	: in std_logic_vector(7 downto 0);
			event_type_7_i	: in std_logic_vector(7 downto 0);
			event_type_8_i	: in std_logic_vector(7 downto 0);
			event_type_9_i	: in std_logic_vector(7 downto 0);
			event_type_10_i	: in std_logic_vector(7 downto 0);
			event_type_11_i	: in std_logic_vector(7 downto 0);
			event_type_12_i	: in std_logic_vector(7 downto 0);
			event_type_13_i	: in std_logic_vector(7 downto 0);
			event_type_14_i	: in std_logic_vector(7 downto 0);
			event_type_15_i	: in std_logic_vector(7 downto 0);
  ---cband
	   event_type_16_i	: in std_logic;  --cband_en
		 event_type_17_i	: in std_logic_vector(7 downto 0);
     event_type_18_i	: in std_logic_vector(7 downto 0);
     event_type_19_i	: in std_logic_vector(7 downto 0);
		 event_type_20_i	: in std_logic_vector(7 downto 0); --length error implemented in 
			--tick
			tick            : in std_logic

		);
	end component;


    
    component bcc_stm_ds_fsm 
        port (
            clk_i	: in	std_logic;
            rst_i	: in	std_logic;
            -- STM fifo input
            stm_i	: in 	rd_fifo;
            stm_o	: out	rd_en_fifo;
            -- Data for DS Link
            stm_data_o		: out	std_logic_vector(8 downto 0);
            stm_data_vld_o	: out	std_logic;
            stm_rx_bsy_i	: in	std_logic
            
        );
        end component;
	


end package;
