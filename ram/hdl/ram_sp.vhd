LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ram_sp IS
  GENERIC(
    g_addr_width  : INTEGER :=  8;
    g_data_width  : INTEGER := 32;
    g_output_reg  : BOOLEAN := FALSE
  );
  PORT (
    address       : IN STD_LOGIC_VECTOR (g_addr_width-1 DOWNTO 0);
    clock         : IN STD_LOGIC  := '1';
    data          : IN STD_LOGIC_VECTOR (g_data_width-1 DOWNTO 0);
    wren          : IN STD_LOGIC ;
    q             : OUT STD_LOGIC_VECTOR (g_data_width-1 DOWNTO 0)
  );
END ram_sp;


ARCHITECTURE SYN OF ram_sp IS

  type t_memory is array(0 to (2**g_addr_width)-1) of STD_LOGIC_VECTOR(g_data_width-1 downto 0);
  shared variable memory : t_memory;

begin

  PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF wren = '1' THEN
        memory(to_integer(unsigned(address))) := data;
      END IF;
    END IF;
  END PROCESS;


  GEN_OUTREG: IF g_output_reg GENERATE
    PROCESS(clock)
    BEGIN
      IF RISING_EDGE(clock) THEN
        q <= memory(to_integer(unsigned(address)));
      END IF;
    END PROCESS;
  ELSE GENERATE
    q <= memory(to_integer(unsigned(address)));
  END GENERATE;

END ARCHITECTURE;
