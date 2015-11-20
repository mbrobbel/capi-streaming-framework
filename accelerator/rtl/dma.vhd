library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;
  use work.psl.all;
  use work.dma_package.all;

entity dma is
  port (
    i                                                   : in  dma_in;
    o                                                   : out dma_out
  );
end entity dma;

architecture logic of dma is

  signal q, r                                           : dma_int;
  signal re                                             : dma_ext;

  alias write                                           : std_logic is i.r.tag(PSL_TAG_WIDTH - 1);
  alias tag                                             : unsigned(DMA_TAG_WIDTH - 1 downto 0) is i.r.tag(DMA_TAG_WIDTH - 1 downto 0);

begin

  comb : process(all)
    variable v                                          : dma_int;
  begin

----------------------------------------------------------------------------------------------------------------------- default assignments

    v                                                   := r;
    v.read                                              := '0';
    v.read_touch                                        := '0';
    v.write                                             := '0';
    v.write_touch                                       := '0';
    v.o.dc.read.valid                                   := '0';
    v.o.dc.write.valid                                  := '0';

    v.id                                                := r.id + u(i.cd.read.valid or i.cd.write.request.valid);
    v.read_credits                                      := r.read_credits + u(i.r.valid and not(write));
    v.write_credits                                     := r.write_credits + u(i.r.valid and write);
    v.rt.available                                      := not is_full(r.rt.tag, r.rb.pull_address);
    v.wt.available                                      := not is_full(r.wt.tag, r.wb.pull_address);
    v.rse.engine(r.rse.pull_engine).touch.count         := r.rse.engine(r.rse.pull_engine).touch.count + u(r.read and not(r.read_touch));
    v.wse.engine(r.wse.pull_engine).touch.count         := r.wse.engine(r.wse.pull_engine).touch.count + u(r.write and not(r.write_touch));

    if i.b.rad(0) then
      v.o.b.rdata                                       := re.wb.data(1023 downto 512);
    else
      v.o.b.rdata                                       := re.wb.data(511 downto 0);
    end if;

----------------------------------------------------------------------------------------------------------------------- select read/write

    if l(r.rse.active_count > 0 and r.wse.active_count > 0 and v.read_credits > 0 and v.write_credits > 0) and v.rt.available and v.wt.available then
      v.read                                            := not(DMA_WRITE_PRIORITY);
      v.write                                           := DMA_WRITE_PRIORITY;
    elsif v.rt.available and l(r.rse.active_count > 0 and v.read_credits > 0) then
      v.read                                            := '1';
    elsif v.wt.available and l(r.wse.active_count > 0 and v.write_credits > 0) then
      v.write                                           := '1';
    end if;

    if v.read then
      v.o.c.tag                                         := "0" & r.rt.tag(DMA_TAG_WIDTH - 1 downto 0);
    else
      v.o.c.tag                                         := "1" & r.wt.tag(DMA_TAG_WIDTH - 1 downto 0);
    end if;

    v.o.c.valid                                         := v.read or v.write;
    v.read_credits                                      := v.read_credits - u(v.read);
    v.write_credits                                     := v.write_credits - u(v.write);
    v.rt.tag                                            := r.rt.tag + u(v.read);
    v.wt.tag                                            := r.wt.tag + u(v.write);

----------------------------------------------------------------------------------------------------------------------- move requests to stream engines

    for stream in 0 to DMA_READ_ENGINES - 1 loop
      if not(re.rq(stream).empty) and r.rse.free(stream) then
        v.rse.free(stream)                              := '0';
        v.rse.ready(stream)                             := '1';
        v.rse.engine(stream).hold                       := (others => '0');
        v.rse.engine(stream).touch.touch                := '0';
        v.rse.engine(stream).touch.count                := (others => '0');
        v.rse.engine(stream).touch.address              := re.rq(stream).request.address + PSL_PAGESIZE;
        v.rse.engine(stream).request                    := re.rq(stream).request;
      end if;
    end loop;

    for stream in 0 to DMA_WRITE_ENGINES - 1 loop
      if not(re.wq(stream).empty) and r.wse.free(stream) then
        v.wse.free(stream)                              := '0';
        v.wse.ready(stream)                             := '1';
        v.wse.engine(stream).hold                       := (others => '0');
        v.wse.engine(stream).touch.touch                := '0';
        v.wse.engine(stream).touch.count                := (others => '0');
        v.wse.engine(stream).touch.address              := re.wq(stream).request.address + PSL_PAGESIZE;
        v.wse.engine(stream).request                    := re.wq(stream).request;
      end if;
    end loop;

