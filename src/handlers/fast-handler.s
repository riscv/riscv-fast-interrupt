.if XLEN == 64
        .equ REGSZ, 8
        .macro sr reg, off, base
            sd \reg, \off(\base)
        .endm
        .macro lr reg, off, base
            ld \reg, \off(\base)
        .endm
    .else
        .equ REGSZ, 4
        .macro sr reg, off, base
            sw \reg, \off(\base)
        .endm
        .macro lr reg, off, base
            lw \reg, \off(\base)
        .endm
    .endif

    .equ STACKSZ, (4*REGSZ)

    .equ CSR_MISTATUS,     0x346

fast_interrupt_entry:
    addi    sp, sp, -STACKSZ     # create stack frame
    sr      s0, 0*REGSZ, sp
    csrr    s0, mepc             # save mepc
    sr      s1, 1*REGSZ, sp
    csrrsi  s1, CSR_MISTATUS, 2  # save mistatus, enable interrupts

fast_interrupt_main:
    # handle interrupt

fast_interrupt_exit:
    csrw    CSR_MISTATUS, s1     # restore mistatus, disables interrupts
    csrw    mepc, s0             # restore mepc
    lr      s0, 0*REGSZ, sp
    lr      s1, 1*REGSZ, sp
    addi    sp, sp, STACKSZ      # destroy stack frame

    mret
