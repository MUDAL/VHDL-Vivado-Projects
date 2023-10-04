library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_slave is
  generic(bus_width: integer := 8);
  port(
    rst: in std_logic;
    addr_in: in std_logic_vector(bus_width - 1 downto 0);
    ack_in: in std_logic_vector(bus_width - 1 downto 0);
    mosi: in std_logic;
    sck: in std_logic;
    nss: in std_logic;
    miso: out std_logic
  );
end spi_slave;

architecture rtl of spi_slave is
type spi_state is (IDLE, GET_ADDR, CHECK_ADDR, SEND_ACK,
                   GET_DATA_SEND_COMP, STOP);
signal state: spi_state;
signal next_state: spi_state;
signal index: integer range 0 to bus_width - 1;
signal mosi_buffer: std_logic_vector(bus_width - 1 downto 0);

begin
  --State transition
  process(state,nss,index,mosi_buffer,addr_in)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if nss = '0' then
          next_state <= GET_ADDR;
        end if;
      when GET_ADDR =>
        if index = bus_width - 1 then
          next_state <= CHECK_ADDR;
        end if;
      when CHECK_ADDR =>
        if mosi_buffer = addr_in then
          next_state <= SEND_ACK;
        else
          next_state <= STOP;
        end if;
      when SEND_ACK =>
        if index = bus_width - 1 then
          next_state <= GET_DATA_SEND_COMP;
        end if;
      when GET_DATA_SEND_COMP =>
        if index = bus_width - 1 then
          next_state <= STOP;
        end if;
      when STOP =>
        if nss = '1' then
          next_state <= IDLE;
        end if;
    end case;
  end process;
  
  --State register
  process(rst,sck)
  begin
    if rst = '1' then
      state <= IDLE;
    elsif rising_edge(sck) then
      state <= next_state;
    end if;
  end process;
  
  --Moore output(s)
  process(state,index,mosi_buffer)
  begin
    miso <= '0';
    case state is
      when SEND_ACK =>
        miso <= ack_in(index);
      when GET_DATA_SEND_COMP =>
        miso <= not(mosi_buffer(index));
      when others =>
    end case;
  end process;
  
  --Buffering address or data on MOSI line
  process(rst,sck)
  begin
    if rst = '1' then
      mosi_buffer <= (others => '0');
    elsif rising_edge(sck) then
      case state is
        when GET_ADDR | GET_DATA_SEND_COMP =>
          mosi_buffer(index) <= mosi;
        when others =>
      end case;
    end if;
  end process;
  
  --Index counter
  process(rst,sck)
  begin
    if rst = '1' then
      index <= 0;
    elsif rising_edge(sck) then
      case state is
        when GET_ADDR | SEND_ACK | GET_DATA_SEND_COMP =>
          if index = bus_width - 1 then
            index <= 0;
          else
            index <= index + 1;
          end if;
        when others =>
          index <= 0;
      end case;
    end if;
  end process;
  
end rtl;
