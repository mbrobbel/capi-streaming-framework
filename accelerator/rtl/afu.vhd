library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.psl.all;
  use work.functions.all;
  use work.frame_package.all;

entity afu is
  port (
    ah_cvalid       : out std_logic;
    ah_ctag         : out std_logic_vector(PSL_TAG_WIDTH - 1 downto 0);
    ah_ctagpar      : out std_logic;
    ah_com          : out std_logic_vector(PSL_COMMAND_WIDTH - 1 downto 0);
    ah_compar       : out std_logic;
    ah_cabt         : out std_logic_vector(PSL_ABT_WIDTH - 1 downto 0);
    ah_cea          : out std_logic_vector(PSL_ADDRESS_WIDTH - 1 downto 0);
    ah_ceapar       : out std_logic;
    ah_cch          : out std_logic_vector(PSL_CH_WIDTH - 1 downto 0);
    ah_csize        : out std_logic_vector(PSL_SIZE_WIDTH - 1 downto 0);
    ha_croom        : in  std_logic_vector(PSL_ROOM_WIDTH - 1 downto 0);
    ha_brvalid      : in  std_logic;
    ha_brtag        : in  std_logic_vector(PSL_TAG_WIDTH - 1 downto 0);
    ha_brtagpar     : in  std_logic;
    ha_brad         : in  std_logic_vector(PSL_HALFLINE_INDEX_WIDTH - 1 downto 0);
    ah_brlat        : out std_logic_vector(PSL_LATENCY_WIDTH - 1 downto 0);
    ah_brdata       : out std_logic_vector(PSL_DATA_WIDTH - 1 downto 0);
    ah_brpar        : out std_logic_vector((PSL_DATA_WIDTH - 1) / PSL_DOUBLE_WORD_WIDTH downto 0);
    ha_bwvalid      : in  std_logic;
    ha_bwtag        : in  std_logic_vector(PSL_TAG_WIDTH - 1 downto 0);
    ha_bwtagpar     : in  std_logic;
    ha_bwad         : in  std_logic_vector(PSL_HALFLINE_INDEX_WIDTH - 1 downto 0);
    ha_bwdata       : in  std_logic_vector(PSL_DATA_WIDTH - 1 downto 0);
    ha_bwpar        : in  std_logic_vector((PSL_DATA_WIDTH - 1) / PSL_DOUBLE_WORD_WIDTH downto 0);
    ha_rvalid       : in  std_logic;
    ha_rtag         : in  std_logic_vector(PSL_TAG_WIDTH - 1 downto 0);
    ha_rtagpar      : in  std_logic;
    ha_response     : in  std_logic_vector(PSL_RESPONSE_WIDTH - 1 downto 0);
    ha_rcredits     : in  std_logic_vector(PSL_CREDITS_WIDTH - 1 downto 0);
    ha_rcachestate  : in  std_logic_vector(PSL_CACHESTATE_WIDTH - 1 downto 0);
    ha_rcachepos    : in  std_logic_vector(PSL_CACHEPOS_WIDTH - 1 downto 0);
    ha_mmval        : in  std_logic;
    ha_mmcfg        : in  std_logic;
    ha_mmrnw        : in  std_logic;
    ha_mmdw         : in  std_logic;
    ha_mmad         : in  std_logic_vector(PSL_MMIO_ADDRESS_WIDTH - 1 downto 0);
    ha_mmadpar      : in  std_logic;
    ha_mmdata       : in  std_logic_vector(PSL_MMIO_DATA_WIDTH - 1 downto 0);
    ha_mmdatapar    : in  std_logic;
    ah_mmack        : out std_logic;
    ah_mmdata       : out std_logic_vector(PSL_MMIO_DATA_WIDTH - 1 downto 0);
    ah_mmdatapar    : out std_logic;
    ha_jval         : in  std_logic;
    ha_jcom         : in  std_logic_vector(PSL_JOB_COMMAND_WIDTH - 1 downto 0);
    ha_jcompar      : in  std_logic;
    ha_jea          : in  std_logic_vector(PSL_ADDRESS_WIDTH - 1 downto 0);
    ha_jeapar       : in  std_logic;
    ah_jrunning     : out std_logic;
    ah_jdone        : out std_logic;
    ah_jcack        : out std_logic;
    ah_jerror       : out std_logic_vector(PSL_ERROR_WIDTH - 1 downto 0);
    ah_jyield       : out std_logic;
    ah_tbreq        : out std_logic;
    ah_paren        : out std_logic;
    ha_pclock       : in  std_logic
  );
