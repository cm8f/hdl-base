LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY OSVVM;
CONTEXT OSVVM.osvvmcontext;
LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;
CONTEXT vunit_lib.vc_context;
CONTEXT vunit_lib.com_context;

ENTITY tb_arbiter_rr IS 
  GENERIC (
    runner_cfg      : STRING;
    g_number_ports  : INTEGER RANGE 1 TO 16 := 2
  );
END ENTITY;

ARCHITECTURE rtl OF tb_arbiter_rr IS 

  SIGNAL i_clock    : STD_LOGIC;
  SIGNAL i_reset    : STD_LOGIC := '1';
  SIGNAL i_request  : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
  SIGNAL o_grant    : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
  SIGNAL s_id       : AlertLogIDType;

BEGIN 

  --==================================================================== 
  --= clocking 
  --====================================================================
  CreateClock(i_clock, 10 ns);
  CreateReset(i_reset, '1', i_clock, 100 ns, 0 ns);



  --====================================================================
  --= stimulus
  --====================================================================
  proc_stim: PROCESS 
    VARIABLE v_old_grant : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
  BEGIN 
    test_runner_setup(runner, runner_cfg);
    s_id <= GetAlertLogID(tb_arbiter_rr'INSTANCE_NAME);
    i_request <= (OTHERS => '0');
    WaitforLevel(i_reset, '0');
    WaitForClock(i_clock, 1);

    --
    IF run("single_port_access") THEN 
      FOR i IN 0 TO g_number_ports-1 LOOP 
        i_request     <= (OTHERS => '0');
        i_request(I)  <= '1';
        WaitForClock(i_clock, 1);
        WAIT FOR std.env.resolution_limit;
        AffirmIf(s_id, o_grant(I) = '1', "no grant received");
        WaitForClock(i_clock, 2);
        AffirmIf(s_id, o_grant(I) = '1', "no grant hold");
        i_request     <= (OTHERS => '0');
        WAIT FOR std.env.resolution_limit;
        AffirmIf(s_id, o_grant(I) = '0', "no grant released");
        WaitForClock(i_clock, 2);
      END LOOP;
    END IF;

    --
    IF run("all_ports_simultan") THEN 
      i_request <= (OTHERS => '1');
      WAIT FOR 0 ns;
      WHILE UNSIGNED(i_request) /= 0 LOOP 
        WaitForClock(i_clock, 1);
        WAIT FOR std.env.resolution_limit;
        AffirmIf(s_id, OneHot(o_grant), "no grant asserted");
        v_old_grant := o_grant;
        WaitForClock(i_clock, 1);
        WAIT FOR std.env.resolution_limit;
        AffirmIf(s_id, o_grant = v_old_grant, "grant changed from " & TO_string(v_old_grant) & " to " & to_string(o_grant));
        i_request <= i_request AND NOT o_grant;
        WaitForClock(i_clock, 1);
        WAIT FOR std.env.resolution_limit;
        AffirmIf(s_id, o_grant /= v_old_grant, "grant did not change" ); 
      END LOOP;
      --WaitForClock(i_clock, 2);
      --AffirmIf(s_id, o_grant = v_old_grant, "grant changed from " & TO_string(v_old_grant) & " to " & to_string(o_grant));
      --i_request <= i_request AND NOT o_grant;


    END IF;

    ReportAlerts;
    check(GetAffirmCount > 0, "not selfchecking");
    check_equal(GetAlertCount, 0, "testcase failed");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 10 ms);

  proc_checker: PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN 
      AlertIfNot(s_id, ZeroOneHot(o_grant), "more than one bit grant high " & TO_STRING(o_grant));
    END IF;
  END PROCESS;



  --====================================================================
  --= device under test arbiter
  --====================================================================
  inst_dut : ENTITY WORK.arbiter_rr 
  GENERIC MAP(
    g_number_ports  => g_number_ports
  )
  PORT MAP(
    i_clock         => i_clock, 
    i_reset         => i_reset,
    i_request       => i_request,
    o_grant         => o_grant
  );

END ARCHITECTURE;
