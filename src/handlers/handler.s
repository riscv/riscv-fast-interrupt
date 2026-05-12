.if XLEN == 64
        .equ REGSZ, 8
        .equ P_ALIGN, 3  # pointer alignment
        .macro sr reg, off, base
            sd \reg, \off(\base)
        .endm
        .macro lr reg, off, base
            ld \reg, \off(\base)
        .endm
    .else
        .equ REGSZ, 4
        .equ P_ALIGN, 2  # pointer alignment
        .macro sr reg, off, base
            sw \reg, \off(\base)
        .endm
        .macro lr reg, off, base
            lw \reg, \off(\base)
        .endm
    .endif

    .equ MEI_ID,           11
    .equ MAJOR_IRQ_COUNT,  64
    .equ HANDLER_SPLIT,    (MAJOR_IRQ_COUNT << P_ALIGN)

    .equ CSR_MISTATUS,     0x346
    .equ CSR_MTOPSI,       0x348

interrupt_dispatcher:
    addi    sp, sp, -(4*REGSZ)     # create stack frame
    sr      s0, 0*REGSZ, sp        # save s0 to stack
    csrr    s0, mepc
    sr      s0, 1*REGSZ, sp        # save mepc to stack
    sr      s1, 2*REGSZ, sp        # save s1 to stack
    csrr    s1, mcause
    csrrs   s0, CSR_MISTATUS, 1    # enable interrupts

    call    __riscv_save           # save ra, t0-t6, a0-a7

    slli    a0, s1, P_ALIGN        # create vector table offset
    la      s1, i_handlers + HANDLER_SPLIT

goto_handler:
    add     a0, a0, s1
    lr      a0, 0, a0
    jalr    a0

next_handler:
    csrrw   a0, CSR_MTOPSI, s0  # restores threshold from s0[8:0], claims interrupt and raises threshold
    srai    a0, a0, (16 - P_ALIGN)

    j       load_handler

spurious_handler:

dispatch_exit:
    call    __riscv_restore      # restore ra, t0-t6, a0-a7

    lr      s1, 2*REGSZ, sp      # restore s1 from stack

    csrw    CSR_MISTATUS, s0     # disables interrupts
    lr      s0, 1*REGSZ, sp      # restore mepc from stack
    csrw    mepc, s0
    lr      s0, 0*REGSZ, sp      # restore s0 from stack
    addi    sp, sp, (4*REGSZ)    # destroy stack frame

    mret
