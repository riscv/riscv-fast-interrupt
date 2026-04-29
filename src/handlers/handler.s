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
    .equ CSR_MITHRESHOLD,  0x347
    .equ CSR_MIPREEMPTCFG, 0x348
    .equ MSTATUS_MIE,      8

interrupt_dispatcher:
    addi    sp, sp, -(3*REGSZ)   # create stack frame
    sr      s0, 0*REGSZ, sp
    csrr    s0, mepc
    sr      s0, 1*REGSZ, sp      # save mepc to stack
    csrrci  s0, CSR_MISTATUS, 1  # enables fast interrupts
    sr      s0, 2*REGSZ, sp      # save mpistatus to stack

    call    __riscv_save

dispatch_loop:
    csrr    s0, mtopi
    srli    t1, s0, (16 - P_ALIGN)
    li      t2, (MEI_ID << P_ALIGN)
    bne     t1, t2, int_irq

ext_irq:
    csrr    s0, mtopei
    srli    t1, s0, (16 - P_ALIGN)

load_handler:
    la      t3, i_handlers + HANDLER_SPLIT
    add     t3, t1, t3
    lr      t3, 0, t3

have_handler:
    csrrw   s0, CSR_MITHRESHOLD, s0  # raise threshold
    # interrupts enabled by writing 0 to mithreshold.mien

    jalr    t3

    csrrw   s0, CSR_MITHRESHOLD, s0  # restore threshold
    # interrupts disabled by restoring mithreshold.mien

    j       dispatch_loop

int_irq:
    neg     t1, t1
    j       load_handler

dispatch_exit:
    call    __riscv_restore

    lr      s0, 2*REGSZ, sp      # restore mpistatus from stack
    csrw    CSR_MISTATUS, s0     # disables fast interrupts
    lr      s0, 1*REGSZ, sp      # restore mepc from stack
    csrw    mepc, s0
    lr      s0, 0*REGSZ, sp
    addi    sp, sp, (3*REGSZ)    # destroy stack frame

    mret
