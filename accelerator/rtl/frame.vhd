library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;
  use work.psl.all;
  use work.control_package.all;
  use work.mmio_package.all;
  use work.dma_package.all;
  use work.frame_package.all;

entity frame is
  port (
    ha        : in  frame_in;
    ah        : out frame_out
  );
end entity frame;

architecture logic of frame is

  signal cr   : cr_in;
  signal ci   : control_in;
  signal co   : control_out;
  signal mi   : mmio_in;
  signal mo   : mmio_out;
  signal di   : dma_in;
  signal do   : dma_out;
  signal rc   : unsigned(63 downto 0);

begin

----------------------------------------------------------------------------------------------------------------------- clock/reset

  cr.clk      <= ha.j.pclock;
  cr.rst      <= co.ca.reset;

----------------------------------------------------------------------------------------------------------------------- control

  ci.clk      <= cr.clk;
  ci.ha       <= ha.j;
  ci.dc       <= do.dc;

  c0          : entity work.control port map (ci, co);

  ah.j        <= co.ah;

----------------------------------------------------------------------------------------------------------------------- mmio

  mi.cr       <= cr;
  mi.ha       <= ha.mm;
  mi.ac.data  <= slv(rc);

  m0          : entity work.mmio port map (mi, mo);

  ah.mm       <= mo.ah;

----------------------------------------------------------------------------------------------------------------------- dma

  di.cr       <= cr;
--di.c        <= ha.c;
  di.b        <= ha.b;
  di.r        <= ha.r;
  di.cd       <= co.cd;

  d0          : entity work.dma port map (di, do);

  ah.c        <= do.c;
  ah.b        <= do.b;

----------------------------------------------------------------------------------------------------------------------- reset & registers

  reg : process(cr)
  begin
    if rising_edge(cr.clk) then
      if cr.rst then
        rc    <= (others => '0');
      else
        -- debug counter
        if ha.r.valid then
          rc  <= rc + 1;
        end if;
      end if;
    end if;
  end process;

end architecture logic;
