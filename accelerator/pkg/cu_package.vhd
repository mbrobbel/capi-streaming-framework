library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.psl.all;
  use work.dma_package.all;
  use work.wed.all;

package cu_package is

----------------------------------------------------------------------------------------------------------------------- io

  type cu_in is record
    cr        : cr_in;
    start     : std_logic;
    wed       : wed_type;
    id        : unsigned(DMA_ID_WIDTH - 1 downto 0);
    read      : dma_read_response;
    write     : dma_write_response;
  end record;

  type cu_out is record
    done      : std_logic;
    read      : dma_read_request;
    write     : dma_write_request;
  end record;

----------------------------------------------------------------------------------------------------------------------- internals

  type cu_state is (
    idle,
    done
  );

  type cu_int is record
    state     : cu_state;
    wed       : wed_type;
    o         : cu_out;
  end record;

  procedure cu_reset (signal r : inout cu_int);

end package cu_package;

package body cu_package is

  procedure cu_reset (signal r : inout cu_int) is
  begin
    r.state   <= idle;
    r.o.done  <= '0';
  end procedure cu_reset;

end package body cu_package;
