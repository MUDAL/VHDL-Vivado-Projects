library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package body tb_pack is

procedure set_input(signal sig: out std_logic_vector; 
                    constant val: in std_logic_vector) is 
begin
  sig <= val;
end procedure set_input;

procedure set_input(signal sig: out std_logic_vector; 
                    constant val: in integer) is
begin
  sig <= std_logic_vector(to_unsigned(val,sig'length));
end procedure set_input;

procedure set_input(signal sig: out std_logic;
                    constant val: in std_logic) is
begin
  sig <= val;
end procedure set_input;

procedure check_equal(signal sig_lhs: in std_logic_vector;
                      signal sig_rhs: in std_logic_vector;
                      constant msg: in string) is
begin
  assert sig_lhs = sig_rhs 
    report "Check: " & msg & " -> Fail" severity failure;
  report "Check: " & msg & " -> Pass" severity note;
end procedure check_equal;

procedure check_equal(signal sig_lhs: in std_logic;
                      constant val: in std_logic;
                      constant msg: in string) is
begin
  assert sig_lhs = val 
    report "Check: " & msg & " -> Fail" severity failure;
  report "Check: " & msg & " -> Pass" severity note;
end procedure check_equal;

end package body tb_pack;
