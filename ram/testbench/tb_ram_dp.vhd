LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMCONTEXT;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY tb_ram_dp IS
  GENERIC(
    runner_cfg   : STRING;
    g_width      : INTEGER;
    g_addr_width : INTEGER;
    g_register   : BOOLEAN
  );
END ENTITY;

ARCHITECTURE tb OF tb_ram_dp IS

  CONSTANT c_period : TIME := 10 ns;
  SIGNAL i_clock_a    : STD_LOGIC;
  SIGNAL i_clock_b    : STD_LOGIC;
  SIGNAL i_addr_a     : STD_LOGIC_VECTOR(g_addr_width-1 DOWNTO 0);
  SIGNAL i_addr_b     : STD_LOGIC_VECTOR(g_addr_width-1 DOWNTO 0);
  SIGNAL i_data_a     : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
  SIGNAL i_data_b     : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
  SIGNAL i_wren_a     : STD_LOGIC;
  SIGNAL i_wren_b     : STD_LOGIC;
  SIGNAL o_q_a        : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);
  SIGNAL o_q_b        : STD_LOGIC_VECTOR(g_width-1 DOWNTO 0);

  SIGNAL id         : AlertLogIdType;
  SHARED VARIABLE sv_rand : RandomPType;
  SHARED VARIABLE sv_mem  : MemoryPType;


BEGIN

  CreateClock(i_clock_a, c_period);
  i_clock_b <= i_clock_b;

  id <= GetAlertLogId(PathTail(tb_ram_dp'INSTANCE_NAME));
  SetLogEnable(INFO, FALSE);
  SetLogEnable(DEBUG, FALSE);

  proc_stim : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);
    WaitForClock(i_clock_a, 16);

    sv_mem.MemInit(AddrWidth => i_addr_a'LENGTH, DataWidth => i_data_a'LENGTH);
    sv_rand.InitSeed(sv_rand'INSTANCE_NAME);

    FOR i IN 0 TO 2**g_addr_width-1 LOOP
      i_wren_a <= '1';
      i_addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_a'LENGTH));
      i_data_a <= (OTHERS => '0');
      WaitForClock(i_clock_a, 1);
    END LOOP;
    i_wren_a <= '0';

    WHILE test_suite LOOP
      IF run("init") THEN
        Log(id, "start test");
        FOR I IN 0 TO 2**g_addr_width-1 LOOP
          i_addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_a'LENGTH));
          i_data_a <= (OTHERS => '1');
          IF g_register = TRUE THEN
            WaitForClock(i_clock_a,1);
          END IF;
          WAIT FOR c_period/4;
          AffirmIf(id, sv_mem.MemRead(i_addr_a) = o_q_a, "readdata missmatch " & to_hstring(o_q_a)& " /= " & to_hstring(sv_mem.MemRead(i_addr_a)), ERROR);
          IF g_register = FALSE THEN
            WaitForClock(i_clock_a,1);
          END IF;
        END LOOP;
      END IF;

      IF run("random_data_sequential") THEN
        Log(id, "start sequential write");
        FOR I IN 0 TO 2**g_addr_width-1 LOOP
          i_wren_a <= '1';
          i_addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_a'LENGTH));
          i_data_a <= sv_rand.RandSlv(g_width);
          WaitForClock(i_clock_a,1);
        END LOOP;

        Log(id, "start sequential read");
        FOR I IN 0 TO 2**g_addr_width-1 LOOP
          i_wren_a <= '0';
          i_addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_a'LENGTH));
          i_data_a <= sv_rand.RandSlv(g_width);
          IF g_register = TRUE THEN
            WaitForClock(i_clock_a,1);
          END IF;
          WAIT FOR c_period/4;
          AffirmIf(id, sv_mem.MemRead(i_addr_a) = o_q_a, "readdata missmatch " & to_hstring(o_q_a)& " /= " & to_hstring(sv_mem.MemRead(i_addr_a)), ERROR);
          IF g_register = FALSE THEN
            WaitForClock(i_clock_a,1);
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



  inst_dut: ENTITY WORK.ram_dp
  GENERIC MAP (
    g_addr_width  => g_addr_width,
    g_data_width  => g_width,
    g_output_reg  => g_register
  )
  PORT MAP (
    address_a     => i_addr_a,
    address_b     => i_addr_b,
    clock_a       => i_clock_a,
    clock_b       => i_clock_b,
    data_a        => i_data_a,
    data_b        => i_data_b,
    wren_a        => i_wren_a,
    wren_b        => i_wren_b,
    q_a           => o_q_a,
    q_b           => o_q_b
  );


  inst_memory_model: PROCESS
  BEGIN
    WaitForClock(i_clock_a,1);
    IF i_wren_a THEN
      Log(id, "Memeory Write @" & TO_HSTRING(i_addr_a) & ": " & TO_HSTRING(i_data_a), DEBUG);
      sv_mem.MemWrite(i_addr_a,i_data_a);
      Log(id, "Memeory is @" & TO_HSTRING(i_addr_a) & ": " & TO_HSTRING(sv_mem.MemRead(i_addr_a)), DEBUG);
    END IF;
  END PROCESS;



END ARCHITECTURE;
