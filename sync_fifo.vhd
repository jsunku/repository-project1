
--------------------------------------------------------------------------------
--!
--! @file sync_fifo.vhd
--! @brief Synchronous FIFO 
--!             
--! @details  Generic synchronous FIFO without using any technology-<BR>
--!             dependent memory cells, intended for small FIFOs.<BR>
--!
--!
--! @author  A. Freund (af) <a.freund@dsi-it.de> <BR>
--!                      Digitale Signalverabeitung & Informationstechnik GmbH, <BR>
--!                      Bremen, Germany <BR>
--------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


use work.sync_fifo_iface.all;


entity sync_fifo is
	generic (
		DEPTH			:	integer			:=	256;
		WIDTH			:	integer			:=	8;
		AFULL_THRES		:	integer			:=	255;
		AEMPTY_THRES	:	integer			:=	1;
		DOUT_RST_TYPE	:	sf_dout_reset_t	:=	SF_DOUT_RST_MASKED
	);
	port (
		rst_n	:	in	std_logic;										-- reset
		clk		:	in	std_logic;										-- clock
		wr_en	:	in	std_logic;
		wdata	:	in	std_logic_vector(WIDTH - 1 downto 0);
		rd_en	:	in	std_logic;
		rdata	:	out	std_logic_vector(WIDTH - 1 downto 0);
		wr_ack	:	out	std_logic;
		rd_ack	:	out	std_logic;
		full	:	out	std_logic;
		afull	:	out	std_logic;
		empty	:	out	std_logic;
		aempty	:	out	std_logic;
		count	:	out	std_logic_vector(bits(DEPTH) - 1 downto 0)
	);
end sync_fifo;


architecture behavioural of sync_fifo is

	type registers is record
		rdata		:	std_logic_vector(rdata'range);
		full		:	std_logic;
		afull		:	std_logic;
		empty		:	std_logic;
		aempty		:	std_logic;
		count		:	std_logic_vector(bits(DEPTH) - 1 downto 0);
		wptr		:	std_logic_vector(bits(DEPTH - 1) - 1 downto 0);
		rptr		:	std_logic_vector(bits(DEPTH - 1) - 1 downto 0);
		wr_ack		:	std_logic;
		rd_ack		:	std_logic;
		rd_mask		:	std_logic;

	end record;


	type variables is record
		tp_ram_wr_en	:	std_logic;
	end record;


	signal	r, rin : registers;


	subtype item_t is std_logic_vector(wdata'range);
	type memory_t is array(0 to DEPTH - 1) of item_t;

	signal s_tp_ram_wr_en	:	std_logic;
	signal s_tp_ram_cont	:	memory_t;
	signal s_tp_ram_rdata	:	std_logic_vector(rdata'range);


begin


-- combinatorial logic
	comb: process (rst_n, r, wr_en, rd_en, s_tp_ram_rdata)
		variable v : registers;
		variable t : variables;
	begin

		-- assign default values
		v := r;

		t.tp_ram_wr_en	:=	'0';

--
--	strobes
--
		v.wr_ack	:=	'0';
		v.rd_ack	:=	'0';


--
--	regular / non-strobe signals
--

		-- write into not full fifo
		if (r.full = '0') and (wr_en = '1') and (rd_en = '0')
			then
				v.count	:=	r.count + 1;
				v.empty	:=	'0';

				if (r.count = (DEPTH - 1))
					then
						v.full	:=	'1';
				end if;

				if (r.count = (AFULL_THRES - 1))
					then
						v.afull	:=	'1';
				end if;

				if (r.count = AEMPTY_THRES)
					then
						v.aempty	:=	'0';
				end if;

		-- read from not empty fifo
		elsif (r.empty = '0') and (wr_en = '0') and (rd_en = '1')
			then
				v.count	:=	r.count - 1;
				v.full	:=	'0';

				if (r.count = 1)
					then
						v.empty	:=	'1';
				end if;

				if (r.count = AFULL_THRES)
					then
						v.afull	:=	'0';
				end if;

				if (r.count = (AEMPTY_THRES + 1))
					then
						v.aempty	:=	'1';
				end if;

		-- simultaneous read/write
		elsif (wr_en = '1') and (rd_en = '1')
			then
				if (r.empty = '1')
					then
						v.count	:=	r.count + 1;
						v.empty	:=	'0';
				elsif (r.full = '1')
					then
						v.count	:=	r.count - 1;
						v.full	:=	'0';
				else
					null;
				end if;

		-- no activity or illegal usage
		else
			null;
		end if;


		-- write operation
		if (r.full = '0') and (wr_en = '1')
			then
				v.wr_ack		:=	'1';
				t.tp_ram_wr_en	:=	'1';

				if (r.wptr = (DEPTH - 1))
					then
						v.wptr	:=	(others => '0');
					else
						v.wptr	:=	r.wptr + 1;
				end if;
		end if;

		-- read operation
		if (r.empty = '0') and (rd_en = '1')
			then
				v.rd_ack	:=	'1';
				v.rdata		:=	s_tp_ram_rdata;
				v.rd_mask	:=	'1';

				if (r.rptr = (DEPTH - 1))
					then
						v.rptr	:=	(others => '0');
					else
						v.rptr	:=	r.rptr + 1;
				end if;
		end if;

--
--	reset handling
--
		if (rst_n = '0')
			then
				-- see async. reset (sync. reset requires additional logic on ProASIC3 devices)

				if (DOUT_RST_TYPE = SF_DOUT_RST_SYNC)
					then
						v.rdata	:=	(others => '0');
				end if;
		end if;

--
--	update registers
--
		rin <= v;

--
--	drive outputs
--
		if (DOUT_RST_TYPE = SF_DOUT_RST_MASKED)
			then
				rdata	<=	r.rdata and (r.rdata'range => r.rd_mask);
			else
				rdata	<=	r.rdata;
		end if;

		full			<=	r.full;
		afull			<=	r.afull;
		wr_ack			<=	r.wr_ack;
		rd_ack			<=	r.rd_ack;
		empty			<=	r.empty;
		aempty			<=	r.aempty;
		count			<=	r.count;

		s_tp_ram_wr_en	<=	t.tp_ram_wr_en;

	end process;



	-- registers
	regs: process (clk, rst_n)
	begin
		if rising_edge(clk)
			then
				r <= rin;
		end if;

		-- async. reset
		if (rst_n = '0')
			then
				if (DOUT_RST_TYPE = SF_DOUT_RST_ASYNC)
					then
						r.rdata	<=	(others => '0');
				end if;

				r.full		<=	'0';
				r.afull		<=	'0';
				r.empty		<=	'1';
				r.aempty	<=	'1';
				r.count		<=	(others => '0');
				r.wptr		<=	(others => '0');
				r.rptr		<=	(others => '0');
				r.wr_ack	<=	'0';
				r.rd_ack	<=	'0';
				r.rd_mask	<=	'0';
		end if;
   end process;


--
-- two-port RAM (separated from other stuff due to the insufficiencies of XST RAM inference)
--

	process
	begin
		wait until rising_edge(clk);

		if (s_tp_ram_wr_en = '1')
			then
				s_tp_ram_cont(CONV_INTEGER(r.wptr)) <= wdata;
		end if;
	end process;

	process(r, s_tp_ram_cont)
	begin
		s_tp_ram_rdata <= s_tp_ram_cont(CONV_INTEGER(r.rptr));
	end process;


end behavioural;