----------------------------------------------------------------------------------------------------------------------- select stream engine

    for stream in 0 to DMA_READ_ENGINES - 1 loop
      if r.rse.ready(stream) and not(r.rse.free(stream)) then
        v.rse.pull_engine                               := stream;
      end if;
    end loop;
    v.rse.pull_stream                                   := (others => '0');
    v.rse.pull_stream(v.rse.pull_engine)                := '1';

    for stream in 0 to DMA_WRITE_ENGINES - 1 loop
      if r.wse.ready(stream) and not(r.wse.free(stream)) and not(re.wqb(stream).empty) then
        v.wse.pull_engine                               := stream;
      end if;
    end loop;
    v.wse.pull_stream                                   := (others => '0');
    v.wse.pull_stream(v.wse.pull_engine)                := '1';

    v.wqb(v.wse.pull_engine)                            := v.wqb(v.wse.pull_engine) - u(v.write and not(v.write_touch));

----------------------------------------------------------------------------------------------------------------------- generate commands

    if v.read then
      if DMA_READ_TOUCH and l(r.rse.engine(v.rse.pull_engine).touch.count = DMA_TOUCH_COUNT and r.rse.engine(v.rse.pull_engine).request.size + DMA_TOUCH_COUNT > PSL_PAGESIZE)
        and not(r.rse.engine(v.rse.pull_engine).touch.touch)
      then
        v.o.c.com                                       := PCO_TOUCH_I;
        v.o.c.ea                                        := r.rse.engine(v.rse.pull_engine).touch.address;
        v.read_touch                                    := '1';
        v.rse.engine(v.rse.pull_engine).touch.touch     := '1';
        v.rse.engine(v.rse.pull_engine).touch.address   := r.rse.engine(v.rse.pull_engine).touch.address + PSL_PAGESIZE;
      else
        v.read_touch                                    := '0';
        v.rse.engine(v.rse.pull_engine).touch.touch     := '0';
        v.o.c.ea                                        := r.rse.engine(v.rse.pull_engine).request.address;
        if r.rse.engine(v.rse.pull_engine).request.size < PSL_CACHELINE_BYTES then
          v.o.c.size                                    := r.rse.engine(v.rse.pull_engine).request.size(PSL_SIZE_WIDTH - 1 downto 0);
          v.o.c.com                                     := PCO_READ_PNA;
        else
          v.o.c.size                                    := PSL_CACHELINE_BYTES_OUT;
          v.o.c.com                                     := PCO_READ_CL_NA;
        end if;
        v.rse.free(v.rse.pull_engine)                   := l(r.rse.engine(v.rse.pull_engine).request.size <= PSL_CACHELINE_BYTES);
        v.rse.active_count                              := v.rse.active_count - u(l(r.rse.engine(v.rse.pull_engine).request.size <= PSL_CACHELINE_BYTES));
        v.rse.engine(v.rse.pull_engine).request.size    := r.rse.engine(v.rse.pull_engine).request.size - PSL_CACHELINE_BYTES;
        v.rse.engine(v.rse.pull_engine).request.address := r.rse.engine(v.rse.pull_engine).request.address + PSL_CACHELINE_BYTES;
        v.rse.ready(v.rse.pull_engine)                  := not(v.rse.free(v.rse.pull_engine) or l(r.rse.active_count > 1));
      end if;
    end if;

    if v.write then
      if DMA_WRITE_TOUCH and l(r.wse.engine(v.wse.pull_engine).touch.count = DMA_TOUCH_COUNT and r.wse.engine(v.wse.pull_engine).request.size + DMA_TOUCH_COUNT > PSL_PAGESIZE)
        and not(r.wse.engine(v.wse.pull_engine).touch.touch)
      then
        v.o.c.com                                       := PCO_TOUCH_I;
        v.o.c.ea                                        := r.wse.engine(v.wse.pull_engine).touch.address;
        v.write_touch                                   := '1';
        v.wse.engine(v.wse.pull_engine).touch.touch     := '1';
        v.wse.engine(v.wse.pull_engine).touch.address   := r.wse.engine(v.wse.pull_engine).touch.address + PSL_PAGESIZE;
      else
        v.write_touch                                   := '0';
        v.wse.engine(v.wse.pull_engine).touch.touch     := '0';
        v.o.c.ea                                        := r.wse.engine(v.wse.pull_engine).request.address;
        v.o.c.com                                       := PCO_WRITE_NA;
        if r.wse.engine(v.wse.pull_engine).request.size <= PSL_CACHELINE_BYTES then
          v.o.c.size                                    := r.wse.engine(v.wse.pull_engine).request.size(PSL_SIZE_WIDTH - 1 downto 0);
          v.wse.free(v.wse.pull_engine)                 := '1';
          v.wse.active_count                            := v.wse.active_count - 1;
        else
          v.o.c.size                                    := PSL_CACHELINE_BYTES_OUT;
        end if;
        v.wse.engine(v.wse.pull_engine).request.size    := r.wse.engine(v.wse.pull_engine).request.size - PSL_CACHELINE_BYTES;
        v.wse.engine(v.wse.pull_engine).request.address := r.wse.engine(v.wse.pull_engine).request.address + PSL_CACHELINE_BYTES;
        v.wse.ready(v.wse.pull_engine)                  := not(v.wse.free(v.wse.pull_engine) or l(r.wse.active_count > 1));
      end if;
    end if;

    v.rse.active_count                                  := u(ones(not(v.rse.free)), v.rse.active_count'length);
    v.wse.active_count                                  := (others => '0');
    for stream in 0 to DMA_WRITE_ENGINES - 1 loop
      v.wqb(stream)                                     := v.wqb(stream) + u(i.cd.write.data.valid and i.cd.write.data.stream(stream));
      v.wse.active_count                                := v.wse.active_count + u(l(v.wqb(stream) > 0) and not(v.wse.free(stream)));
    end loop;

    for stream in 0 to DMA_READ_ENGINES - 1 loop
      if not(v.rse.pull_stream(stream)) then
        if not(v.rse.free(stream)) and not(v.rse.ready(stream)) then
          v.rse.engine(stream).hold                     := r.rse.engine(stream).hold + u(v.read and not(v.rse.free(stream)));
          if v.rse.engine(stream).hold >= v.rse.active_count - 1 then
            v.rse.ready(stream)                         := '1';
            v.rse.engine(stream).hold                   := (others => '0');
          end if;
        end if;
      end if;
    end loop;

    for stream in 0 to DMA_WRITE_ENGINES - 1 loop
      if stream /= v.wse.pull_engine then
        if not(v.wse.free(stream)) and not(v.wse.ready(stream)) then
          v.wse.engine(stream).hold                     := r.wse.engine(stream).hold + u(v.write);
          if v.wse.engine(stream).hold >= v.wse.active_count - 1 then
            v.wse.ready(stream)                         := '1';
            v.wse.engine(stream).hold                   := (others => '0');
          end if;
        end if;
      end if;
    end loop;

--------------------------------------------------------------------------------------------------------------------- handle responses

    if i.r.valid and not(write) and
      l((i.r.tag <  r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0) and r.rb.put_flip =  r.rb.pull_flip) or
        (i.r.tag >= r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0) and r.rb.put_flip /= r.rb.pull_flip))
    then
      v.rb.put_flip                                     := not r.rb.put_flip;
    end if;
    if i.r.valid and write and
      l((tag <  r.wb.pull_address(DMA_TAG_WIDTH - 1 downto 0) and r.wb.put_flip =  r.wb.pull_flip) or
        (tag >= r.wb.pull_address(DMA_TAG_WIDTH - 1 downto 0) and r.wb.put_flip /= r.wb.pull_flip))
    then
      v.wb.put_flip                                     := not r.wb.put_flip;
    end if;

    if i.r.valid then
      if write then
        v.wb.status(idx(tag))                           := v.wb.put_flip;
      else
        v.rb.status(idx(tag))                           := v.rb.put_flip;
      end if;
    end if;

    if r.rb.status(idx(r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0))) = r.rb.pull_flip then
      v.o.dc.read.valid                                 := not re.rh.touch;
      v.rb.pull_address                                 := r.rb.pull_address + 1;
      if r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0) = (DMA_TAG_WIDTH - 1 downto 0 => '1') then
        v.rb.pull_flip                                  := not r.rb.pull_flip;
      end if;
    elsif r.wb.status(idx(r.wb.pull_address(DMA_TAG_WIDTH - 1 downto 0))) = r.wb.pull_flip then
      v.o.dc.write.valid                                := not re.wh.touch;
      v.wb.pull_address                                 := r.wb.pull_address + 1;
      if r.wb.pull_address(DMA_TAG_WIDTH - 1 downto 0) = (DMA_TAG_WIDTH - 1 downto 0 => '1') then
        v.wb.pull_flip                                  := not r.wb.pull_flip;
      end if;
    end if;

