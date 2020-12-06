LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMContext;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY tb_reset IS
  GENERIC(
    runner_cfg : string;
    g_sync      : BOOLEAN := FALSE
  );
END ENTITY;

ARCHITECTURE rtl OF tb_reset IS

CONSTANT c_period : TIME := 10 ns;

SIGNAL i_clock    : STD_LOGIC := '0';
SIGNAL i_reset    : STD_LOGIC := '0';
SIGNAL o_reset    : STD_LOGIC;
SIGNAL id         : AlertLogIDType;
BEGIN

  CreateClock(i_clock, c_period);

  id <= GetAlertLogID(tb_reset'INSTANCE_NAME);

	PROCESS
    VARIABLE v_timestamp : TIME;
	BEGIN
    test_runner_setup(runner, runner_cfg);

    WHILE test_suite LOOP
      IF run("single_cycle_reset") THEN
        i_reset <= '1';
        WaitForClock(i_clock, 1);
        i_reset <= '0';

        v_timestamp := now;
        IF g_sync = TRUE THEN
          WaitForClock(i_clock, 1);
        END IF;
        AffirmIf(id, o_reset = '1', "1st reset check unsuccessfull", WARNING);
        WAIT UNTIL o_reset = '0' FOR 10*c_period;
        AffirmIf(id, o_reset = '0', "2nd reset check unsuccessfull", WARNING);
        IF o_reset = '0' THEN
        Log(id, "reset deasserted after " & TO_STRING(now - v_timestamp));
        END IF;
      END IF;

      IF run("multi_cycle_reset") THEN
        i_reset <= '1';
        WaitForClock(i_clock, 10);
        i_reset <= '0';

        v_timestamp := now;
        AffirmIf(id, o_reset = '1', "1st reset check unsuccessfull", WARNING);
        WAIT UNTIL o_reset = '0' FOR 10*c_period;
        AffirmIf(id, o_reset = '0', "2nd reset check unsuccessfull", WARNING);
        IF o_reset = '0' THEN
        Log(id, "reset deasserted after " & TO_STRING(now - v_timestamp));
        END IF;
      END IF;

    END LOOP;

    ReportAlerts;
    check(GetAffirmCount > 0, "test not selfchecking", FAILURE);
    check_equal(GetAlertCount, 0, "test failed", FAILURE);

    test_runner_cleanup(runner);
	END PROCESS;
  test_runner_watchdog(runner, 500 ns);

i_dut: ENTITY WORK.reset_control
  GENERIC MAP(
    g_use_sync_reset    => g_sync
  )
  PORT MAP(
    i_clock => i_clock,
    i_reset => i_reset,
    o_reset => o_reset
  );

END ARCHITECTURE;
