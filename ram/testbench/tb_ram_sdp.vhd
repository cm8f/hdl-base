LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMCONTEXT;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

ENTITY tb_ram_sdp IS
  GENERIC(
    runner_cfg   : STRING;
    g_width_a    : INTEGER;
    g_width_b    : INTEGER;
    g_depth_a    : INTEGER;
    g_depth_b    : INTEGER;
    g_register   : BOOLEAN
  );
END ENTITY;

ARCHITECTURE tb OF tb_ram_sdp IS

  CONSTANT c_period : TIME := 10 ns;
  CONSTANT c_factor   : INTEGER := maximum(g_width_a, g_width_b) / minimum(g_width_a, g_width_b);
  CONSTANT c_factor_log : INTEGER := INTEGER(ceil(log2(real(c_factor))));
  SIGNAL i_clock_a    : STD_LOGIC;
  -- write port
  SIGNAL i_addr_a     : STD_LOGIC_VECTOR(INTEGER(CEIL(LOG2(REAL(g_depth_a))))-1 DOWNTO 0);
  SIGNAL i_data_a     : STD_LOGIC_VECTOR(g_width_a-1 DOWNTO 0);
  SIGNAL i_wren_a     : STD_LOGIC;
  -- read port
  SIGNAL i_addr_b     : STD_LOGIC_VECTOR(INTEGER(CEIL(LOG2(REAL(g_depth_b))))-1 DOWNTO 0);
  SIGNAL o_q_b        : STD_LOGIC_VECTOR(g_width_b-1 DOWNTO 0);

  SIGNAL id         : AlertLogIdType;
  SHARED VARIABLE sv_rand : RandomPType;
  SHARED VARIABLE sv_mem  : MemoryPType;


BEGIN

  CreateClock(i_clock_a, c_period);

  id <= GetAlertLogId(PathTail(tb_ram_sdp'INSTANCE_NAME));
  SetLogEnable(INFO, TRUE);
  SetLogEnable(DEBUG, TRUE);

  proc_stim : PROCESS
  BEGIN
    test_runner_setup(runner, runner_cfg);
    WaitForClock(i_clock_a, 16);

    sv_mem.MemInit(
      AddrWidth => maximum(i_addr_a'LENGTH, i_addr_b'length),
      DataWidth => minimum(i_data_a'LENGTH, o_q_b'LENGTH)
    );
    sv_rand.InitSeed(sv_rand'INSTANCE_NAME);

    FOR i IN 0 TO g_depth_a-1 LOOP
      i_wren_a <= '1';
      i_addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_a'LENGTH));
      i_data_a <= (OTHERS => '0');
      WaitForClock(i_clock_a, 1);
    END LOOP;
    i_wren_a <= '0';

    WHILE test_suite LOOP

      IF run("random_data_sequential") THEN
        Log(id, "start sequential write");
        FOR I IN 0 TO g_depth_a-1 LOOP
          i_wren_a <= '1';
          i_addr_a <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_a'LENGTH));
          i_data_a <= sv_rand.RandSlv(g_width_a);
          WaitForClock(i_clock_a,1);
        END LOOP;
        i_wren_a <= '0';

        Log(id, "start sequential read");
        FOR I IN 0 TO g_depth_b-1 LOOP
          i_addr_b <= STD_LOGIC_VECTOR(TO_UNSIGNED(I, i_addr_b'LENGTH));
          IF g_register = TRUE THEN
            WaitForClock(i_clock_a,1);
          END IF;
          WAIT FOR c_period/4;
          
          IF g_width_a = g_width_b THEN 
            AffirmIf(id, sv_mem.MemRead(i_addr_b) = o_q_b, "readdata missmatch " & to_hstring(o_q_b)& " /= " & to_hstring(sv_mem.MemRead(i_addr_b)), ERROR);
          ELSIF g_width_a > g_width_b THEN 
            AffirmIf(id, sv_mem.MemRead(i_addr_b) = o_q_b, "readdata missmatch " & to_hstring(o_q_b) & " /= " & to_hstring(sv_mem.MemRead(i_addr_b)), ERROR);
          ELSIF g_width_a < g_width_b THEN 
            FOR i IN 0 TO c_factor-1 LOOP
              AffirmIf(id, sv_mem.MemRead(i_addr_b & STD_LOGIC_VECTOR(TO_UNSIGNED(I, c_factor_log))) = o_q_b( (I+1)*g_width_a-1 DOWNTO I*g_width_a ), 
                "readdata missmatch " & to_hstring(o_q_b) & " /= " & to_hstring(sv_mem.MemRead(i_addr_b & STD_LOGIC_VECTOR(TO_UNSIGNED(I, c_factor_log)))), ERROR);
            END LOOP;
          END IF;

          IF g_register = FALSE THEN
            WaitForClock(i_clock_a,1);
          END IF;
        END LOOP;
      END IF;

      --IF run("random_data_random_access") THEN
      --  Log(id, "start sequential write");
      --END IF;

    END LOOP;
    ReportAlerts;
    check(GetAffirmCount > 0, "test not selfchecking", FAILURE);
    check(GetAlertCount = 0,  "test failed", FAILURE);

    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 5 ms);



  inst_dut: ENTITY WORK.ram_sdp
  GENERIC MAP (
    g_depth_a     => g_depth_a,
    g_depth_b     => g_depth_b,
    g_data_width_a  => g_width_a,
    g_data_width_b  => g_width_b,
    g_output_reg  => g_register
  )
  PORT MAP (
    address_a     => i_addr_a,
    address_b     => i_addr_b,
    clock         => i_clock_a,
    data_a        => i_data_a,
    wren_a        => i_wren_a,
    q_b           => o_q_b
  );


  inst_memory_model_a: PROCESS
  BEGIN
    WaitForClock(i_clock_a,1);
    IF i_wren_a THEN
      Log(id, "Memeory Write @" & TO_HSTRING(i_addr_a) & ": " & TO_HSTRING(i_data_a), DEBUG);
      IF g_width_a = g_width_b THEN 
        sv_mem.MemWrite(i_addr_a,i_data_a);
      ELSIF g_width_a > g_width_b THEN 
        FOR I IN 0 TO c_factor-1 LOOP 
          sv_mem.MemWrite(i_addr_a & STD_LOGIC_VECTOR(TO_UNSIGNED(I, c_factor_log)), i_data_a( (I+1)*g_width_b-1 DOWNTO I*g_width_b) );
        END LOOP;
      ELSIF g_width_a <= g_width_b THEN 
        sv_mem.MemWrite(i_addr_a,i_data_a);
      END IF;
    END IF;
  END PROCESS;


END ARCHITECTURE;
