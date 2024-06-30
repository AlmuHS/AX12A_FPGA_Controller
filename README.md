# Dynamixel AX-12A FPGA Controller

This project implements a controller for Dynamixel AX-12A servomotor, compatible with FPGA boards. 
The controller is implemented in VHDL, and its able to generate custom commands based in type of commands, and parameters like angle and speed. 
The commands are sent using a UART module, which is also able to receive the response from the servo. 

