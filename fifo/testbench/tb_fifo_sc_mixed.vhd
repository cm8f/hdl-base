LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMcontext;
USE OSVVM.ScoreBoardPkg_slv.ALL;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY tb_fifo_sc_mixed IS
  GENERIC(
    runner_cfg    : STRING;
    g_wr_width    : INTEGER := 8;
    g_rd_width    : INTEGER := 8;
    g_wr_depth    : INTEGER := 512;
    g_output_reg  : BOOLEAN := FALSE
  );
END ENTITY;

ARCHITECTURE tb OF tb_fifo_sc_mixed IS

  CONSTANT c_period : TIME := 10 ns;

  SIGNAL i_clock            : STD_LOGIC := '0';
  SIGNAL i_reset            : STD_LOGIC := '1';
  SIGNAL i_din              : STD_LOGIC_VECTOR(g_wr_width-1 DOWNTO 0);
  SIGNAL i_wrreq            : STD_LOGIC;
  SIGNAL i_rdreq            : STD_LOGIC;
  SIGNAL o_dout             : STD_LOGIC_VECTOR(g_rd_width-1 DOWNTO 0);
  SIGNAL o_empty            : STD_LOGIC;
  SIGNAL o_full             : STD_LOGIC;
  SIGNAL o_almost_empty     : STD_LOGIC;
  SIGNAL o_almost_full      : STD_LOGIC;

  SIGNAL s_rdreq            : STD_LOGIC;
  SIGNAL s_empty            : STD_LOGIC;


  SIGNAL id                 : AlertLogIDType;
  SHARED VARIABLE sv_rand   : RandomPType;
  SHARED VARIABLE sv_score  : ScoreboardPType;
  SHARED VARIABLE sv_bin1   : CovPType;
  SHARED VARIABLE sv_bin2   : CovPType;
  SHARED VARIABLE sv_bin3   : CovPType;
  SHARED VARIABLE sv_bin4   : CovPType;
  SHARED VARIABLE sv_bin5   : CovPType;
  SHARED VARIABLE sv_bin6   : CovPType;

