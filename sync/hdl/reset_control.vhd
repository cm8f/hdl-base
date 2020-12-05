LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY reset_control IS 
  GENERIC(
    g_pipeline_stages   : INTEGER RANGE 2 TO 10   := 5;
    g_use_sync_reset    : BOOLEAN                 := FALSE;
    g_reset_level       : STD_LOGIC               := '1'
  );
  PORT(
    i_clock             : IN    STD_LOGIC;
    i_reset             : IN    STD_LOGIC;
    o_reset             : OUT    STD_LOGIC  
  );
END ENTITY reset_control;

ARCHITECTURE rtl OF reset_control IS

  SIGNAL s_pipeline     : STD_LOGIC_VECTOR(g_pipeline_stages-1 DOWNTO 0);

BEGIN

  GEN_SYNC_RESET: IF g_use_sync_reset = TRUE GENERATE
    PROCESS(i_clock, i_reset)
    BEGIN
      IF RISING_EDGE(i_clock) THEN
        IF (i_reset = g_reset_level) THEN
          s_pipeline    <= (OTHERS => g_reset_level);
        ELSE 
          s_pipeline    <= (NOT g_reset_level) & s_pipeline(g_pipeline_stages-1 DOWNTO 1);
        END IF;
      END IF;
    END PROCESS;
    o_reset             <= s_pipeline(0);
  END GENERATE;

  GEN_ASYNC_RESET: IF g_use_sync_reset = FALSE GENERATE
    PROCESS(i_clock, i_reset)
    BEGIN
      IF (i_reset = g_reset_level) THEN
        s_pipeline    <= (OTHERS => g_reset_level);
      ELSIF RISING_EDGE(i_clock) THEN
        s_pipeline    <= (NOT g_reset_level) & s_pipeline(g_pipeline_stages-1 DOWNTO 1);
      END IF;
    END PROCESS;
    o_reset             <= s_pipeline(0);
  END GENERATE;

END ARCHITECTURE rtl;
