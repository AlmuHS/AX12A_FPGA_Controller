----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.05.2024 17:35:15
-- Design Name: 
-- Module Name: top_gen_commands_v1_5_tb - Behavioral
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
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


use work.command_array.all; --the array of std_logic_vector is defined here

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_gen_commands_v1_5_tb is
--  Port ( );
end top_gen_commands_v1_5_tb;

architecture Behavioral of top_gen_commands_v1_5_tb is
    component top is
    port (
      i_clk       : in  std_logic;
      
      tx_rx_serial : inout std_logic;      
      tx_serial_pc: out std_logic; --send data to pc
           
      select_com: in std_logic_vector(2 downto 0);
      on_off: in std_logic;
      angle: in std_logic_vector(5 downto 0); --angle divided by 16
      speed: in std_logic_vector(3 downto 0); --speed divided by 16
      
      reset : in std_logic;
      start: in std_logic;
      
      endless_enable: out std_logic;
      
      read_enable: in std_logic
      );
    end component;
    
    signal i_clk                : std_logic;
    signal tx_rx_serial         : std_logic;
    signal tx_serial_pc         : std_logic;
    signal select_com           : std_logic_vector(2 downto 0);
    signal com_counter: integer := 0;
    
    
    signal on_off               : std_logic;
    signal angle                : std_logic_vector(5 downto 0);
    signal speed                : std_logic_vector(3 downto 0);
    signal reset                : std_logic;
    signal start                : std_logic;
    signal endless_enable       : std_logic;
        
    constant clk_period         : time := 10ns;
begin
    uut: top
    port map (
      i_clk => i_clk,
      tx_rx_serial => tx_rx_serial, 
      tx_serial_pc => tx_serial_pc,
      select_com => select_com,
      on_off => on_off,
      angle => angle,
      speed => speed,
      reset => reset,
      start => start,
      endless_enable => endless_enable,
      read_enable => '1'
      );

    tbclk: process
    begin
        i_clk <= '0';
        wait for clk_period/2;
        i_clk <= '1';
        wait for clk_period/2;
    end process;
    
    tbreset: process
    begin
        reset <= '1';
        wait for 11*clk_period/4;
        reset <= '0';
        wait;
    end process;
    
    tbdata:process
    begin
        tx_rx_serial <= 'H';
        tx_serial_pc <= '1';
        com_counter <= 0;
        select_com <= "000";
        on_off <= '1';
        angle <= (others => '0');
        speed <= (others => '0');
        
        start <= '0';
        wait until reset='0';
        loop
            select_com <= std_logic_vector(to_unsigned(com_counter, select_com'length));
            wait for 10*clk_period;
            start <= '1';
            wait for clk_period;
            start <= '0';
            wait for 1000000*clk_period;
            if(com_counter < 5) then
                com_counter <= com_counter + 1;
            else
                com_counter <= 0;
            end if;
        end loop;
        wait;
    end process;
    
end Behavioral;
