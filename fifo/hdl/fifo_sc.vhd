LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

--LIBRARY altera_mf;
--USE altera_mf.all;

ENTITY fifo_sc IS
  GENERIC (
    g_wr_width        : INTEGER := 8;
    g_wr_depth        : INTEGER := 256;
    g_rd_width        : INTEGER := 8
  );
	PORT
	(
		clock		          : IN  STD_LOGIC ;
		data		          : IN  STD_LOGIC_VECTOR (g_wr_width-1 DOWNTO 0);
		rdreq		          : IN  STD_LOGIC ;
		sclr		          : IN  STD_LOGIC ;
		wrreq		          : IN  STD_LOGIC ;
		almost_empty		  : OUT STD_LOGIC ;
		almost_full		    : OUT STD_LOGIC ;
		empty		          : OUT STD_LOGIC ;
		full		          : OUT STD_LOGIC ;
		q		              : OUT STD_LOGIC_VECTOR (g_rd_width-1  DOWNTO 0);
		usedw		          : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END ENTITY fifo_sc;

ARCHITECTURE rtl OF fifo_sc IS 
  TYPE t_mem IS ARRAY (0 TO g_wr_depth-1) OF STD_LOGIC_VECTOR(g_wr_width-1 DOWNTO 0);
  SIGNAL ram : t_mem;

  SUBTYPE index_type IS INTEGER RANGE t_mem'RANGE;
  SIGNAL r_head     : index_type;
  SIGNAL r_tail     : index_type;
  SIGNAL s_empty    : STD_LOGIC;
  SIGNAL s_full     : STD_LOGIC;
  SIGNAL s_usedw    : INTEGER RANGE 0 TO t_mem'HIGH;
  
  PROCEDURE p_incr(
    SIGNAL index : INOUT index_type
  ) IS
  BEGIN
    IF index = index_type'HIGH THEN
      index <= index_type'LOW;
    ELSE 
      index <= index+1;
    END IF;
  END PROCEDURE;
  
  --  TODO
BEGIN
  empty        <= s_empty;
  full         <= s_full;
  almost_empty <= '1' WHEN s_usedw < 10 ELSE '0';
  almost_full  <= '1' WHEN s_usedw > g_wr_width - 10 ELSE '0';
  s_empty      <= '1' WHEN s_usedw = 0 ELSE '0';
  s_full       <= '1' WHEN s_usedw = g_wr_depth-1 ELSE '0';
  usedw        <= STD_LOGIC_VECTOR(TO_UNSIGNED(s_usedw, 32));


  proc_head: PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF sclr = '1' THEN
        r_head <= 0;
      ELSE
        IF wrreq = '1' AND s_full = '0' THEN
          p_incr(r_head);
        END IF;
      END IF;
    END IF;
  END PROCESS;


  proc_tail: PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      IF sclr = '1' THEN
        r_tail <= 0;
      ELSE
        IF rdreq = '1' AND s_empty = '0' THEN
          p_incr(r_tail);
        END IF;
      END IF;
    END IF;
  END PROCESS;

  proc_ram: PROCESS(clock)
  BEGIN
    IF RISING_EDGE(clock) THEN
      ram(r_head) <= data;
      q <= ram(r_tail);
    END IF;
  END PROCESS;

  proc_count: PROCESS(ALL)
  BEGIN
    IF r_head < r_tail THEN
      s_usedw <= r_head - r_tail + g_wr_depth;
    ELSE
      s_usedw <= r_head - r_tail;
    END IF;
  END PROCESS;

END ARCHITECTURE rtl;

