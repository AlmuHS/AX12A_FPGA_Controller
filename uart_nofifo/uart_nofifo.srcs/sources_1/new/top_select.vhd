----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
 
entity top is
port (
      i_clk       : in  std_logic;
      
      tx_serial : out std_logic;
      --rx_serial : in  std_logic;
      
      select_com: in std_logic_vector(3 downto 0);
      
      reset : in std_logic;
      start: in std_logic
      );
end top;
 
architecture behave of top is
 
  component uart_tx is
    generic (
      g_CLKS_PER_BIT : integer := 100   -- Needs to be set correctly
      );
    port (
      i_clk       : in  std_logic; --clock
      i_tx_dv     : in  std_logic; --enable to start the sending
      i_tx_byte   : in  std_logic_vector(7 downto 0); --8-bit data packet
      o_tx_active : out std_logic; --enable to half-duplex
      o_tx_serial : out std_logic; --the data to send
      o_tx_done   : out std_logic --enabled is transmission is end
      );
  end component uart_tx;
 
  -- Test Bench uses a 10 MHz Clock
  -- Want to interface to 115200 baud UART
  -- 10000000 / 115200 = 87 Clocks Per Bit.
  constant c_CLKS_PER_BIT : integer := 100;
 
  constant c_BIT_PERIOD : time := 10 ns;
  
  --UART signals 
  signal r_TX_DV     : std_logic                    := '0';
  signal r_TX_BYTE   : std_logic_vector(7 downto 0) := (others => '0');
  signal w_TX_SERIAL : std_logic;
  signal w_TX_DONE   : std_logic;
  signal w_RX_DV     : std_logic;
  signal w_RX_BYTE   : std_logic_vector(7 downto 0);
  signal r_RX_SERIAL : std_logic := '1';
 
    
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
  
    
  signal ANGLE_DESIRED: STD_LOGIC_VECTOR(7 downto 0); 
  signal AX_POSITION_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); 
    
    
  type mem is array(integer range <>) of STD_LOGIC_VECTOR(7 downto 0); --8-bit each element  
  signal command: mem(0 to 10) :=  (AX_START, AX_START, ID, x"04", AX_WRITE, AX_LED_ADDR, LED_ON, x"DD", x"DD", x"DD", x"DD");
      
  signal index: integer;  
  signal lenght: integer;
  
  type state is (s_start_click, s_wait_unclick, s_start, s_check_tx, s_prepare, s_tx_send, s_wait_end); 
  signal cur_state: state; 
  
begin

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
            
       when "0110" => --turn 1000 --FF FF 01 05 03 20 E8 03 EB
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
    
        when "0111" => --Endless ON -- FF FF 01 05 03 08 00 00 EE
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_CCW_ANGLE_LIMIT_L; --x08
            command(6) <= x"00";
            command(7) <= x"00";
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEE
            
            lenght <= 8;
            
        when "1000" => --Endless OFF -- FF FF 01 05 03 08 FF 03 EC
            command(3) <= AX_GOAL_LENGHT; --x05
            command(4) <= AX_WRITE; --x03
            command(5) <= AX_CCW_ANGLE_LIMIT_L; --x08
            command(6) <= AX_CCW_AL_L; --xFF
            command(7) <= AX_CCW_AL_H; --x03
            
            AX_CHECKSUM <= not(ID + command(3) + command(4) + command(5) + command(6) + command(7)) and x"FF";
            command(8) <= AX_CHECKSUM; --xEC
            
            lenght <= 8;
            
        when "1001" => --Move speed to 267 angle at 712 speed -- FF FF 01 07 03 1E 0B 01 C8 02 00
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
            
        when "1010" => --Move speed to 358 angle at 337 speed - FF FF 01 07 03 1E 66 01 51 01 1D
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
            
        when "1011" => --Move speed to 797 angle at 777 speed - FF FF 01 07 03 1E 1D 03 09 03 AA
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
         
         when "1100" => --turn 0, to stop engine --FF FF 01 05 03 20 00 00 D6
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

-- Instantiate UART transmitter 
UART_TX_INST : uart_tx 
  generic map (
    g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => i_clk,
      i_tx_dv     => r_TX_DV,
      i_tx_byte   => r_TX_BYTE,
      o_tx_active => open,
      o_tx_serial => tx_serial,
      o_tx_done   => w_TX_DONE
      );
    
    p1: process(i_clk, reset) 
    begin 
        if reset = '1' then
           cur_state <= s_start_click;
        elsif (i_clk='1' and i_clk'event) then
            case cur_state is 
                when s_start_click => --waiting to press button start
                    if start = '1' then
                        cur_state <= s_wait_unclick; --if button is pressed, wait until button is unpressed before start
                     else 
                        cur_state <= s_start_click; --if button is unpressed, start the process
                     end if;
                     
                  when s_wait_unclick => --wait until button is unpressed
                    if start = '0' then
                        cur_state <= s_start; --if button is unclicked, start the transmission process
                    else 
                        cur_state <= s_wait_unclick; --if button is still clicked, continues waiting
                    end if;
            
                when s_start => --start the transmission process
                    index <= 0; --set command index to zero, to access to the command's first data
                    cur_state <= s_check_tx; --start transmission
                    
                 when s_check_tx =>  --prepare data for transmission
                    r_TX_DV <= '0'; --set start transmission flag to 0, to disable transmission until data is ready to send
                    if index <= lenght then --check if all commands are sent
                        cur_state <= s_prepare; --if not, pprepare to send next command data
                    else
                        cur_state <= s_start_click; --if the command is fully sent, wait until a new start
                    end if;
                
                 when s_prepare => --prepare new command data
                    r_TX_BYTE <= command(index); --write the command data to the port
                    index <= index + 1; --increase command data index
                    
                    cur_state <= s_tx_send;
                
                when s_tx_send => --send the written data
                    r_TX_DV <= '1'; --enable signal to start data transmission
                    
                    cur_state <= s_wait_end;
                
                when s_wait_end => --wait until data is sent
                    r_TX_DV <= '0';
                    if w_TX_DONE = '0' then --if the signal indicates data is not fully sent, continues waiting
                        cur_state <= s_wait_end;
                    elsif w_TX_DONE = '1' then --if the data is fully sent, start again to send a new command
                        cur_state <= s_check_tx;
                    end if;
            end case; 
        end if;
    end process;


end behave;