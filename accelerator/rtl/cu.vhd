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
  signal re                 : cu_ext;

begin

  comb : process(all)
    variable v              : cu_int;
  begin

----------------------------------------------------------------------------------------------------------------------- default assignments

    v                       := r;
    v.pull                  := '0';
    v.o.read.valid          := '0';
    v.o.write.request.valid := '0';
    v.o.write.data.valid    := '0';

----------------------------------------------------------------------------------------------------------------------- state machine

    case r.state is
      when idle =>
        if i.start then
          v.state           := copy;
          v.wed             := i.wed;
          v.o.done          := '0';
          read_cachelines   (v.o.read, i.wed.source, i.wed.size);
          write_cachelines  (v.o.write.request, i.wed.destination, i.wed.size);
        end if;

      when copy =>
        if not(re.fifo.empty) and not(i.write.full(0)) then
          v.pull            := '1';
          write_data        (v.o.write.data, re.fifo.data);
        end if;

        v.wed.size          := r.wed.size - u(i.write.valid);

        if v.wed.size = 0 then
          v.state           := done;
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

----------------------------------------------------------------------------------------------------------------------- fifo

  fifo0 : entity work.fifo generic map (DMA_DATA_WIDTH, 8, '1', 0)
    port map (
      cr.clk                => i.cr.clk,
      cr.rst                => i.start,
      put                   => i.read.valid,
      data_in               => i.read.data,
      pull                  => q.pull,
      data_out              => re.fifo.data,
      empty                 => re.fifo.empty,
      full                  => re.fifo.full
    );

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
