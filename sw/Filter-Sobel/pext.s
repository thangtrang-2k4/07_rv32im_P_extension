
pext.elf:     file format elf32-littleriscv


Disassembly of section .text:

80000000 <_start>:
80000000:	00020117          	auipc	sp,0x20
80000004:	00010113          	mv	sp,sp
80000008:	00010297          	auipc	t0,0x10
8000000c:	01428293          	addi	t0,t0,20 # 8001001c <output>
80000010:	00010317          	auipc	t1,0x10
80000014:	02530313          	addi	t1,t1,37 # 80010035 <_bss_end>

80000018 <clear_bss>:
80000018:	0062d863          	bge	t0,t1,80000028 <done_bss>
8000001c:	0002a023          	sw	zero,0(t0)
80000020:	00428293          	addi	t0,t0,4
80000024:	ff5ff06f          	j	80000018 <clear_bss>

80000028 <done_bss>:
80000028:	168000ef          	jal	80000190 <main>
8000002c:	0000006f          	j	8000002c <done_bss+0x4>

80000030 <sobel_pext>:
80000030:	fe010113          	addi	sp,sp,-32 # 8001ffe0 <_bss_end+0xffab>
80000034:	00812e23          	sw	s0,28(sp)
80000038:	00912c23          	sw	s1,24(sp)
8000003c:	80010437          	lui	s0,0x80010
80000040:	800104b7          	lui	s1,0x80010
80000044:	00010837          	lui	a6,0x10
80000048:	000202b7          	lui	t0,0x20
8000004c:	01000fb7          	lui	t6,0x1000
80000050:	00010f37          	lui	t5,0x10
80000054:	01212a23          	sw	s2,20(sp)
80000058:	01312823          	sw	s3,16(sp)
8000005c:	01412623          	sw	s4,12(sp)
80000060:	01512423          	sw	s5,8(sp)
80000064:	01612223          	sw	s6,4(sp)
80000068:	01c48493          	addi	s1,s1,28 # 8001001c <output>
8000006c:	00540413          	addi	s0,s0,5 # 80010005 <input+0x5>
80000070:	0ff80813          	addi	a6,a6,255 # 100ff <_start-0x7ffeff01>
80000074:	0fe28293          	addi	t0,t0,254 # 200fe <_start-0x7ffdff02>
80000078:	efff8f93          	addi	t6,t6,-257 # fffeff <_start-0x7f000101>
8000007c:	201f0f13          	addi	t5,t5,513 # 10201 <_start-0x7ffefdff>
80000080:	00a00e13          	li	t3,10
80000084:	00000893          	li	a7,0
80000088:	ffb00313          	li	t1,-5
8000008c:	00100e93          	li	t4,1
80000090:	00400393          	li	t2,4
80000094:	002e9513          	slli	a0,t4,0x2
80000098:	01d50533          	add	a0,a0,t4
8000009c:	00a48533          	add	a0,s1,a0
800000a0:	001e8e93          	addi	t4,t4,1
800000a4:	011406b3          	add	a3,s0,a7
800000a8:	00100613          	li	a2,1
800000ac:	00d307b3          	add	a5,t1,a3
800000b0:	011789b3          	add	s3,a5,a7
800000b4:	0029c583          	lbu	a1,2(s3)
800000b8:	01c787b3          	add	a5,a5,t3
800000bc:	0019ca03          	lbu	s4,1(s3)
800000c0:	0027c703          	lbu	a4,2(a5)
800000c4:	0017c903          	lbu	s2,1(a5)
800000c8:	0009ca83          	lbu	s5,0(s3)
800000cc:	008a1a13          	slli	s4,s4,0x8
800000d0:	0007c983          	lbu	s3,0(a5)
800000d4:	01059793          	slli	a5,a1,0x10
800000d8:	00fa6a33          	or	s4,s4,a5
800000dc:	00891913          	slli	s2,s2,0x8
800000e0:	01071793          	slli	a5,a4,0x10
800000e4:	00f96933          	or	s2,s2,a5
800000e8:	00000713          	li	a4,0
800000ec:	00c505b3          	add	a1,a0,a2
800000f0:	015a6a33          	or	s4,s4,s5
800000f4:	01396933          	or	s2,s2,s3
800000f8:	00070793          	mv	a5,a4
800000fc:	00160613          	addi	a2,a2,1
80000100:	ed4857bb          	pm4addasu.b	a5,a6,s4
80000104:	0016c983          	lbu	s3,1(a3)
80000108:	0026ca83          	lbu	s5,2(a3)
8000010c:	0006cb03          	lbu	s6,0(a3)
80000110:	00899993          	slli	s3,s3,0x8
80000114:	010a9a93          	slli	s5,s5,0x10
80000118:	0159e9b3          	or	s3,s3,s5
8000011c:	0169e9b3          	or	s3,s3,s6
80000120:	ed32d7bb          	pm4addasu.b	a5,t0,s3
80000124:	ed2857bb          	pm4addasu.b	a5,a6,s2
80000128:	ed4fd73b          	pm4addasu.b	a4,t6,s4
8000012c:	ed2f573b          	pm4addasu.b	a4,t5,s2
80000130:	01079793          	slli	a5,a5,0x10
80000134:	01071713          	slli	a4,a4,0x10
80000138:	0107d793          	srli	a5,a5,0x10
8000013c:	00e7e7b3          	or	a5,a5,a4
80000140:	e077a79b          	psabs.h	a5,a5
80000144:	0107d713          	srli	a4,a5,0x10
80000148:	80e787bb          	padd.h	a5,a5,a4
8000014c:	a187c79b          	pusati.h	a5,a5,0x8
80000150:	00f58023          	sb	a5,0(a1)
80000154:	00168693          	addi	a3,a3,1
80000158:	f4761ae3          	bne	a2,t2,800000ac <sobel_pext+0x7c>
8000015c:	ffb30313          	addi	t1,t1,-5
80000160:	00588893          	addi	a7,a7,5
80000164:	005e0e13          	addi	t3,t3,5
80000168:	f2ce96e3          	bne	t4,a2,80000094 <sobel_pext+0x64>
8000016c:	01c12403          	lw	s0,28(sp)
80000170:	01812483          	lw	s1,24(sp)
80000174:	01412903          	lw	s2,20(sp)
80000178:	01012983          	lw	s3,16(sp)
8000017c:	00c12a03          	lw	s4,12(sp)
80000180:	00812a83          	lw	s5,8(sp)
80000184:	00412b03          	lw	s6,4(sp)
80000188:	02010113          	addi	sp,sp,32
8000018c:	00008067          	ret

