----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.05.2024 19:23:07
-- Design Name: 
-- Module Name: sniffer_dynamixel - Behavioral
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

use work.command_array.all; --the array of std_logic_vector is defined here

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sniffer_dynamixel is
    generic (
      motor_atacado     : std_logic_vector(7 downto 0) := X"01";
      c_CLKS_PER_BIT : integer := 100   -- Needs to be set correctly
      );
    Port ( i_clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           rx_serial    : in STD_LOGIC;
           lectura_completa : out std_logic;
           data_out     : out std_logic_vector(7 downto 0);
           sacar        : in std_logic
    );
end sniffer_dynamixel;

architecture Behavioral of sniffer_dynamixel is
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

    signal rx_done      : std_logic;
    signal rx_byte      : std_logic_vector(7 downto 0);
    
    -- Captura de información
    type estados_asm is (inicio, cabecera1, cabecera2, direccion, longitud, parametros, chequeo);
    signal estado   : estados_asm;
    signal tam_trama : std_logic_vector(7 downto 0);
    signal data_tmp : mem(0 to 100);
begin
    sniffer : uart_rx
    generic map (
        g_CLKS_PER_BIT => c_CLKS_PER_BIT
    )
    port map (
        i_clk       => i_clk,
        i_rx_serial => rx_serial,
        o_rx_dv     => rx_done,
        o_rx_byte   => rx_byte
    );

    -- Captura de información
    P1:process (i_clk, reset)
    begin
        if (reset = '1') then
            estado <= inicio;
            tam_trama <= (others => '0');
            data_tmp <= (others => (others => '0'));
            lectura_completa <= '0';
        elsif (i_clk='1' and i_clk'event) then
            case estado is
                when cabecera1 =>
                    if (rx_done = '1') then
                        tam_trama <= (others => '0');
                        data_tmp <= (others => (others => '0'));
                        lectura_completa <= '0';
                        if (rx_byte = X"FF") then
                            estado <= cabecera2;
                        end if;
                    end if;
                when cabecera2 => 
                    if (rx_done = '1') then
                        if (rx_byte = X"FF") then
                            estado <= direccion;
                        else
                            estado <= inicio;
                        end if;
                    end if;
                when direccion =>
                    if (rx_done = '1') then
                        if (rx_byte = X"FF") then
                            estado <= cabecera1;
                        else
                            data_tmp <= rx_byte & data_tmp(0 to 99);
                            estado <= longitud;
                        end if;
                    end if;
                when longitud =>
                    if (rx_done = '1') then
                        tam_trama <= rx_byte;
                        data_tmp <= rx_byte & data_tmp(0 to 99);
                        estado <= parametros;
                    end if;
                when parametros =>
                    if (rx_done = '1') then
                        tam_trama <= tam_trama-1;
                        data_tmp <= rx_byte & data_tmp(0 to 99);
                        estado <= parametros;
                    else
                        if (tam_trama = 0) then
                            estado <= chequeo;
                        end if;
                    end if;
                when chequeo =>
                    lectura_completa <= '1';
                    estado <= inicio;
                when others =>
                    estado <= cabecera1; 
            end case;
        end if;
    end process;

end Behavioral;