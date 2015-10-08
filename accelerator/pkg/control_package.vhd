library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.dma_package.all;
  use work.psl.all;
  use work.wed.all;
  use work.cu_package.all;

package control_package is

----------------------------------------------------------------------------------------------------------------------- io

  type control_ca_out is record
    reset           : std_logic;
  end record;

  type control_in is record
    clk             : std_logic;
    ha              : psl_control_in;
    dc              : dma_dc_out;
  end record;

  type control_out is record
    ca              : control_ca_out;
    ah              : psl_control_out;
    cd              : dma_cd_in;
  end record;

----------------------------------------------------------------------------------------------------------------------- internals

  type control_state is (
    idle,
    reset,
    wed,
    go,
    done
  );

  type control_int is record
    state           : control_state;
    start           : std_logic;
    wed             : wed_type;
    o               : control_out;
  end record;

  procedure control_reset (signal r : inout control_int);

end package control_package;

package body control_package is

  procedure control_reset (signal r : inout control_int) is
  begin
    r.state         <= reset;
    r.start         <= '0';
    r.o.ca.reset    <= '0';
    r.o.ah.running  <= '0';
    r.o.ah.done     <= '0';
  end procedure control_reset;

end package body control_package;
