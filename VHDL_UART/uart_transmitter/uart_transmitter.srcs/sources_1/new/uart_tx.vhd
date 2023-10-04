library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
  generic(
    clk_freq: integer := 50_000_000;
    bus_width: integer := 8;
    baud_rate: integer := 9600;
    tx_data: std_logic_vector := x"41"
  );
  port(
    rst: in std_logic;
    clk: in std_logic;
    en: in std_logic;
    data_out: out std_logic
  );
end uart_tx;

architecture rtl of uart_tx is

type uart_state is (IDLE, INIT, START_BIT, 
                    SEND_DATA, STOP_BIT, PAUSE);
signal state: uart_state;
signal next_state: uart_state;
signal data_in: std_logic_vector(bus_width - 1 downto 0);
signal bit_index: integer range 0 to bus_width - 1;
constant clk_per_bit: integer := clk_freq / baud_rate;
signal clk_counter: integer;

begin
  --Set input
  data_in <= tx_data;
  
  --State transition
  process(state,en,bit_index,clk_counter)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if en = '1' then
          next_state <= INIT;
        end if;
      when INIT =>
        if clk_counter = clk_per_bit - 1 then
          next_state <= START_BIT;
        end if;
      when START_BIT =>
        if clk_counter = clk_per_bit - 1 then
          next_state <= SEND_DATA;
        end if;
      when SEND_DATA =>
        if bit_index = bus_width - 1 and clk_counter = clk_per_bit - 1 then
          next_state <= STOP_BIT;
        end if;
      when STOP_BIT =>
        if clk_counter = clk_per_bit - 1 then
          next_state <= PAUSE;
        end if;
      when PAUSE =>
        if clk_counter = clk_freq - 1 then
          next_state <= IDLE;
        end if;
    end case;
  end process;
  
  --State register
  process(rst,clk)
  begin
    if rst = '1' then
      state <= IDLE; 
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  --Moore output(s)
  process(state,data_in,bit_index)
  begin
    case state is
      when SEND_DATA =>
        data_out <= data_in(bit_index);
      when START_BIT =>
        data_out <= '0';  
      when others =>
        data_out <= '1';
    end case;
  end process;
  
  --Clock (cycle) counter
  process(rst,clk)
  procedure inc_counter(signal counter: inout integer;
                        constant max_value: in integer) is
  begin
    if counter = max_value - 1 then
      counter <= 0;
    else
      counter <= counter + 1;
    end if;
  end procedure inc_counter;
    
  begin
    if rst = '1' then
      clk_counter <= 0;
    elsif rising_edge(clk) then
      case state is
        when INIT | START_BIT | SEND_DATA | STOP_BIT =>
          inc_counter(clk_counter,clk_per_bit);
        when PAUSE =>
          inc_counter(clk_counter,clk_freq);
        when others =>
          clk_counter <= 0;
      end case;
    end if;
  end process;
  
  --Bit index counter
  process(rst,clk)
  begin
    if rst = '1' then
      bit_index <= 0;
    elsif rising_edge(clk) then
      case state is
        when SEND_DATA =>
          if clk_counter = clk_per_bit - 1 then
            if bit_index < bus_width - 1 then
              bit_index <= bit_index + 1;
            end if;
          end if;
        when others =>
          bit_index <= 0;
      end case;
    end if;
  end process;

end rtl;
