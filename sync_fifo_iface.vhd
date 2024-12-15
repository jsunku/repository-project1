--------------------------------------------------------------------------------
--!
--! @file sync_fifo_iface.vhd
--! @brief Interface Synchronous FIFO 
--!             
--! @details  The package provides component definition for small,<BR>
--!                      generic synchronous FIFO as well some required type<BR>
--!                      and function definitions.<BR>
--!
--!
--! @author  A. Freund (af) <a.freund@dsi-it.de> <BR>
--!                      Digitale Signalverabeitung & Informationstechnik GmbH, <BR>
--!                      Bremen, Germany <BR>
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


package sync_fifo_iface is

	type sf_dout_reset_t is (SF_DOUT_RST_NONE, SF_DOUT_RST_MASKED, SF_DOUT_RST_SYNC, SF_DOUT_RST_ASYNC);


	function bits(x : integer) return natural;

--
--
--



--
-- Component declarations
--

	-- sync fifo
	component sync_fifo is
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
	end component;


end sync_fifo_iface;


package body sync_fifo_iface is


	function bits(x : integer) return natural is
		variable res : natural := 0;
	begin
		while (2**res <= x) loop
			res := res + 1;
		end loop;

		return res;
	end function;


end sync_fifo_iface;
