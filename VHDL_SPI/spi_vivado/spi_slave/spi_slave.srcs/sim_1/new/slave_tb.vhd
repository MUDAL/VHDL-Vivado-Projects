library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.tb_pack.all;

entity spi_slave_tb is
end spi_slave_tb;

architecture rtl of spi_slave_tb is

constant bus_width: integer := 8;
signal rst: std_logic;
signal addr_in: std_logic_vector(bus_width - 1 downto 0);
signal ack_in: std_logic_vector(bus_width - 1 downto 0);
signal mosi: std_logic;
signal sck: std_logic;
signal nss: std_logic;
signal miso: std_logic;
constant clk_period: time := 20 ns;
signal miso_test: std_logic_vector(bus_width - 1 downto 0);
signal data: std_logic_vector(bus_width - 1 downto 0);
signal clk_en: std_logic;

begin
  UUT: entity work.spi_slave
  generic map(bus_width => bus_width)
  port map(
    rst => rst,
    addr_in => addr_in,
    ack_in => ack_in,
    mosi => mosi,
    sck => sck,
    nss => nss,
    miso => miso
  );
  
  reset: process
  begin
    --Async reset
    set_input(rst,'1');
    wait for clk_period;
    set_input(rst,'0');
    wait for clk_period;
    wait;
  end process;
  
  clk_gen: process
  begin
    set_input(sck,'0');
    wait until clk_en = '1';
    while clk_en = '1' loop
      wait for clk_period / 2;
      sck <= not sck;
    end loop;
    wait;
  end process;
  
  main_test: process
  --Read the ACK the slave sends to the master
  procedure read_ack_sent(signal s_miso_test: out std_logic_vector;
                          signal s_miso: in std_logic) is
  begin
    for i in 0 to bus_width - 1 loop
      s_miso_test(i) <= s_miso;
      wait for clk_period;
    end loop;
  end procedure read_ack_sent;
  
  --Simulate the reception of an ADDR or data from the master
  procedure simulate_get(signal s_mosi: out std_logic;
                         signal s_mosi_in: in std_logic_vector) is
  begin
    for i in 0 to bus_width - 1 loop
      s_mosi <= s_mosi_in(i); --Master sending ADDR or data to slave
      wait for clk_period;
    end loop;
  end procedure simulate_get;
  
  --Initialize testbench's internal signals
  procedure init_tb_signals is
  begin
    set_input(clk_en,'0');
    set_input(mosi,'0');
    set_input(miso_test,x"00");
    set_input(addr_in,x"BA"); --Address of slave to be received from the master
    set_input(ack_in,x"F4"); --ACK to send to master
    set_input(data,x"88"); --Data to be received from the master
  end procedure init_tb_signals;
  
  --Test IDLE state
  procedure test_idle is
  constant msg_idle: string := "Idle";
  begin
    report "Test: " & msg_idle;
    wait for 3 * clk_period;
    check_equal(miso,'0',"MISO - " & msg_idle);
    set_input(nss,'0');
    set_input(clk_en,'1');
    wait for clk_period;
  end procedure test_idle;
  
  --Test GET ADDR state
  procedure test_get_addr is
  constant msg_get_addr: string := "Get address";
  begin
    report "Test: " & msg_get_addr;
    simulate_get(mosi,addr_in);
    check_equal(miso,'0',"MISO - " & msg_get_addr);
  end procedure test_get_addr;
  
  --Test CHECK ADDR state
  procedure test_check_addr is
  constant msg_check_addr: string := "Check address";
  begin
    report "Test: " & msg_check_addr;
    check_equal(miso,'0',"MISO - " & msg_check_addr);
    wait for clk_period;
  end procedure test_check_addr;
  
  --Test SEND ACK state
  procedure test_send_ack is
  constant msg_send_ack: string := "Send ack";
  begin
    report "Test: " & msg_send_ack;
    read_ack_sent(miso_test,miso);
    check_equal(miso_test,ack_in,"MISO - " & msg_send_ack);
  end procedure test_send_ack;
  
  --Test GET DATA SEND COMPLEMENT state
  procedure test_get_data_send_comp is
  constant msg_get_data_send_comp: string := "Get data, send complement";
  begin
    report "Test: " & msg_get_data_send_comp;
    simulate_get(mosi,data);
    check_equal(miso,not(mosi),"MISO - " & msg_get_data_send_comp);
  end procedure test_get_data_send_comp;
  
  --Test STOP state
  procedure test_stop is
  constant msg_stop: string := "Stop";
  begin
    report "Test: " & msg_stop;
    set_input(clk_en,'0');
    check_equal(miso,'0',"MISO - " & msg_stop);
  end procedure test_stop;
  
  begin
  init_tb_signals;
  test_idle;
  test_get_addr;
  test_check_addr;
  test_send_ack;
  test_get_data_send_comp;
  test_stop;  
  wait;
  end process;

end rtl;
