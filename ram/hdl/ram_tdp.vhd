LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;


ENTITY ram_dp IS
  GENERIC(
    g_addr_width  : INTEGER := 8;
    g_data_width  : INTEGER := 32;
    g_output_reg  : BOOLEAN := TRUE
  );
	PORT
	(
		address_a   : IN STD_LOGIC_VECTOR (g_addr_width-1 DOWNTO 0);
		address_b   : IN STD_LOGIC_VECTOR (g_addr_width-1 DOWNTO 0);
		clock_a     : IN STD_LOGIC  := '1';
		clock_b     : IN STD_LOGIC  := '1';
		data_a      : IN STD_LOGIC_VECTOR (g_data_width-1 DOWNTO 0);
		data_b      : IN STD_LOGIC_VECTOR (g_data_width-1 DOWNTO 0);
		wren_a      : IN STD_LOGIC  := '0';
		wren_b      : IN STD_LOGIC  := '0';
		q_a         : OUT STD_LOGIC_VECTOR (g_data_width-1 DOWNTO 0);
		q_b         : OUT STD_LOGIC_VECTOR (g_data_width-1 DOWNTO 0)
	);
END ram_dp;

ARCHITECTURE SYN OF ram_dp IS

  type t_memory is array(0 to (2**g_addr_width)-1) of STD_LOGIC_VECTOR(g_data_width-1 downto 0);
  shared variable memory : t_memory;

begin

  PROCESS(clock_a)
  BEGIN
    IF rising_edge(clock_a) THEN
      IF wren_a = '1' THEN
        memory(to_integer(unsigned(address_a))) := data_a;
      END IF;
    END IF;
  END PROCESS;

  PROCESS(clock_b)
  BEGIN
    IF rising_edge(clock_b) THEN
      IF wren_b = '1' THEN
        memory(to_integer(unsigned(address_b))) := data_b;
      END IF;
    END IF;
  END PROCESS;

  GEN_OUTREG: IF g_output_reg GENERATE
    PROCESS(clock_a)
    BEGIN
      IF RISING_EDGE(clock_a) THEN
        q_a <= memory(to_integer(unsigned(address_a)));
      END IF;
    END PROCESS;

    PROCESS(clock_b)
    BEGIN
      IF RISING_EDGE(clock_b) THEN
        q_b <= memory(to_integer(unsigned(address_b)));
      END IF;
    END PROCESS;

  ELSE GENERATE
    q_a <= memory(to_integer(unsigned(address_a)));
    q_b <= memory(to_integer(unsigned(address_b)));
  END GENERATE;

end ARCHITECTURE;
