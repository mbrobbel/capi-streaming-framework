library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.functions.all;
  use work.psl.all;

package wed is

  type wed_type is record
    status          : std_logic_vector(7 downto 0);   -- 7    downto 0
    wed00_a         : std_logic_vector(7 downto 0);   -- 15   downto 8
    wed00_b         : std_logic_vector(15 downto 0);  -- 31   downto 16
    size            : unsigned(31 downto 0);          -- 63   downto 32
    source          : unsigned(63 downto 0);          -- 127  downto 64
    destination     : unsigned(63 downto 0);          -- 191  downto 128
    wed03           : std_logic_vector(63 downto 0);  -- 255  downto 192
    wed04           : std_logic_vector(63 downto 0);  -- 319  downto 256
    wed05           : std_logic_vector(63 downto 0);  -- 383  downto 320
    wed06           : std_logic_vector(63 downto 0);  -- 447  downto 384
    wed07           : std_logic_vector(63 downto 0);  -- 511  downto 448
    wed08           : std_logic_vector(63 downto 0);  -- 575  downto 512
    wed09           : std_logic_vector(63 downto 0);  -- 639  downto 576
    wed10           : std_logic_vector(63 downto 0);  -- 703  downto 640
    wed11           : std_logic_vector(63 downto 0);  -- 767  downto 704
    wed12           : std_logic_vector(63 downto 0);  -- 831  downto 768
    wed13           : std_logic_vector(63 downto 0);  -- 895  downto 832
    wed14           : std_logic_vector(63 downto 0);  -- 959  downto 896
    wed15           : std_logic_vector(63 downto 0);  -- 1023 downto 960
  end record;

  procedure wed_parse (signal data : in std_logic_vector(1023 downto 0); variable wed : out wed_type);

end package wed;

package body wed is

  procedure wed_parse (signal data : in std_logic_vector(1023 downto 0); variable wed : out wed_type) is
  begin
    wed.status      := data(7 downto 0);
    wed.wed00_a     := data(15 downto 8);
    wed.wed00_b     := data(31 downto 16);
    wed.size        := u(data(63 downto 32));
    wed.source      := u(data(127 downto 64));
    wed.destination := u(data(191 downto 128));
    wed.wed03       := data(255 downto 192);
    wed.wed04       := data(319 downto 256);
    wed.wed05       := data(383 downto 320);
    wed.wed06       := data(447 downto 384);
    wed.wed07       := data(511 downto 448);
    wed.wed08       := data(575 downto 512);
    wed.wed09       := data(639 downto 576);
    wed.wed10       := data(703 downto 640);
    wed.wed11       := data(767 downto 704);
    wed.wed12       := data(831 downto 768);
    wed.wed13       := data(895 downto 832);
    wed.wed14       := data(959 downto 896);
    wed.wed15       := data(1023 downto 960);
  end procedure wed_parse;

end package body wed;
