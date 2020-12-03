LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMContext;
USE OSVVM.Scoreboardpkg_slv.ALL;

LIBRARY Vunit_lib;
CONTEXT Vunit_lib.vunit_context;

ENTITY tb_fifo_sc IS
  GENERIC(
    runner_cfg  : STRING;
    g_depth  : INTEGER := 256;
    g_width  : INTEGER := 8
  );
END ENTITY;

ARCHITECTURE rtl OF tb_fifo_sc IS

  SIGNAL id   : AlertLogIDType;
  SIGNAL i_clock    : STD_LOGIC;
  SIGNAL i_reset    : STD_LOGIC;
  SIGNAL i_rdreq    : STD_LOGIC;
  SIGNAL i_wrreq    : STD_LOGIC;
  SIGNAL i_din      : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
  SIGNAL o_dout     : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
  SIGNAL o_empty    : STD_LOGIC;
  SIGNAL o_full     : STD_LOGIC;
  SIGNAL o_usedw    : STD_LOGIC_VECTOR(31 DOWNTO 0);

  SHARED VARIABLE sb : ScoreboardPType;


BEGIN

  CreateClock(i_clock, 10 ns);
  CreateReset(i_reset, '1', i_clock, 50 ns, 2 ns);

  id <= GetAlertLogID(PathTail(tb_fifo_sc'INSTANCE_NAME));

  proc_main: PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);

    while test_suite LOOP
      IF run("single_word") THEN
        i_din   <= (OTHERS => '0');
        i_wrreq <= '0';
        i_rdreq <= '0';
        WaitForLevel(i_reset, '0');
        WaitForClock(i_clock, 1);
        i_din <= STD_LOGIC_VECTOR(TO_UNSIGNED(123, i_din'LENGTH));
        i_wrreq <= '1';
        WaitForClock(i_clock, 1);
        i_wrreq <= '0';
        WaitForLevel(o_empty, '0');
        AffirmIf(id, UNSIGNED(o_usedw) = 1, "usedword error" & TO_HSTRING(o_usedw), WARNING);
        WaitForClock(i_clock, 1);
        i_rdreq <= '1';
        WaitForClock(i_clock, 1);
        i_rdreq <= '0';
        AffirmIf(id, o_dout = i_din, "readback failed. " & TO_HSTRING(o_dout) & " " & TO_HSTRING(i_din), ERROR);
        ReportAlerts;
        check(GetAlertCount = 0, "encountered errors");
      END IF;

      IF run("write_until_full_read_until_empty") THEN
        i_din   <= (OTHERS => '0');
        i_wrreq <= '0';
        i_rdreq <= '0';
        WaitForLevel(i_reset, '0');
        WaitForClock(i_clock, 1);
        Log(id, "Write until full");
        FOR I IN 0 TO g_depth-2 LOOP
          i_din <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_din'LENGTH));
          i_wrreq <= '1';
          sb.push(i_din);
          WaitForClock(i_clock, 1);
        END LOOP;
        i_wrreq <= '0';
        WaitForClock(i_clock, 5);
        Affirmif(id, o_full = '1', "full flag not asserted", ERROR);
        Affirmif(id, UNSIGNED(o_usedw) = g_depth-1, "usedword unexpected" & TO_HSTRING(o_usedw), WARNING);

        Log(id, "read until empty");
        FOR I IN 0 TO g_depth-2 LOOP
          i_rdreq <= '1';
          WaitForClock(i_clock, 1);
          sb.check(o_dout);
        END LOOP;
        i_rdreq <= '0';

        WaitForClock(i_clock, 5);
        Affirmif(id, o_empty = '1', "empty flag not asserted", ERROR);
        AffirmIf(id, UNSIGNED(o_usedw) = 0, "usedword not zero" & TO_HSTRING(o_usedw), WARNING);

        ReportAlerts;
        check(GetAlertCount = 0 AND sb.empty, "encountered errors");
      END IF;
    END LOOP;

    test_runner_cleanup(runner);
  END PROCESS;

  inst_dut: ENTITY WORK.fifo_sc(rtl)
    GENERIC MAP(
      g_wr_width    => g_width,
      g_rd_width    => g_width,
      g_wr_depth    => g_depth
    )
    PORT MAP(
      clock         => i_clock,
      data          => i_din,
      rdreq         => i_rdreq,
      sclr          => i_reset,
      wrreq         => i_wrreq,
      almost_empty  => OPEN,
      almost_full   => OPEN,
      empty         => o_empty,
      full          => o_full,
      q             => o_dout,
      usedw         => o_usedw
    );


END ARCHITECTURE rtl;
