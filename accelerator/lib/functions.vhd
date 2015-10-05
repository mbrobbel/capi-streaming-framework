library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package functions is

  function endian_swap      (a : in std_logic_vector)                           return std_logic_vector;
  function is_full          (a : in std_logic_vector; b : in std_logic_vector)  return std_logic;
  function is_full          (a : in unsigned; b : in unsigned)                  return std_logic;
  function is_empty         (a : in std_logic_vector; b : in std_logic_vector)  return std_logic;
  function is_empty         (a : in unsigned; b : in unsigned)                  return std_logic;
  function idx              (a : in std_logic_vector)                           return integer;
  function idx              (a : in unsigned)                                   return integer;
  function slv              (a : in integer; b : in natural)                    return std_logic_vector;
  function slv              (a : in unsigned)                                   return std_logic_vector;
  function u                (a : in integer; b : in natural)                    return unsigned;
  function u                (a : in std_logic_vector)                           return unsigned;
  function u                (a : in std_logic)                                  return unsigned;
  function l                (a : in boolean)                                    return std_logic;
  function log2             (a : in natural)                                    return natural;
  function ones             (a : in std_logic_vector)                           return natural;

end package functions;

package body functions is

  function endian_swap (a : in std_logic_vector) return std_logic_vector is
    variable result         : std_logic_vector(a'range);
    constant bytes          : natural := a'length / 8;
  begin
    for i in 0 to bytes - 1 loop
      result(8 * i + 7 downto 8 * i) := a((bytes - 1 - i) * 8 + 7 downto (bytes - 1 - i) * 8);
    end loop;
    return                  result;
  end function endian_swap;

  function is_full (a : in std_logic_vector; b : in std_logic_vector) return std_logic is
    variable result         : std_logic;
  begin
    if a(a'high) /= b(b'high) and a(a'high - 1 downto a'low) = b(b'high - 1 downto b'low) then
      result                := '1';
    else
      result                := '0';
    end if;
    return                  result;
  end function is_full;

  function is_full (a : in unsigned; b : in unsigned) return std_logic is
    variable result         : std_logic;
  begin
    if a(a'high) /= b(b'high) and a(a'high - 1 downto a'low) = b(b'high - 1 downto b'low) then
      result                := '1';
    else
      result                := '0';
    end if;
    return                  result;
  end function is_full;

  function is_empty (a : in std_logic_vector; b : in std_logic_vector) return std_logic is
    variable result         : std_logic;
  begin
    if a = b then
      result                := '1';
    else
      result                := '0';
    end if;
    return                  result;
  end function is_empty;

  function is_empty (a : in unsigned; b : in unsigned) return std_logic is
    variable result         : std_logic;
  begin
    if a = b then
      result                := '1';
    else
      result                := '0';
    end if;
    return                  result;
  end function is_empty;

  function idx (a : in std_logic_vector) return integer is
  begin
    return                  to_integer(unsigned(a));
  end function idx;

  function idx (a : in unsigned) return integer is
  begin
    return                  to_integer(a);
  end function idx;

  function slv (a : in integer; b : in natural) return std_logic_vector is
  begin
    return                  std_logic_vector(to_unsigned(a, b));
  end function slv;

  function slv (a : in unsigned) return std_logic_vector is
  begin
    return                  std_logic_vector(a);
  end function slv;

  function u (a : in integer; b : in natural) return unsigned is
  begin
    return                  to_unsigned(a, b);
  end function u;

  function u (a : in std_logic_vector) return unsigned is
  begin
    return                  unsigned(a);
  end function u;

  function u (a : in std_logic) return unsigned is
    variable result         : unsigned(0 downto 0);
  begin
    if a then
      result                := u("1");
    else
      result                := u("0");
    end if;
    return                  result;
  end function u;

  function l (a: boolean) return std_logic is
    variable result         : std_logic;
  begin
    if a then
      result                := '1';
    else
      result                := '0';
    end if;
    return                  result;
  end function l;

  function log2 (a : in natural) return natural is
    variable b              : natural := a;
    variable result         : natural := 0;
  begin
    while b > 1 loop
      result                := result + 1;
      b                     := b / 2;
    end loop;
    return                  result;
  end function log2;

  function ones (a : in std_logic_vector) return natural is
    variable result         : natural := 0;
  begin
    for i in a'range loop
      if a(i) then
        result              := result + 1;
      end if;
    end loop;
    return                  result;
  end function ones;

end package body functions;
