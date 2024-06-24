----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.command_array.all; --the array of std_logic_vector is defined here

 
entity top is
port (
      --Board integrated clock
      i_clk       : in  std_logic;
      
      --Board pins
      tx_rx_serial : inout std_logic; --send and receive data to Dynamixel 
      
      --Board USB 
      tx_serial_pc: out std_logic; --send data to pc
      
      --Board buttons
      reset : in std_logic;
      start: in std_logic;
          
      --Board switches 
      select_com: in std_logic_vector(2 downto 0);
      on_off: in std_logic;
      angle: in std_logic_vector(5 downto 0); --angle divided by 16
      speed: in std_logic_vector(3 downto 0); --speed divided by 16
      
      --Board led
      endless_enable: out std_logic --endless on/off
      );
end top;
 
architecture behave of top is 

  component tx_send_command is
  Port (                            
    i_clk: in std_logic;            
    command: in mem(0 to 10);       
    lenght:in integer;              
    start: in std_logic;            
    reset: in std_logic;            
                             
    tx_rx_serial: inout std_logic;
                                    
    read_required: in std_logic;
    tx_serial_pc: out std_logic
   );      
  end component;
  
  --tx_send control signals
  signal command: mem(0 to 10);
  signal lenght: integer;
  
  
  component command_generator is
  Port (
      select_com: in std_logic_vector(2 downto 0);
      on_off: in std_logic;
      ax_position: in STD_LOGIC_VECTOR(15 downto 0);
      ax_speed: in STD_LOGIC_VECTOR(15 downto 0);
      start: in std_logic;
      o_command: out mem(0 to 10);
      lenght:out integer;
      reply_lenght: out integer;
      o_endless_status: out STD_LOGIC
  );
  end component;
      
  --Input values by user, to control engine action's parameters
  signal ANGLE_WANTED: STD_LOGIC_VECTOR(8 downto 0);  --Angle in degrees
  signal AX_POSITION_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --ANGLE_WANTED*0.29 degrees
  
  signal SPEED_WANTED: STD_LOGIC_VECTOR(7 downto 0);  --Speed in rpm
  signal AX_SPEED_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --SPEED_WANTED*0.111 rpm
  
  signal ENDLESS_STATUS: STD_LOGIC := '0';
  
  --this signal indicates that the command return a data required to read
  signal o_READ_REQUIRED: STD_LOGIC;
  signal REPLY_LENGHT: integer;
  signal WRITE_ENABLE: STD_LOGIC;
  
  signal w_TX_SERIAL_PC: std_logic;
  
  constant c_CLKS_PER_BIT : integer := 100;
  
begin


--Because we have not enough switches to set the angle in range 0-300, and the speed in 0-111 we split in 16 slices
ANGLE_WANTED <= angle&"000"; --the real angle is the value multiplied by 16
SPEED_WANTED <= speed&"0000"; --the real speed is the value multiplied by 16

----each position step is 0.29 degrees, so calculate the position to move applying a calculus
AX_POSITION_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(ANGLE_WANTED)*100)/29, AX_POSITION_WANTED_ALL'length)); --angle/0.29

--each speed unit is 0.111 rpm, so calculate the speed to set applying a calculus
AX_SPEED_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(SPEED_WANTED)*1000)/111, AX_SPEED_WANTED_ALL'length)); --speed/0,111

--Enable led in Endless is ON
endless_enable <= ENDLESS_STATUS;

com_generator: command_generator
port map(
    select_com => select_com,
    on_off => on_off,
    ax_position => AX_POSITION_WANTED_ALL,
    ax_speed => AX_SPEED_WANTED_ALL,
    start => start, 
    o_command => command,
    lenght => lenght,
    reply_lenght => REPLY_LENGHT,
    o_endless_status => ENDLESS_STATUS
);

tx_sending: tx_send_command
port map(
    i_clk => i_clk,
    command => command,
    lenght => lenght,
    start => start,
    reset => reset,

    read_required => '0',
    
    tx_rx_serial => tx_rx_serial,
    tx_serial_pc => tx_serial_pc
);


end behave;