.global _start

.text
_start:
    la      gp, _uart
    # Set baud rate (div const = 1)
    li      a0, 0x80
    sb      a0, 3(gp)           # Set DLAB = 1
    li      a0, 0x01
    sb      a0, 0(gp)           # Set DLL = 1
    li      a0, 0x00
    sb      a0, 1(gp)           # Set DLM = 1
    # Set LCR (word len = 8, parity none)
    li      a0, 0x03
    sb      a0, 3(gp)
loop:
wait_rx:
    # Check if data is ready
    lb      a0, 5(gp)           # Read LSR
    andi    a1, a0, 0x01        # Extract RX_DATA_READY
    beqz    a1, wait_rx         # Wait if not ready
    # Read RX
    lb      a2, 0(gp)
wait_tx:
    # Check if thr is empty
    lb      a0, 5(gp)           # Read LSR
    andi    a1, a0, 0x20        # Extract THR_EMPTY
    beqz    a1, wait_tx         # Wait if not empty
    # Write TX
    sb      a2, 0(gp)
    # Repeat the loop
    j       loop

