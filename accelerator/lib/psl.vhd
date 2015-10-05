library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;

package psl is

----------------------------------------------------------------------------------------------------------------------- clock/reset

  type cr_in is record
    clk                             : std_logic;
    rst                             : std_logic;
  end record;

----------------------------------------------------------------------------------------------------------------------- psl interface

  constant PSL_AFU_DESC_WIDTH       : natural                                               := 64;
  constant PSL_TAG_WIDTH            : natural                                               := 8;
  constant PSL_COMMAND_WIDTH        : natural                                               := 13;
  constant PSL_ABT_WIDTH            : natural                                               := 3;
  constant PSL_ADDRESS_WIDTH        : natural                                               := 64;
  constant PSL_CH_WIDTH             : natural                                               := 16;
  constant PSL_SIZE_WIDTH           : natural                                               := 12;
  constant PSL_ROOM_WIDTH           : natural                                               := 8;
  constant PSL_HALFLINE_INDEX_WIDTH : natural                                               := 6;
  constant PSL_LATENCY_WIDTH        : natural                                               := 4;
  constant PSL_DATA_WIDTH           : natural                                               := 512;
  constant PSL_RESPONSE_WIDTH       : natural                                               := 8;
  constant PSL_CREDITS_WIDTH        : natural                                               := 9;
  constant PSL_CACHESTATE_WIDTH     : natural                                               := 2;
  constant PSL_CACHEPOS_WIDTH       : natural                                               := 13;
  constant PSL_MMIO_ADDRESS_WIDTH   : natural                                               := 24;
  constant PSL_MMIO_DATA_WIDTH      : natural                                               := 64;
  constant PSL_JOB_COMMAND_WIDTH    : natural                                               := 8;
  constant PSL_ERROR_WIDTH          : natural                                               := 64;
  constant PSL_WORD_WIDTH           : natural                                               := 32;
  constant PSL_DOUBLE_WORD_WIDTH    : natural                                               := 64;
  constant PSL_ERAT_WIDTH           : natural                                               := 9;
  constant PSL_PAGESIZE             : natural                                               := 65536;
  constant PSL_CACHELINE_SIZE       : natural                                               := 128;

  constant PSL_CACHELINE_BYTES      : unsigned(log2(PSL_CACHELINE_SIZE) downto 0)           := u(PSL_CACHELINE_SIZE, log2(PSL_CACHELINE_SIZE) + 1);
  constant PSL_CACHELINE_BYTES_OUT  : unsigned(PSL_SIZE_WIDTH - 1 downto 0)                 := u(PSL_CACHELINE_SIZE, PSL_SIZE_WIDTH);

