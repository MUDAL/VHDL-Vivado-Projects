# RTL design for SPI communication between two custom devices  

## Requirements  
1. Communication can be started or stopped by driving the SS(slave select) line.  
2. Master sends an 8-bit address to the slave via the MOSI line.   
3. Slave responds to the master by sending an 8-bit ACK to the master through the MISO line.  
4. After receiving the ACK from the slave, the master can proceed to send data to the slave.  
5. Data transfer: When the master sends a byte to the slave, the slave responds with a bitwise complement of the data that it receives from the master.  
