----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.02.2024 16:18:29
-- Design Name: 
-- Module Name: command_generator - Behavioral
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

entity command_generator is
  Port (
      select_com: in std_logic_vector(3 downto 0);     
      start: in std_logic;
      o_command: out mem(0 to 10);
      lenght: out integer;
      finished: out std_logic
  );
end command_generator;

architecture Behavioral of command_generator is

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
  
  constant AX_READ_DATA: STD_LOGIC_VECTOR(7 downto 0) := x"02";
  constant AX_PRESENT_SPEED_L: STD_LOGIC_VECTOR(7 downto 0):= x"26";
  constant AX_BYTE_READ_POS: STD_LOGIC_VECTOR(7 downto 0) := x"02";
  constant AX_POS_LENGTH: STD_LOGIC_VECTOR(7 downto 0) := x"04";

  --Dynamixel config values
  signal AX_LENGHT: STD_LOGIC_VECTOR(7 downto 0) := x"04";
  signal AX_CHECKSUM: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_POSITION_WANTED_L: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_POSITION_WANTED_H: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_SPEED_WANTED_L: STD_LOGIC_VECTOR(7 downto 0);
  signal AX_SPEED_WANTED_H: STD_LOGIC_VECTOR(7 downto 0);
      
  --Input values by user, to control engine action's parameters
  signal AX_POSITION_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --ANGLE_WANTED*0.29 degrees  
  signal AX_SPEED_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --SPEED_WANTED*0.111 rpm
    
  --command to generate using type of command (select_com), position and speed
  signal command: mem(0 to 10);

  --this signal is enabled when ENDLESS mode is active
  signal ENDLESS_STATUS: STD_LOGIC := '0';
  
  signal FINISH: STD_LOGIC := '0';

begin

o_command <= command;
finished <= FINISH;

set_com: process(start) is
begin
    command(0) <= AX_START;
    command(1) <= AX_START;
    command(2) <= ID;    

    case select_com is
        when "0000" => --LED ON - FF FF 01 04 03 19 01 DD
            AX_LENGHT <= x"04";
            --AX_CHECKSUM <= x"DD";
            
            command(3) <= AX_LENGHT;
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_LED_ADDR; --x04
            command(6) <= LED_ON; --x01
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6)) and x"FF";
            command(7) <= AX_CHECKSUM; --xDD
            
            lenght <= 7;
        
        when "0001" => --LED OFF - FF FF 01 04 03 19 00 DE
            AX_LENGHT <= x"04";
            --AX_CHECKSUM <= x"DE";
        
            command(3) <= AX_LENGHT;
            command(4) <= AX_WRITE;
            command(5) <= AX_LED_ADDR;
            command(6) <= LED_OFF;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6)) and x"FF";
            command(7) <= AX_CHECKSUM; --xDE
            
            lenght <= 7;

        when "0010" => --Move to position 0 -- FF FF 01 05 03 1E 00 00 D8
            AX_POSITION_WANTED_L <= x"00";
            AX_POSITION_WANTED_H <= x"00";
             
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xD8
            
            lenght <= 8;
                
        when "0011" => --Move to 447 degrees - FF FF 01 05 03 1E BF 01 18
            AX_POSITION_WANTED_L <= x"BF";
            AX_POSITION_WANTED_H <= x"01";
            --AX_CHECKSUM <= x"18";
        
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --x18
            
            lenght <= 8; 
        
        when "0100" => --Move to 513 - FF FF 01 05 03 1E 01 02 D5
            AX_POSITION_WANTED_L <= x"01";
            AX_POSITION_WANTED_H <= x"02";
        
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xD5
            
            lenght <= 8;
        
        when "0101" => --Move to 773 - FF FF 01 05 03 1E 05 03 D0
            AX_POSITION_WANTED_L <= x"05";
            AX_POSITION_WANTED_H <= x"03";
            --AX_CHECKSUM <= x"D1";
        
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xD0
            
            lenght <= 8;
       
       when "0110" => --Endless ON -- FF FF 01 05 03 08 00 00 EE
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_CCW_ANGLE_LIMIT_L; --x08
            command(6) <= x"00";
            command(7) <= x"00";
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEE
            
            lenght <= 8;
       
       
       when "0111" => --turn 1000 --FF FF 01 05 03 20 E8 03 EB
            AX_SPEED_WANTED_L <= x"E8";
            AX_SPEED_WANTED_H <= x"03";
       
       
            command(3) <= AX_SPEED_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_SPEED_L; --x20
            command(6) <= AX_SPEED_WANTED_L;
            command(7) <= AX_SPEED_WANTED_H;            
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEB
            
            lenght <= 8;
    
        when "1000" => --turn 0, to stop engine --FF FF 01 05 03 20 00 00 D6
            AX_SPEED_WANTED_L <= x"00";
            AX_SPEED_WANTED_H <= x"00";
       
       
            command(3) <= AX_SPEED_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_SPEED_L; --x20
            command(6) <= AX_SPEED_WANTED_L;
            command(7) <= AX_SPEED_WANTED_H;            
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xD6
            
            lenght <= 8;
            
        when "1001" => --Endless OFF -- FF FF 01 05 03 08 FF 03 EC
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_CCW_ANGLE_LIMIT_L; --x08
            command(6) <= AX_CCW_AL_L; --xFF
            command(7) <= AX_CCW_AL_H; --x03
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEC
            
            lenght <= 8;
            
        when "1010" => --Move speed to 267 angle at 712 speed -- FF FF 01 07 03 1E 0B 01 C8 02 00
            AX_POSITION_WANTED_L <= x"0B";
            AX_POSITION_WANTED_H <= x"01";
        
            AX_SPEED_WANTED_L <= x"C8";
            AX_SPEED_WANTED_H <= x"02";            
        
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
            
        when "1011" => --Move speed to 358 angle at 337 speed - FF FF 01 07 03 1E 66 01 51 01 1D
            AX_POSITION_WANTED_L <= x"66";
            AX_POSITION_WANTED_H <= x"01";
        
            AX_SPEED_WANTED_L <= x"51";
            AX_SPEED_WANTED_H <= x"01";            
        
            command(3) <= AX_GOAL_SP_LENGTH; --x07
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            command(8) <= AX_SPEED_WANTED_L;
            command(9) <= AX_SPEED_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7) + command(8) + command(9)) and x"FF";
            command(10) <= AX_CHECKSUM; --x1D
            
            lenght <= 10;
            
        when "1100" => --Move speed to 797 angle at 777 speed - FF FF 01 07 03 1E 1D 03 09 03 AA
            AX_POSITION_WANTED_L <= x"1D";
            AX_POSITION_WANTED_H <= x"03";
        
            AX_SPEED_WANTED_L <= x"09";
            AX_SPEED_WANTED_H <= x"03";            
        
            command(3) <= AX_GOAL_SP_LENGTH; --x07 
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_GOAL_POSITION_L; --x1E
            command(6) <= AX_POSITION_WANTED_L;
            command(7) <= AX_POSITION_WANTED_H;
            command(8) <= AX_SPEED_WANTED_L;
            command(9) <= AX_SPEED_WANTED_H;
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7) + command(8) + command(9)) and x"FF";
            command(10) <= AX_CHECKSUM; --xAA
            
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
    
    FINISH <= '1';
    
end process;


end Behavioral;
