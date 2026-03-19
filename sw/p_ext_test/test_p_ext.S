.section .text
.global _start

_start:

li t0, 0x01020304
li t1, 0x11121314
la t2, results

# ===== padd.b =====
padd.b t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

padd.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

# ===== psadd =====
psadd.b t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

psadd.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

# ===== psaddu =====
psaddu.b t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

psaddu.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

# ===== psub =====
psub.b t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

psub.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

# ===== pssub =====
pssub.b t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

pssub.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

# ===== min/max =====
pmin.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

pmax.h t3, t0, t1
sw t3, 0(t2)
addi t2, t2, 4

# ===== abs =====
psabs.h t3, t0
sw t3, 0(t2)
addi t2, t2, 4

# ===== sat =====
psati.h t3, t0, 7
sw t3, 0(t2)
addi t2, t2, 4

pusati.h t3, t0, 7
sw t3, 0(t2)
addi t2, t2, 4

# ===== mac =====
li t4, 0
pmhacc.h t4, t0, t1
sw t4, 0(t2)

loop:
j loop

.section .bss
.align 4
results:
.space 256
