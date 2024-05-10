----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.02.2024 16:19:19
-- Design Name: 
-- Module Name: half_duplex_uart - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity half_duplex_uart is
  Port (i_clk: in std_logic;
        serial_data: inout std_logic;
        
        TX_RX_mode: in std_logic;

        
        i_TX_DV     : in  std_logic;
        i_TX_Byte   : in  std_logic_vector(7 downto 0);
        o_TX_Done   : out std_logic;
        o_TX_Active : out std_logic;
        
        o_RX_DV     : out std_logic;
        o_RX_Byte   : out std_logic_vector(7 downto 0)
        );
end half_duplex_uart;

architecture Behavioral of half_duplex_uart is

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

  signal w_RX_SERIAL: std_logic;
  signal r_TX_SERIAL: std_logic;

  constant c_CLKS_PER_BIT : integer := 100;
  signal w_TX_ACTIVE: std_logic;-- := '0';

begin

o_TX_Active <= w_TX_Active;

-- Instantiate UART Receiver
UART_RX_INST : uart_rx
generic map (
  g_CLKS_PER_BIT => c_CLKS_PER_BIT
  )
port map (
  i_clk       => i_clk,
  i_rx_serial => w_RX_SERIAL,
  o_rx_dv     => o_RX_DV,
  o_rx_byte   => o_RX_BYTE
  );
  
-- Instantiate UART transmitter 
UART_TX_PC : uart_tx 
  generic map (
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => i_clk,
      i_tx_dv     => i_TX_DV,
      i_tx_byte   => i_TX_BYTE,
      o_tx_active => w_TX_ACTIVE,
      o_tx_serial => r_TX_SERIAL,
      o_tx_done   => o_TX_DONE
      );

--Half duplex communication
serial_data <= r_TX_SERIAL when TX_RX_MODE = '1' else 'Z'; --write mode
w_RX_SERIAL <= serial_data; --read mode


end Behavioral;
