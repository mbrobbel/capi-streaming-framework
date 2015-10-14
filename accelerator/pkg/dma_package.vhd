library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.psl.all;
  use work.functions.all;

package dma_package is

----------------------------------------------------------------------------------------------------------------------- dma parameters

  constant DMA_SIZE_WIDTH           : natural   := 32;    -- number of bits for dma size port - should be log2 of largest request
  constant DMA_ID_WIDTH             : natural   := 32;    -- number of bits for unique id field - should be log2 of total requests
  constant DMA_READ_QUEUE_DEPTH     : natural   := 8;     -- number of address bits for read queues
  constant DMA_WRITE_QUEUE_DEPTH    : natural   := 8;     -- number of address bits for write queues
  constant DMA_WRITE_BUFFER_DEPTH   : natural   := 8;     -- number of address bits for write buffers - should be larger than write queue depth if requests are mostly more than one cacheline

  constant DMA_DATA_WIDTH           : natural   := 1024;  -- number of bits for dma data port - don't change

  constant DMA_READ_ENGINES         : natural   := 1;     -- number of stream engines for reading
  constant DMA_WRITE_ENGINES        : natural   := 1;     -- number of stream engines for writing

  constant DMA_READ_CREDITS         : natural   := 32;    -- number of credits used for reading - recommended to be (31 or 32) - sum of credits can't exceed 64
  constant DMA_WRITE_CREDITS        : natural   := 32;    -- number of credits used for writing - recommended to be (32 or 33) - sum of credits can't exceed 64

  constant DMA_TOUCH_COUNT          : natural   := 1;     -- should be smaller than number of cachelines in page (512 by default on POWER8)

  constant DMA_READ_TOUCH           : std_logic := '0';   -- '1' enables pre-touching pages for large read requests
  constant DMA_WRITE_TOUCH          : std_logic := '0';   -- '1' enables pre-touching pages for large write requests

  constant DMA_WRITE_PRIORITY       : std_logic := '1';   -- '1' enables write priority - '0' enables read priority

  constant DMA_TAG_WIDTH            : natural   := PSL_TAG_WIDTH - 1;

  constant DMA_READ_CREDITS_WIDTH   : natural   := log2(DMA_READ_CREDITS) + 1;
  constant DMA_WRITE_CREDITS_WIDTH  : natural   := log2(DMA_WRITE_CREDITS) + 1;

  constant DMA_READ_ENGINES_WIDTH   : natural   := log2(DMA_READ_ENGINES) + 1;
  constant DMA_WRITE_ENGINES_WIDTH  : natural   := log2(DMA_WRITE_ENGINES) + 1;

----------------------------------------------------------------------------------------------------------------------- io

  type dma_read_request is record
    valid                           : std_logic;
    stream                          : std_logic_vector(DMA_READ_ENGINES - 1 downto 0);
    address                         : unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    size                            : unsigned(DMA_SIZE_WIDTH - 1 downto 0);
  end record;

  type dma_read_response is record
    valid                           : std_logic;
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);
    stream                          : std_logic_vector(DMA_READ_ENGINES - 1 downto 0);
    data                            : std_logic_vector(DMA_DATA_WIDTH - 1 downto 0);
    full                            : std_logic_vector(DMA_READ_ENGINES - 1 downto 0);
  end record;

  type dma_write_request_item is record
    valid                           : std_logic;
    stream                          : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
    address                         : unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    size                            : unsigned(DMA_SIZE_WIDTH - 1 downto 0);
  end record;

  type dma_write_data_item is record
    valid                           : std_logic;
    stream                          : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
    data                            : std_logic_vector(DMA_DATA_WIDTH - 1 downto 0);
  end record;

  type dma_write_request is record
    request                         : dma_write_request_item;
    data                            : dma_write_data_item;
  end record;

  type dma_write_response is record
    valid                           : std_logic;
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);
    stream                          : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
    full                            : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
  end record;

  type dma_cd_in is record
    read                            : dma_read_request;
    write                           : dma_write_request;
  end record;

  type dma_dc_out is record
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);
    read                            : dma_read_response;
    write                           : dma_write_response;
  end record;

  type dma_in is record
    cr                              : cr_in;
 -- c                               : psl_command_in;
    b                               : psl_buffer_in;
    r                               : psl_response_in;
    cd                              : dma_cd_in;
  end record;

  type dma_out is record
    c                               : psl_command_out;
    b                               : psl_buffer_out;
    dc                              : dma_dc_out;
  end record;