----------------------------------------------------------------------------------------------------------------------- outputs

    q                                                   <= v;

    o                                                   <= r.o;
    o.dc.id                                             <= q.id;
    o.dc.read.id                                        <= re.rh.id;
    o.dc.read.stream                                    <= slv(re.rh.stream);
    o.dc.read.data                                      <= re.rb.data1 & re.rb.data0;
    for stream in 0 to DMA_READ_ENGINES - 1 loop
      o.dc.read.full(stream)                            <= re.rq(stream).full;
    end loop;
    o.dc.write.id                                       <= re.wh.id;
    o.dc.write.stream                                   <= slv(re.wh.stream);
    for stream in 0 to DMA_WRITE_ENGINES - 1 loop
      o.dc.write.full(stream)                           <= re.wq(stream).full or l(r.wqb(stream) >= (2**DMA_WRITE_QUEUE_DEPTH - 4));
    end loop;


  end process comb;

----------------------------------------------------------------------------------------------------------------------- read queues

  rqs : for stream in 0 to DMA_READ_ENGINES - 1 generate
    rq : entity work.fifo_unsigned generic map (DMA_ID_WIDTH + PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH, DMA_WRITE_QUEUE_DEPTH, '1', 1)
      port map (
        cr                                              => i.cr,
        put                                             => i.cd.read.valid and i.cd.read.stream(stream),
        data_in                                          => r.id & i.cd.read.address & i.cd.read.size,
        pull                                            => not(re.rq(stream).empty) and r.rse.free(stream),
        data_out                                        => re.rq(stream).data,
        empty                                           => re.rq(stream).empty,
        full                                            => re.rq(stream).full
      );

    re.rq(stream).request.id                            <= re.rq(stream).data(DMA_ID_WIDTH + PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH - 1 downto PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH);
    re.rq(stream).request.address                       <= re.rq(stream).data(PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH - 1 downto DMA_SIZE_WIDTH);
    re.rq(stream).request.size                          <= re.rq(stream).data(DMA_SIZE_WIDTH - 1 downto 0);
  end generate rqs;
