LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uart_rx IS 
  GENERIC(
    g_parity      : INTEGER RANGE 0 TO 2 := 0; -- 0 none, 1 odd, 2 even
    g_stopbits    : INTEGER RANGE 1 TO 2 := 1
  );
  PORT(
    i_clock       : IN  STD_LOGIC;
    i_cfg_divider : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    i_uart_rx     : IN  STD_LOGIC;
    o_data_valid  : OUT STD_LOGIC;
    o_data        : OUT STD_LOGIC_VECTOR(7 DOWNTO  0)
  );
END ENTITY;

ARCHITECTURE rtl OF uart_rx IS 

  SIGNAL r_rx_data_p           : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"F";
  SIGNAL r_rx_data             : STD_LOGIC;

  SIGNAL r_data_byte           : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL r_bit_idx             : INTEGER RANGE 0 TO 7 := 0;
  SIGNAL r_rx_valid            : STD_LOGIC;
  SIGNAL r_halfperiod_counter  : UNSIGNED(15 DOWNTO 0);

  TYPE t_state IS (idle, start_bit, data_bits, stop_bit);
  SIGNAL sm_state : t_state := idle;
BEGIN

  --==========================================================================-
  --= input pipeline
  --==========================================================================-
  proc_input: PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      r_rx_data_p(0)    <= i_uart_rx;    
      r_rx_data         <= r_rx_data_p(3);
      FOR I IN 1 TO r_rx_data_p'LEFT LOOP
        r_rx_data_p(I)  <= r_rx_data_p(I-1);
      END LOOP;
    END IF;
  END PROCESS proc_input;



  --==========================================================================-
  --= rx control 
  --==========================================================================-
  proc_rx_control : PROCESS(i_clock)
  BEGIN
    IF RISING_EDGE(i_clock) THEN
      r_rx_valid                  <= '0';

      CASE (sm_state) IS 
        WHEN idle => 
          r_halfperiod_counter    <= UNSIGNED(i_cfg_divider)/2-1;
          sm_state                <= idle;
          r_bit_idx               <= 0;

          IF r_rx_data = '0' THEN
            -- deassertion of input data => start bit
            sm_state <= start_bit;
          END IF;

        WHEN start_bit => 
          -- wait for half period and check for 0 again
          r_halfperiod_counter      <= r_halfperiod_counter-1;
          sm_state                  <= start_bit;
          IF r_halfperiod_counter = 0 THEN
            IF r_rx_data = '0' THEN
              -- it is truely a start bit => progress
              sm_state              <= data_bits;
              r_halfperiod_counter  <= UNSIGNED(i_cfg_divider);
            ELSE 
              -- false alarm, return to home
              sm_state              <= idle;
            END IF;
          END IF;

        WHEN data_bits => 
          sm_state                  <= data_bits;
          r_halfperiod_counter      <= r_halfperiod_counter-1;

          IF r_halfperiod_counter = 0 THEN
            r_halfperiod_counter    <= UNSIGNED(i_cfg_divider);
            r_data_byte(r_bit_idx)  <= r_rx_data;
            IF r_bit_idx = 7 THEN 
              sm_state              <= stop_bit;
            ELSE 
              r_bit_idx               <= r_bit_idx+1;
            END IF;
          END IF;

        WHEN stop_bit => 
          r_halfperiod_counter      <= r_halfperiod_counter-1;
          sm_state                  <= stop_bit;

          IF r_halfperiod_counter = 0 THEN
            sm_state                <= idle;
            r_rx_valid              <= '1';
            r_halfperiod_counter    <= UNSIGNED(i_cfg_divider); 

          END IF;
      END CASE;
    END IF;
  END PROCESS proc_rx_control;

  PROCESS(i_clock)
  BEGIN 
    IF RISING_EDGE(i_clock) THEN 
      o_data_valid    <= r_rx_valid;
      IF r_rx_valid THEN 
        o_data          <= r_data_byte;
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;
