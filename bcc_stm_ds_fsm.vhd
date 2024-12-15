-- ============================================================================
--
-- FSM for STM Anomaly Report Generator
-- ============================================================================

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.bcc_stm_iface.all;


entity bcc_stm_ds_fsm is
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
end entity;

architecture behav of bcc_stm_ds_fsm is

    type states_stm_ds is (IDLE, RD_CFIFO, RD_1ST_BYTES, DROP_DATA, WR_SOF, WR_RHDR, WR_TYPE, WR_EOF, WR_ERR, WR_DATA, RD_DATA);

    type req_type_stm_ds is record
		state			: states_stm_ds;
		frame_cnt		: integer range 0 to 28;
		frame_len		: integer range 0 to 28;
		dfifo_rd_en		: std_logic;
		cfifo_rd_en		: std_logic;
		stm_data		: std_logic_vector(8 downto 0);
		stm_data_vld	: std_logic;
		word_1st_byte	: std_logic_vector(7 downto 0);
		word_2nd_byte	: std_logic_vector(7 downto 0);
		target			: std_logic_vector(4 downto 0);
		second_byte		: std_logic;
      	
	end record;    

signal r, rin	: req_type_stm_ds;

begin 


		seq: process(clk_i, rst_i)
	begin
		if rst_i = '1' then	
			r.state			<= IDLE;
			r.frame_cnt		<= 0;
			r.frame_len		<= 0;
			r.dfifo_rd_en	<= '0';
			r.cfifo_rd_en	<= '0';
			r.stm_data		<= (others => '0');
			r.stm_data_vld	<= '0';
            r.word_1st_byte	<= (others => '0');
            r.word_2nd_byte	<= (others => '0');
            r.second_byte	<= '0';
		
		elsif rising_edge(clk_i) then
			r <= rin;
		end if;
	end process;
	
	fsm: process(r, stm_i, stm_rx_bsy_i)
	variable v	: req_type_stm_ds;
	begin
		v	:= r;
		v.dfifo_rd_en	:= '0';
		v.cfifo_rd_en	:= '0';
		v.stm_data_vld	:= '0';
        
		case r.state is
			when IDLE =>
				v.frame_cnt	:= 0;
				v.frame_len	:= 0;
				if stm_i.cfifo_empty = '0' then
					v.state			:= RD_CFIFO;
					v.cfifo_rd_en	:= '1';
				end if;
			when RD_CFIFO =>
				if stm_i.cfifo_rd_ack = '1' then
					v.frame_len	:= CONV_INTEGER(stm_i.cfifo_rdata(11 downto 0));
					if stm_i.cfifo_rdata(15) = '0' then
						v.state	:= DROP_DATA;
						if r.frame_cnt < CONV_INTEGER(stm_i.cfifo_rdata(11 downto 0)) then
							v.cfifo_rd_en	:= '1';
						end if;
					else
						v.state			:= RD_1ST_BYTES;
						v.dfifo_rd_en	:= '1';
					end if;
				end if;
			when RD_1ST_BYTES =>
				if stm_i.dfifo_rerr = '1' then
					v.state 	:= IDLE;
                elsif stm_i.dfifo_dvld = '1' and r.dfifo_rd_en = '1' then
					if (stm_i.dfifo_ecc_err = '0') then
						v.frame_cnt	:= r.frame_cnt + 2;
						if(stm_i.dfifo_rdata(17) = '1') then
							v.word_1st_byte	:= stm_i.dfifo_rdata(15 downto 8);
							v.word_2nd_byte	:= stm_i.dfifo_rdata(7 downto 0);
							v.state			:= WR_SOF;
						else
							v.state		:= DROP_DATA;
							if r.frame_cnt < r.frame_len-2 then
								v.dfifo_rd_en	:= '1';
							end if;
						end if;
					else
						
						v.state		:= DROP_DATA;
                        v.frame_cnt	:= r.frame_cnt + 2;
						if r.frame_cnt < r.frame_len-2 then
							v.dfifo_rd_en	:= '1';
						end if;
					end if;
				end if;
			when WR_SOF =>
				
				if (stm_rx_bsy_i = '0') then
					v.stm_data		:= SOF;
					v.stm_data_vld	:= '1';
					v.state			:= WR_RHDR;
				end if;			
			when WR_RHDR =>
				if (stm_rx_bsy_i = '0' and r.stm_data_vld = '0') then
					v.stm_data		:= '0' & r.word_1st_byte;
					v.stm_data_vld	:= '1';
					v.state			:= WR_TYPE;
		
				end if;
			when WR_TYPE =>
				if (stm_rx_bsy_i = '0' and r.stm_data_vld = '0') then
					v.stm_data		:= '0' & r.word_2nd_byte;
					v.stm_data_vld	:= '1';
					v.state			:= RD_DATA;
					v.dfifo_rd_en	:= '1';
					
				end if;
			when RD_DATA =>
                if stm_i.dfifo_rerr = '1' then
				
                    v.state 	:= WR_ERR;
				elsif (stm_i.dfifo_dvld = '1' and r.dfifo_rd_en = '1') then
					if (stm_i.dfifo_ecc_err = '0') then
						v.word_1st_byte	:= stm_i.dfifo_rdata(15 downto 8);
                        v.word_2nd_byte	:= stm_i.dfifo_rdata(7 downto 0);
						v.state			:= WR_DATA;
						v.second_byte	:= '0';
						v.frame_cnt	:= r.frame_cnt + 2;
						
					else
						
						v.state		:= WR_ERR;
						v.frame_cnt	:= r.frame_cnt + 2;
					end if;
				end if;
			when WR_DATA =>
				if (stm_rx_bsy_i = '0' and r.stm_data_vld = '0') then
					if r.second_byte = '1' then
						v.stm_data		:= '0' & r.word_2nd_byte;
						v.stm_data_vld	:= '1';
						v.second_byte	:= '0';
						if r.frame_cnt < r.frame_len then
							v.dfifo_rd_en 	:= '1';
							v.state			:= RD_DATA;
						else
							v.state	:= WR_EOF;
						end if;
					else
						v.stm_data		:= '0' & r.word_1st_byte;
						v.stm_data_vld	:= '1';
						v.state			:= WR_DATA;
                        v.second_byte	:= '1';
						
					end if;
				end if;

		
			when WR_EOF =>
				if (stm_rx_bsy_i = '0' and r.stm_data_vld = '0') then
					v.stm_data		:= EOF;
					v.stm_data_vld	:= '1';
					v.state			:= IDLE;
				end if;
			when WR_ERR =>
				if (stm_rx_bsy_i = '0' and r.stm_data_vld = '0') then
					v.stm_data		:= ERR;
					v.stm_data_vld	:= '1';
					if r.frame_cnt < r.frame_len then
						v.dfifo_rd_en	:= '1';
					end if;
					v.state	:= DROP_DATA;
				end if;
			when DROP_DATA =>
				if r.frame_cnt >= r.frame_len then
                    v.state := IDLE;
                elsif stm_i.dfifo_rerr = '1' then
                    v.state := IDLE;
                elsif stm_i.dfifo_dvld = '1' then
                    if r.frame_len-r.frame_cnt = 1 then
                        v.frame_cnt	:= r.frame_cnt + 1;
                        v.state		:= IDLE;
                    elsif r.frame_len-r.frame_cnt = 2 then
                        v.frame_cnt	:= r.frame_cnt + 2;
                        v.state		:= IDLE;
                    else
                        v.dfifo_rd_en	:= '1';
                        v.frame_cnt		:= r.frame_cnt + 2;
                    end if;
				end if;
		end case;
		rin	<= v;
		
		stm_data_o			<= r.stm_data;
		stm_data_vld_o		<= r.stm_data_vld;
		stm_o.dfifo_rd_en	<= r.dfifo_rd_en;
		stm_o.cfifo_rd_en	<= r.cfifo_rd_en;
		

	end process;
end;