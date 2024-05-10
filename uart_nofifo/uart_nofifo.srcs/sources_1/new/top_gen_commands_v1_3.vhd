----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
--use IEEE.MATH_REAL.ALL;

 
entity top is
port (
      i_clk       : in  std_logic;
      
      tx_serial : out std_logic;
      --rx_serial : in  std_logic;
      
      select_com: in std_logic_vector(2 downto 0);
      on_off: in std_logic;
      angle: in std_logic_vector(4 downto 0); --angle divided by 16
      speed: in std_logic_vector(3 downto 0); --speed divided by 16
      
      reset : in std_logic;
      start: in std_logic;
      
      endless_enable: out std_logic
      );
end top;
 
architecture behave of top is
 
  type mem is array(integer range <>) of STD_LOGIC_VECTOR(7 downto 0); --8-bit each element  

 
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
  
  --tx_send control signals
  signal command: mem(0 to 10);
  signal lenght: integer;
  
  --Dynamixel constants
  constant AX_START: STD_LOGIC_VECTOR(7 downto 0) := x"FF";
  constant ID: STD_LOGIC_VECTOR(7 downto 0) := x"01"; --servo's id
  constant AX_WRITE: STD_LOGIC_VECTOR(7 downto 0) := x"03";
  constant AX_LED_ADDR: STD_LOGIC_VECTOR(7 downto 0) := x"19";
  constant LED_ON: STD_LOGIC_VECTOR(7 downto 0) := x"01";
  constant LED_OFF: STD_LOGIC_VECTOR(7 downto 0) := x"00";
  constant AX_GOAL_POSITION_L: STD_LOGIC_VECTOR(7 downto 0) := x"1E"; 
  constant AX_GOAL_LENGHT: STD_LOGIC_VECTOR(7 downto 0) := x"05";
  constant AX_SPEED_LENGHT: STD_LOGIC_VECTOR(7 downto 0) := x"05";
  constant AX_GOAL_SPEED_L: STD_LOGIC_VECTOR(7 downto 0) := x"20";
  constant AX_CCW_ANGLE_LIMIT_L: STD_LOGIC_VECTOR(7 downto 0) := x"08";
  constant AX_CCW_AL_L: STD_LOGIC_VECTOR(7 downto 0) := x"FF";
  constant AX_CCW_AL_H: STD_LOGIC_VECTOR(7 downto 0) := x"03";
  constant AX_GOAL_SP_LENGTH: STD_LOGIC_VECTOR(7 downto 0) := x"07";

  --Dynamixel config values
  signal AX_LENGHT: STD_LOGIC_VECTOR(7 downto 0) := x"04";
  signal AX_CHECKSUM: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_POSITION_WANTED_L: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_POSITION_WANTED_H: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_SPEED_WANTED_L: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_SPEED_WANTED_H: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_LED_STATUS: STD_LOGIC_VECTOR(7 downto 0);
  
    
  --Input values by user, to control engine action's parameters
  signal ANGLE_WANTED: STD_LOGIC_VECTOR(8 downto 0);  --Angle in degrees
  signal AX_POSITION_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --ANGLE_WANTED*0.29 degrees
  
  signal SPEED_WANTED: STD_LOGIC_VECTOR(7 downto 0);  --Speed in rpm
  signal AX_SPEED_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --SPEED_WANTED*0.111 rpm
  
  signal ENDLESS_STATUS: STD_LOGIC := '0';
    
  
  
begin

tx_sending: tx_send_command
port map(
    i_clk => i_clk,
    command => command,
    lenght => lenght,
    start => start,
    reset => reset,
    
    tx_serial => tx_serial

);

ANGLE_WANTED <= angle&"0000"; --the real angle is the value multiplied by 16
SPEED_WANTED <= speed&"0000"; --the real speed is the value multiplied by 16


--ANGLE_WANTED <= angle_speed when select_com = "001" or select_com = "100" or select_com = "101";
--SPEED_WANTED <= angle_speed when select_com = "010";


