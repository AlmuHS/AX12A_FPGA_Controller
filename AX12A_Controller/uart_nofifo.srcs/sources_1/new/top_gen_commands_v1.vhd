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
      
      select_com: in std_logic_vector(2 downto 0);
      on_off: in std_logic;
      angle_speed: in std_logic_vector(9 downto 0);
      select_ang_sp: in std_logic;
      
      reset : in std_logic;
      start: in std_logic;
      
      endless_enable: out std_logic
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
  signal AX_LED_STATUS: STD_LOGIC_VECTOR(7 downto 0);
  
    
  --Input values by user, to control engine action's parameters
  signal ANGLE_WANTED: STD_LOGIC_VECTOR(9 downto 0);  --Angle in degrees
  signal AX_POSITION_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --ANGLE_WANTED*0.29 degrees
  
  signal SPEED_WANTED: STD_LOGIC_VECTOR(9 downto 0);  --Speed in rpm
  signal AX_SPEED_WANTED_ALL: STD_LOGIC_VECTOR(15 downto 0); --SPEED_WANTED*0.111 rpm
  
  signal ENDLESS_STATUS: STD_LOGIC;
    
  type mem is array(integer range <>) of STD_LOGIC_VECTOR(7 downto 0); --8-bit each element  
  signal command: mem(0 to 10) :=  (AX_START, AX_START, ID, x"04", AX_WRITE, AX_LED_ADDR, LED_ON, x"DD", x"DD", x"DD", x"DD");
      
  signal index: integer;  
  signal lenght: integer;
  
  type state is (s_start_click, s_wait_unclick, s_start, s_check_tx, s_prepare, s_tx_send, s_wait_end); 
  signal cur_state: state; 
  
begin

--ANGLE_WANTED <= angle_speed when select_com = "001" or select_com = "100" or select_com = "101";
--SPEED_WANTED <= angle_speed when select_com = "010";


----each position step is 0.29 degrees, so calculate the position to move applying a calculus
--AX_POSITION_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(ANGLE_WANTED)*100)/29, AX_POSITION_WANTED_ALL'length)); --angle/0.29
--AX_SPEED_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(SPEED_WANTED)*1000)/111, AX_SPEED_WANTED_ALL'length)); --speed/0,111


calculate: process(start, i_clk) is
begin
    if (i_clk='1' and i_clk'event) then
        if select_ang_sp = '0' then
            ANGLE_WANTED <= angle_speed;
            AX_POSITION_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(ANGLE_WANTED)*100)/29, AX_POSITION_WANTED_ALL'length)); --angle/0.29
        else
            SPEED_WANTED <= angle_speed;
            --each position step is 0.29 degrees, so calculate the position to move applying a calculus
            AX_SPEED_WANTED_ALL <= std_logic_vector(to_unsigned(to_integer(unsigned(SPEED_WANTED)*1000)/111, AX_SPEED_WANTED_ALL'length)); --speed/0,111
        end if;
    end if;
end process;


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