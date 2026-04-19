
scala.elf:     file format elf32-littleriscv


Disassembly of section .text:

80000000 <_start>:
80000000:	00020117          	auipc	sp,0x20
80000004:	00010113          	mv	sp,sp
80000008:	00010297          	auipc	t0,0x10
8000000c:	ff828293          	addi	t0,t0,-8 # 80010000 <output>
80000010:	00010317          	auipc	t1,0x10
80000014:	0b830313          	addi	t1,t1,184 # 800100c8 <_bss_end>

80000018 <clear_bss>:
80000018:	0062d863          	bge	t0,t1,80000028 <done_bss>
8000001c:	0002a023          	sw	zero,0(t0)
80000020:	00428293          	addi	t0,t0,4
80000024:	ff5ff06f          	j	80000018 <clear_bss>

80000028 <done_bss>:
80000028:	008000ef          	jal	80000030 <main>
8000002c:	0000006f          	j	8000002c <done_bss+0x4>

80000030 <main>:
80000030:	800008b7          	lui	a7,0x80000
80000034:	0c488893          	addi	a7,a7,196 # 800000c4 <input_data>
80000038:	80010337          	lui	t1,0x80010
8000003c:	01f88513          	addi	a0,a7,31
80000040:	00030313          	mv	t1,t1
80000044:	0e888893          	addi	a7,a7,232
80000048:	01f00693          	li	a3,31
8000004c:	80000fb7          	lui	t6,0x80000
80000050:	f8000f13          	li	t5,-128
80000054:	07f00e93          	li	t4,127
80000058:	0c800e13          	li	t3,200
8000005c:	18cf8713          	addi	a4,t6,396 # 8000018c <fir_coeffs>
80000060:	00050613          	mv	a2,a0
80000064:	00000793          	li	a5,0
80000068:	00070583          	lb	a1,0(a4)
8000006c:	00060803          	lb	a6,0(a2)
80000070:	00170713          	addi	a4,a4,1
80000074:	fff60613          	addi	a2,a2,-1
80000078:	030585b3          	mul	a1,a1,a6
8000007c:	00b787b3          	add	a5,a5,a1
80000080:	fee894e3          	bne	a7,a4,80000068 <main+0x38>
80000084:	20078793          	addi	a5,a5,512
80000088:	40a7d793          	srai	a5,a5,0xa
8000008c:	01e7d463          	bge	a5,t5,80000094 <main+0x64>
80000090:	f8000793          	li	a5,-128
80000094:	00fed463          	bge	t4,a5,8000009c <main+0x6c>
80000098:	07f00793          	li	a5,127
8000009c:	00d30733          	add	a4,t1,a3
800000a0:	00f70023          	sb	a5,0(a4)
800000a4:	00168693          	addi	a3,a3,1
800000a8:	00150513          	addi	a0,a0,1
800000ac:	fbc698e3          	bne	a3,t3,8000005c <main+0x2c>
800000b0:	800117b7          	lui	a5,0x80011
800000b4:	00100713          	li	a4,1
800000b8:	00e7a023          	sw	a4,0(a5) # 80011000 <_bss_end+0xf38>
800000bc:	00000513          	li	a0,0
800000c0:	00008067          	ret

Disassembly of section .rodata:

