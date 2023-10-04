library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
  generic(bus_width: integer := 8);
  port(
    rst: in std_logic;
    clk: in std_logic;
    addr_in: in std_logic_vector(bus_width - 1 downto 0);
    data_in: in std_logic_vector(bus_width - 1 downto 0);
    ack_in: in std_logic_vector(bus_width - 1 downto 0);
    miso: in std_logic;
    start: in std_logic;
    sck: out std_logic;
    mosi: out std_logic;
    nss: out std_logic
  );
end spi_master;

architecture rtl of spi_master is
type spi_state is (IDLE, INIT, SEND_ADDR, GET_ACK, 
                   CHECK_ACK, SEND_DATA_GET_COMP, STOP);
signal state: spi_state;
signal next_state: spi_state;
signal index: integer range 0 to bus_width - 1;
signal miso_buffer: std_logic_vector(bus_width - 1 downto 0);
signal sck_en: std_logic;
signal valid: std_logic;

begin
  --State transition
  process(state,start,index,miso_buffer,ack_in)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if start = '1' then
          next_state <= INIT;
        end if;
      when INIT =>
        next_state <= SEND_ADDR;
      when SEND_ADDR =>
        if index = bus_width - 1 then
          next_state <= GET_ACK;
        end if;
      when GET_ACK =>
        if index = bus_width - 1 then
          next_state <= CHECK_ACK;
        end if;
      when CHECK_ACK =>
        if miso_buffer = ack_in then
          next_state <= SEND_DATA_GET_COMP;
        else
          next_state <= STOP;
        end if;
      when SEND_DATA_GET_COMP =>
        if index = bus_width - 1 then
          next_state <= STOP;
        end if;
      when STOP =>
        if start = '0' then
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
  process(state,index,addr_in,data_in)
  begin
    nss <= '0';
    mosi <= '0';
    sck_en <= '1';
    case state is
      when IDLE | STOP =>
        nss <= '1';
        sck_en <= '0';
      when SEND_ADDR =>
        mosi <= addr_in(index);
      when SEND_DATA_GET_COMP =>
        mosi <= data_in(index);
      when others =>
    end case;
  end process;

  --Mealy output(s)
  sck <= clk when sck_en = '1' else
         '0' when sck_en = '0';
  
  process(state,miso_buffer,data_in)
  begin
    valid <= '0';
    case state is
      when STOP =>
        if miso_buffer = not(data_in) then
          valid <= '1';
        end if;
      when others =>
    end case;
  end process;

  --Buffering ACK or data(complement) from MISO line
  process(rst,clk)
  begin
    if rst = '1' then
      miso_buffer <= (others => '0');
    elsif rising_edge(clk) then
      case state is
        when GET_ACK | SEND_DATA_GET_COMP =>
          miso_buffer(index) <= miso;
        when others =>
      end case;
    end if;
  end process;
  
  --Index counter
  process(rst,clk)
  begin
    if rst = '1' then
      index <= 0;
    elsif rising_edge(clk) then
      case state is
        when SEND_ADDR | GET_ACK | SEND_DATA_GET_COMP =>
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
