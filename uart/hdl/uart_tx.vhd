LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY uart_tx IS 
  GENERIC(
    g_parity      : INTEGER RANGE 0 TO 2 := 0; -- 0 none, 1 odd, 2 even
    g_stopbits    : INTEGER RANGE 1 TO 2 := 1
  );
  PORT(
    i_clock       : IN  STD_LOGIC;
    i_cfg_divider : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    i_data_valid  : IN  STD_LOGIC;
    i_data        : IN  STD_LOGIC_VECTOR(7 DOWNTO  0);
    o_tx_busy     : OUT STD_LOGIC;
    o_tx_done     : OUT STD_LOGIC;
    o_uart_tx     : OUT STD_LOGIC
  );
END ENTITY uart_tx;

ARCHITECTURE rtl OF uart_tx IS

  TYPE t_state IS (idle, tx_start, tx_data, tx_stop);
  SIGNAL r_state  : t_state := idle;
  SIGNAL r_clk_count    : UNSIGNED(15 DOWNTO 0);
  SIGNAL r_bit_idx      : INTEGER RANGE 0 TO 7;
  SIGNAL r_tx_data_sr   : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL r_tx_done      : STD_LOGIC;

BEGIN

  proc_uart_tx: PROCESS(i_clock) 
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      r_tx_done           <= '0';
      CASE r_state IS 
        WHEN idle =>
          r_state         <= idle;
          o_tx_busy       <= '0';
          o_uart_tx       <= '1';
          r_clk_count     <= UNSIGNED(i_cfg_divider);

          IF i_data_valid = '1' THEN
            r_tx_data_sr  <= i_data;
            r_state       <= tx_start;
          END IF;

        WHEN tx_start =>
          r_state         <= tx_start;
          o_tx_busy       <= '1';
          o_uart_tx       <= '0';
          r_clk_count     <= r_clk_count -1;

          IF r_clk_count = 0 THEN
            r_state       <= tx_data;
            r_clk_count   <= UNSIGNED(i_cfg_divider);
          END IF;

        WHEN tx_data =>
          r_state         <= tx_data;
          o_uart_tx       <= r_tx_data_sr(r_bit_idx);
          r_clk_count     <= r_clk_count -1 ;

          IF r_clk_count = 0 THEN
            r_clk_count   <= UNSIGNED(i_cfg_divider);
            IF r_bit_idx < 7 THEN
              r_bit_idx   <= r_bit_idx + 1;
            ELSE
              r_bit_idx   <= 0;
              r_state     <= tx_stop;
            END IF;
          END IF;
          
        WHEN tx_stop =>
          r_state         <= tx_stop;
          o_uart_tx       <= '1';
          r_clk_count     <= r_clk_count -1 ;
          
          IF r_clk_count = 0 THEN
            r_tx_done     <= '1';
            r_state       <= idle;
          END IF;

      END CASE;
    END IF;
  END PROCESS;

  o_tx_done <= r_tx_done;

END ARCHITECTURE;
