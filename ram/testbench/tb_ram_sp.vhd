LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMCONTEXT;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY tb_ram_sp IS
  GENERIC(
    runner_cfg   : STRING;
    g_width      : INTEGER;
    g_addr_width : INTEGER;
    g_register   : BOOLEAN
  );
END ENTITY;

ARCHITECTURE tb OF tb_ram_sp IS

  CONSTANT c_period : TIME := 10 ns;
  SIGNAL i_clock    : STD_LOGIC;
  SIGNAL id         : AlertLogIdType;


BEGIN

  CreateClock(i_clock, c_period);
  id <= GetAlertLogId(PathTail(tb_ram_sp'INSTANCE_NAME));

  proc_stim : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);
    WaitForClock(i_clock, 16);

    WHILE test_suite LOOP
      IF run("test") THEN
        Log(id, "start test");

      END IF;
    END LOOP;

    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 5 us);


END ARCHITECTURE;