----------------------------------------------------------------------------------------------------------------------- psl flags

  constant PCO_READ_CL_S            : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0a50#, PSL_COMMAND_WIDTH);
  constant PCO_READ_CL_M            : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0a60#, PSL_COMMAND_WIDTH);
  constant PCO_READ_CL_LCK          : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0a6b#, PSL_COMMAND_WIDTH);
  constant PCO_READ_CL_RES          : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0240#, PSL_COMMAND_WIDTH);
  constant PCO_TOUCH_I              : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0250#, PSL_COMMAND_WIDTH);
  constant PCO_TOUCH_M              : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0260#, PSL_COMMAND_WIDTH);
  constant PCO_WRITE_MI             : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0d60#, PSL_COMMAND_WIDTH);
  constant PCO_WRITE_MS             : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0d70#, PSL_COMMAND_WIDTH);
  constant PCO_WRITE_UNLOCK         : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0d6b#, PSL_COMMAND_WIDTH);
  constant PCO_WRITE_C              : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0d67#, PSL_COMMAND_WIDTH);
  constant PCO_PUSH_I               : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0140#, PSL_COMMAND_WIDTH);
  constant PCO_PUSH_S               : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0150#, PSL_COMMAND_WIDTH);
  constant PCO_EVICT_I              : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#1140#, PSL_COMMAND_WIDTH);
  constant PCO_RESERVED             : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#1260#, PSL_COMMAND_WIDTH);
  constant PCO_LOCK                 : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#016b#, PSL_COMMAND_WIDTH);
  constant PCO_UNLOCK               : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#017b#, PSL_COMMAND_WIDTH);

  constant PCO_READ_CL_NA           : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0a00#, PSL_COMMAND_WIDTH);
  constant PCO_READ_PNA             : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0e00#, PSL_COMMAND_WIDTH);
  constant PCO_WRITE_NA             : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0d00#, PSL_COMMAND_WIDTH);
  constant PCO_WRITE_NJ             : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0d10#, PSL_COMMAND_WIDTH);

  constant PCO_FLUSH                : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0100#, PSL_COMMAND_WIDTH);
  constant PCO_INTREQ               : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0000#, PSL_COMMAND_WIDTH);
  constant PCO_RESTART              : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0)      := slv(16#0001#, PSL_COMMAND_WIDTH);

  constant PTOB_STRICT              : std_logic_vector(PSL_ABT_WIDTH - 1 downto 0)          := slv(16#0#, PSL_ABT_WIDTH);
  constant PTOB_ABORT               : std_logic_vector(PSL_ABT_WIDTH - 1 downto 0)          := slv(16#1#, PSL_ABT_WIDTH);
  constant PTOB_PAGE                : std_logic_vector(PSL_ABT_WIDTH - 1 downto 0)          := slv(16#2#, PSL_ABT_WIDTH);
  constant PTOB_PREF                : std_logic_vector(PSL_ABT_WIDTH - 1 downto 0)          := slv(16#3#, PSL_ABT_WIDTH);
  constant PTOB_SPEC                : std_logic_vector(PSL_ABT_WIDTH - 1 downto 0)          := slv(16#7#, PSL_ABT_WIDTH);

  constant PRC_DONE                 : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#00#, PSL_RESPONSE_WIDTH);
  constant PRC_AERROR               : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#01#, PSL_RESPONSE_WIDTH);
  constant PRC_DERROR               : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#03#, PSL_RESPONSE_WIDTH);
  constant PRC_NLOCK                : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#04#, PSL_RESPONSE_WIDTH);
  constant PRC_NRES                 : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#05#, PSL_RESPONSE_WIDTH);
  constant PRC_FLUSHED              : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#06#, PSL_RESPONSE_WIDTH);
  constant PRC_FAULT                : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#07#, PSL_RESPONSE_WIDTH);
  constant PRC_FAILED               : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#08#, PSL_RESPONSE_WIDTH);
  constant PRC_PAGED                : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0)     := slv(16#0a#, PSL_RESPONSE_WIDTH);

  constant PCC_START                : std_logic_vector(PSL_JOB_COMMAND_WIDTH - 1 downto 0)  := slv(16#90#, PSL_JOB_COMMAND_WIDTH);
  constant PCC_RESET                : std_logic_vector(PSL_JOB_COMMAND_WIDTH - 1 downto 0)  := slv(16#80#, PSL_JOB_COMMAND_WIDTH);
  constant PCC_TIMEBASE             : std_logic_vector(PSL_JOB_COMMAND_WIDTH - 1 downto 0)  := slv(16#42#, PSL_JOB_COMMAND_WIDTH);

----------------------------------------------------------------------------------------------------------------------- afu descriptors

  -- dedicated mode with 1 dedicated process
  constant AFUD_0                   : std_logic_vector(PSL_AFU_DESC_WIDTH - 1 downto 0)     := x"0000_0001_0000_8010";

  -- problem state area
  constant AFUD_30                  : std_logic_vector(PSL_AFU_DESC_WIDTH - 1 downto 0)     := x"0100_0000_0000_0000";

----------------------------------------------------------------------------------------------------------------------- psl command

  --type psl_command_in is record
   -- room                          : std_logic_vector(PSL_ROOM_WIDTH - 1 downto 0);
  --end record;

    type psl_command_out is record
      valid                         : std_logic;
      tag                           : unsigned(PSL_TAG_WIDTH - 1 downto 0);
   -- tagpar                        : std_logic;
      com                           : std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0);
   -- compar                        : std_logic;
   -- abt                           : std_logic_vector(PSL_ABT_WIDTH - 1 downto 0);
      ea                            : unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
   -- eapar                         : std_logic;
   -- ch                            : unsigned(PSL_CH_WIDTH - 1 downto 0);
      size                          : unsigned(PSL_SIZE_WIDTH - 1 downto 0);
    end record;

  ----------------------------------------------------------------------------------------------------------------------- psl control

    type psl_control_in is record
      val                           : std_logic;
      com                           : std_logic_vector(PSL_JOB_COMMAND_WIDTH - 1 downto 0);
   -- compar                        : std_logic;
      ea                            : unsigned(PSL_ADDRESS_WIDTH - 1 downto 0);
   -- eapar                         : std_logic;
      pclock                        : std_logic;
    end record;

    type psl_control_out is record
      running                       : std_logic;
      done                          : std_logic;
   -- ack                           : std_logic;
      error                         : std_logic_vector(PSL_ERROR_WIDTH - 1 downto 0);
   -- yield                         : std_logic;
   -- tbreq                         : std_logic;
   -- paren                         : std_logic;
    end record;

  ----------------------------------------------------------------------------------------------------------------------- psl buffer

    type psl_buffer_in is record
      rvalid                        : std_logic;
      rtag                          : unsigned(PSL_TAG_WIDTH - 1 downto 0);
   -- rtagpar                       : std_logic;
      rad                           : unsigned(PSL_HALFLINE_INDEX_WIDTH - 1 downto 0);
      wvalid                        : std_logic;
      wtag                          : unsigned(PSL_TAG_WIDTH - 1 downto 0);
   -- wtagpar                       : std_logic;
      wad                           : unsigned(PSL_HALFLINE_INDEX_WIDTH - 1 downto 0);
      wdata                         : std_logic_vector(PSL_DATA_WIDTH - 1 downto 0);
   -- wpar                          : std_logic_vector((PSL_DATA_WIDTH / PSL_DOUBLE_WORD_WIDTH) - 1 downto 0);
    end record;

    type psl_buffer_out is record
   -- rlat                          : unsigned(PSL_LATENCY_WIDTH - 1 downto 0);
      rdata                         : std_logic_vector(PSL_DATA_WIDTH - 1 downto 0);
   -- rpar                          : std_logic_vector((PSL_DATA_WIDTH / PSL_DOUBLE_WORD_WIDTH) - 1 downto 0);
    end record;

  ----------------------------------------------------------------------------------------------------------------------- psl mmio

    type psl_mmio_in is record
      val                           : std_logic;
      cfg                           : std_logic;
      rnw                           : std_logic;
      dw                            : std_logic;
      ad                            : unsigned(PSL_MMIO_ADDRESS_WIDTH - 1 downto 0);
   -- adpar                         : std_logic;
      data                          : std_logic_vector(PSL_MMIO_DATA_WIDTH - 1 downto 0);
   -- datapar                       : std_logic;
    end record;

    type psl_mmio_out is record
      ack                           : std_logic;
      data                          : std_logic_vector(PSL_MMIO_DATA_WIDTH - 1 downto 0);
   -- datapar                       : std_logic;
    end record;

  ----------------------------------------------------------------------------------------------------------------------- psl response

    type psl_response_in is record
      valid                         : std_logic;
      tag                           : unsigned(PSL_TAG_WIDTH - 1 downto 0);
   -- tagpar                        : std_logic;
      response                      : std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0);
   -- credits                       : unsigned(PSL_CREDITS_WIDTH - 1 downto 0);
   -- cachestate                    : std_logic_vector(PSL_CACHESTATE_WIDTH - 1 downto 0);
   -- cachepos                      : std_logic_vector(PSL_CACHEPOS_WIDTH - 1 downto 0);
    end record;

end package psl;
