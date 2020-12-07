LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;

ENTITY fifo_sc_mixed IS
  GENERIC (
    g_wr_width  : INTEGER := 16;
    g_rd_width  : INTEGER := 16;
    g_wr_depth  : INTEGER := 512;
    g_output_reg: BOOLEAN := FALSE
  );
  PORT(
    i_clock     : IN STD_LOGIC;
    i_reset     : IN STD_LOGIC;
    i_din       : IN STD_LOGIC_VECTOR(g_wr_width-1 DOWNTO 0);
    i_wrreq     : IN STD_LOGIC;
    i_rdreq     : IN  STD_LOGIC;
    o_dout      : OUT STD_LOGIC_VECTOR(g_rd_width-1 DOWNTO 0);
    o_usedw_wr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_usedw_rd  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_empty     : OUT STD_LOGIC;
    o_full      : OUT STD_LOGIC;
    o_almost_empty  : OUT STD_LOGIC;
    o_almost_full   : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE rtl OF fifo_sc_mixed IS

  CONSTANT c_rd_depth   : INTEGER := g_wr_depth * g_wr_width / g_rd_width;
  CONSTANT c_factor     : INTEGER := maximum(g_wr_width, g_rd_width) / minimum(g_wr_width, g_rd_width);
  CONSTANT c_factor_log : INTEGER := INTEGER(CEIL(LOG2(REAL(c_factor))));

  -- pointer handling write domain
  SIGNAL r_wr_ptr_wr    : UNSIGNED( INTEGER(CEIL(LOG2(REAL(g_wr_depth)))) DOWNTO 0 );
  SIGNAL r_rd_ptr_wr    : UNSIGNED( INTEGER(CEIL(LOG2(REAL(g_wr_depth)))) DOWNTO 0 );
  -- pointer handling read domain
  SIGNAL r_wr_ptr_rd    : UNSIGNED( INTEGER(CEIL(LOG2(REAL(c_rd_depth)))) DOWNTO 0 );
  SIGNAL r_rd_ptr_rd    : UNSIGNED( INTEGER(CEIL(LOG2(REAL(c_rd_depth)))) DOWNTO 0 );
  -- status signals
  SIGNAL s_full         : STD_LOGIC := '0';
  SIGNAL s_empty        : STD_LOGIC := '0';
  SIGNAL s_almost_empty : STD_LOGIC := '0';
  SIGNAL s_almost_full  : STD_LOGIC := '0';
  SIGNAL r_usedw_wr     : UNSIGNED(r_wr_ptr_wr'RANGE);
  SIGNAL r_usedw_rd     : UNSIGNED(r_wr_ptr_rd'RANGE);

BEGIN

  -- write pointer handling
  proc_wr_ptr : PROCESS(i_reset, i_clock)
  BEGIN
    IF i_reset = '1' THEN
      r_wr_ptr_wr <= (OTHERS => '0');
    ELSIF RISING_EDGE(i_clock) THEN
      -- write ptr
      IF i_wrreq = '1' AND s_full = '0' THEN
        r_wr_ptr_wr <= r_wr_ptr_wr + 1;
      END IF;
      -- used word processing
      r_usedw_wr <= r_wr_ptr_wr - r_rd_ptr_wr;
    END IF;
  END PROCESS;


  -- read pointer handling
  proc_rd_ptr : PROCESS(i_reset, i_clock)
  BEGIN
    IF i_reset = '1' THEN
      r_rd_ptr_rd <= (OTHERS => '0');
    ELSIF RISING_EDGE(i_clock) THEN
      -- read pointer
      IF i_rdreq = '1' AND s_empty = '0' THEN
        r_rd_ptr_rd <= r_rd_ptr_rd + 1;
      END IF;
      -- used word processing
      r_usedw_rd <= r_wr_ptr_rd - r_rd_ptr_rd;
    END IF;
  END PROCESS;

  proc_async_ptr_asign: PROCESS(ALL)
  BEGIN
    -- write pointer
    IF r_wr_ptr_wr'LENGTH = r_wr_ptr_rd'LENGTH THEN
      r_wr_ptr_rd <= r_wr_ptr_wr;
    ELSIF r_wr_ptr_rd'LENGTH < r_wr_ptr_wr'LENGTH THEN
      r_wr_ptr_rd <= r_wr_ptr_wr(r_wr_ptr_wr'HIGH DOWNTO c_factor_log);
    ELSIF r_wr_ptr_rd'LENGTH > r_wr_ptr_wr'LENGTH THEN
      r_wr_ptr_rd <= r_wr_ptr_wr & TO_UNSIGNED(0, C_factor_log);
    END IF;
    --read ptr
    IF r_rd_ptr_wr'LENGTH = r_rd_ptr_rd'LENGTH THEN
      r_rd_ptr_wr <= r_rd_ptr_rd;
    ELSIF r_rd_ptr_wr'LENGTH < r_rd_ptr_rd'LENGTH THEN
      r_rd_ptr_wr <= r_rd_ptr_rd(r_rd_ptr_rd'HIGH DOWNTO c_factor_log);
    ELSIF r_rd_ptr_wr'LENGTH > r_rd_ptr_rd'LENGTH THEN
      r_rd_ptr_wr <= r_rd_ptr_rd & TO_UNSIGNED(0, c_factor_log);
    END IF;
  END PROCESS;




  --====================================================================
  --= memory instance
  --====================================================================
  inst_mem: ENTITY WORK.ram_sdp
    GENERIC MAP (
      g_depth_a       => g_wr_depth,
      g_depth_b       => c_rd_depth,
      g_output_reg    => g_output_reg,
      g_data_width_a  => g_wr_width,
      g_data_width_b  => g_rd_width
    )
    PORT MAP (
      clock           => i_clock,
      -- write
      address_a       => STD_LOGIC_VECTOR(r_wr_ptr_wr(r_wr_ptr_wr'HIGH-1 DOWNTO 0)),
      data_a          => i_din,
      wren_a          => i_wrreq,
      -- read
      address_b       => STD_LOGIC_VECTOR(r_rd_ptr_rd(r_rd_ptr_rd'HIGH-1 DOWNTO 0)),
      q_b             => o_dout
    );


  --====================================================================
  --= status
  --====================================================================
  s_empty <= '1' WHEN (r_wr_ptr_rd = r_rd_ptr_rd) ELSE '0';

--  s_full <= '1' WHEN (
--                r_wr_ptr_wr(r_wr_ptr_wr'HIGH)            = NOT r_rd_ptr_wr(r_rd_ptr_wr'HIGH)
--            AND r_wr_ptr_wr(r_wr_ptr_wr'HIGH-1 DOWNTO 0) = r_rd_ptr_wr(r_rd_ptr_wr'HIGH-1 DOWNTO 0))
--          ELSE '0';
  s_full <= '1' WHEN (r_wr_ptr_wr(r_wr_ptr_wr'HIGH-1 DOWNTO 0)+1 = r_rd_ptr_wr(r_rd_ptr_wr'HIGH-1 DOWNTO 0))
          ELSE '0';

  s_almost_empty <= '1' WHEN r_usedw_rd < 4 ELSE '0';
  s_almost_full  <= '1' WHEN r_usedw_wr > g_wr_depth-4;


  --====================================================================
  --= wire status signals
  --====================================================================
  o_full          <= s_full;
  o_almost_full   <= s_almost_full;
  o_usedw_wr      <= STD_LOGIC_VECTOR(RESIZE(r_usedw_wr, 32));

  o_empty         <= s_empty;
  o_almost_empty  <= s_almost_empty;
  o_usedw_rd      <= STD_LOGIC_VECTOR(RESIZE(r_usedw_rd, 32));



END ARCHITECTURE;
