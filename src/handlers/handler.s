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
.equ CSR_MISTATUS,     0x346
.equ CSR_MITHRESHOLD,  0x347
.equ CSR_MIPREEMPTCFG, 0x348
.equ MSTATUS_MIE,      8

interrupt_dispatcher:
    addi    sp, sp, -(2*REGSZ)
    sr      s0, 0*REGSZ, sp
    sr      s1, 1*REGSZ, sp

    csrr    s0, mepc
    csrr    s1, CSR_MISTATUS
    csrsi   CSR_MIPREEMPTCFG, 1  # enable fast interrupts

    call    __riscv_save

dispatch_loop:
    csrr    t0, mtopi
    srli    t1, t0, (16 - P_ALIGN)
    li      t2, (MEI_ID << P_ALIGN)
    bne     t1, t2, int_irq

ext_irq:
    csrr    t0, mtopei
    srli    t1, t0, (16 - P_ALIGN)
    la      t3, ei_handlers
    add     t3, t1, t3
    lr      t3, 0, t3

have_handler:
    csrw    CSR_MITHRESHOLD, t0  # raise threshold

    csrsi   mstatus, MSTATUS_MIE
    jalr    t3
    csrci   mstatus, MSTATUS_MIE

    csrw    CSR_MITHRESHOLD, s1  # restore threshold

    j       dispatch_loop

int_irq:
    la      t3, i_handlers
    add     t3, t1, t3
    lr      t3, 0, t3
    j       have_handler

dispatch_exit:
    call    __riscv_restore
    csrci   CSR_MIPREEMPTCFG, 1  # disable fast interrupts
    csrw    mepc, s0
    csrw    CSR_MISTATUS, s1

    lr      s0, 0*REGSZ, sp
    lr      s1, 1*REGSZ, sp
    addi    sp, sp, (2*REGSZ)
    mret