end entity afu;

architecture logic of afu is

  signal ha         : frame_in;
  signal ah         : frame_out;

begin

----------------------------------------------------------------------------------------------------------------------- inputs

--ha.c.room         <= ha_croom;
  ha.b.rvalid       <= ha_brvalid;
  ha.b.rtag         <= u(ha_brtag);
--ha.b.rtagpar      <= ha_brtagpar;
  ha.b.rad          <= u(ha_brad);
  ha.b.wvalid       <= ha_bwvalid;
  ha.b.wtag         <= u(ha_bwtag);
--ha.b.wtagpar      <= ha_bwtagpar;
  ha.b.wad          <= u(ha_bwad);
  ha.b.wdata        <= ha_bwdata;
--ha.b.wpar         <= ha_bwpar;
  ha.r.valid        <= ha_rvalid;
  ha.r.tag          <= u(ha_rtag);
--ha.r.tagpar       <= ha_rtagpar;
  ha.r.response     <= ha_response;
--ha.r.credits      <= ha_rcredits;
--ha.r.cachestate   <= ha_rcachestate;
--ha.r.cachepos     <= ha_rcachepos;
  ha.mm.val         <= ha_mmval;
  ha.mm.cfg         <= ha_mmcfg;
  ha.mm.rnw         <= ha_mmrnw;
  ha.mm.dw          <= ha_mmdw;
  ha.mm.ad          <= u(ha_mmad);
--ha.mm.adpar       <= ha_mmadpar;
  ha.mm.data        <= ha_mmdata;
--ha.mm.datapar     <= ha_mmdatapar;
  ha.j.com          <= ha_jcom;
  ha.j.val          <= ha_jval;
--ha.j.compar       <= ha_jcompar;
  ha.j.ea           <= u(ha_jea);
--ha.j.eapar        <= ha_jeapar;
  ha.j.pclock       <= ha_pclock;

----------------------------------------------------------------------------------------------------------------------- outputs

  ah_cvalid         <= ah.c.valid;
  ah_ctag           <= slv(ah.c.tag);
  ah_ctagpar        <= '0';                       --ah.c.tagpar;
  ah_com            <= ah.c.com;
  ah_compar         <= '0';                       --ah.c.compar;
  ah_cabt           <= PTOB_PAGE;                 --ah.c.abt;
  ah_cea            <= slv(ah.c.ea);
  ah_ceapar         <= '0';                       --ah.c.eapar;
  ah_cch            <= (others => '0');           --ah.c.ch;
  ah_csize          <= slv(ah.c.size);
  ah_brlat          <= slv(1, PSL_LATENCY_WIDTH); --ah.b.rlat;
  ah_brdata         <= ah.b.rdata;
  ah_brpar          <= (others => '0');           --ah.b.rpar;
  ah_mmack          <= ah.mm.ack;
  ah_mmdata         <= ah.mm.data;
  ah_mmdatapar      <= '0';                       --ah.mm.datapar;
  ah_jrunning       <= ah.j.running;
  ah_jdone          <= ah.j.done;
  ah_jcack          <= '0';                       --ah.j.ack;
  ah_jerror         <= (others => '0');           --ah.j.error;
  ah_jyield         <= '0';                       --ah.j.yield;
  ah_tbreq          <= '0';                       --ah.j.tbreq;
  ah_paren          <= '0';                       --ah.j.paren;

  f0                : entity work.frame port map (ha, ah);

end architecture logic;
