library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.tb_pack.all;

entity uart_tx_tb is
end uart_tx_tb;

architecture rtl of uart_tx_tb is

constant clk_freq: integer := 153_600;
constant bus_width: integer := 8;
constant baud_rate: integer := 9600;
signal rst: std_logic;
signal clk: std_logic;
signal en: std_logic;
signal data_out: std_logic;
constant clk_period: time := (1_000_000_000 ns / clk_freq);
signal read_data: std_logic_vector(bus_width - 1 downto 0);
constant tx_data: std_logic_vector(bus_width - 1 downto 0) := x"6A";
signal expected: std_logic_vector(bus_width - 1 downto 0) := tx_data;
constant clk_per_bit: integer := clk_freq / baud_rate;
  
begin

  UUT:entity work.uart_tx 
  generic map(
    clk_freq => clk_freq,
    bus_width => bus_width,
    baud_rate => baud_rate,
    tx_data => tx_data
  )
  port map(
    rst => rst,
    clk => clk,
    en => en,
    data_out => data_out
  );
  
  rst_clk_gen: process
  begin
    --Async reset
    set_input(rst,'1');
    wait for clk_period;
    set_input(rst,'0');
    wait for  clk_period;
    --Clock
    set_input(clk,'0');
    while true loop
      wait for clk_period / 2;
      clk <= not clk;
    end loop;
    wait;
  end process;  
  
  main_test: process
  --Test IDLE state
  procedure test_idle(constant msg: in string) is
  begin
    report "Test: " & msg;
    wait until rst = '0';
    wait for 2 * clk_period;
    check_equal(data_out,'1',msg);
    set_input(en,'1');
    wait for clk_period;
  end procedure test_idle;
  
  --Test INIT state
  procedure test_init(constant msg: in string) is
  begin
    report "Test: " & msg;
    check_equal(data_out,'1',msg);
    wait for clk_period * clk_per_bit;
  end procedure test_init;
  
  --Test START_BIT state
  procedure test_start_bit(constant msg: in string) is
  begin
    report "Test: " & msg;
    check_equal(data_out,'0',msg);
    wait for clk_period * clk_per_bit;
  end procedure test_start_bit;
  
  --Test SEND_DATA state
  procedure test_send_data(constant msg: in string) is
  begin
    report "Test: " & msg;
    for i in 0 to bus_width - 1 loop
      read_data(i) <= data_out;
      wait for clk_period * clk_per_bit;
    end loop;
    check_equal(read_data,expected,msg);
  end procedure test_send_data;
  
  --Test STOP_BIT state
  procedure test_stop_bit(constant msg: in string) is
  begin
    report "Test: " & msg;
    check_equal(data_out,'1',msg);
    wait for clk_period * clk_per_bit;
  end procedure test_stop_bit;  
  
  --Test PAUSE state
  procedure test_pause(constant msg: in string) is
  begin
    report "Test: " & msg;
    check_equal(data_out,'1',msg);
    wait for clk_period * clk_freq;
  end procedure test_pause;
  
  --Test PAUSE - IDLE transition
  procedure test_pause_idle(constant msg: in string) is
  begin
    report "Test: " & msg;
    check_equal(data_out,'1',msg);
  end procedure test_pause_idle;
  
  begin
    test_idle("<IDLE>");
    test_init("<INIT>");
    test_start_bit("<START_BIT>");
    test_send_data("<SEND_DATA>");
    wait for clk_period; --Tolerance for FSM's transition (deviation by 1 cycle)
    test_stop_bit("<STOP_BIT>");
    test_pause("<PAUSE>");
    test_pause_idle("<PAUSE-TO-IDLE>");
    report "End of simulation" severity failure; --Success
  end process;
  
end rtl;
