LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;

ENTITY ram_sdp IS
  GENERIC (
    g_depth_a  : INTEGER := 8;
    g_depth_b  : INTEGER := 8;
    g_output_reg    : BOOLEAN := FALSE;
    g_data_width_a  : INTEGER := 8;
    g_data_width_b  : INTEGER := 8
  );
  PORT (
    address_a       : IN  STD_LOGIC_VECTOR(INTEGER(ceil(log2(REAL(g_depth_a))))-1 DOWNTO 0);
    address_b       : IN  STD_LOGIC_VECTOR(INTEGER(ceil(log2(REAL(g_depth_b))))-1 DOWNTO 0);
    clock           : IN  STD_LOGIC;
    data_a          : IN  STD_LOGIC_VECTOR(g_data_width_a-1 DOWNTO 0);
    wren_a          : IN  STD_LOGIC;
    q_b             : OUT STD_LOGIC_VECTOR(g_data_width_b-1 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE rtl OF ram_sdp IS
  CONSTANT c_factor : INTEGER := maximum(g_data_width_a,g_data_width_b) / minimum(g_data_width_a, g_data_width_b);
  CONSTANT c_length : INTEGER := minimum(g_data_width_a, g_data_width_b);
  CONSTANT c_ram_depth : INTEGER := minimum(g_depth_a, g_depth_b);

  TYPE word_t IS ARRAY (0 TO c_factor-1) OF STD_LOGIC_VECTOR(c_length-1 DOWNTO 0);
  TYPE ram_t  IS ARRAY (0 TO c_ram_depth-1) OF word_t;

  SIGNAL ram : ram_t;

  SIGNAL s_wr_in : word_t;
  SIGNAL s_rd_dout : STD_LOGIC_VECTOR(g_data_width_b-1 DOWNTO 0);

BEGIN

  --====================================================================
  --= write size greater read size
  --====================================================================
  gen_wr_greater: IF g_data_width_a >= g_data_width_b GENERATE
    gen_map: FOR I IN 0 TO c_factor-1 GENERATE
      s_wr_in(I)   <= data_a( (I+1)*g_data_width_b-1 DOWNTO I*g_data_width_b);
    END GENERATE;

    PROCESS(clock)
    BEGIN
      IF RISING_EDGE(clock) THEN
        IF wren_a = '1' THEN
          ram(TO_INTEGER(UNSIGNED(address_a))) <= s_wr_in;
        END IF;
      END IF;
    END PROCESS;

    gen_out_wrgreater: IF g_output_reg = True GENERATE
      PROCESS(clock)
      BEGIN
        IF RISING_EDGE(clock) THEN
          q_b <= ram(TO_INTEGER(UNSIGNED(address_b))/c_factor)(TO_INTEGER(UNSIGNED(address_b)) MOD c_factor);
        END IF;
      END PROCESS;

    ELSE GENERATE
      q_b <= ram(TO_INTEGER(UNSIGNED(address_b))/c_factor)(TO_INTEGER(UNSIGNED(address_b)) MOD c_factor);
    END GENERATE;

  END GENERATE;



  --====================================================================
  --= read size greater write size
  --====================================================================
  gen_rd_greater: IF g_data_width_a < g_data_width_b GENERATE
    gen_map: FOR I IN 0 TO c_factor-1 GENERATE
      s_rd_dout( (I+1)*g_data_width_a -1 DOWNTO I*g_data_width_a) <= ram(TO_INTEGER(UNSIGNED(address_b)))(I);
    END GENERATE;

    PROCESS(clock)
    BEGIN
      IF RISING_EDGE(clock) THEN
        IF wren_a = '1' THEN
          ram(to_INTEGER(UNSIGNED(address_a))/c_factor)(TO_INTEGER(UNSIGNED(address_a)) MOD c_factor) <= data_a;
        END IF;
      END IF;
    END PROCESS;

    gen_out_wrgreater: IF g_output_reg = True GENERATE
      PROCESS(clock)
      BEGIN
        IF RISING_EDGE(clock) THEN
          q_b <= s_rd_dout;
        END IF;
      END PROCESS;

    ELSE GENERATE
      q_b <= s_rd_dout;
    END GENERATE;

  END GENERATE;

END ARCHITECTURE;