----------------------------------------------------------------------------------------------------------------------- write queues + buffers

  wqs : for stream in 0 to DMA_WRITE_ENGINES - 1 generate
    wq : entity work.fifo_unsigned generic map (DMA_ID_WIDTH + PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH, DMA_WRITE_QUEUE_DEPTH, '1', 1)
      port map (
        cr                                              => i.cr,
        put                                             => i.cd.write.request.valid and i.cd.write.request.stream(stream),
        data_in                                         => r.id & i.cd.write.request.address & i.cd.write.request.size,
        pull                                            => not(re.wq(stream).empty) and r.wse.free(stream),
        data_out                                        => re.wq(stream).data,
        empty                                           => re.wq(stream).empty,
        full                                            => re.wq(stream).full
      );

    re.wq(stream).request.id                            <= re.wq(stream).data(DMA_ID_WIDTH + PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH - 1 downto PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH);
    re.wq(stream).request.address                       <= re.wq(stream).data(PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH - 1 downto DMA_SIZE_WIDTH);
    re.wq(stream).request.size                          <= re.wq(stream).data(DMA_SIZE_WIDTH - 1 downto 0);

    wqb : entity work.fifo generic map (DMA_DATA_WIDTH, DMA_WRITE_BUFFER_DEPTH, '0', 1)
      port map (
        cr                                              => i.cr,
        put                                             => i.cd.write.data.valid and i.cd.write.data.stream(stream),
        data_in                                         => endian_swap(i.cd.write.data.data),
        pull                                            => r.write and not(r.write_touch) and r.wse.pull_stream(stream),
        data_out                                        => re.wqb(stream).data,
        empty                                           => re.wqb(stream).empty,
        full                                            => re.wqb(stream).full
      );
  end generate wqs;