----------------------------------------------------------------------------------------------------------------------- stream engines

  type request_item is record
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);
    address                         : unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    size                            : unsigned(DMA_SIZE_WIDTH - 1 downto 0);
  end record;

  type touch_control is record
    touch                           : std_logic;
    count                           : unsigned(PSL_ERAT_WIDTH - 1 downto 0);
    address                         : unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
  end record;

  type read_stream_engine is record
    request                         : request_item;
    hold                            : unsigned(DMA_READ_ENGINES_WIDTH - 1 downto 0);
    touch                           : touch_control;
  end record;

  type write_stream_engine is record
    request                         : request_item;
    hold                            : unsigned(DMA_WRITE_ENGINES_WIDTH - 1 downto 0);
    touch                           : touch_control;
  end record;

  type read_stream_engines          is array (0 to DMA_READ_ENGINES - 1) of read_stream_engine;
  type write_stream_engines         is array (0 to DMA_WRITE_ENGINES - 1) of write_stream_engine;

  type read_stream_engines_control is record
    free                            : std_logic_vector(DMA_READ_ENGINES - 1 downto 0);
    active_count                    : unsigned(DMA_READ_ENGINES_WIDTH - 1 downto 0);
    ready                           : std_logic_vector(DMA_READ_ENGINES - 1 downto 0);
    pull_engine                     : natural;
    pull_stream                     : std_logic_vector(DMA_READ_ENGINES - 1 downto 0);
    engine                          : read_stream_engines;
  end record;

  type write_stream_engines_control is record
    free                            : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
    active_count                    : unsigned(DMA_WRITE_ENGINES_WIDTH - 1 downto 0);
    ready                           : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
    pull_engine                     : natural;
    pull_stream                     : std_logic_vector(DMA_WRITE_ENGINES - 1 downto 0);
    engine                          : write_stream_engines;
  end record;

----------------------------------------------------------------------------------------------------------------------- queues

  type queue_item is record
    data                            : unsigned(DMA_ID_WIDTH + PSL_ADDRESS_WIDTH + DMA_SIZE_WIDTH - 1 downto 0);
    request                         : request_item;
    empty                           : std_logic;
    full                            : std_logic;
  end record;

  type read_queues                  is array (0 to DMA_READ_ENGINES - 1) of queue_item;
  type write_queues                 is array (0 to DMA_WRITE_ENGINES - 1) of queue_item;

  type write_buffer_item is record
    data                            : std_logic_vector(DMA_DATA_WIDTH - 1 downto 0);
    full                            : std_logic;
    empty                           : std_logic;
  end record;

  type write_buffers                is array (0 to DMA_WRITE_ENGINES - 1) of write_buffer_item;
  type write_buffer_control         is array (0 to DMA_WRITE_ENGINES - 1) of unsigned(DMA_WRITE_BUFFER_DEPTH - 1 downto 0);

----------------------------------------------------------------------------------------------------------------------- tag control

  type tag_control is record
    available                       : std_logic;
    tag                             : unsigned(DMA_TAG_WIDTH downto 0);
  end record;

----------------------------------------------------------------------------------------------------------------------- response buffer

  type response_buffer_control is record
    put_flip                        : std_logic;
    pull_flip                       : std_logic;
    pull_address                    : unsigned(DMA_TAG_WIDTH downto 0);
    status                          : std_logic_vector(2 ** DMA_TAG_WIDTH - 1 downto 0);
  end record;

  type read_buffer_item is record
    data0                           : std_logic_vector(PSL_DATA_WIDTH - 1 downto 0);
    data1                           : std_logic_vector(PSL_DATA_WIDTH - 1 downto 0);
  end record;

----------------------------------------------------------------------------------------------------------------------- command history

  type read_history_item is record
    data                            : unsigned(DMA_ID_WIDTH + DMA_READ_ENGINES downto 0);
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);
    stream                          : unsigned(DMA_READ_ENGINES - 1 downto 0);
    touch                           : std_logic;
  end record;

  type write_history_item is record
    data                            : unsigned(DMA_ID_WIDTH + DMA_WRITE_ENGINES downto 0);
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);
    stream                          : unsigned(DMA_WRITE_ENGINES - 1 downto 0);
    touch                           : std_logic;
  end record;

----------------------------------------------------------------------------------------------------------------------- internals

  type dma_int is record
    id                              : unsigned(DMA_ID_WIDTH - 1 downto 0);

    read                            : std_logic;
    read_touch                      : std_logic;

    write                           : std_logic;
    write_touch                     : std_logic;

    read_credits                    : unsigned(DMA_READ_CREDITS_WIDTH - 1 downto 0);
    write_credits                   : unsigned(DMA_WRITE_CREDITS_WIDTH - 1 downto 0);

    wqb                             : write_buffer_control;

    rt                              : tag_control;
    wt                              : tag_control;

    rse                             : read_stream_engines_control;
    wse                             : write_stream_engines_control;

    rb                              : response_buffer_control;
    wb                              : response_buffer_control;

    o                               : dma_out;

  end record;

