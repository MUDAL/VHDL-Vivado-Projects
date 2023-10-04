library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.tb_pack.all;

entity spi_master_tb is
end spi_master_tb;

architecture rtl of spi_master_tb is

constant bus_width: integer := 8;
signal rst: std_logic;
signal clk: std_logic;
signal addr_in: std_logic_vector(bus_width - 1 downto 0);
signal data_in: std_logic_vector(bus_width - 1 downto 0);
signal ack_in: std_logic_vector(bus_width - 1 downto 0);
signal miso: std_logic;
signal start: std_logic;
signal sck: std_logic;
signal mosi: std_logic;
signal nss: std_logic;
constant clk_period: time := 20 ns;
signal mosi_test: std_logic_vector(bus_width - 1 downto 0);
signal complement: std_logic_vector(bus_width - 1 downto 0);

begin
  UUT: entity work.spi_master 
  generic map(bus_width => bus_width)
  port map(
    rst => rst,
    clk => clk,
    addr_in => addr_in,
    data_in => data_in,
    ack_in => ack_in,
    miso => miso,
    start => start,
    sck => sck,
    mosi => mosi,
    nss => nss
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
  
  complement <= not(data_in);
  
  main_test: process
  --Read the address the master sends to the slave
  procedure read_addr_sent(signal s_mosi_test: out std_logic_vector;
                           signal s_mosi: in std_logic) is 
  begin
    for i in 0 to bus_width - 1 loop 
      s_mosi_test(i) <= s_mosi;
      wait for clk_period;
    end loop; 
  end procedure read_addr_sent;
  
  --Simulate the reception of an ACK or data (complement) from the slave
  procedure simulate_get(signal s_miso: out std_logic;
                         signal s_miso_in: in std_logic_vector) is
  begin
    for i in 0 to bus_width - 1 loop 
      s_miso <= s_miso_in(i); --Slave sending ACK or data to master
      wait for clk_period;
    end loop;
  end procedure simulate_get;
  
  --Initialize testbench's internal signals
  procedure init_tb_signals is
  begin
    set_input(start,'0');
    set_input(miso,'0');
    set_input(mosi_test,x"00");
    set_input(addr_in,x"BA"); --Address of slave device
    set_input(ack_in,x"F4"); --ACK to expect from the slave
    set_input(data_in,x"88"); --Data to send to slave device
  end procedure init_tb_signals;
  
  --Test IDLE state
  procedure test_idle is
  constant msg_idle: string := "Idle";
  begin
    report "Test: " & msg_idle;
    wait for 3 * clk_period;
    check_equal(nss,'1',"NSS - " & msg_idle);
    check_equal(mosi,'0',"MOSI - " & msg_idle);
    set_input(start,'1');
    wait for clk_period;
  end procedure test_idle;
  
  --Test INIT state
  procedure test_init is
  constant msg_init: string := "Init";
  begin
    report "Test: " & msg_init;
    check_equal(nss,'0',"NSS - " & msg_init);
    check_equal(mosi,'0',"MOSI - " & msg_init);
    wait for clk_period;
  end procedure;
  
  --Test SEND ADDR state
  procedure test_send_addr is
  constant msg_send_addr: string := "Send address";
  begin
    report "Test: " & msg_send_addr;
    read_addr_sent(mosi_test,mosi);
    check_equal(nss,'0',"NSS - " & msg_send_addr);
    check_equal(mosi_test,addr_in,"MOSI - " & msg_send_addr);  
  end procedure test_send_addr;
  
  --Test GET ACK state
  procedure test_get_ack is
  constant msg_get_ack: string := "Get ACK"; 
  begin
    report "Test: " & msg_get_ack;
    simulate_get(miso,ack_in); 
    check_equal(nss,'0',"NSS - " & msg_get_ack);
  end procedure test_get_ack;
  
  --Test CHECK ACK state
  procedure test_check_ack is
  constant msg_check_ack: string := "Check ack";
  begin
    report "Test: " & msg_check_ack;
		check_equal(nss,'0',"NSS - " & msg_check_ack);
    wait for clk_period;
  end procedure test_check_ack;
  
  --Test SEND DATA GET COMPLEMENT state
  procedure test_send_data_get_comp is
  constant msg_send_data_get_comp: string := "Send data, get complement"; 
  begin
    report "Test: " & msg_send_data_get_comp;
    check_equal(nss,'0',"NSS - " & msg_send_data_get_comp);
    simulate_get(miso,complement);
  end procedure test_send_data_get_comp;
  
  --Test STOP state
  procedure test_stop is
  constant msg_stop: string := "Stop";
  begin
    report "Test: " & msg_stop;
    check_equal(nss,'1',"NSS - " & msg_stop);
  end procedure test_stop;
  
  --Test STOP - IDLE transition
  procedure test_stop_to_idle is
  constant msg_stop_to_idle: string := "Stop to Idle";
  begin
    report "Test: " & msg_stop_to_idle;
    set_input(start,'0');
    wait for clk_period;
    check_equal(nss,'1',"NSS - " & msg_stop_to_idle);
    check_equal(mosi,'0',"MOSI - " & msg_stop_to_idle);
  end procedure test_stop_to_idle;
  
  begin
    init_tb_signals;
    test_idle;
    test_init;
    test_send_addr;
    test_get_ack;
    test_check_ack;
    test_send_data_get_comp;
    test_stop;
    test_stop_to_idle;
    report "End of simulation" severity failure; --Success
    wait;
  end process;
  
end rtl;
