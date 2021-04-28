// -----------
// Copyright (c) 2021. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
//
// This assembly file tests the privilege interrupt behavior based on
// CLICINTCTLBITS, nlbits, clicintattr[i] setting for m, m/u, m/s/u
// implementations of the RISC-V fast-interrupt extension.
// 
//  if implementation only supports levels,
//     external tb needs to set pending intererupt before running image
//  otherwise
//     the test sets pending bit during interrupt setup.
//
//  if implementation clicintie bits default to 1 or unknown,
//     RVMODEL_BOOT needs to initialize all clicintie to 0 before running image
//
// clic specific defines needed for this test:
// CLICCFG
// NEG
// EDGE
// INTERRUPT1_NUM
// 
// addresses of not yet ratified clic CSRs:
// mtvt              
// mnxti             
// mintstatus        
// mintthresh        
// mscratchcsw       
// mscratchcswl      
// 
// stvt              
// snxti             
// sintstatus        
// sintthresh        
// sscratchcsw       
// sscratchcswl      
// 
// utvt              
// unxti             
// uintstatus        
// uintthresh        
// uscratchcsw       
// uscratchcswl      
// 
 

#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV32I")

# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_SIGBASE( a1,signature_a1_m) // a1 will point to signature_a1_m label in the signature region - m-mode
RVTEST_SIGBASE( a2,signature_a2_s) // a2 will point to signature_a2_s label in the signature region - s-mode
RVTEST_SIGBASE( a3,signature_a3_u) // a3 will point to signature_a3_u label in the signature region - u-mode

// priv-modes nmbits clicintattr[i].mode  Interpretation
//        M      0       xx               M-mode interrupt 1A
// 
//      M/U      0       xx               M-mode interrupt 2A
//      M/U      1       0x               U-mode interrupt 2B
//      M/U      1       1x               M-mode interrupt 2C
// 
//    M/S/U      0       xx               M-mode interrupt 3A
//    M/S/U      1       0x               S-mode interrupt 3B
//    M/S/U      1       1x               M-mode interrupt 3C
//    M/S/U      2       00               U-mode interrupt 3D
//    M/S/U      2       01               S-mode interrupt 3E
//    M/S/U      2       11               M-mode interrupt 3F

  li    t0, MSTATUS_MPIE | MSTATUS_SPIE | MSTATUS_UPIE | MSTATUS_MIE | MSTATUS_SIE | MSTATUS_UIE
  csrrc x0, mstatus, t0; //  Disable mstatus.xpie, mstatus.xie

  li    t0, MSTATUS_SPP
  csrrs x0, mstatus, t0; //  initialize mstatus.spp
  

#ifdef TEST_CASE_1A
    RVTEST_CASE(1A,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*clic.*); def TEST_CASE_1A=True",priv_m_nmbits0_clicintattrmode0)
