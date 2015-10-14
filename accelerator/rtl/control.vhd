library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.functions.all;
  use work.psl.all;
  use work.wed.all;
  use work.control_package.all;
  use work.cu_package.all;
  use work.dma_package.all;

entity control is
  port (
    i                           : in  control_in;
    o                           : out control_out
  );
end entity control;

architecture logic of control is

  signal q, r                   : control_int;
  signal ci                     : cu_in;
  signal co                     : cu_out;

begin

  comb : process(all)
    variable v                  : control_int;
  begin

----------------------------------------------------------------------------------------------------------------------- default assignments

    v                           := r;
    v.o.cd.read.valid           := '0';
    v.o.cd.write.request.valid  := '0';
    v.o.cd.write.data.valid     := '0';

----------------------------------------------------------------------------------------------------------------------- control commands

    if  i.ha.val then
      case i.ha.com is
        when PCC_RESET =>
          v.state               := reset;
          v.o.ca.reset          := '1';
        when PCC_START =>
          v.state               := wed;
          v.o.ah.running        := '1';
          read_cacheline        (v.o.cd.read, i.ha.ea);
        when others =>
          null;
      end case;
    end if;

----------------------------------------------------------------------------------------------------------------------- afu state machine

    case r.state is
      when idle =>
        v.o.ah.done             := '0';
      when reset =>
        v.state                 := idle;
        v.o.ca.reset            := '0';
        v.o.ah.done             := '1';
      when wed =>
        if i.dc.read.valid then
          v.state               := go;
          wed_parse             (i.dc.read.data, v.wed);
          v.start               := '1';
        end if;
      when go =>
        v.start                 := '0';
        if co.done then
          write_byte            (v.o.cd.write, i.ha.ea, slv(x"01"));
          v.state               := done;
        else
          v.o.cd.read           := co.read;
          v.o.cd.write          := co.write;
        end if;
      when done =>
        if i.dc.write.valid then
          v.state               := idle;
          v.o.ah.running        := '0';
          v.o.ah.done           := '1';
        end if;
      when others =>
        null;
    end case;

----------------------------------------------------------------------------------------------------------------------- outputs

    -- drive input registers
    q                           <= v;

    -- output
    ci.start                    <= r.start;
    o                           <= r.o;

  end process;

----------------------------------------------------------------------------------------------------------------------- reset & registers

  reg : process(i.clk, r.o.ca.reset)
  begin
    if rising_edge(i.clk) then
      if r.o.ca.reset then
        control_reset(r);
      else
        r                       <= q;
      end if;
    end if;
  end process;

----------------------------------------------------------------------------------------------------------------------- cu

  ci.wed                        <= q.wed;
  ci.cr.clk                     <= i.clk;
  ci.cr.rst                     <= r.o.ca.reset;
  ci.id                         <= i.dc.id;
  ci.read                       <= i.dc.read;
  ci.write                      <= i.dc.write;

  cu0                           : entity work.cu port map (ci, co);

end architecture logic;
