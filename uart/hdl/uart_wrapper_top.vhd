LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uart_wrapper_top IS 
  GENERIC(
    g_parity      : INTEGER RANGE 0 TO 2 := 0; -- 0 none, 1 odd, 2 even
    g_stopbits    : INTEGER RANGE 1 TO 2 := 1
  );
  PORT(
    i_clock       : IN  STD_LOGIC;
    i_cfg_divider : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    -- 
    o_rx_valid    : OUT STD_LOGIC;
    o_rx_data     : OUT STD_LOGIC_VECTOR(7 DOWNTO  0);
    i_tx_valid    : IN  STD_LOGIC;
    i_tx_data     : IN  STD_LOGIC_VECTOR(7 DOWNTO  0);
    o_tx_busy     : OUT STD_LOGIC;
    o_tx_done     : OUT STD_LOGIC;
    --
    i_uart_rx     : IN  STD_LOGIC;
    o_uart_tx     : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structural OF uart_wrapper_top IS 

BEGIN


  inst_uart_rx : ENTITY WORK.uart_rx 
    GENERIC MAP(
      g_parity    => g_parity,
      g_stopbits  => g_stopbits
    )
    PORT MAP(
      i_clock     => i_clock, 
      i_cfg_divider   => i_cfg_divider,
      i_uart_rx       => i_uart_rx,
      o_data_valid    => o_rx_valid,
      o_data          => o_rx_data
    );

  inst_uart_tx : ENTITY WORK.uart_tx
    GENERIC MAP(
      g_parity    => g_parity,
      g_stopbits  => g_stopbits
    )
    PORT MAP(
      i_clock     => i_clock,
      i_cfg_divider   => i_cfg_divider,
      i_data_valid    => i_tx_valid,
      i_data          => i_tx_data,
      o_tx_busy       => o_tx_busy,
      o_tx_done       => o_tx_done,
      o_uart_tx       => o_uart_tx
    );

END ARCHITECTURE;
