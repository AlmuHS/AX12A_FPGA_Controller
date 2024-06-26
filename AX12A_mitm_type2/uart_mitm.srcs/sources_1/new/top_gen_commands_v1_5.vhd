library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.command_array.all; --the array of std_logic_vector is defined here

 
entity top is
port (
      i_clk       : in  std_logic;
      
      tx_serial : out std_logic; --send command to servo
      rx_serial: in std_logic; --read command sent by original controller
          
      reset : in std_logic;
      lectura_completa  : out std_logic
      );
end top;
 
architecture behave of top is 

  component tx_send_command is
  Port (
    i_clk: in std_logic;
    command: in mem(0 to 100);
    lenght:in integer;
    start: in std_logic;
    reset: in std_logic;
    
    tx_serial : out std_logic
   );
   end component;
    
    --tx_send control signals
    signal command: mem(0 to 100);
    signal lenght: integer;
          
    signal ENDLESS_STATUS: STD_LOGIC := '0';    
    constant c_CLKS_PER_BIT : integer := 100;
  
    component sniffer_dynamixel is
    generic (
      motor_atacado     : std_logic_vector(7 downto 0) := X"01";
      c_CLKS_PER_BIT : integer := 100   -- Needs to be set correctly
      );
    Port ( i_clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           rx_serial    : in STD_LOGIC;
           lectura_completa : out std_logic;
           comando: out mem(0 to 100);
           long: out integer
    );
    end component;
    
    component command_modifier is
      Port (
        command: in mem(0 to 100); --modified to fit with the sniffer
        out_command: out mem(0 to 100);
        lenght:in integer;
        start: in std_logic
       );
    end component;

    signal sacar      : std_logic;
    signal leido: std_logic := '0';
    signal mod_command: mem(0 to 100);
    
    
begin

lectura_completa <= leido;

sniffer : sniffer_dynamixel
generic map (
    motor_atacado => X"01",
    c_CLKS_PER_BIT => c_CLKS_PER_BIT
)
port map (
    i_clk       => i_clk,
    reset       => reset,
    rx_serial => rx_serial,
    lectura_completa     => leido,
    comando    => command,
    long => lenght
);

--Modify command parameters before sending again
modifier: command_modifier
port map(
    command => command,
    lenght => lenght,
    out_command => mod_command,
    start => leido
);

tx_sending: tx_send_command
port map(
    i_clk => i_clk,
    command => mod_command,
    lenght => lenght,
    start => leido, --send the command just after receive it. Currently send the same command than received
    reset => reset,

    tx_serial => tx_serial
);


end behave;
