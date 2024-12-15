-- ============================================================================
--
-- STM Anomaly Report Generator top component
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.bcc_stm_iface.all;
use work.sync_fifo_iface.all;



entity bcc_stm_top is
	generic (
		STM_DF_AW		: natural range 6 to 9	:=	6;	-- Addres Width is 6 => 64 Entries (2 bytes)
		STM_DF_AFT		: natural				:=	50;	-- Almost full threshold are 57 because length of the STC(without CRC) is 14 bytes (7 entries)
		STM_DF_AET		: natural				:=	2;
		STM_CF_DEPTH	: natural				:=	4;	-- max 9 Frames fits into the data fifo
        DS_DATA_LENGTH  : natural               := 10;
        STM_CNT         : integer               := 5000;
        DS_CLKDIV       : integer               := 4;
        DS_FRAME_GAP    : integer               := 3
	);
	port (
		-- global signals 

		rst_n_i		: in	std_logic;
		clk_i		: in	std_logic;
        init_done   : in	std_logic;					    --! Initialization done
	

		-- DS Link TX
		dsl_autb_stm_d_o		: out	std_logic;
		dsl_autb_stm_s_o		: out	std_logic;
		dsl_autb_stm_bsy_i	    : in	std_logic;

        -- Event Type strobe

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
        event_type_20_i	: in std_logic_vector(7 downto 0) --length error implemented in    
--tick              
       
	
	);
end entity;

architecture behavioural of bcc_stm_top is
	
    
    signal s_stm_wr_i            :   wr_full_fifo;
    signal s_stm_wr_o            :   wr_fifo;
    signal s_tick_1ms            :   std_logic;
    signal s_rst_i               :   std_logic;
    signal stm_i                 :   rd_en_fifo;
    signal stm_o                 :   rd_fifo;
    signal s_stm_ds_data         : std_logic_vector (8 downto 0);       
    signal s_stm_ds_dvld         : std_logic;
    signal s_stm_ds_bsy          : std_logic;
    signal s_ds_link_bsy	     : std_logic;
    signal ds_link_tready       : std_logic;
    signal ds_data              : std_logic_vector(9 downto 0)  := (others => '0');


    component bcc_time_pulse
        generic (
           PREDIV    : integer := 1600 -- CLKFREQ_HZ/100us
        );
        Port (
           CLK_I         : in  std_logic;
           RST_I         : in  std_logic;
           PULSE_100us_O : out std_logic;
           PULSE_1ms_O   : out std_logic
        );
        end component;
    
    component sfifo_fwft_ecc_usram
        generic (
            ZRZ_EN		:	boolean					:=	false;		-- enable zeroization circuitry
            AW			:	integer range 6 to 9	:=	6;			-- address width, 6 => 64x<DW>b / 1 uSRAM deep
            DW			:	positive				:=	18;			-- data width, 18 => <2**AW>x18b / 1 uSRAM wide
            AFT			:	integer					:=	60;			-- almost-full threshold
            AET			:	integer					:=	4			-- almost-empty threshold
        );
        port (
            rst_n		:	in	std_logic;							-- async. low-active reset
            clk			:	in	std_logic;							-- clock
            mclr		:	in	std_logic;							-- trigger clear/zeroization (strobe)
            zact		:	out	std_logic;							-- clear/zeroization in progress
    
            -- user write port
            wen			:	in	std_logic;							-- write enable (strobe)
            wdata		:	in	std_logic_vector(DW - 1 downto 0);	-- write data
            werr		:	out	std_logic;							-- write error (strobe)
            full		:	out	std_logic;							-- FIFO full
            afull		:	out	std_logic;							-- FIFO almost-full, wcnt >= AFT
            wcnt		:	out	std_logic_vector(AW downto 0);		-- write count
    
            -- user read port
            ren			:	in	std_logic;							-- read enable (strobe)
            rerr		:	out	std_logic;							-- read error (strobe)
            dvld		:	out	std_logic;							-- data valid on output (FWFT)
            rdata		:	out	std_logic_vector(DW - 1 downto 0);	-- read data
            ecc_err		:	out	std_logic;							-- non-correctable EDAC error
            aempty		:	out	std_logic;							-- FIFO almost-empty, rcnt < AET
            rcnt		:	out	std_logic_vector(AW downto 0)		-- read count
        );
        end component;


        
        component ds_link_tx is
        generic (
           CLKDIV      : natural;         -- TX_CLKDIV = CLK_Freq / TX_Data_Rate
           DATA_LENGTH : natural;         -- Payload length in bits
           FRAME_GAP   : natural;         -- Gap between TX frames in bit periods (>= 1)
           IDLE_LEVEL  : std_logic := '1' -- DOUT/SOUT level when link is idle
        );
        port (
           CLK    : in  std_logic;
           RST    : in  std_logic; -- Asynchronous reset
           -- Transmitter data in (AXI4 stream)
           TDATA  : in  std_logic_vector(DATA_LENGTH-1 downto 0);
           TVALID : in  std_logic;
           TREADY : out std_logic;
           -- DS encoded serial out
           DOUT   : out std_logic;
           SOUT   : out std_logic
        );
        end component ds_link_tx;

    
