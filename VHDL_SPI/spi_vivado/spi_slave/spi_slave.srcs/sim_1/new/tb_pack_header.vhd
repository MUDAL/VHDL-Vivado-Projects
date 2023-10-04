library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package tb_pack is

procedure set_input(signal sig: out std_logic_vector; 
                    constant val: in std_logic_vector);

procedure set_input(signal sig: out std_logic_vector; 
                    constant val: in integer);

procedure set_input(signal sig: out std_logic;
                    constant val: in std_logic);

procedure check_equal(signal sig_lhs: in std_logic_vector;
                      signal sig_rhs: in std_logic_vector;
                      constant msg: in string);

procedure check_equal(signal sig_lhs: in std_logic;
                      constant val: in std_logic;
                      constant msg: in string);

end package tb_pack;