// priv-modes nmbits clicintattr[i].mode  Interpretation
//        M      0       xx               M-mode interrupt

  li    t1, CLICCFG
  li    t2, 0x00 | 0x0 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_2A
  #define CLIC_UMODE_INT
  RVTEST_CASE(2A,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*N.*clic.*); def TEST_CASE_2A=True",priv_mu_nmbits0_clicintattrmode0)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //      M/U      0       xx               M-mode interrupt

  li    t1, CLICCFG
  li    t2, 0x00 | 0x0 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_2B
  #define CLIC_UMODE_INT
  RVTEST_CASE(2B,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*N.*clic.*); def TEST_CASE_2B=True",priv_mu_nmbits1_clicintattrmode1)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //      M/U      1       0x               U-mode interrupt

  li    t1, CLICCFG
  li    t2, 0x00 | 0x1 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_2C
  #define CLIC_UMODE_INT
  RVTEST_CASE(2C,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*N.*clic.*); def TEST_CASE_2C=True",priv_mu_nmbits1_clicintattrmode3)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //      M/U      1       1x               M-mode interrupt

  li    t1, CLICCFG
  li    t2, 0x00 | 0x1 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x3 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x3 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_3A
  #define CLIC_SMODE_INT
  RVTEST_CASE(3A,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*S.*clic.*); def TEST_CASE_3A=True",priv_msu_nmbits0_clicintattrmode0)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //    M/S/U      0       xx               M-mode interrupt 

  li    t1, CLICCFG
  li    t2, 0x00 | 0x0 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_3B
  #define CLIC_SMODE_INT
  RVTEST_CASE(3B,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*S.*clic.*); def TEST_CASE_3B=True",priv_msu_nmbits1_clicintattrmode1)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //    M/S/U      1       0x               S-mode interrupt 

  li    t1, CLICCFG
  li    t2, 0x00 | 0x1 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x1 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x1 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_3C
  #define CLIC_SMODE_INT
  RVTEST_CASE(3C,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*S.*clic.*); def TEST_CASE_3C=True",priv_msu_nmbits1_clicintattrmode3)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //    M/S/U      1       1x               M-mode interrupt 

  li    t1, CLICCFG
  li    t2, 0x00 | 0x1 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x3 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x3 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_3D
  #define CLIC_SMODE_INT
  #define CLIC_UMODE_INT
  RVTEST_CASE(3D,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*N.*S.*clic.*); def TEST_CASE_3D=True",priv_msu_nmbits2_clicintattrmode0)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //    M/S/U      2       00               U-mode interrupt 

  li    t1, CLICCFG
  li    t2, 0x00 | 0x2 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x0 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_3E
  #define CLIC_SMODE_INT
  RVTEST_CASE(3E,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*S.*clic.*); def TEST_CASE_3E=True",priv_msu_nmbits2_clicintattrmode1)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //    M/S/U      2       01               S-mode interrupt

  li    t1, CLICCFG
  li    t2, 0x00 | 0x2 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x1 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip 
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x1 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

#ifdef TEST_CASE_3F
  RVTEST_CASE(3F,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*clic.*); def TEST_CASE_3F=True",priv_msu_nmbits2_clicintattrmode3)
  // priv-modes nmbits clicintattr[i].mode  Interpretation
  //    M/S/U      2       11               M-mode interrupt

  li    t1, CLICCFG
  li    t2, 0x00 | 0x2 << 5       ; //  set cliccfg.nmbits, 0bits for int level
  sw    t2, 0(t1)                 ; //  Setup cliccfg
 
  li    t1, CLICCFG + 0x1000 + 4*INTERRUPT1_NUM
  li    t2, 0xFF000000 | 0x3 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1);                                       // setting attr before setting ie/ip
  fence;                                                 // ensure attr is set before setting ie/ip
  li    t2, 0xFF000101 | 0x3 <<22 | NEG <<18 | EDGE<<17; // {clicintctl,clicintattr,clicintie,clicintip}          
  sw    t2, 0(t1); 
#endif

  fence; // ensure memory mapped registers are setup

  csrw  mintthresh, x0; //  Setup xthresh to 0
  li    t0, 0x55555555
  csrw  mscratch, t0
  la    t0, clic_mtvec_handler        
  
  csrrw s1,mtvec, t0
  csrsi mtvec, 0x3; //  enable clic mode        
  csrr  t0, mie
RVTEST_SIGUPD( a1,t0)
  csrr  t0, mip
RVTEST_SIGUPD( a1,t0)

#ifdef CLIC_SMODE_INT
  csrw  sintthresh, x0; //  Setup xthresh to 0
  li    t0, 0x66666666
  csrw  sscratch, t0
  la    t0, clic_stvec_handler        
  csrrw s2,stvec, t0
  csrsi stvec, 0x3; //  enable clic mode        
  csrr  t0, sie
RVTEST_SIGUPD( a2,t0)
  csrr  t0, sip
RVTEST_SIGUPD( a2,t0)
  la    t0, goto_smode        
  csrw  sepc, t0
  sret  ; # switch to s mode, m ints enabled on mode switch, s ints enabled later
#endif
goto_smode:

#ifdef CLIC_UMODE_INT
  csrw  uintthresh, x0; //  Setup xthresh to 0
  li    t0, 0x77777777
  csrw  uscratch, t0
  la    t0, clic_utvec_handler        
  csrrw s3,utvec, t0
  csrsi utvec, 0x3; //  enable clic mode        
  csrr  t0, uie
RVTEST_SIGUPD( a3,t0)
  csrr  t0, uip
