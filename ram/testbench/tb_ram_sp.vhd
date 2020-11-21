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
  SIGNAL i_addr     : STD_LOGIC_VECTOR(g_addr_width-1 DOWNTO 0);
  SIGNAL i_data     : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
  SIGNAL i_wren     : STD_LOGIC;
  SIGNAL o_q        : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);

  SIGNAL id         : AlertLogIdType;
  SHARED VARIABLE sv_rand : RandomPType;
  SHARED VARIABLE sv_mem  : MemoryPType;


BEGIN

  CreateClock(i_clock, c_period);
  id <= GetAlertLogId(PathTail(tb_ram_sp'INSTANCE_NAME));

  proc_stim : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);
    WaitForClock(i_clock, 16);

    sv_mem.MemInit(i_addr'LENGTH, i_data'LENGTH);
    sv_rand.InitSeed(sv_rand'INSTANCE_NAME);

    FOR i IN 0 TO 2**g_addr_width-1 LOOP
      i_wren <= '1';
      i_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr'LENGTH));
      i_data <= (OTHERS => '0');
      WaitForClock(i_clock, 1);
    END LOOP;
    i_wren <= '0';

    WHILE test_suite LOOP
      IF run("init") THEN
        Log(id, "start test");
        FOR I IN 0 TO 2**g_addr_width-1 LOOP
          i_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr'LENGTH));
          i_data <= (OTHERS => '1');
          IF g_register = TRUE THEN
            WaitForClock(i_clock,1);
          END IF;
          WAIT FOR c_period/4;
          AffirmIf(id, sv_mem.MemRead(i_addr) = o_q, "readdata missmatch " & to_hstring(o_q)& " /= " & to_hstring(sv_mem.MemRead(i_addr)), ERROR);
          IF g_register = FALSE THEN
            WaitForClock(i_clock,1);
          END IF;
        END LOOP;
      END IF;

      IF run("random_data_sequential") THEN
        Log(id, "start sequential write");
        FOR I IN 0 TO 2**g_addr_width-1 LOOP
          i_wren <= '1';
          i_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr'LENGTH));
          i_data <= sv_rand.RandSlv(g_width);
          WaitForClock(i_clock,1);
        END LOOP;

        Log(id, "start sequential read");
        FOR I IN 0 TO 2**g_addr_width-1 LOOP
          i_wren <= '0';
          i_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr'LENGTH));
          i_data <= sv_rand.RandSlv(g_width);
          IF g_register = TRUE THEN
            WaitForClock(i_clock,1);
          END IF;
          WAIT FOR c_period/4;
          AffirmIf(id, sv_mem.MemRead(i_addr) = o_q, "readdata missmatch " & to_hstring(o_q)& " /= " & to_hstring(sv_mem.MemRead(i_addr)), ERROR);
          IF g_register = FALSE THEN
            WaitForClock(i_clock,1);
          END IF;
        END LOOP;
      END IF;

    END LOOP;
    ReportAlerts;
    check(GetAffirmCount > 0, "test not selfchecking", FAILURE);
    check(GetAlertCount = 0,  "test failed", FAILURE);

    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 5 ms);



  inst_dut: ENTITY WORK.ram_sp
  GENERIC MAP (
    g_addr_width  => g_addr_width,
    g_data_width  => g_width,
    g_output_reg  => g_register
  )
  PORT MAP (
    address       => i_addr,
    clock         => i_clock,
    data          => i_data,
    wren          => i_wren,
    q             => o_q
  );


  inst_memory_model: PROCESS
  BEGIN
    WaitForClock(i_clock,1);
    IF i_wren THEN
      sv_mem.MemWrite(i_addr,i_data);
    END IF;
  END PROCESS;



END ARCHITECTURE;