----------------------------------------------------------------------------------------------------------------------- write buffer

  wb : entity work.ram_dual generic map (DMA_DATA_WIDTH, DMA_TAG_WIDTH, '0')
    port map (
      clk                                               => i.cr.clk,
      put                                               => r.write,
      write_address                                     => r.o.c.tag(DMA_TAG_WIDTH - 1 downto 0),
      data_in                                           => re.wqb(r.wse.pull_engine).data,
      read_address                                      => i.b.rtag(DMA_TAG_WIDTH - 1 downto 0),
      data_out                                          => re.wb.data
    );

----------------------------------------------------------------------------------------------------------------------- read buffer

  rb0 : entity work.ram_dual generic map (PSL_DATA_WIDTH, DMA_TAG_WIDTH, '0')
    port map (
      clk                                               => i.cr.clk,
      put                                               => i.b.wvalid and not(i.b.wad(0)),
      write_address                                     => i.b.wtag(DMA_TAG_WIDTH - 1 downto 0),
      data_in                                           => endian_swap(i.b.wdata),
      read_address                                      => r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0),
      data_out                                          => re.rb.data0
    );

  rb1 : entity work.ram_dual generic map (PSL_DATA_WIDTH, DMA_TAG_WIDTH, '0')
    port map (
      clk                                               => i.cr.clk,
      put                                               => i.b.wvalid and i.b.wad(0),
      write_address                                     => i.b.wtag(DMA_TAG_WIDTH - 1 downto 0),
      data_in                                           => endian_swap(i.b.wdata),
      read_address                                      => r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0),
      data_out                                          => re.rb.data1
    );

----------------------------------------------------------------------------------------------------------------------- command history

  rh : entity work.ram_dual_unsigned generic map (DMA_ID_WIDTH + DMA_READ_ENGINES + 1, DMA_TAG_WIDTH, '0')
    port map (
      clk                                               => i.cr.clk,
      put                                               => r.read,
      write_address                                     => r.o.c.tag(DMA_TAG_WIDTH - 1 downto 0),
      data_in                                           => r.rse.engine(r.rse.pull_engine).request.id & u(r.rse.pull_stream) & r.rse.engine(r.rse.pull_engine).touch.touch,
      read_address                                      => r.rb.pull_address(DMA_TAG_WIDTH - 1 downto 0),
      data_out                                          => re.rh.data
    );

  re.rh.id                                              <= re.rh.data(DMA_ID_WIDTH + DMA_READ_ENGINES downto DMA_READ_ENGINES + 1);
  re.rh.stream                                          <= re.rh.data(DMA_READ_ENGINES downto 1);
  re.rh.touch                                           <= re.rh.data(0);

  wh : entity work.ram_dual_unsigned generic map (DMA_ID_WIDTH + DMA_WRITE_ENGINES + 1, DMA_TAG_WIDTH, '0')
    port map (
      clk                                               => i.cr.clk,
      put                                               => r.write,
      write_address                                     => r.o.c.tag(DMA_TAG_WIDTH - 1 downto 0),
      data_in                                           => r.wse.engine(r.wse.pull_engine).request.id & u(r.wse.pull_stream) & r.wse.engine(r.wse.pull_engine).touch.touch,
      read_address                                      => r.wb.pull_address(DMA_TAG_WIDTH - 1 downto 0),
      data_out                                          => re.wh.data
    );

  re.wh.id                                              <= re.wh.data(DMA_ID_WIDTH + DMA_WRITE_ENGINES downto DMA_WRITE_ENGINES + 1);
  re.wh.stream                                          <= re.wh.data(DMA_WRITE_ENGINES downto 1);
  re.wh.touch                                           <= re.wh.data(0);

----------------------------------------------------------------------------------------------------------------------- reset & registers

  reg : process(i.cr)
  begin
    if rising_edge(i.cr.clk) then
      if i.cr.rst then
        dma_reset(r);
      else
        r                                               <= q;
      end if;
    end if;
  end process;

end architecture logic;