BEGIN

  -- clocking
  CreateClock(i_clock, c_period);
  CreateReset(i_reset, '1', i_clock, 10*c_period, 1 ns);

  proc_init: PROCESS
  BEGIN
    id <= GetAlertLogID(tb_fifo_sc_mixed'INSTANCE_NAME);
    WAIT FOR 0 ns;
    SetLogEnable(DEBUG, FALSE);
    SetLogEnable(PASSED, FALSE );
    WAIT;
  END PROCESS;


  --====================================================================
  --= test sequencer
  --====================================================================
  proc_stim : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);
    sv_bin1.AddBins("Write while empty", ONE_BIN);
    sv_bin2.AddBins("Read while full", ONE_BIN);
    sv_bin3.AddBins("Read and write while almost empty", ONE_BIN);
    sv_bin4.AddBins("Read and write while almost full", ONE_BIN);
    sv_bin5.AddBins("Read when almost empty", ONE_BIN);
    sv_bin6.AddBins("Write when almost full", ONE_BIN);

    WaitForLevel(i_reset, '1');
    WaitForLevel(i_reset, '0');
    WaitForClock(i_clock, 8);

    WHILE test_suite LOOP
      IF run("constrained_random") THEN
        LOOP
          WaitForClock(i_clock, 1);
          sv_bin1.ICover( TO_INTEGER(i_wrreq = '1' AND o_empty = '1') );
          sv_bin2.ICover( TO_INTEGER(i_rdreq = '1' AND o_full  = '1') );
          sv_bin3.ICover( TO_INTEGER(i_wrreq = '1' AND i_rdreq = '1' AND o_almost_empty = '1') );
          sv_bin4.ICover( TO_INTEGER(i_wrreq = '1' AND i_rdreq = '1' AND o_almost_full = '1') );
          sv_bin5.ICover( TO_INTEGER(i_rdreq = '1' AND o_almost_empty = '1') );
          sv_bin6.ICover( TO_INTEGER(i_wrreq = '1' AND o_almost_full = '1') );

          EXIT WHEN
            sv_bin1.IsCovered AND
            sv_bin2.IsCovered AND
            sv_bin3.IsCovered AND
            sv_bin4.IsCovered AND
            sv_bin5.IsCovered AND
            sv_bin6.IsCovered;
        END LOOP;
        Log(id, "coverage target reached");

        -- clear fifo
        i_wrreq <= FORCE '0';
        i_rdreq <= FORCE '1';
        WHILE o_empty = '0' LOOP
          WaitForClock(i_clock, 1);
        END LOOP;

      END IF;
    END LOOP;

    sv_bin1.writeBin;
    sv_bin2.writeBin;
    sv_bin3.writeBin;
    sv_bin4.writeBin;
    sv_bin5.writeBin;
    sv_bin6.writeBin;

    ReportAlerts;
    check(GetAffirmCount > 0, "test not self checking");
    check(sv_bin1.IsCovered, "coverage error 1");
    check(sv_bin2.IsCovered, "coverage error 2");
    check(sv_bin3.IsCovered, "coverage error 3");
    check(sv_bin4.IsCovered, "coverage error 4");
    check(sv_bin5.IsCovered, "coverage error 5");
    check(sv_bin6.IsCovered, "coverage error 6");
    check_equal(GetAlertCount, 0, "test failed");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 10 ms);


  --====================================================================
  --= watch cover
  --====================================================================
  PROCESS
  BEGIN
    WAIT FOR 500 us;
    Log(id, "==================================================");
    Log(id, "cover temp report @ " & TIME'IMAGE(NOW) );
    Log(id, "==================================================");

    sv_bin1.writeBin;
    sv_bin2.writeBin;
    sv_bin3.writeBin;
    sv_bin4.writeBin;
    sv_bin5.writeBin;
    sv_bin6.writeBin;
  END PROCESS;


  --====================================================================
  --= write process
  --====================================================================
  proc_write: PROCESS
  BEGIN
    --IF g_wr_width = g_rd_width THEN
      i_wrreq <= sv_rand.RandSlv(1)(1) AND NOT i_reset;
    --ELSIF g_wr_width > g_rd_width THEN
    --  i_wrreq <= TO_UNSIGNED(sv_rand.FavorSmall(0,1),1)(0) AND NOT i_reset;
    --ELSIF g_wr_width < g_rd_width THEN
    --  i_wrreq <= TO_UNSIGNED(sv_rand.FavorBig(0,1),1)(0) AND NOT i_reset;
    --END IF;
    FOR I IN 0 TO sv_rand.RandInt(1, g_wr_depth) LOOP
      i_din   <= sv_rand.RandSlv(i_din'LENGTH);
      WaitForClock(i_clock, 1);
    END LOOP;
  END PROCESS;


  --====================================================================
  --= read process
  --====================================================================
  proc_read: PROCESS
  BEGIN
    --IF g_wr_width = g_rd_width THEN
      i_rdreq <= sv_rand.RandSlv(1)(1) AND NOT i_reset;
    --ELSIF g_wr_width > g_rd_width THEN
    --  i_rdreq <= TO_UNSIGNED(sv_rand.FavorBig(0,1),1)(0) AND NOT i_reset;
    --ELSIF g_wr_width < g_rd_width THEN
    --  i_rdreq <= TO_UNSIGNED(sv_rand.FavorSmall(0,1),1)(0) AND NOT i_reset;
    --END IF;
    FOR I IN 0 TO sv_rand.RandInt(1, g_wr_depth) LOOP
      WaitForClock(i_clock, 1);
    END LOOP;
  END PROCESS;


  --====================================================================
  --= device under test
  --====================================================================
  inst_dut: ENTITY WORK.fifo_sc_mixed
    GENERIC MAP (
      g_wr_width    => g_wr_width,
      g_rd_width    => g_rd_width,
      g_wr_depth    => g_wr_depth,
      g_output_reg  => g_output_reg
    )
    PORT MAP(
      i_clock         => i_clock,
      i_reset         => i_reset,
      i_din           => i_din,
      i_wrreq         => i_wrreq,
      i_rdreq         => i_rdreq,
      o_dout          => o_dout,
      o_empty         => o_empty,
      o_full          => o_full,
      o_almost_empty  => o_almost_full,
      o_almost_full   => o_almost_empty
    );


  --====================================================================
  --= fifo modeling
  --====================================================================
  proc_model_wr : PROCESS(i_clock, i_reset)
  BEGIN
    IF i_reset = '1' THEN
      -- todo
    ELSIF RISING_EDGE(i_clock) THEN
      IF i_wrreq = '1' AND o_full = '0' THEN
        IF g_wr_width <= g_rd_width THEN
          sv_score.push(i_din);
          Log(id, "push: " & TO_HSTRING(i_din), DEBUG);
        ELSE
          FOR i IN 0 TO g_wr_width/g_rd_width-1 LOOP
            sv_score.push(i_din( (I+1)*g_rd_width-1 DOWNTO I*g_rd_width ));
            Log(id, "push: " & TO_STRING(i_din( (I+1)*g_rd_width-1 DOWNTO I*g_rd_width)), DEBUG);
          END LOOP;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  GEN_OUTREG: IF g_output_reg = FALSE GENERATE
    s_rdreq <= i_rdreq;
    s_empty <= o_empty;
  ELSE GENERATE
    PROCESS(i_reset, i_clock)
    BEGIN
      IF i_reset = '1' THEN
        s_rdreq <= '0';
        s_empty <= '0';
      ELSIF RISING_EDGE(i_clock) THEN
        s_rdreq <= i_rdreq;
        s_empty <= o_empty;
      END IF;
    END PROCESS;
  END GENERATE;

  proc_model_rd : PROCESS(i_clock, i_reset)
  BEGIN
    IF i_reset = '1' THEN
      -- todo
    ELSIF RISING_EDGE(i_clock) THEN
      IF s_rdreq = '1' AND s_empty = '0' THEN
        IF g_rd_width = g_wr_width THEN
          sv_score.check(o_dout);
        ELSIF g_wr_width < g_rd_width THEN
          FOR i IN 0 TO g_rd_width/g_wr_width-1 LOOP
            sv_score.check( o_dOUT( (I+1)*g_wr_width-1 DOWNTO I*g_wr_width ));
          END LOOP;
        ELSIF g_wr_width > g_rd_width THEN
          sv_score.check(o_dout);
        END IF;
      END IF;
    END IF;
  END PROCESS;


END ARCHITECTURE;
