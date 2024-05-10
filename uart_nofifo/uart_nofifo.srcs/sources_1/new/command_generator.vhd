----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.02.2024 23:52:35
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

entity command_generator is
  Port (
      select_com: in std_logic_vector(2 downto 0);
      on_off: in std_logic;
      ax_position: in STD_LOGIC_VECTOR(15 downto 0);
      ax_speed: in STD_LOGIC_VECTOR(15 downto 0);
      start: in std_logic;
      o_command: out mem(0 to 10);
      lenght: out integer;
      reply_lenght: out integer;
      o_endless_status: out std_logic;
      o_read_required: out std_logic
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
  
  --this signal indicates that the command return a data required to read
  signal READ_REQUIRED: STD_LOGIC := '0';
begin

READ_REQUIRED <= '1' when select_com = "101" else '0';

o_command <= command;

AX_POSITION_WANTED_ALL <= ax_position;
AX_SPEED_WANTED_ALL <= ax_speed;

set_com: process(start) is
begin
    o_endless_status <= ENDLESS_STATUS;
    o_read_required <= READ_REQUIRED;

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
            READ_REQUIRED <= '0';

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
            READ_REQUIRED <= '1';
            
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
            READ_REQUIRED <= '1';
    
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
            READ_REQUIRED <= '1';
            
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
            READ_REQUIRED <= '1';
         
         when "101" => --Read speed
            command(3) <= AX_POS_LENGTH; --x04
            command(4) <= AX_READ_DATA; --x02
            command(5) <= AX_PRESENT_SPEED_L; --x26
            command(6) <= AX_BYTE_READ_POS; --x02
                
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6)) and x"FF";
            command(7) <= AX_CHECKSUM;
            
            lenght <= 7;
            reply_lenght <= 6;
            
            READ_REQUIRED <= '1';
                
         when others => --turn LED ON
            AX_LENGHT <= x"04";
            AX_CHECKSUM <= x"DD";
            
            command(3) <= AX_LENGHT;
            command(4) <= AX_WRITE;
            command(5) <= AX_LED_ADDR;
            command(6) <= LED_ON;
            command(7) <= AX_CHECKSUM;
            
            READ_REQUIRED <= '0';
            
            lenght <= 7;
    end case;
    
end process;


end Behavioral;
