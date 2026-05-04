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
    .equ MSTATUS_MIE,      8

interrupt_dispatcher:
    addi    sp, sp, -(4*REGSZ)   # create stack frame
    sr      s0, 0*REGSZ, sp
    csrr    s0, mepc
    sr      s0, 1*REGSZ, sp      # save mepc to stack
    csrrsi  s0, CSR_MISTATUS, 1  # enables fast interrupts
    sr      s0, 2*REGSZ, sp      # save mistatus to stack
    sr      s1, 3*REGSZ, sp      # save s1 to stack

    call    __riscv_save

    la      s1, i_handlers + HANDLER_SPLIT

dispatch_loop:
    csrr    s0, mtopi
    srli    t1, s0, (16 - P_ALIGN)
    li      t0, (MEI_ID << P_ALIGN)
    bne     t1, t0, int_irq

ext_irq:
    csrr    s0, mtopei
    srli    t1, s0, (16 - P_ALIGN)

load_handler:
    add     t0, t1, s1
    lr      t0, 0, t0

have_handler:
    csrrw   s0, CSR_MITHRESHOLD, s0  # raise threshold
    # interrupts enabled by writing 0 to mithreshold.mien

    jalr    t0

    csrrw   s0, CSR_MITHRESHOLD, s0  # restore threshold
    # interrupts disabled by restoring mithreshold.mien

    j       dispatch_loop

int_irq:
    neg     t1, t1
    j       load_handler

spurious_handler:
    csrrw   s0, CSR_MITHRESHOLD, s0  # restore threshold, disable interrupts

dispatch_exit:
    call    __riscv_restore

    lr      s1, 3*REGSZ, sp      # restore s1 from stack
    lr      s0, 2*REGSZ, sp      # restore mistatus from stack
    csrw    CSR_MISTATUS, s0     # disables fast interrupts
    lr      s0, 1*REGSZ, sp      # restore mepc from stack
    csrw    mepc, s0
    lr      s0, 0*REGSZ, sp
    addi    sp, sp, (4*REGSZ)    # destroy stack frame

    mret
