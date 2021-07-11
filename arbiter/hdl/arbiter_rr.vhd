LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY arbiter_rr IS 
  GENERIC(
    g_number_ports : INTEGER RANGE 1 TO 16
  );
  PORT(
    i_clock         : IN  STD_LOGIC;
    i_reset         : IN  STD_LOGIC;
    --
    i_request       : IN  STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
    o_grant         : OUT STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0)
  );
END ENTITY arbiter_rr;

ARCHITECTURE rtl OF arbiter_rr IS 

  SIGNAL s_double_request : STD_LOGIC_VECTOR(2*g_number_ports-1 DOWNTO 0);
  SIGNAL s_double_grant   : STD_LOGIC_VECTOR(2*g_number_ports-1 DOWNTO 0);
  SIGNAL r_priority       : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
  SIGNAL r_grant          : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);
  SIGNAL r_last_request   : STD_LOGIC_VECTOR(g_number_ports-1 DOWNTO 0);

BEGIN 
  -- source: https://fpgasite.wordpress.com/2016/04/19/vhdl-arbiter-iii/

  s_double_request      <= i_request & i_request;
  s_double_grant        <= s_double_request AND NOT STD_LOGIC_VECTOR((UNSIGNED(s_double_request) - UNSIGNED(r_priority)));

  proc_arbiter: PROCESS(i_clock, i_reset)
  BEGIN 
    IF i_reset THEN 
      r_priority        <= (OTHERS => '0');
      r_priority(0)     <= '1';
      r_last_request    <= (OTHERS => '0');
      r_grant           <= (OTHERS => '0');
    ELSIF RISING_EDGE(i_clock) THEN 
      IF r_last_request /= i_request THEN 
        r_last_request  <= i_request;
        r_priority      <= r_priority(r_priority'HIGH-1 DOWNTO 0) & r_priority(r_priority'HIGH);
        r_grant         <= s_double_grant(g_number_ports-1 DOWNTO 0) OR s_double_grant(2*g_number_ports-1 DOWNTO g_number_ports);
      END IF;
    END IF;
  END PROCESS;

  o_grant <= r_grant AND i_request;

END ARCHITECTURE;
