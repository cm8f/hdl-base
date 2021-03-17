----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
LIBRARY OSVVM;
CONTEXT OSVVM.OSVVMContext;
LIBRARY vunit_lib;
CONTEXT vunit_lib.vunit_context;

ENTITY tb_uart IS
  GENERIC(
    runner_cfg    : STRING
  );
END tb_uart;

ARCHITECTURE testbench OF tb_uart IS

  -- Test Bench uses a 10 MHz Clock
  -- Want to interface to 115200 baud UART
  -- 10000000 / 115200 = 87 Clocks Per Bit.
  CONSTANT c_period         : TIME    := 10.0 ns;
  CONSTANT c_cycles_per_bit : INTEGER := 8;

  CONSTANT c_bit_period     : TIME := (c_cycles_per_bit+1) * c_period;

  SIGNAL s_clock            : STD_LOGIC                     := '0';
  SIGNAL s_reset            : STD_LOGIC                     := '1';
  SIGNAL s_tx_valid         : STD_LOGIC                     := '0';
  SIGNAL s_rx_valid         : STD_LOGIC                     := '0';
  SIGNAL s_tx_byte          : STD_LOGIC_VECTOR(7 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL s_tx_serial        : STD_LOGIC;
  SIGNAL s_tx_done          : STD_LOGIC;
  SIGNAL s_rx_divider       : STD_LOGIC;
  SIGNAL s_rx_byte          : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL s_rx_serial        : STD_LOGIC                     := '1';
  SIGNAL s_rx_serial_muxed  : STD_LOGIC                     := '1';
  SIGNAL s_mux_select       : STD_LOGIC;

  SIGNAL s_id               : AlertLogIDType;


  -- Low-level byte-write
  PROCEDURE UART_WRITE_BYTE (
    i_data_in       : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL o_serial : OUT STD_LOGIC) IS
  BEGIN
    -- Send Start Bit
    o_serial <= '0';
    WAIT FOR c_bit_period;
    -- Send Data Byte
    FOR ii IN 0 TO 7 LOOP
      o_serial    <= i_data_in(ii);
      WAIT FOR c_bit_period;
    END LOOP;  -- ii
    -- Send Stop Bit
    o_serial <= '1';
    WAIT FOR c_bit_period;
  END PROCEDURE UART_WRITE_BYTE;


BEGIN

  CreateClock(s_clock, c_period);
  CreateReset(s_reset, '1', s_clock, 10*c_period, 2 ns);

  proc_stim: PROCESS IS
  BEGIN
    test_runner_setup(runner, runner_cfg);
    s_id          <= GetAlertLogID(tb_uart'INSTANCE_NAME);
    s_tx_valid    <= '0';
    s_tx_byte     <= (OTHERS => '0');
    --s_tx_serial   <= '1';
    s_rx_serial   <= '1';

    WaitForLevel(s_reset, '0');
    WaitForClock(s_clock, 1);

    WHILE test_suite LOOP
      IF run("tx") THEN
        s_mux_select <= '1';
        FOR i IN 0 TO 127 LOOP
          s_tx_valid   <= '1';
          s_tx_byte <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 8));
          WaitForClock(s_clock, 1);
          s_tx_valid   <= '0';
          WaitForLevel(s_rx_valid,'1');
          AffirmIf(s_id, UNSIGNED(s_rx_byte) = I, "data error " & TO_HSTRING(s_rx_byte)  & "/=" & TO_STRING(I));
          WAIT FOR 2*c_period;
        END LOOP;
      END IF;

      IF run("rx") THEN
        s_mux_select <= '0';
        WaitForClock(s_clock, 1);
        -- Send a command to the UART
        FOR i IN 0 TO 127 LOOP
          WaitForClock(s_clock, 1);
          UART_WRITE_BYTE(STD_LOGIC_VECTOR(TO_UNSIGNED(I, 8)), s_rx_serial);
          WaitForLevel(s_rx_valid);
          AffirmIf(s_id, UNSIGNED(s_rx_byte) = I, "data error " & TO_HSTRING(s_rx_byte)  & "/=" & TO_STRING(I));
        END LOOP;
      END IF;
    END LOOP;

    ReportAlerts;
    check(GetAffirmCount > 0, "not selfchecking");
    check(GetAlertCount = 0, "errors occured");
    test_runner_cleanup(runner);
  END PROCESS;
  test_runner_watchdog(runner, 400 us);

  WITH s_mux_select SELECT s_rx_serial_muxed <=
    s_rx_serial WHEN '0', s_tx_serial WHEN OTHERS;



  -- Instantiate UART transmitter
  inst_uart_tx : ENTITY WORK.uart_tx
    port map (
      i_clock     => s_clock,
      i_data_valid=> s_tx_valid,
      i_cfg_divider => STD_LOGIC_VECTOR(TO_UNSIGNED(c_cycles_per_bit, 16)),
      i_data      => s_tx_byte,
      o_tx_busy   => open,
      o_uart_tx   => s_tx_serial,
      o_tx_done   => s_tx_done
      );


  -- Instantiate UART Receiver
  inst_uart_rx : ENTITY WORK.uart_rx
    port map (
      i_clock       => s_clock,
      i_cfg_divider => STD_LOGIC_VECTOR(TO_UNSIGNED(c_cycles_per_bit, 16)),
      i_uart_rx     => s_rx_serial_muxed,
      o_data_valid  => s_rx_valid,
      o_data        => s_rx_byte
      );


  END ARCHITECTURE;
