----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.02.2024 13:56:30
-- Design Name: 
-- Module Name: tx_send_command - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.command_array.all;

entity tx_send_command is
  Port (
    i_clk: in std_logic;
    command: in mem(0 to 100);
    lenght:in integer;
    start: in std_logic;
    reset: in std_logic;
    
    tx_serial : out std_logic
   );
end tx_send_command;

architecture Behavioral of tx_send_command is

    component uart_tx is
    generic (
        g_CLKS_PER_BIT : integer := 100   -- Needs to be set correctly
    );
    port (
        i_clk       : in  std_logic; --clock
        i_tx_dv     : in  std_logic; --enable to start the sending
        i_tx_byte   : in  std_logic_vector(7 downto 0); --8-bit data packet
        o_tx_active : out std_logic; --enable to half-duplex
        o_tx_serial : out std_logic; --the data to send
        o_tx_done   : out std_logic --enabled is transmission is end
    );
    end component uart_tx;
    
    
    constant c_CLKS_PER_BIT : integer := 100;
    constant c_BIT_PERIOD : time := 10 ns;
    
    --UART signals 
    signal r_TX_DV     : std_logic                    := '0';
    signal r_TX_BYTE   : std_logic_vector(7 downto 0) := (others => '0');
    signal w_TX_SERIAL : std_logic;
    signal w_TX_DONE   : std_logic;

    signal w_TX_ACTIVE: std_logic;-- := '0';
        
    signal index: integer;  
  
    type state is (s_start_click, s_wait_unclick, s_start, s_check_tx, s_prepare, s_tx_send, s_wait_end); 
    signal cur_state: state; 
    
begin
        
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
                    if index <= lenght then --check if all commands are sent
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

    
    
end Behavioral;