begin
	s_rst_i <= not rst_n_i;
	
	-- STM Generation
	i_stm_gen: bcc_stm_generation

        generic map (
        COUNT               => STM_CNT
        )
		port map(
			clk_i			=>	clk_i,
			rst_n_i			=>	rst_n_i,
            init_done       =>	init_done,
            --
			stm_wr_o		=>	s_stm_wr_o,
			stm_wr_i		=>	s_stm_wr_i,
            -- input for BCC
	        event_type_0_i	=> event_type_0_i,	
	        event_type_1_i	=> event_type_1_i,	
	        event_type_2_i	=> event_type_2_i,
	        event_type_3_i	=> event_type_3_i,
	        event_type_4_i	=> event_type_4_i,
	        event_type_5_i	=> event_type_5_i,
	        event_type_6_i	=> event_type_6_i,
	        event_type_7_i	=> event_type_7_i,
	        event_type_8_i	=> event_type_8_i,
	        event_type_9_i	=> event_type_9_i,
	        event_type_10_i	=> event_type_10_i,
	        event_type_11_i	=> event_type_11_i,
            event_type_12_i	=> event_type_12_i,
            event_type_13_i	=> event_type_13_i,
	        event_type_14_i	=> event_type_14_i,
	        event_type_15_i	=> event_type_15_i,
             ---cband
            event_type_16_i	=> event_type_16_i,
            event_type_17_i	=> event_type_17_i,
            event_type_18_i	=> event_type_18_i,
            event_type_19_i	=> event_type_19_i,
            event_type_20_i	=> event_type_20_i,
    --tick
            tick            => s_tick_1ms

			
		);

    i_bcc_time_pulse: bcc_time_pulse
         generic map (
             PREDIV    =>  3200 -- CLKFREQ_HZ/100us
          )
          port map (
             CLK_I         =>	clk_i,
             RST_I         =>	s_rst_i,
             PULSE_100us_O =>   open,
             PULSE_1ms_O   =>   s_tick_1ms
          );

	
	i_stm_dfifo: sfifo_fwft_ecc_usram		-- Data Fifo to the STM Handler 
		generic map(
			AW			=> 	STM_DF_AW,
			AFT			=> 	STM_DF_AFT,
			AET			=> 	STM_DF_AET
		)
		port map(
			rst_n		=>  rst_n_i,
			clk			=>  clk_i,
			mclr		=>  '0',
			zact		=>  open,
			-- user write port
			wen			=>  s_stm_wr_o.dfifo_wr_en,
			wdata		=>  s_stm_wr_o.dfifo_wdata,
			werr		=>  open,
			full		=>  open,
			afull		=>  s_stm_wr_i.dfifo_afull,
			wcnt		=>  open,
			-- user read port
			ren			=>  stm_i.dfifo_rd_en,
			rerr		=>  stm_o.dfifo_rerr,
			dvld		=>  stm_o.dfifo_dvld,
			rdata		=>  stm_o.dfifo_rdata,
			ecc_err		=>  stm_o.dfifo_ecc_err,
			aempty		=>  stm_o.dfifo_aempty,
			rcnt		=>  open
		);
	i_stm_cfifo: sync_fifo				-- Control Fifo to the STM Handler 
		generic map(
			DEPTH			=>  STM_CF_DEPTH,
			WIDTH			=>  16,
			AFULL_THRES		=>  STM_CF_DEPTH-1,
			AEMPTY_THRES	=>	1,
			DOUT_RST_TYPE	=>	SF_DOUT_RST_ASYNC
		)
		port map(
			rst_n	=>  rst_n_i,
			clk		=>  clk_i,
			wr_en	=>  s_stm_wr_o.cfifo_wr_en,
			wdata	=>  s_stm_wr_o.cfifo_wdata,
			rd_en	=>  stm_i.cfifo_rd_en,
			rdata	=>  stm_o.cfifo_rdata,
			wr_ack	=>  open,
			rd_ack	=>  stm_o.cfifo_rd_ack,
			full	=>  s_stm_wr_i.cfifo_full,
			afull	=>  open,
			empty	=>  stm_o.cfifo_empty,
			aempty	=>  open,
			count	=>  open
		);
	
    i_stc_ctrl: bcc_stm_ds_fsm
        port map(
            clk_i			=>  clk_i,
            rst_i			=>  s_rst_i,
            stm_i			=>  stm_o,
            stm_o			=>  stm_i,
            stm_data_o		=>  s_stm_ds_data,
            stm_data_vld_o	=>  s_stm_ds_dvld,
            stm_rx_bsy_i	=>  s_stm_ds_bsy
            
        );  
    
        bsy_sync: process (rst_n_i, clk_i)
        begin
            if rst_n_i = '0' then
                s_ds_link_bsy	<= '1';
            elsif rising_edge(clk_i) then
                s_ds_link_bsy	<= dsl_autb_stm_bsy_i;
            end if;
        end process;

    s_stm_ds_bsy <= s_ds_link_bsy or not ds_link_tready;
    ds_data(DS_DATA_LENGTH-2 downto 0) <= s_stm_ds_data;
        

    i_ds_link_tx: ds_link_tx
        generic map(
            CLKDIV      => DS_CLKDIV,		-- Transmitter clock divider
            DATA_LENGTH => DS_DATA_LENGTH,	-- Payload length in bits
            FRAME_GAP   => DS_FRAME_GAP		-- Gap between TX frames in bit periods (>= 1)
        )
        port map(
            CLK    => clk_i, 
            RST    => s_rst_i,		-- Asynchronous reset   
            -- Transmitter data in (AXI4 stream)
            TDATA  => ds_data,
            TVALID => s_stm_ds_dvld,
            TREADY => ds_link_tready,
            -- DS encoded serial out
            DOUT   => dsl_autb_stm_d_o,
            SOUT   => dsl_autb_stm_s_o
        );

	
end architecture;