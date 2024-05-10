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
      --rx_serial : in  std_logic;
      
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
  
  type state is (s_start_click, s_wait_unclick, s_start, s_check_tx, s_prepare, s_tx_send, s_wait_end); 
  signal cur_state: state; 
 
  
begin

--allow to turn off led
command(6) <= x"01" when on_off='1' else x"00";
command(7) <= x"DD" when on_off='1' else x"DE";

-- Instantiate UART transmitter 
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
    
    p1: process(i_clk, reset) 
    begin 
        if reset = '1' then
           cur_state <= s_start_click;
        elsif (i_clk='1' and i_clk'event) then
            case cur_state is 
                when s_start_click => --waiting to press button start
                    if start = '1' then
                        cur_state <= s_wait_unclick; --if button is pressed, wait until button is unpressed before start
                     else 
                        cur_state <= s_start_click; --if button is unpressed, start the process
                     end if;
                     
                  when s_wait_unclick => --wait until button is unpressed
                    if start = '0' then
                        cur_state <= s_start;
                    else 
                        cur_state <= s_wait_unclick;
                    end if;
            
                when s_start => --start the transmission process
                    index <= 0; --set command index to zero, to access to the command's first data
                    cur_state <= s_check_tx; --start transmission
                    
                 when s_check_tx =>  --prepare data for transmission
                    r_TX_DV <= '0'; --set start transmission flag to 0, to disable transmission until data is ready to send
                    if index <= 7 then --check if all commands are sent
                        cur_state <= s_prepare; --if not, pprepare to send next command data
                    else
                        cur_state <= s_start_click; --if the command is fully sent, wait until a new start
                    end if;
                
                 when s_prepare => --prepare new command data
                    r_TX_BYTE <= command(index); --write the command data to the port
                    index <= index + 1; --increase command data index
                    
                    cur_state <= s_tx_send;
                
                when s_tx_send => --send the written data
                    r_TX_DV <= '1'; --enable signal to start data transmission
                    
                    cur_state <= s_wait_end;
                
                when s_wait_end => --wait until data is sent
                    r_TX_DV <= '0';
                    if w_TX_DONE = '0' then --if the signal indicates data is not fully sent, continues waiting
                        cur_state <= s_wait_end;
                    elsif w_TX_DONE = '1' then --if the data is fully sent, start again to send a new command
                        cur_state <= s_check_tx;
                    end if;
            end case; 
        end if;
            
        
    
    end process;


end behave;