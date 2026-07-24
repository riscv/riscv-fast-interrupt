    .macro MIPOPRET
        .word 0x308000733
    .endm

    .equ CSR_MISTATUS,     0x346

fast_interrupt_entry:
    csrr    a0, mepc             # save mepc
    csrrsi  a1, CSR_MISTATUS, 2  # save mistatus, enable interrupts

fast_interrupt_main:
    # handle interrupt

fast_interrupt_exit:
    csrw    CSR_MISTATUS, a1     # restore mistatus, disables interrupts
    csrw    mepc, a0             # restore mepc

    MIPOPRET
