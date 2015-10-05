library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;
  use work.psl.all;
  use work.cu_package.all;
  use work.dma_package.all;

entity cu is
  port (
    i                       : in  cu_in;
    o                       : out cu_out
  );
end entity cu;

architecture logic of cu is

  signal q, r               : cu_int;

begin

  comb : process(all)
    variable v              : cu_int;
  begin

----------------------------------------------------------------------------------------------------------------------- default assignments

    v                       := r;
    v.o.read.valid          := '0';
    v.o.write.request.valid := '0';
    v.o.write.data.valid    := '0';

----------------------------------------------------------------------------------------------------------------------- state machine

    case r.state is
      when idle =>
        if i.start then
          v.state           := done;
          v.wed             := i.wed;
          v.o.done          := '0';
        end if;

      when done =>
        v.o.done            := '1';
        v.state             := idle;

      when others => null;
    end case;

----------------------------------------------------------------------------------------------------------------------- outputs

    -- drive input registers
    q                       <= v;

    -- outputs
    o                       <= r.o;

  end process;

----------------------------------------------------------------------------------------------------------------------- reset & registers

  reg : process(i.cr)
  begin
    if rising_edge(i.cr.clk) then
      if i.cr.rst then
        cu_reset(r);
      else
        r                   <= q;
      end if;
    end if;
  end process;

end architecture logic;