80000190 <main>:
80000190:	ff010113          	addi	sp,sp,-16
80000194:	800106b7          	lui	a3,0x80010
80000198:	00112623          	sw	ra,12(sp)
8000019c:	01c68693          	addi	a3,a3,28 # 8001001c <output>
800001a0:	00000713          	li	a4,0
800001a4:	00500613          	li	a2,5
800001a8:	00271793          	slli	a5,a4,0x2
800001ac:	00e787b3          	add	a5,a5,a4
800001b0:	00f687b3          	add	a5,a3,a5
800001b4:	00078023          	sb	zero,0(a5)
800001b8:	000780a3          	sb	zero,1(a5)
800001bc:	00078123          	sb	zero,2(a5)
800001c0:	000781a3          	sb	zero,3(a5)
800001c4:	00078223          	sb	zero,4(a5)
800001c8:	00170713          	addi	a4,a4,1
800001cc:	fcc71ee3          	bne	a4,a2,800001a8 <main+0x18>
800001d0:	e61ff0ef          	jal	80000030 <sobel_pext>
800001d4:	00c12083          	lw	ra,12(sp)
800001d8:	800117b7          	lui	a5,0x80011
800001dc:	00100713          	li	a4,1
800001e0:	00e7a023          	sw	a4,0(a5) # 80011000 <_bss_end+0xfcb>
800001e4:	00000513          	li	a0,0
800001e8:	01010113          	addi	sp,sp,16
800001ec:	00008067          	ret

Disassembly of section .data:

80010000 <input>:
80010000:	0a0a                	.insn	2, 0x0a0a
80010002:	0a0a                	.insn	2, 0x0a0a
80010004:	0a0a                	.insn	2, 0x0a0a
80010006:	3232                	.insn	2, 0x3232
80010008:	0a32                	.insn	2, 0x0a32
8001000a:	320a                	.insn	2, 0x320a
8001000c:	3264                	.insn	2, 0x3264
8001000e:	0a0a                	.insn	2, 0x0a0a
80010010:	3232                	.insn	2, 0x3232
80010012:	0a32                	.insn	2, 0x0a32
80010014:	0a0a                	.insn	2, 0x0a0a
80010016:	0a0a                	.insn	2, 0x0a0a
80010018:	0a                	.byte	0x0a

Disassembly of section .riscv.attributes:

00000000 <.riscv.attributes>:
   0:	2f41                	.insn	2, 0x2f41
   2:	0000                	.insn	2, 0x0000
   4:	7200                	.insn	2, 0x7200
   6:	7369                	.insn	2, 0x7369
   8:	01007663          	bgeu	zero,a6,14 <_start-0x7fffffec>
   c:	0025                	.insn	2, 0x0025
   e:	0000                	.insn	2, 0x0000
  10:	1004                	.insn	2, 0x1004
  12:	7205                	.insn	2, 0x7205
  14:	3376                	.insn	2, 0x3376
  16:	6932                	.insn	2, 0x6932
  18:	7032                	.insn	2, 0x7032
  1a:	5f31                	.insn	2, 0x5f31
  1c:	326d                	.insn	2, 0x326d
  1e:	3070                	.insn	2, 0x3070
  20:	705f 7030 3531      	.insn	6, 0x35317030705f
  26:	7a5f 6d6d 6c75      	.insn	6, 0x6c756d6d7a5f
  2c:	7031                	.insn	2, 0x7031
  2e:	0030                	.insn	2, 0x0030

Disassembly of section .comment:

00000000 <.comment>:
   0:	3a434347          	.insn	4, 0x3a434347
   4:	2820                	.insn	2, 0x2820
   6:	66663667          	.insn	4, 0x66663667
   a:	6664                	.insn	2, 0x6664
   c:	3764                	.insn	2, 0x3764
   e:	31383633          	.insn	4, 0x31383633
  12:	2938                	.insn	2, 0x2938
  14:	3120                	.insn	2, 0x3120
  16:	2e36                	.insn	2, 0x2e36
  18:	2e30                	.insn	2, 0x2e30
  1a:	2030                	.insn	2, 0x2030
  1c:	3032                	.insn	2, 0x3032
  1e:	3532                	.insn	2, 0x3532
  20:	3830                	.insn	2, 0x3830
  22:	3331                	.insn	2, 0x3331
  24:	2820                	.insn	2, 0x2820
  26:	7865                	.insn	2, 0x7865
  28:	6570                	.insn	2, 0x6570
  2a:	6972                	.insn	2, 0x6972
  2c:	656d                	.insn	2, 0x656d
  2e:	746e                	.insn	2, 0x746e
  30:	6c61                	.insn	2, 0x6c61
  32:	0029                	.insn	2, 0x0029