----------------------------------------------------------------------------------------------------------------------- externals

  type dma_ext is record
    rq                              : read_queues;
    wq                              : write_queues;
    wqb                             : write_buffers;

    rb                              : read_buffer_item;
    wb                              : write_buffer_item;

    rh                              : read_history_item;
    wh                              : write_history_item;
  end record;

  procedure dma_reset (signal r : inout dma_int);

----------------------------------------------------------------------------------------------------------------------- read procedures

  procedure read_byte (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0)
  );

  procedure read_byte (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  );

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  );

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  );

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure read_cacheline (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0)
  );

  procedure read_cacheline (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  );

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  );

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  );

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  );

----------------------------------------------------------------------------------------------------------------------- write procedures

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(7 downto 0)
  );

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(7 downto 0)
  );

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(7 downto 0);
    stream                          : in natural
  );

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(7 downto 0);
    stream                          : in natural
  );

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  );

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  );

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  );

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  );

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  );

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  );

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(DMA_DATA_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(DMA_DATA_WIDTH - 1 downto 0);
    stream                          : in natural
  );

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(DMA_DATA_WIDTH - 1 downto 0)
  );

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(DMA_DATA_WIDTH - 1 downto 0)
  );

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in std_logic_vector
  );

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in unsigned
  );

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in std_logic_vector;
    stream                          : in natural
  );

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in unsigned;
    stream                          : in natural
  );

end package dma_package;

package body dma_package is

----------------------------------------------------------------------------------------------------------------------- reset procedure

  procedure dma_reset (signal r : inout dma_int) is
  begin
    r.id                            <= (others => '0');

    r.read                          <= '0';
    r.read_touch                    <= '0';

    r.write                         <= '0';
    r.write_touch                   <= '0';

    r.read_credits                  <= u(DMA_READ_CREDITS, DMA_READ_CREDITS_WIDTH);
    r.write_credits                 <= u(DMA_WRITE_CREDITS, DMA_WRITE_CREDITS_WIDTH);

    r.wqb                           <= (others => (others => '0'));

    r.rt.available                  <= '1';
    r.rt.tag                        <= (others => '0');
    r.wt.available                  <= '1';
    r.wt.tag                        <= (others => '0');

    r.rse.free                      <= (others => '1');
    r.rse.ready                     <= (others => '0');
    r.rse.active_count              <= (others => '0');
    r.rse.pull_engine               <= 0;
    r.rse.pull_stream               <= (others => '0');

    for stream in 0 to DMA_READ_ENGINES - 1 loop
      r.rse.engine(stream).hold     <= (others => '0');
    end loop;

    r.wse.free                      <= (others => '1');
    r.wse.ready                     <= (others => '0');
    r.wse.active_count              <= (others => '0');
    r.wse.pull_engine               <= 0;
    r.wse.pull_stream               <= (others => '0');

    for stream in 0 to DMA_WRITE_ENGINES - 1 loop
      r.wse.engine(stream).hold     <= (others => '0');
    end loop;

    r.rb.put_flip                   <= '1';
    r.rb.pull_flip                  <= '1';
    r.rb.pull_address               <= (others => '0');
    r.rb.status                     <= (others => '0');

    r.wb.put_flip                   <= '1';
    r.wb.pull_flip                  <= '1';
    r.wb.pull_address               <= (others => '0');
    r.wb.status                     <= (others => '0');
  end procedure dma_reset;

----------------------------------------------------------------------------------------------------------------------- read procedures

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    read.valid                      := '1';
    read.address                    := address;
    read.size                       := n;
    read.stream                     := (others => '0');
    read.stream(stream)             := '1';
  end procedure read_bytes;

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  ) is
  begin
    read_bytes                      (read, address, u(n, DMA_SIZE_WIDTH), stream);
  end procedure read_bytes;

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  ) is
  begin
    read_bytes                      (read, address, n, 0);
  end procedure read_bytes;

  procedure read_bytes (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  ) is
  begin
    read_bytes                      (read, address, u(n, DMA_SIZE_WIDTH), 0);
  end procedure read_bytes;

  procedure read_byte (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    read_bytes                      (read, address, u(1, DMA_SIZE_WIDTH), stream);
  end procedure read_byte;

  procedure read_byte (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0)
  ) is
  begin
    read_bytes                      (read, address, u(1, DMA_SIZE_WIDTH), 0);
  end procedure read_byte;

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  ) is
  begin
    read_bytes                      (read, address, u(n*PSL_CACHELINE_SIZE, DMA_SIZE_WIDTH), stream);
  end procedure read_cachelines;

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    read_cachelines                 (read, address, idx(n), stream);
  end procedure read_cachelines;

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  ) is
  begin
    read_cachelines                 (read, address, n, 0);
  end procedure read_cachelines;

  procedure read_cachelines (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  ) is
  begin
    read_cachelines                 (read, address, n, 0);
  end procedure read_cachelines;

  procedure read_cacheline (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    read_cachelines                 (read, address, 1, stream);
  end procedure read_cacheline;

  procedure read_cacheline (
    variable read                   : out dma_read_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0)
  ) is
  begin
    read_cachelines                 (read, address, 1, 0);
  end procedure read_cacheline;

