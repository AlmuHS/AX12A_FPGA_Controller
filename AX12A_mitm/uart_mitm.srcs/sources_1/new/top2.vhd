----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.02.2024 12:50:02
-- Design Name: 
-- Module Name: top2 - Behavioral
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
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.command_array.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top2 is
  Port (i_clk       : in  std_logic;
      
      tx_serial : out std_logic;
      rx_serial : in  std_logic;
      
      reset : in std_logic;
      select_com: std_logic_vector(3 downto 0)
      --start: in std_logic
  );
end top2;

architecture Behavioral of top2 is

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

  signal r_TX_DV     : std_logic                    := '0';
  signal r_TX_BYTE   : std_logic_vector(7 downto 0) := (others => '0');
  signal w_TX_SERIAL : std_logic;
  signal w_TX_DONE   : std_logic;
  signal w_RX_DV     : std_logic;
  signal w_RX_BYTE   : std_logic_vector(7 downto 0);
  signal r_RX_SERIAL : std_logic := '1';
  
  signal FINISH: STD_LOGIC;
  
  component command_generator is
  Port (
      select_com: in std_logic_vector(3 downto 0);     
      start: in std_logic;
      o_command: out mem(0 to 10);
      lenght: out integer;
      finished: out std_logic
  );
  end component;
  
  component tx_send_command is
  Port (
    i_clk: in std_logic;
    command: in mem(0 to 10);
    lenght:in integer;
    start: in std_logic;
    reset: in std_logic;
    
    tx_serial : out std_logic
   );
end component;

signal command: mem(0 to 10) := (x"FF", x"FF", x"01", x"04", x"03", x"19", x"01", x"DD", x"DD", x"", x""); 
signal lenght: integer := 7;
constant c_CLKS_PER_BIT : integer := 100;

signal start: std_logic;

begin

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

    gen_command: command_generator
    port map(
        select_com => SELECT_COM,
        start => w_RX_DV,
        o_command => command,
        lenght => lenght,
        finished => finish
    );

    send_command: tx_send_command
    port map(
        i_clk => i_clk,
        command => command,
        lenght => lenght,
        start => w_RX_DV,
        reset => reset,
        tx_serial => tx_serial
    );


end Behavioral;
