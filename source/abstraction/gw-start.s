#ifdef EXEC_GATEWAY

.section .text.start
.global _start
.align 4
.arm

_vectors:
    ldr pc, =InfiniteLoop
    .pool
    ldr pc, =InfiniteLoop
    .pool
    ldr pc, =InfiniteLoop
    .pool
    ldr pc, =InfiniteLoop
    .pool
    ldr pc, =InfiniteLoop
    .pool
    ldr pc, =InfiniteLoop
    .pool

_start:
    ldr sp,=0x22140000

    @@wait for the arm11 kernel threads to be ready
    ldr r1, =0x10000
    waitLoop9:
        sub r1, #1

        cmp r1, #0
        bgt waitLoop9

    ldr r1, =0x10000
    waitLoop92:
        sub r1, #1

        cmp r1, #0
        bgt waitLoop92

    @ Disable caches / mpu
    mrc p15, 0, r4, c1, c0, 0  @ read control register
    bic r4, #(1<<12)           @ - instruction cache disable
    bic r4, #(1<<2)            @ - data cache disable
    bic r4, #(1<<0)            @ - mpu disable
    mcr p15, 0, r4, c1, c0, 0  @ write control register
    
    @ Clear bss
    ldr r0, =__bss_start
    ldr r1, =__bss_end
    mov r2, #0

    .bss_clr:
    cmp r0, r1
    beq .bss_clr_done
    str r2, [r0], #4
    b .bss_clr
    .bss_clr_done:
    
    @ Give read/write access to all the memory regions
    ldr r5, =0x33333333
    mcr p15, 0, r5, c5, c0, 2 @ write data access
    mcr p15, 0, r5, c5, c0, 3 @ write instruction access

    @ Sets MPU permissions and cache settings
    ldr r0, =0xFFFF001D	@ ffff0000 32k  | bootrom (unprotected part)
    ldr r1, =0x3000801B	@ 30000000 16k  | dtcm
    ldr r2, =0x01FF801D	@ 01ff8000 32k  | itcm
    ldr r3, =0x08000029	@ 08000000 2M   | arm9 mem (O3DS / N3DS) 
    ldr r4, =0x10000029	@ 10000000 2M   | io mem (ARM9 / first 2MB)
    ldr r5, =0x20000037	@ 20000000 256M | fcram (O3DS / N3DS)
    ldr r6, =0x1FF00027	@ 1FF00000 1M   | dsp / axi wram
    ldr r7, =0x1800002D	@ 18000000 8M   | vram (+ 2MB)
    mov r8, #0x2D
    mcr p15, 0, r0, c6, c0, 0
    mcr p15, 0, r1, c6, c1, 0
    mcr p15, 0, r2, c6, c2, 0
    mcr p15, 0, r3, c6, c3, 0
    mcr p15, 0, r4, c6, c4, 0
    mcr p15, 0, r5, c6, c5, 0
    mcr p15, 0, r6, c6, c6, 0
    mcr p15, 0, r7, c6, c7, 0
    mcr p15, 0, r8, c3, c0, 0	@ Write bufferable 0, 2, 5
    mcr p15, 0, r8, c2, c0, 0	@ Data cacheable 0, 2, 5
    mcr p15, 0, r8, c2, c0, 1	@ Inst cacheable 0, 2, 5

    @ Enable dctm
    ldr r1, =0x3000800A        @ set dtcm
    mcr p15, 0, r1, c9, c1, 0  @ set the dtcm Region Register
    
    @ Enable caches
    mrc p15, 0, r4, c1, c0, 0  @ read control register
    orr r4, r4, #(1<<18)       @ - itcm enable
    orr r4, r4, #(1<<16)       @ - dtcm enable
    orr r4, r4, #(1<<12)       @ - instruction cache enable
    orr r4, r4, #(1<<2)        @ - data cache enable
    orr r4, r4, #(1<<0)        @ - mpu enable
    mcr p15, 0, r4, c1, c0, 0  @ write control register

    @ Flush caches
    mov r5, #0
    mcr p15, 0, r5, c7, c5, 0  @ flush I-cache
    mcr p15, 0, r5, c7, c6, 0  @ flush D-cache
    mcr p15, 0, r5, c7, c10, 4 @ drain write buffer

    @ Fixes mounting of SDMC
    ldr r0, =0x10000020
    mov r1, #0x340
    str r1, [r0]

    ldr sp, =0x22160000
    ldr r3, =main
    blx r3
.pool

InfiniteLoop:
    b InfiniteLoop

#endif // EXEC_GATEWAY