800000c4 <input_data>:
800000c4:	07204327          	.insn	4, 0x07204327
800000c8:	4f36                	.insn	2, 0x4f36
800000ca:	2454                	.insn	2, 0x2454
800000cc:	6a4a                	.insn	2, 0x6a4a
800000ce:	3666                	.insn	2, 0x3666
800000d0:	6f3e                	.insn	2, 0x6f3e
800000d2:	154a                	.insn	2, 0x154a
800000d4:	624e                	.insn	2, 0x624e
800000d6:	2e071c37          	lui	s8,0x2e071
800000da:	e8edea17          	auipc	s4,0xe8ede
800000de:	cbde                	.insn	2, 0xcbde
800000e0:	0bf2                	.insn	2, 0x0bf2
800000e2:	d5d5                	.insn	2, 0xd5d5
800000e4:	b2e407cb          	.insn	4, 0xb2e407cb
800000e8:	09fc                	.insn	2, 0x09fc
800000ea:	33f4fb13          	andi	s6,s1,831
800000ee:	6b2b063b          	.insn	4, 0x6b2b063b
800000f2:	3430                	.insn	2, 0x3430
800000f4:	32607f3b          	.insn	4, 0x32607f3b
800000f8:	5532                	.insn	2, 0x5532
800000fa:	481e3e43          	.insn	4, 0x481e3e43
800000fe:	0631                	.insn	2, 0x0631
80000100:	2325                	.insn	2, 0x2325
80000102:	fcf4e51b          	pmaxu.db	a0,s0,a4
80000106:	e2ddbee7          	.insn	4, 0xe2ddbee7
8000010a:	fee0acc3          	.insn	4, 0xfee0acc3
8000010e:	b7e0                	.insn	2, 0xb7e0
80000110:	25fe                	.insn	2, 0x25fe
80000112:	0519                	.insn	2, 0x0519
80000114:	4d2a                	.insn	2, 0x4d2a
80000116:	47420f27          	.insn	4, 0x47420f27
8000011a:	4455                	.insn	2, 0x4455
8000011c:	3a696b63          	bltu	s2,t1,800004d2 <fir_coeffs+0x346>
80000120:	6948                	.insn	2, 0x6948
80000122:	3d60                	.insn	2, 0x3d60
80000124:	032b2c47          	.insn	4, 0x032b2c47
80000128:	351a                	.insn	2, 0x351a
8000012a:	edf0                	.insn	2, 0xedf0
8000012c:	efd8                	.insn	2, 0xefd8
8000012e:	d7ecbaf3          	.insn	4, 0xd7ecbaf3
80000132:	cbc1                	.insn	2, 0xcbc1
80000134:	f9be                	.insn	2, 0xf9be
80000136:	d2fa                	.insn	2, 0xd2fa
80000138:	f2fa                	.insn	2, 0xf2fa
8000013a:	f708                	.insn	2, 0xf708
8000013c:	321d2d17          	auipc	s10,0x321d2
80000140:	3819                	.insn	2, 0x3819
80000142:	1d5e                	.insn	2, 0x1d5e
80000144:	5434                	.insn	2, 0x5434
80000146:	4f60                	.insn	2, 0x4f60
80000148:	5b2e                	.insn	2, 0x5b2e
8000014a:	4e25162b          	.insn	4, 0x4e25162b
8000014e:	f01c                	.insn	2, 0xf01c
80000150:	0512                	.insn	2, 0x0512
80000152:	fce8                	.insn	2, 0xfce8
80000154:	f7dd                	.insn	2, 0xf7dd
80000156:	dbf2d9ef          	jal	s3,7ff2df14 <_start-0xd20ec>
8000015a:	dbe0                	.insn	2, 0xdbe0
8000015c:	ffbe                	.insn	2, 0xffbe
8000015e:	c6f6                	.insn	2, 0xc6f6
80000160:	15e0                	.insn	2, 0x15e0
80000162:	ddfc                	.insn	2, 0xddfc
80000164:	2e10                	.insn	2, 0x2e10
80000166:	1629                	.insn	2, 0x1629
80000168:	4c2a                	.insn	2, 0x4c2a
8000016a:	484f2157          	.insn	4, 0x484f2157
8000016e:	2b5c                	.insn	2, 0x2b5c
80000170:	5230                	.insn	2, 0x5230
80000172:	392c4033          	.insn	4, 0x392c4033
80000176:	1e1c                	.insn	2, 0x1e1c
80000178:	281a                	.insn	2, 0x281a
8000017a:	d80c                	.insn	2, 0xd80c
8000017c:	09ea                	.insn	2, 0x09ea
8000017e:	b2c4                	.insn	2, 0xb2c4
80000180:	b7dedfcf          	.insn	4, 0xb7dedfcf
80000184:	cadcf9ef          	jal	s3,7ffcfe30 <_start-0x301d0>
80000188:	d5090afb          	.insn	4, 0xd5090afb

8000018c <fir_coeffs>:
8000018c:	fefe                	.insn	2, 0xfefe
8000018e:	fdfd                	.insn	2, 0xfdfd
80000190:	fffd                	.insn	2, 0xfffd
80000192:	0802                	.insn	2, 0x0802
80000194:	1e12                	.insn	2, 0x1e12
80000196:	3c2c                	.insn	2, 0x3c2c
80000198:	6762584b          	.insn	4, 0x6762584b
8000019c:	4b586267          	.insn	4, 0x4b586267
800001a0:	2c3c                	.insn	2, 0x2c3c
800001a2:	121e                	.insn	2, 0x121e
800001a4:	0208                	.insn	2, 0x0208
800001a6:	fdff                	.insn	2, 0xfdff
800001a8:	fdfd                	.insn	2, 0xfdfd
800001aa:	fefe                	.insn	2, 0xfefe

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
