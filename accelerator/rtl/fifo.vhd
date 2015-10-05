library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;
  use work.psl.all;

entity fifo is
  generic (
    width               : integer   := 1;
    depth               : integer   := 1;
    wr                  : std_logic := '0';
    fd                  : natural   := 1
  );
  port (
    cr                  : in  cr_in;
    put                 : in  std_logic;
    data_in             : in  std_logic_vector(width - 1 downto 0);
    pull                : in  std_logic;
    data_out            : out std_logic_vector(width - 1 downto 0);
    empty               : out std_logic;
    full                : out std_logic
  );
end fifo;

architecture logic of fifo is

  type fifo_int is record
    put_address         : unsigned(depth downto 0);
    pull_address        : unsigned(depth downto 0);
    empty               : std_logic;
    full                : std_logic;
  end record;

  signal q,  r          : fifo_int;

begin

  comb : process(all)
    variable v          : fifo_int;
  begin

    v                   := r;

    v.put_address       := r.put_address + u(put);
    v.pull_address      := r.pull_address + u(pull);

    v.empty             := is_empty(v.put_address, v.pull_address);
    v.full              := is_full(v.put_address + fd, v.pull_address) or is_full(v.put_address + fd + 1, v.pull_address);

    empty               <= r.empty;
    full                <= r.full;

    q                   <= v;

  end process comb;

  ram : entity work.ram_dual generic map (width, depth, wr)
  port map (
    clk                 => cr.clk,
    put                 => put,
    write_address       => r.put_address(depth - 1 downto 0),
    data_in             => data_in,
    read_address        => q.pull_address(depth - 1 downto 0),
    data_out            => data_out
  );

  reg : process(cr)
  begin
    if rising_edge(cr.clk) then
      if cr.rst then
        r.put_address   <= (others => '0');
        r.pull_address  <= (others => '0');
        r.empty         <= '1';
        r.full          <= '0';
      else
        r               <= q;
      end if;
    end if;
  end process;

end architecture logic;

-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;
  use work.psl.all;

entity fifo_unsigned is
  generic (
    width               : integer   := 1;
    depth               : integer   := 1;
    wr                  : std_logic := '0';
    fd                  : natural   := 1
  );
  port (
    cr                  : in  cr_in;
    put                 : in  std_logic;
    data_in             : in  unsigned(width - 1 downto 0);
    pull                : in  std_logic;
    data_out            : out unsigned(width - 1 downto 0);
    empty               : out std_logic;
    full                : out std_logic
  );
end fifo_unsigned;

architecture logic of fifo_unsigned is

  type fifo_int is record
    put_address         : unsigned(depth downto 0);
    pull_address        : unsigned(depth downto 0);
    empty               : std_logic;
    full                : std_logic;
  end record;

  signal q,  r          : fifo_int;

begin

  comb : process(all)
    variable v          : fifo_int;
  begin

    v                   := r;

    v.put_address       := r.put_address + u(put);
    v.pull_address      := r.pull_address + u(pull);

    v.empty             := is_empty(v.put_address, v.pull_address);
    v.full              := is_full(v.put_address + fd, v.pull_address) or is_full(v.put_address + fd + 1, v.pull_address);

    empty               <= r.empty;
    full                <= r.full;

    q                   <= v;

  end process comb;

  ram : entity work.ram_dual_unsigned generic map (width, depth, wr)
  port map (
    clk                 => cr.clk,
    put                 => put,
    write_address       => r.put_address(depth - 1 downto 0),
    data_in             => data_in,
    read_address        => q.pull_address(depth - 1 downto 0),
    data_out            => data_out
  );

  reg : process(cr)
  begin
    if rising_edge(cr.clk) then
      if cr.rst then
        r.put_address   <= (others => '0');
        r.pull_address  <= (others => '0');
        r.empty         <= '1';
        r.full          <= '0';
      else
        r               <= q;
      end if;
    end if;
  end process;

end architecture logic;
