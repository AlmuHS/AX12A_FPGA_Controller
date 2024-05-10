----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
use work.command_array.all; --the array of std_logic_vector is defined here


entity reply_rx_tx is
port (
      i_clk       : in  std_logic;
      
      tx_serial : out std_logic;
      rx_serial : in  std_logic;
      
      enable : in std_logic
      );
end reply_rx_tx;
 
architecture behave of reply_rx_tx is
 
  component uart_tx is
    generic (
      g_CLKS_PER_BIT : integer := 100   -- Needs to be set correctly
      );
    port (
      i_clk       : in  std_logic;
      i_tx_dv     : in  std_logic;
      i_tx_byte   : in  std_logic_vector(7 downto 0);
      o_tx_active : out std_logic;
      o_tx_serial : out std_logic;
      o_tx_done   : out std_logic
      );
  end component uart_tx;
   
  component uart_rx is
    generic (
      g_CLKS_PER_BIT : integer := 100   -- Needs to be set correctly
      );
    port (
      i_clk       : in  std_logic;
      i_rx_serial : in  std_logic;
      o_rx_dv     : out std_logic;
      o_rx_byte   : out std_logic_vector(7 downto 0)
      );
  end component uart_rx;
   
  -- Test Bench uses a 10 MHz Clock
  -- Want to interface to 115200 baud UART
  -- 10000000 / 115200 = 87 Clocks Per Bit.
  constant c_CLKS_PER_BIT : integer := 100;
 
  constant c_BIT_PERIOD : time := 8680 ns;
   
  signal w_TX_SERIAL : std_logic;
  signal w_RX_DV     : std_logic;
  signal w_RX_BYTE   : std_logic_vector(7 downto 0);
  signal r_RX_SERIAL : std_logic := '1';
  signal w_TX_BYTE   : std_logic_vector(7 downto 0);
  signal w_TX_DV     : std_logic;

  type state is (s_start, s_store, s_end);
  signal cur_state: state; 
  
  --tx_send control signals
  signal command: mem(0 to 10);
  signal lenght: integer;
  signal index: integer := 0;
  
    
begin

r_RX_SERIAL <= rx_serial;
--tx_serial <= w_TX_SERIAL when enable = '1' else 'Z';

  -- Instantiate UART Receiver
  UART_RX_INST : uart_rx
    port map (
      i_clk       => i_clk,
      i_rx_serial  => r_rx_serial,
      o_rx_dv     => w_RX_DV,
      o_rx_byte   => w_RX_BYTE
      );
  
-- Instantiate UART transmitter 
UART_TX_INST : uart_tx 
  generic map (
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => i_clk,
      i_tx_dv     => w_RX_DV,
      i_tx_byte   => w_RX_BYTE,
      o_tx_active => open,
      o_tx_serial => tx_serial,
      o_tx_done   => open
      );
      
--      process(i_clk) is
--      begin
--        if i_clk'event and i_clk='1' then
--            if w_RX_DV = '1' and w_RX_BYTE = x"FF" then
--                command(0) <= w_RX_BYTE;
--                index <= 1;
--                cur_state <= s_start;
--                w_TX_DV <= '0';
--            end if;
            
--            case cur_state is
--                when s_start => 
--                    if w_RX_DV = '1' and w_RX_BYTE = x"FF" then
--                       command(index) <= w_RX_BYTE;
--                       index <= index + 1;
                       
--                       cur_state <= s_store;
--                    else
--                        cur_state <= s_start;
--                    end if;
                    
--                when s_store =>
--                    if w_RX_DV = '1' then
--                        if w_RX_BYTE <= x"FF" then
--                            command(1) <= w_RX_BYTE;
--                            index <= 2;
--                        elsif w_RX_BYTE <= x"01" then
--                            command(2) <= w_RX_BYTE;
--                            index <= 3;
--                        elsif index < 5 then
--                            command(index) <= w_RX_BYTE;
--                            index <= index + 1;
--                        else
--                            cur_state <= s_end;
--                        end if;
--                     end if;
                    
                        
--                    if index < 5 then
--                        cur_state <= s_store;
--                    else
--                        cur_state <= s_end;
--                    end if;
                
--                when s_end =>
--                    w_TX_BYTE <= command(4);
--                    w_TX_DV <= '1';
                
--                    cur_state <= s_start;
--            end case;
--        end if;
--      end process;

end behave;