----------------------------------------------------------------------------------------------------------------------- write procedures

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in std_logic_vector;
    stream                          : in natural
  ) is
  begin
    write.valid                     := '1';
    write.stream                    := (others => '0');
    write.stream(stream)            := '1';
    write.data(data'range)          := data;
  end procedure write_data;

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in unsigned;
    stream                          : in natural
  ) is
  begin
    write_data                      (write, slv(data), stream);
  end procedure write_data;

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in std_logic_vector
  ) is
  begin
    write_data                      (write, data, 0);
  end procedure write_data;

  procedure write_data (
    variable write                  : out dma_write_data_item;
    data                            : in unsigned
  ) is
  begin
    write_data                      (write, slv(data), 0);
  end procedure write_data;

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    write.valid                     := '1';
    write.address                   := address;
    write.size                      := n;
    write.stream                    := (others => '0');
    write.stream(stream)            := '1';
  end procedure write_bytes;

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  ) is
  begin
    write_bytes                     (write, address, u(n, DMA_SIZE_WIDTH), stream);
  end procedure write_bytes;

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  ) is
  begin
    write_bytes                     (write, address, n, 0);
  end procedure write_bytes;

  procedure write_bytes (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  ) is
  begin
    write_bytes                     (write, address, n, 0);
  end procedure write_bytes;

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(7 downto 0);
    stream                          : in natural
  ) is
  begin
    write_bytes                     (write.request, address, u(1, DMA_SIZE_WIDTH), stream);
    write_data                      (write.data, data, stream);
  end procedure write_byte;

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(7 downto 0);
    stream                          : in natural
  ) is
  begin
    write_bytes                     (write.request, address, u(1, DMA_SIZE_WIDTH), stream);
    write_data                      (write.data, data, stream);
  end procedure write_byte;

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(7 downto 0)
  ) is
  begin
    write_bytes                     (write.request, address, u(1, DMA_SIZE_WIDTH), 0);
    write_data                      (write.data, data, 0);
  end procedure write_byte;

  procedure write_byte (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(7 downto 0)
  ) is
  begin
    write_bytes                     (write.request, address, u(1, DMA_SIZE_WIDTH), 0);
    write_data                      (write.data, data, 0);
  end procedure write_byte;

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural;
    stream                          : in natural
  ) is
  begin
    write_bytes                     (write, address, u(n*PSL_CACHELINE_SIZE, DMA_SIZE_WIDTH), stream);
  end procedure write_cachelines;

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    write_cachelines                (write, address, idx(n), stream);
  end procedure write_cachelines;

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in natural
  ) is
  begin
    write_cachelines                (write, address, n, 0);
  end procedure write_cachelines;

  procedure write_cachelines (
    variable write                  : out dma_write_request_item;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    n                               : in unsigned(DMA_SIZE_WIDTH - 1 downto 0)
  ) is
  begin
    write_cachelines                (write, address, n, 0);
  end procedure write_cachelines;

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(DMA_DATA_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    write_cachelines                (write.request, address, 1, stream);
    write_data                      (write.data, data, stream);
  end procedure write_cacheline;

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(DMA_DATA_WIDTH - 1 downto 0);
    stream                          : in natural
  ) is
  begin
    write_cachelines                (write.request, address, 1, stream);
    write_data                      (write.data, data, stream);
  end procedure write_cacheline;

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in std_logic_vector(DMA_DATA_WIDTH - 1 downto 0)
  ) is
  begin
    write_cachelines                (write.request, address, 1, 0);
    write_data                      (write.data, data, 0);
  end procedure write_cacheline;

  procedure write_cacheline (
    variable write                  : out dma_write_request;
    address                         : in unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
    data                            : in unsigned(DMA_DATA_WIDTH - 1 downto 0)
  ) is
  begin
    write_cachelines                (write.request, address, 1, 0);
    write_data                      (write.data, data, 0);
  end procedure write_cacheline;

end package body dma_package;
