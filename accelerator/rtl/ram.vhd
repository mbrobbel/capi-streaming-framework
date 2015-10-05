library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.idx;

entity ram is
  generic (
    width                         : integer   := 1;
    depth                         : integer   := 1;
    wr                            : std_logic := '0'
  );
  port (
    clk                           : in  std_logic;
    put                           : in  std_logic;
    address                       : in  unsigned(depth - 1 downto 0);
    data_in                       : in  std_logic_vector(width - 1 downto 0);
    data_out                      : out std_logic_vector(width - 1 downto 0)
  );
end ram;

architecture logic of ram is
  type mem_type                   is array ((2 ** depth) - 1 downto 0) of std_logic_vector(width - 1 downto 0);
begin

  -- read new data
  w_r : if wr generate
    process(clk)
      variable mem                : mem_type := (others => (others => '0'));
    begin
      if rising_edge(clk) then
        if put then
          mem(idx(address))       := data_in;
        end if;
        data_out                  <= mem(idx(address));
      end if;
    end process;
  end generate w_r;

  -- read old data
  r_w : if not wr generate
    process(clk)
      variable mem                : mem_type := (others => (others => '0'));
    begin
      if rising_edge(clk) then
        data_out                  <= mem(idx(address));
        if put then
          mem(idx(address))       := data_in;
        end if;
      end if;
    end process;
  end generate r_w;

end architecture logic;

-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.idx;

entity ram_unsigned is
  generic (
    width                         : integer   := 1;
    depth                         : integer   := 1;
    wr                            : std_logic := '0'
  );
  port (
    clk                           : in  std_logic;
    put                           : in  std_logic;
    address                       : in  unsigned(depth - 1 downto 0);
    data_in                       : in  unsigned(width - 1 downto 0);
    data_out                      : out unsigned(width - 1 downto 0)
  );
end ram_unsigned;

architecture logic of ram_unsigned is
  type mem_type                   is array ((2 ** depth) - 1 downto 0) of unsigned(width - 1 downto 0);
begin

  -- read new data
  w_r : if wr generate
    process(clk)
      variable mem                : mem_type := (others => (others => '0'));
    begin
      if rising_edge(clk) then
        if put then
          mem(idx(address))       := data_in;
        end if;
        data_out                  <= mem(idx(address));
      end if;
    end process;
  end generate w_r;

  -- read old data
  r_w : if not wr generate
    process(clk)
      variable mem                : mem_type := (others => (others => '0'));
    begin
      if rising_edge(clk) then
        data_out                  <= mem(idx(address));
        if put then
          mem(idx(address))       := data_in;
        end if;
      end if;
    end process;
  end generate r_w;

end architecture logic;

-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.idx;

entity ram_dual is
  generic (
    width                         : integer   := 1;
    depth                         : integer   := 1;
    wr                            : std_logic := '0'
  );
  port (
    clk                           : in  std_logic;
    put                           : in  std_logic;
    write_address                 : in  unsigned(depth - 1 downto 0);
    data_in                       : in  std_logic_vector(width - 1 downto 0);
    read_address                  : in  unsigned(depth - 1 downto 0);
    data_out                      : out std_logic_vector(width - 1 downto 0)
  );
end ram_dual;

architecture logic of ram_dual is
  type mem_type                   is array ((2 ** depth) - 1 downto 0) of std_logic_vector(width - 1 downto 0);
  shared variable mem             : mem_type := (others => (others => '0'));
begin

  -- read new data
  w_r : if wr generate
    process(clk)
    begin
      if rising_edge(clk) then
        if put then
          mem(idx(write_address)) := data_in;
        end if;
        data_out                  <= mem(idx(read_address));
      end if;
    end process;
  end generate w_r;

  -- read old data
  r_w : if not wr generate
    process(clk)
    begin
      if rising_edge(clk) then
        data_out                  <= mem(idx(read_address));
        if put then
          mem(idx(write_address)) := data_in;
        end if;
      end if;
    end process;
  end generate r_w;

end architecture logic;

-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.idx;

entity ram_dual_unsigned is
  generic (
    width                         : integer   := 1;
    depth                         : integer   := 1;
    wr                            : std_logic := '0'
  );
  port (
    clk                           : in  std_logic;
    put                           : in  std_logic;
    write_address                 : in  unsigned(depth - 1 downto 0);
    data_in                       : in  unsigned(width - 1 downto 0);
    read_address                  : in  unsigned(depth - 1 downto 0);
    data_out                      : out unsigned(width - 1 downto 0)
  );
end ram_dual_unsigned;

architecture logic of ram_dual_unsigned is
  type mem_type                   is array ((2 ** depth) - 1 downto 0) of unsigned(width - 1 downto 0);
  shared variable mem             : mem_type := (others => (others => '0'));
begin

  -- read new data
  w_r : if wr generate
    process(clk)
    begin
      if rising_edge(clk) then
        if put then
          mem(idx(write_address)) := data_in;
        end if;
        data_out                  <= mem(idx(read_address));
      end if;
    end process;
  end generate w_r;

  -- read old data
  r_w : if not wr generate
    process(clk)
    begin
      if rising_edge(clk) then
        data_out                  <= mem(idx(read_address));
        if put then
          mem(idx(write_address)) := data_in;
        end if;
      end if;
    end process;
  end generate r_w;

end architecture logic;
