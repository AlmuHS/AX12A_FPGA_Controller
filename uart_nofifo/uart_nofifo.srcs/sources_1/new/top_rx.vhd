----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity top is
port (
      i_clk       : in  std_logic;
      
      tx_serial : out std_logic;
      rx_serial : in  std_logic;
      
      on_off: in std_logic;
      reset : in std_logic;
      start: in std_logic
      );
end top;
 
architecture behave of top is
 
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
 
  constant c_BIT_PERIOD : time := 10 ns;
   
  signal r_TX_DV     : std_logic                    := '0';
  signal r_TX_BYTE   : std_logic_vector(7 downto 0) := (others => '0');
  signal w_TX_SERIAL : std_logic;
  signal w_TX_DONE   : std_logic;
  signal w_RX_DV     : std_logic;
  signal w_RX_BYTE   : std_logic_vector(7 downto 0);
  signal r_RX_SERIAL : std_logic := '1';
 
    
  type mem is array(integer range <>) of STD_LOGIC_VECTOR(7 downto 0);
  signal command: mem(0 to 8) := (x"FF", x"FF", x"01", x"04", x"03", x"19", x"01", x"DD", x"DD"); 
    
  signal index: integer;
  signal index2: integer;
  
  type state is (s_start, s_wait_start, s_check_rx, s_wait_receive, s_rx_receive); 
  signal cur_state: state; 
 
  
begin

---- Instantiate UART transmitter - To simply reply the RX data in TX
--UART_TX_INST : uart_tx 
--  generic map (
--    g_CLKS_PER_BIT => c_CLKS_PER_BIT
--      )
--    port map (
--      i_clk       => i_clk,
--      i_tx_dv     => w_RX_DV,
--      i_tx_byte   => w_RX_BYTE,
--      o_tx_active => open,
--      o_tx_serial => tx_serial,
--      o_tx_done   => open
--      );
      
--Instantiate UART transmitter  - To send a new command
UART_TX_INST : uart_tx 
  generic map (
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => i_clk,
      i_tx_dv     => r_TX_DV,
      i_tx_byte   => r_TX_BYTE,
      o_tx_active => open,
      o_tx_serial => tx_serial,
      o_tx_done   => w_TX_DONE
      );
      
-- Instantiate UART Receiver
  UART_RX_INST : uart_rx
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => i_clk,
      i_rx_serial => rx_serial,
      o_rx_dv     => w_RX_DV,
      o_rx_byte   => w_RX_BYTE
      );


 --TODO: Modify to receive the command
 --When receive is complete o_rx_dv will be driven high for one clock cycle
 
    receive_com: process(i_clk, reset) 
    begin 
        if reset = '1' then
           cur_state <= s_start_click;
        elsif (i_clk='1' and i_clk'event) then
            case cur_state is 
                when s_start => --start the reception process
                    index <= 0; --set command index to zero, to access to the command's first data
                    cur_state <= s_wait_start; --start transmission
                 
                 when s_wait_start =>
                    if i_RX_SERIAL = '0' then --wait to start reception
                        cur_state <= s_check_rx;
                    else
                        cur_state <= w_wait_start;
                    end if;
                        
                 when s_check_rx =>  --prepare data for reception
                    if index <= 10 then --check if all command data are received. Each command has a max of 11 fields
                        cur_state <= s_wait_receive; --if not, prepare to receive next command data
                    else
                        cur_state <= s_start; --if the command is fully received, wait until a new start
                    end if;
                
                 when s_wait_receive => --prepare new command data
                    if r_RX_DV = '1' then --check the data is sent
                        cur_state <= s_rx_receive; 
                    else
                        cur_state <= s_wait_receive;
                    end if;
                        
                when s_rx_receive => --send the written data
                    if r_RX_DV = '0' then --if data is full received
                        command(index) <= w_RX_BYTE; --read the command from the port
                        index <= index + 1; --increase command data index
                        
                        cur_state <= s_wait_start;
                    else 
                        cur_state <= s_rx_receive;
                    end if;                    
            end case; 
        end if;
    end process;


end behave;