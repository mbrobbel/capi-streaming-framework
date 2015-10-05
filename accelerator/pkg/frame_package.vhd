library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.psl.all;

package frame_package is

----------------------------------------------------------------------------------------------------------------------- io

  type frame_in is record
 -- c   : psl_command_in;
    b   : psl_buffer_in;
    r   : psl_response_in;
    mm  : psl_mmio_in;
    j   : psl_control_in;
  end record;

  type frame_out is record
    c   : psl_command_out;
    b   : psl_buffer_out;
    mm  : psl_mmio_out;
    j   : psl_control_out;
  end record;

end package frame_package;