RVTEST_SIGUPD( a3,t0)
  la    t0, goto_umode       
  csrw  uepc, t0
  uret  ; # switch to user mode, m/s ints enabled on mode switch, u ints enabled next
goto_umode:
  li    t0, MSTATUS_MIE | MSTATUS_SIE | MSTATUS_UIE; // enable global interrupts in u-mode
  csrrs x0, ustatus, t0
wait_int_umode:
  beqz  x0, wait_int_umode; //  Loop to self 
#endif

#ifdef CLIC_SMODE_INT
  li    t0, MSTATUS_MIE | MSTATUS_SIE | MSTATUS_UIE; // enable global interrupts in s-mode
  csrrs x0, sstatus, t0
wait_int_smode:
  beqz  x0, wait_int_smode; //  Loop to self 
#endif

  li    t0, MSTATUS_MIE | MSTATUS_SIE | MSTATUS_UIE; // enable global interrupts in m-mode
  csrrs x0, mstatus, t0

wait_int_mmode:
  beqz  x0, wait_int_mmode; //  Loop to self 

  .align 6
  .global clic_mtvec_handler
clic_mtvec_handler:
  
  csrr  t0, mcause
RVTEST_SIGUPD( a1,t0)
  csrr  t0, mstatus
RVTEST_SIGUPD( a1,t0)
  csrr  t0, mepc
RVTEST_SIGUPD( a1,t0)
  csrr  t0, mtval
RVTEST_SIGUPD( a1,t0)
  csrr  t0, mintstatus
RVTEST_SIGUPD( a1,t0)
  li t0, 0x12345678
  csrrw  t0, mscratchcsw, t0
RVTEST_SIGUPD( a1,t0)
  li t0, 0x98765432
  csrrw  t0, mscratchcswl, t0
RVTEST_SIGUPD( a1,t0)

  j     finish

  .align 6
  .global clic_stvec_handler
clic_stvec_handler:

#ifdef CLIC_SMODE_INT
  csrr  t0, scause
RVTEST_SIGUPD( a2,t0)
  csrr  t0, sstatus
RVTEST_SIGUPD( a2,t0)
  csrr  t0, sepc
RVTEST_SIGUPD( a2,t0)
  csrr  t0, stval
RVTEST_SIGUPD( a2,t0)
  csrr  t0, sintstatus
RVTEST_SIGUPD( a2,t0)
  li t0, 0x12345678
  csrrw  t0, sscratchcsw, t0
RVTEST_SIGUPD( a2,t0)
  li t0, 0x98765432
  csrrw  t0, sscratchcswl, t0
RVTEST_SIGUPD( a2,t0)
#endif

  j     finish

  .align 6
  .global clic_utvec_handler
clic_utvec_handler:

#ifdef CLIC_UMODE_INT
  csrr  t0, ucause
RVTEST_SIGUPD( a3,t0)
  csrr  t0, ustatus
RVTEST_SIGUPD( a3,t0)
  csrr  t0, uepc
RVTEST_SIGUPD( a3,t0)
  csrr  t0, utval
RVTEST_SIGUPD( a3,t0)
  csrr  t0, uintstatus
RVTEST_SIGUPD( a3,t0)
  li t0, 0x12345678
  csrrw  t0, uscratchcsw, t0
RVTEST_SIGUPD( a3,t0)
  li t0, 0x98765432
  csrrw  t0, uscratchcswl, t0
RVTEST_SIGUPD( a3,t0)
#endif

  j     finish

finish:
  csrw mtvec, s1; // restore mtvec

#ifdef CLIC_SMODE_INT
  csrw stvec, s2; // restore stvec
#endif

#ifdef CLIC_UMODE_INT
  csrw utvec, s3; // restore utvec
#endif

RVMODEL_IO_WRITE_STR(t5, "# Test End\n")

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
// Input data section.
    .data
    .align 4
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
.align 4

signature_a1_m:
    .fill 9*(XLEN/32),4,0xdeadbeef

signature_a2_s:
    .fill 9*(XLEN/32),4,0xdeadbeef

signature_a3_u:
    .fill 9*(XLEN/32),4,0xdeadbeef

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif

RVMODEL_DATA_END