--ANGLE_WANTED <= angle_speed(3 downto 0)&"0000" when (ENDLESS_STATUS = '0' and select_com = "100") else angle_speed(7 downto 0); 
--SPEED_WANTED <= angle_speed(6 downto 0) when ENDLESS_STATUS='1' else angle_speed(10 downto 4); 


----each position step is 0.29 degrees, so calculate the position to move applying a calculus
AX_POSITION_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(ANGLE_WANTED)*100)/29, AX_POSITION_WANTED_ALL'length)); --angle/0.29

--each speed unit is 0.111 rpm, so calculate the speed to set applying a calculus
AX_SPEED_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(SPEED_WANTED)*1000)/111, AX_SPEED_WANTED_ALL'length)); --speed/0,111


set_com: process(start) is
begin
    endless_enable <= ENDLESS_STATUS;

    command(0) <= AX_START;
    command(1) <= AX_START;
    command(2) <= ID;  
    
    case select_com is
        when "000" => --LED ON - FF FF 01 04 03 19 01 DD
            AX_LENGHT <= x"04";
            --AX_CHECKSUM <= x"DD";
            
            command(3) <= AX_LENGHT;
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_LED_ADDR; --x04
            
            if on_off = '0' then
                command(6) <= x"00"; --OFF
            else
                command(6) <= x"01"; --ON
            end if;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6)) and x"FF";
            command(7) <= AX_CHECKSUM; --xDD
            
            lenght <= 7;

        when "001" => --Move to position indicates by angle wanted
            AX_POSITION_WANTED_L <= AX_POSITION_WANTED_ALL(7 downto 0);
            AX_POSITION_WANTED_H <= AX_POSITION_WANTED_ALL(15 downto 8);
             
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xDD
            
            lenght <= 8;
            
       when "010" => --turn at speed indicated by speed wanted
            AX_SPEED_WANTED_L <= AX_SPEED_WANTED_ALL(7 downto 0);
            AX_SPEED_WANTED_H <= AX_SPEED_WANTED_ALL(15 downto 8);
       
       
            command(3) <= AX_SPEED_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_SPEED_L; --x20
            command(6) <= AX_SPEED_WANTED_L;
            command(7) <= AX_SPEED_WANTED_H;            
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEB
            
            lenght <= 8;
    
        when "011" => --Endless ON/OFF -- FF FF 01 05 03 08 00 00 EE -- FF FF 01 05 03 08 FF 03 EC
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_CCW_ANGLE_LIMIT_L; --x08
            
            if on_off = '1' then --ON
                command(6) <= x"00";
                command(7) <= x"00";
                
                ENDLESS_STATUS <= '1';
                
            else --OFF
                command(6) <= AX_CCW_AL_L; --xFF
                command(7) <= AX_CCW_AL_H; --x03
                
                ENDLESS_STATUS <= '0';
                
            end if;
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEE
            
            lenght <= 8;
            
        when "100" => --Move to the position indicated by position wanted, at the indicated speed      
            --The position is only used is Endless mode is disabled
            AX_POSITION_WANTED_L <= AX_POSITION_WANTED_ALL(7 downto 0);
            AX_POSITION_WANTED_H <= AX_POSITION_WANTED_ALL(15 downto 8);

            AX_SPEED_WANTED_L <= AX_SPEED_WANTED_ALL(7 downto 0);
            AX_SPEED_WANTED_H <= AX_SPEED_WANTED_ALL(15 downto 8);

        
            command(3) <= AX_GOAL_SP_LENGTH; --x07
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            
            
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            
            
            command(8) <= AX_SPEED_WANTED_L;
            command(9) <= AX_SPEED_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7) + command(8) + command(9)) and x"FF";
            command(10) <= AX_CHECKSUM; --x00
            
            lenght <= 10;      
         
         when others => --turn LED ON
            AX_LENGHT <= x"04";
            AX_CHECKSUM <= x"DD";
            
            command(3) <= AX_LENGHT;
            command(4) <= AX_WRITE;
            command(5) <= AX_LED_ADDR;
            command(6) <= LED_ON;
            command(7) <= AX_CHECKSUM;
            
            lenght <= 7;
    end case;
    
end process;


end behave;