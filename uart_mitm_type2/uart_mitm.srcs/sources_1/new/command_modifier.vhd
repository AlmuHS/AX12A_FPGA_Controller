----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.05.2024 01:16:18
-- Design Name: 
-- Module Name: command_modifier - Behavioral
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

entity command_modifier is
  Port (
    command: in mem(0 to 100); --modified to fit with the sniffer
    out_command: out mem(0 to 100);
    lenght:in integer;
    start: in std_logic
   );
end command_modifier;

architecture Behavioral of command_modifier is

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

  signal command_mod: mem(0 to 100);

begin

out_command <= command_mod;

process(start) 
begin
    command_mod <= command;

    if command(4) = AX_WRITE then
    
        if command(5) = AX_LED_ADDR then --Command LED ON/OFF: Change ON to OFF and reverse
            if command(6) = "00" then
                command_mod(6) <= "01";
            elsif command(6) = "01" then
                command_mod(6) <= "00";
            end if;
            
            AX_CHECKSUM <= not(ID + command_mod(3) + command_mod(4) + command_mod(5) + command_mod(6)) and x"FF";
            command_mod(7) <= AX_CHECKSUM; 
            
        elsif command(5) = AX_GOAL_SPEED_L then -- Turn command: divide speed / 2
            command_mod(6) <= x"00"&command(6)(AX_SPEED_WANTED_L'length-1 downto 1); --divide speed by two
        
            AX_CHECKSUM <= not(ID + command_mod(3) + command_mod(4) + command_mod(5) + command_mod(6) + command_mod(7)) and x"FF";
            command_mod(8) <= AX_CHECKSUM; 
        
        elsif command(5) = AX_GOAL_POSITION_L then --Move commands: divide position / 4
            command_mod(6) <= x"0000"&command(6)(AX_POSITION_WANTED_L'length-1 downto 2);
            
            if lenght = 10 then --Move speed
                command_mod(6) <= "00"&command(6)(AX_SPEED_WANTED_L'length-1 downto 1); --divide speed by two
                
                AX_CHECKSUM <= not(ID + command_mod(3) + command_mod(4) + command_mod(5) + command_mod(6) + command_mod(7) + command_mod(8) + command_mod(9)) and x"FF";
                command_mod(10) <= AX_CHECKSUM;
            
            else --Move
                AX_CHECKSUM <= not(ID + command_mod(3) + command_mod(4) + command_mod(5) + command_mod(6) + command_mod(7)) and x"FF";
                command_mod(8) <= AX_CHECKSUM;
            end if;
        
        elsif command(5) <= AX_CCW_ANGLE_LIMIT_L then --Change Endless ON to Endless OFF and the reverse
            
            if command(6) = "00" and command(7) = "00" then
                command_mod(6) <= AX_CCW_AL_L; --xFF
                command_mod(7) <= AX_CCW_AL_H; --x03
            elsif command(6) = AX_CCW_AL_L and command(7) = AX_CCW_AL_H then
                command_mod(6) <= "00";
                command_mod(7) <= "00";
            end if;
            
            AX_CHECKSUM <= not(ID + command_mod(3) + command_mod(4) + command_mod(5) + command_mod(6) + command_mod(7)) and x"FF";
            command_mod(8) <= AX_CHECKSUM; --xEE
            
        end if;
    end if;


end process;

end Behavioral;
