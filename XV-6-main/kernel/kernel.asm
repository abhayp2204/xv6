
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d3c78793          	addi	a5,a5,-708 # 80005da0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	37a080e7          	jalr	890(ra) # 800024a6 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ed8080e7          	jalr	-296(ra) # 800020ac <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	240080e7          	jalr	576(ra) # 80002450 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	20a080e7          	jalr	522(ra) # 800024fc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	df2080e7          	jalr	-526(ra) # 80002238 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	8a078793          	addi	a5,a5,-1888 # 80021d18 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	998080e7          	jalr	-1640(ra) # 80002238 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	780080e7          	jalr	1920(ra) # 800020ac <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	84e080e7          	jalr	-1970(ra) # 80002722 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f04080e7          	jalr	-252(ra) # 80005de0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	024080e7          	jalr	36(ra) # 80001f08 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7ae080e7          	jalr	1966(ra) # 800026fa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	7ce080e7          	jalr	1998(ra) # 80002722 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e6e080e7          	jalr	-402(ra) # 80005dca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e7c080e7          	jalr	-388(ra) # 80005de0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	054080e7          	jalr	84(ra) # 80002fc0 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6e4080e7          	jalr	1764(ra) # 80003658 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	68e080e7          	jalr	1678(ra) # 8000460a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f7e080e7          	jalr	-130(ra) # 80005f02 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d42080e7          	jalr	-702(ra) # 80001cce <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	262a0a13          	addi	s4,s4,610 # 80017ad0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	19048493          	addi	s1,s1,400
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	19698993          	addi	s3,s3,406 # 80017ad0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	19048493          	addi	s1,s1,400
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	f707a783          	lw	a5,-144(a5) # 80008970 <first.1686>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d30080e7          	jalr	-720(ra) # 8000273a <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f407ab23          	sw	zero,-170(a5) # 80008970 <first.1686>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	bb4080e7          	jalr	-1100(ra) # 800035d8 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	f2878793          	addi	a5,a5,-216 # 80008974 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
  p->mask=0;
    80001bb0:	1604a423          	sw	zero,360(s1)
  p->ctime = 0;
    80001bb4:	1604a623          	sw	zero,364(s1)
  p->rtime = 0;
    80001bb8:	1604aa23          	sw	zero,372(s1)
  p->stime = 0;
    80001bbc:	1604ac23          	sw	zero,376(s1)
  p->niceness=0;
    80001bc0:	1804a223          	sw	zero,388(s1)
  p->static_priority=0;
    80001bc4:	1604ae23          	sw	zero,380(s1)
  p->no_of_proc=0;
    80001bc8:	1804a423          	sw	zero,392(s1)
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <allocproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	00010497          	auipc	s1,0x10
    80001be6:	aee48493          	addi	s1,s1,-1298 # 800116d0 <proc>
    80001bea:	00016917          	auipc	s2,0x16
    80001bee:	ee690913          	addi	s2,s2,-282 # 80017ad0 <tickslock>
    acquire(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	ff0080e7          	jalr	-16(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bfc:	4c9c                	lw	a5,24(s1)
    80001bfe:	cf81                	beqz	a5,80001c16 <allocproc+0x40>
      release(&p->lock);
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	096080e7          	jalr	150(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	19048493          	addi	s1,s1,400
    80001c0e:	ff2492e3          	bne	s1,s2,80001bf2 <allocproc+0x1c>
  return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	a8b5                	j	80001c90 <allocproc+0xba>
  p->pid = allocpid();
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	e18080e7          	jalr	-488(ra) # 80001a2e <allocpid>
    80001c1e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c20:	4785                	li	a5,1
    80001c22:	cc9c                	sw	a5,24(s1)
  p->mask=0;
    80001c24:	1604a423          	sw	zero,360(s1)
  p->ctime = ticks;
    80001c28:	00007797          	auipc	a5,0x7
    80001c2c:	4087a783          	lw	a5,1032(a5) # 80009030 <ticks>
    80001c30:	16f4a623          	sw	a5,364(s1)
  p->rtime = 0;
    80001c34:	1604aa23          	sw	zero,372(s1)
  p->stime = 0;
    80001c38:	1604ac23          	sw	zero,376(s1)
  p->niceness=5;
    80001c3c:	4795                	li	a5,5
    80001c3e:	18f4a223          	sw	a5,388(s1)
  p->static_priority=60;
    80001c42:	03c00793          	li	a5,60
    80001c46:	16f4ae23          	sw	a5,380(s1)
  p->no_of_proc=0;
    80001c4a:	1804a423          	sw	zero,392(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	ea6080e7          	jalr	-346(ra) # 80000af4 <kalloc>
    80001c56:	892a                	mv	s2,a0
    80001c58:	eca8                	sd	a0,88(s1)
    80001c5a:	c131                	beqz	a0,80001c9e <allocproc+0xc8>
  p->pagetable = proc_pagetable(p);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	e16080e7          	jalr	-490(ra) # 80001a74 <proc_pagetable>
    80001c66:	892a                	mv	s2,a0
    80001c68:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6a:	c531                	beqz	a0,80001cb6 <allocproc+0xe0>
  memset(&p->context, 0, sizeof(p->context));
    80001c6c:	07000613          	li	a2,112
    80001c70:	4581                	li	a1,0
    80001c72:	06048513          	addi	a0,s1,96
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	06a080e7          	jalr	106(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c7e:	00000797          	auipc	a5,0x0
    80001c82:	d6a78793          	addi	a5,a5,-662 # 800019e8 <forkret>
    80001c86:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c88:	60bc                	ld	a5,64(s1)
    80001c8a:	6705                	lui	a4,0x1
    80001c8c:	97ba                	add	a5,a5,a4
    80001c8e:	f4bc                	sd	a5,104(s1)
}
    80001c90:	8526                	mv	a0,s1
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6902                	ld	s2,0(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret
    freeproc(p);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	ec2080e7          	jalr	-318(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	fee080e7          	jalr	-18(ra) # 80000c98 <release>
    return 0;
    80001cb2:	84ca                	mv	s1,s2
    80001cb4:	bff1                	j	80001c90 <allocproc+0xba>
    freeproc(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	eaa080e7          	jalr	-342(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	fd6080e7          	jalr	-42(ra) # 80000c98 <release>
    return 0;
    80001cca:	84ca                	mv	s1,s2
    80001ccc:	b7d1                	j	80001c90 <allocproc+0xba>

0000000080001cce <userinit>:
{
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	efe080e7          	jalr	-258(ra) # 80001bd6 <allocproc>
    80001ce0:	84aa                	mv	s1,a0
  initproc = p;
    80001ce2:	00007797          	auipc	a5,0x7
    80001ce6:	34a7b323          	sd	a0,838(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cea:	03400613          	li	a2,52
    80001cee:	00007597          	auipc	a1,0x7
    80001cf2:	c9258593          	addi	a1,a1,-878 # 80008980 <initcode>
    80001cf6:	6928                	ld	a0,80(a0)
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	670080e7          	jalr	1648(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d00:	6785                	lui	a5,0x1
    80001d02:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d04:	6cb8                	ld	a4,88(s1)
    80001d06:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0a:	6cb8                	ld	a4,88(s1)
    80001d0c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0e:	4641                	li	a2,16
    80001d10:	00006597          	auipc	a1,0x6
    80001d14:	4f058593          	addi	a1,a1,1264 # 80008200 <digits+0x1c0>
    80001d18:	15848513          	addi	a0,s1,344
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	116080e7          	jalr	278(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d24:	00006517          	auipc	a0,0x6
    80001d28:	4ec50513          	addi	a0,a0,1260 # 80008210 <digits+0x1d0>
    80001d2c:	00002097          	auipc	ra,0x2
    80001d30:	2da080e7          	jalr	730(ra) # 80004006 <namei>
    80001d34:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d38:	478d                	li	a5,3
    80001d3a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6105                	addi	sp,sp,32
    80001d4e:	8082                	ret

0000000080001d50 <growproc>:
{
    80001d50:	1101                	addi	sp,sp,-32
    80001d52:	ec06                	sd	ra,24(sp)
    80001d54:	e822                	sd	s0,16(sp)
    80001d56:	e426                	sd	s1,8(sp)
    80001d58:	e04a                	sd	s2,0(sp)
    80001d5a:	1000                	addi	s0,sp,32
    80001d5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	c52080e7          	jalr	-942(ra) # 800019b0 <myproc>
    80001d66:	892a                	mv	s2,a0
  sz = p->sz;
    80001d68:	652c                	ld	a1,72(a0)
    80001d6a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d6e:	00904f63          	bgtz	s1,80001d8c <growproc+0x3c>
  } else if(n < 0){
    80001d72:	0204cc63          	bltz	s1,80001daa <growproc+0x5a>
  p->sz = sz;
    80001d76:	1602                	slli	a2,a2,0x20
    80001d78:	9201                	srli	a2,a2,0x20
    80001d7a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d7e:	4501                	li	a0,0
}
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6902                	ld	s2,0(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d8c:	9e25                	addw	a2,a2,s1
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	1582                	slli	a1,a1,0x20
    80001d94:	9181                	srli	a1,a1,0x20
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	68a080e7          	jalr	1674(ra) # 80001422 <uvmalloc>
    80001da0:	0005061b          	sext.w	a2,a0
    80001da4:	fa69                	bnez	a2,80001d76 <growproc+0x26>
      return -1;
    80001da6:	557d                	li	a0,-1
    80001da8:	bfe1                	j	80001d80 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001daa:	9e25                	addw	a2,a2,s1
    80001dac:	1602                	slli	a2,a2,0x20
    80001dae:	9201                	srli	a2,a2,0x20
    80001db0:	1582                	slli	a1,a1,0x20
    80001db2:	9181                	srli	a1,a1,0x20
    80001db4:	6928                	ld	a0,80(a0)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	624080e7          	jalr	1572(ra) # 800013da <uvmdealloc>
    80001dbe:	0005061b          	sext.w	a2,a0
    80001dc2:	bf55                	j	80001d76 <growproc+0x26>

0000000080001dc4 <fork>:
{
    80001dc4:	7179                	addi	sp,sp,-48
    80001dc6:	f406                	sd	ra,40(sp)
    80001dc8:	f022                	sd	s0,32(sp)
    80001dca:	ec26                	sd	s1,24(sp)
    80001dcc:	e84a                	sd	s2,16(sp)
    80001dce:	e44e                	sd	s3,8(sp)
    80001dd0:	e052                	sd	s4,0(sp)
    80001dd2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	bdc080e7          	jalr	-1060(ra) # 800019b0 <myproc>
    80001ddc:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	df8080e7          	jalr	-520(ra) # 80001bd6 <allocproc>
    80001de6:	10050f63          	beqz	a0,80001f04 <fork+0x140>
    80001dea:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dec:	04893603          	ld	a2,72(s2)
    80001df0:	692c                	ld	a1,80(a0)
    80001df2:	05093503          	ld	a0,80(s2)
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	778080e7          	jalr	1912(ra) # 8000156e <uvmcopy>
    80001dfe:	04054a63          	bltz	a0,80001e52 <fork+0x8e>
  np->sz = p->sz;
    80001e02:	04893783          	ld	a5,72(s2)
    80001e06:	04f9b423          	sd	a5,72(s3)
  np->mask=p->mask;
    80001e0a:	16892783          	lw	a5,360(s2)
    80001e0e:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e12:	05893683          	ld	a3,88(s2)
    80001e16:	87b6                	mv	a5,a3
    80001e18:	0589b703          	ld	a4,88(s3)
    80001e1c:	12068693          	addi	a3,a3,288
    80001e20:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e24:	6788                	ld	a0,8(a5)
    80001e26:	6b8c                	ld	a1,16(a5)
    80001e28:	6f90                	ld	a2,24(a5)
    80001e2a:	01073023          	sd	a6,0(a4)
    80001e2e:	e708                	sd	a0,8(a4)
    80001e30:	eb0c                	sd	a1,16(a4)
    80001e32:	ef10                	sd	a2,24(a4)
    80001e34:	02078793          	addi	a5,a5,32
    80001e38:	02070713          	addi	a4,a4,32
    80001e3c:	fed792e3          	bne	a5,a3,80001e20 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e40:	0589b783          	ld	a5,88(s3)
    80001e44:	0607b823          	sd	zero,112(a5)
    80001e48:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e4c:	15000a13          	li	s4,336
    80001e50:	a03d                	j	80001e7e <fork+0xba>
    freeproc(np);
    80001e52:	854e                	mv	a0,s3
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	d0e080e7          	jalr	-754(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e5c:	854e                	mv	a0,s3
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	e3a080e7          	jalr	-454(ra) # 80000c98 <release>
    return -1;
    80001e66:	5a7d                	li	s4,-1
    80001e68:	a069                	j	80001ef2 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e6a:	00003097          	auipc	ra,0x3
    80001e6e:	832080e7          	jalr	-1998(ra) # 8000469c <filedup>
    80001e72:	009987b3          	add	a5,s3,s1
    80001e76:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e78:	04a1                	addi	s1,s1,8
    80001e7a:	01448763          	beq	s1,s4,80001e88 <fork+0xc4>
    if(p->ofile[i])
    80001e7e:	009907b3          	add	a5,s2,s1
    80001e82:	6388                	ld	a0,0(a5)
    80001e84:	f17d                	bnez	a0,80001e6a <fork+0xa6>
    80001e86:	bfcd                	j	80001e78 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e88:	15093503          	ld	a0,336(s2)
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	986080e7          	jalr	-1658(ra) # 80003812 <idup>
    80001e94:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e98:	4641                	li	a2,16
    80001e9a:	15890593          	addi	a1,s2,344
    80001e9e:	15898513          	addi	a0,s3,344
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	f90080e7          	jalr	-112(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001eaa:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	de8080e7          	jalr	-536(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eb8:	0000f497          	auipc	s1,0xf
    80001ebc:	40048493          	addi	s1,s1,1024 # 800112b8 <wait_lock>
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d22080e7          	jalr	-734(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eca:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ece:	8526                	mv	a0,s1
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ed8:	854e                	mv	a0,s3
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	d0a080e7          	jalr	-758(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ee2:	478d                	li	a5,3
    80001ee4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	dae080e7          	jalr	-594(ra) # 80000c98 <release>
}
    80001ef2:	8552                	mv	a0,s4
    80001ef4:	70a2                	ld	ra,40(sp)
    80001ef6:	7402                	ld	s0,32(sp)
    80001ef8:	64e2                	ld	s1,24(sp)
    80001efa:	6942                	ld	s2,16(sp)
    80001efc:	69a2                	ld	s3,8(sp)
    80001efe:	6a02                	ld	s4,0(sp)
    80001f00:	6145                	addi	sp,sp,48
    80001f02:	8082                	ret
    return -1;
    80001f04:	5a7d                	li	s4,-1
    80001f06:	b7f5                	j	80001ef2 <fork+0x12e>

0000000080001f08 <scheduler>:
{
    80001f08:	7139                	addi	sp,sp,-64
    80001f0a:	fc06                	sd	ra,56(sp)
    80001f0c:	f822                	sd	s0,48(sp)
    80001f0e:	f426                	sd	s1,40(sp)
    80001f10:	f04a                	sd	s2,32(sp)
    80001f12:	ec4e                	sd	s3,24(sp)
    80001f14:	e852                	sd	s4,16(sp)
    80001f16:	e456                	sd	s5,8(sp)
    80001f18:	e05a                	sd	s6,0(sp)
    80001f1a:	0080                	addi	s0,sp,64
    80001f1c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f1e:	2781                	sext.w	a5,a5
        swtch(&c->context, &p->context);
    80001f20:	00779a93          	slli	s5,a5,0x7
    80001f24:	0000f717          	auipc	a4,0xf
    80001f28:	3b470713          	addi	a4,a4,948 # 800112d8 <cpus+0x8>
    80001f2c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f2e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f30:	4b11                	li	s6,4
        c->proc = p;
    80001f32:	079e                	slli	a5,a5,0x7
    80001f34:	0000fa17          	auipc	s4,0xf
    80001f38:	36ca0a13          	addi	s4,s4,876 # 800112a0 <pid_lock>
    80001f3c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	00016917          	auipc	s2,0x16
    80001f42:	b9290913          	addi	s2,s2,-1134 # 80017ad0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f46:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f4a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f4e:	10079073          	csrw	sstatus,a5
    80001f52:	0000f497          	auipc	s1,0xf
    80001f56:	77e48493          	addi	s1,s1,1918 # 800116d0 <proc>
    80001f5a:	a03d                	j	80001f88 <scheduler+0x80>
        p->state = RUNNING;
    80001f5c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f60:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f64:	06048593          	addi	a1,s1,96
    80001f68:	8556                	mv	a0,s5
    80001f6a:	00000097          	auipc	ra,0x0
    80001f6e:	726080e7          	jalr	1830(ra) # 80002690 <swtch>
        c->proc = 0;
    80001f72:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	d20080e7          	jalr	-736(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f80:	19048493          	addi	s1,s1,400
    80001f84:	fd2481e3          	beq	s1,s2,80001f46 <scheduler+0x3e>
      acquire(&p->lock);
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	c5a080e7          	jalr	-934(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f92:	4c9c                	lw	a5,24(s1)
    80001f94:	ff3791e3          	bne	a5,s3,80001f76 <scheduler+0x6e>
    80001f98:	b7d1                	j	80001f5c <scheduler+0x54>

0000000080001f9a <sched>:
{
    80001f9a:	7179                	addi	sp,sp,-48
    80001f9c:	f406                	sd	ra,40(sp)
    80001f9e:	f022                	sd	s0,32(sp)
    80001fa0:	ec26                	sd	s1,24(sp)
    80001fa2:	e84a                	sd	s2,16(sp)
    80001fa4:	e44e                	sd	s3,8(sp)
    80001fa6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	a08080e7          	jalr	-1528(ra) # 800019b0 <myproc>
    80001fb0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	bb8080e7          	jalr	-1096(ra) # 80000b6a <holding>
    80001fba:	c93d                	beqz	a0,80002030 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fbe:	2781                	sext.w	a5,a5
    80001fc0:	079e                	slli	a5,a5,0x7
    80001fc2:	0000f717          	auipc	a4,0xf
    80001fc6:	2de70713          	addi	a4,a4,734 # 800112a0 <pid_lock>
    80001fca:	97ba                	add	a5,a5,a4
    80001fcc:	0a87a703          	lw	a4,168(a5)
    80001fd0:	4785                	li	a5,1
    80001fd2:	06f71763          	bne	a4,a5,80002040 <sched+0xa6>
  if(p->state == RUNNING)
    80001fd6:	4c98                	lw	a4,24(s1)
    80001fd8:	4791                	li	a5,4
    80001fda:	06f70b63          	beq	a4,a5,80002050 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fde:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fe4:	efb5                	bnez	a5,80002060 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe8:	0000f917          	auipc	s2,0xf
    80001fec:	2b890913          	addi	s2,s2,696 # 800112a0 <pid_lock>
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	97ca                	add	a5,a5,s2
    80001ff6:	0ac7a983          	lw	s3,172(a5)
    80001ffa:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ffc:	2781                	sext.w	a5,a5
    80001ffe:	079e                	slli	a5,a5,0x7
    80002000:	0000f597          	auipc	a1,0xf
    80002004:	2d858593          	addi	a1,a1,728 # 800112d8 <cpus+0x8>
    80002008:	95be                	add	a1,a1,a5
    8000200a:	06048513          	addi	a0,s1,96
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	682080e7          	jalr	1666(ra) # 80002690 <swtch>
    80002016:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002018:	2781                	sext.w	a5,a5
    8000201a:	079e                	slli	a5,a5,0x7
    8000201c:	97ca                	add	a5,a5,s2
    8000201e:	0b37a623          	sw	s3,172(a5)
}
    80002022:	70a2                	ld	ra,40(sp)
    80002024:	7402                	ld	s0,32(sp)
    80002026:	64e2                	ld	s1,24(sp)
    80002028:	6942                	ld	s2,16(sp)
    8000202a:	69a2                	ld	s3,8(sp)
    8000202c:	6145                	addi	sp,sp,48
    8000202e:	8082                	ret
    panic("sched p->lock");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	1e850513          	addi	a0,a0,488 # 80008218 <digits+0x1d8>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	506080e7          	jalr	1286(ra) # 8000053e <panic>
    panic("sched locks");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1e850513          	addi	a0,a0,488 # 80008228 <digits+0x1e8>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4f6080e7          	jalr	1270(ra) # 8000053e <panic>
    panic("sched running");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1e850513          	addi	a0,a0,488 # 80008238 <digits+0x1f8>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4e6080e7          	jalr	1254(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1e850513          	addi	a0,a0,488 # 80008248 <digits+0x208>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4d6080e7          	jalr	1238(ra) # 8000053e <panic>

0000000080002070 <yield>:
{
    80002070:	1101                	addi	sp,sp,-32
    80002072:	ec06                	sd	ra,24(sp)
    80002074:	e822                	sd	s0,16(sp)
    80002076:	e426                	sd	s1,8(sp)
    80002078:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	936080e7          	jalr	-1738(ra) # 800019b0 <myproc>
    80002082:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b60080e7          	jalr	-1184(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000208c:	478d                	li	a5,3
    8000208e:	cc9c                	sw	a5,24(s1)
  sched();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	f0a080e7          	jalr	-246(ra) # 80001f9a <sched>
  release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
}
    800020a2:	60e2                	ld	ra,24(sp)
    800020a4:	6442                	ld	s0,16(sp)
    800020a6:	64a2                	ld	s1,8(sp)
    800020a8:	6105                	addi	sp,sp,32
    800020aa:	8082                	ret

00000000800020ac <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ac:	7179                	addi	sp,sp,-48
    800020ae:	f406                	sd	ra,40(sp)
    800020b0:	f022                	sd	s0,32(sp)
    800020b2:	ec26                	sd	s1,24(sp)
    800020b4:	e84a                	sd	s2,16(sp)
    800020b6:	e44e                	sd	s3,8(sp)
    800020b8:	1800                	addi	s0,sp,48
    800020ba:	89aa                	mv	s3,a0
    800020bc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	8f2080e7          	jalr	-1806(ra) # 800019b0 <myproc>
    800020c6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	b1c080e7          	jalr	-1252(ra) # 80000be4 <acquire>
  release(lk);
    800020d0:	854a                	mv	a0,s2
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	bc6080e7          	jalr	-1082(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020da:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020de:	4789                	li	a5,2
    800020e0:	cc9c                	sw	a5,24(s1)

  sched();
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	eb8080e7          	jalr	-328(ra) # 80001f9a <sched>

  // Tidy up.
  p->chan = 0;
    800020ea:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	ba8080e7          	jalr	-1112(ra) # 80000c98 <release>
  acquire(lk);
    800020f8:	854a                	mv	a0,s2
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	aea080e7          	jalr	-1302(ra) # 80000be4 <acquire>
}
    80002102:	70a2                	ld	ra,40(sp)
    80002104:	7402                	ld	s0,32(sp)
    80002106:	64e2                	ld	s1,24(sp)
    80002108:	6942                	ld	s2,16(sp)
    8000210a:	69a2                	ld	s3,8(sp)
    8000210c:	6145                	addi	sp,sp,48
    8000210e:	8082                	ret

0000000080002110 <wait>:
{
    80002110:	715d                	addi	sp,sp,-80
    80002112:	e486                	sd	ra,72(sp)
    80002114:	e0a2                	sd	s0,64(sp)
    80002116:	fc26                	sd	s1,56(sp)
    80002118:	f84a                	sd	s2,48(sp)
    8000211a:	f44e                	sd	s3,40(sp)
    8000211c:	f052                	sd	s4,32(sp)
    8000211e:	ec56                	sd	s5,24(sp)
    80002120:	e85a                	sd	s6,16(sp)
    80002122:	e45e                	sd	s7,8(sp)
    80002124:	e062                	sd	s8,0(sp)
    80002126:	0880                	addi	s0,sp,80
    80002128:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	886080e7          	jalr	-1914(ra) # 800019b0 <myproc>
    80002132:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002134:	0000f517          	auipc	a0,0xf
    80002138:	18450513          	addi	a0,a0,388 # 800112b8 <wait_lock>
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	aa8080e7          	jalr	-1368(ra) # 80000be4 <acquire>
    havekids = 0;
    80002144:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002146:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002148:	00016997          	auipc	s3,0x16
    8000214c:	98898993          	addi	s3,s3,-1656 # 80017ad0 <tickslock>
        havekids = 1;
    80002150:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002152:	0000fc17          	auipc	s8,0xf
    80002156:	166c0c13          	addi	s8,s8,358 # 800112b8 <wait_lock>
    havekids = 0;
    8000215a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000215c:	0000f497          	auipc	s1,0xf
    80002160:	57448493          	addi	s1,s1,1396 # 800116d0 <proc>
    80002164:	a0bd                	j	800021d2 <wait+0xc2>
          pid = np->pid;
    80002166:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000216a:	000b0e63          	beqz	s6,80002186 <wait+0x76>
    8000216e:	4691                	li	a3,4
    80002170:	02c48613          	addi	a2,s1,44
    80002174:	85da                	mv	a1,s6
    80002176:	05093503          	ld	a0,80(s2)
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	4f8080e7          	jalr	1272(ra) # 80001672 <copyout>
    80002182:	02054563          	bltz	a0,800021ac <wait+0x9c>
          freeproc(np);
    80002186:	8526                	mv	a0,s1
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	9da080e7          	jalr	-1574(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
          release(&wait_lock);
    8000219a:	0000f517          	auipc	a0,0xf
    8000219e:	11e50513          	addi	a0,a0,286 # 800112b8 <wait_lock>
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
          return pid;
    800021aa:	a09d                	j	80002210 <wait+0x100>
            release(&np->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	aea080e7          	jalr	-1302(ra) # 80000c98 <release>
            release(&wait_lock);
    800021b6:	0000f517          	auipc	a0,0xf
    800021ba:	10250513          	addi	a0,a0,258 # 800112b8 <wait_lock>
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ada080e7          	jalr	-1318(ra) # 80000c98 <release>
            return -1;
    800021c6:	59fd                	li	s3,-1
    800021c8:	a0a1                	j	80002210 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021ca:	19048493          	addi	s1,s1,400
    800021ce:	03348463          	beq	s1,s3,800021f6 <wait+0xe6>
      if(np->parent == p){
    800021d2:	7c9c                	ld	a5,56(s1)
    800021d4:	ff279be3          	bne	a5,s2,800021ca <wait+0xba>
        acquire(&np->lock);
    800021d8:	8526                	mv	a0,s1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	a0a080e7          	jalr	-1526(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021e2:	4c9c                	lw	a5,24(s1)
    800021e4:	f94781e3          	beq	a5,s4,80002166 <wait+0x56>
        release(&np->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
        havekids = 1;
    800021f2:	8756                	mv	a4,s5
    800021f4:	bfd9                	j	800021ca <wait+0xba>
    if(!havekids || p->killed){
    800021f6:	c701                	beqz	a4,800021fe <wait+0xee>
    800021f8:	02892783          	lw	a5,40(s2)
    800021fc:	c79d                	beqz	a5,8000222a <wait+0x11a>
      release(&wait_lock);
    800021fe:	0000f517          	auipc	a0,0xf
    80002202:	0ba50513          	addi	a0,a0,186 # 800112b8 <wait_lock>
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
      return -1;
    8000220e:	59fd                	li	s3,-1
}
    80002210:	854e                	mv	a0,s3
    80002212:	60a6                	ld	ra,72(sp)
    80002214:	6406                	ld	s0,64(sp)
    80002216:	74e2                	ld	s1,56(sp)
    80002218:	7942                	ld	s2,48(sp)
    8000221a:	79a2                	ld	s3,40(sp)
    8000221c:	7a02                	ld	s4,32(sp)
    8000221e:	6ae2                	ld	s5,24(sp)
    80002220:	6b42                	ld	s6,16(sp)
    80002222:	6ba2                	ld	s7,8(sp)
    80002224:	6c02                	ld	s8,0(sp)
    80002226:	6161                	addi	sp,sp,80
    80002228:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000222a:	85e2                	mv	a1,s8
    8000222c:	854a                	mv	a0,s2
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	e7e080e7          	jalr	-386(ra) # 800020ac <sleep>
    havekids = 0;
    80002236:	b715                	j	8000215a <wait+0x4a>

0000000080002238 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002238:	7139                	addi	sp,sp,-64
    8000223a:	fc06                	sd	ra,56(sp)
    8000223c:	f822                	sd	s0,48(sp)
    8000223e:	f426                	sd	s1,40(sp)
    80002240:	f04a                	sd	s2,32(sp)
    80002242:	ec4e                	sd	s3,24(sp)
    80002244:	e852                	sd	s4,16(sp)
    80002246:	e456                	sd	s5,8(sp)
    80002248:	0080                	addi	s0,sp,64
    8000224a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000224c:	0000f497          	auipc	s1,0xf
    80002250:	48448493          	addi	s1,s1,1156 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002254:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002256:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002258:	00016917          	auipc	s2,0x16
    8000225c:	87890913          	addi	s2,s2,-1928 # 80017ad0 <tickslock>
    80002260:	a821                	j	80002278 <wakeup+0x40>
        p->state = RUNNABLE;
    80002262:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a30080e7          	jalr	-1488(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002270:	19048493          	addi	s1,s1,400
    80002274:	03248463          	beq	s1,s2,8000229c <wakeup+0x64>
    if(p != myproc()){
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	738080e7          	jalr	1848(ra) # 800019b0 <myproc>
    80002280:	fea488e3          	beq	s1,a0,80002270 <wakeup+0x38>
      acquire(&p->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	95e080e7          	jalr	-1698(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000228e:	4c9c                	lw	a5,24(s1)
    80002290:	fd379be3          	bne	a5,s3,80002266 <wakeup+0x2e>
    80002294:	709c                	ld	a5,32(s1)
    80002296:	fd4798e3          	bne	a5,s4,80002266 <wakeup+0x2e>
    8000229a:	b7e1                	j	80002262 <wakeup+0x2a>
    }
  }
}
    8000229c:	70e2                	ld	ra,56(sp)
    8000229e:	7442                	ld	s0,48(sp)
    800022a0:	74a2                	ld	s1,40(sp)
    800022a2:	7902                	ld	s2,32(sp)
    800022a4:	69e2                	ld	s3,24(sp)
    800022a6:	6a42                	ld	s4,16(sp)
    800022a8:	6aa2                	ld	s5,8(sp)
    800022aa:	6121                	addi	sp,sp,64
    800022ac:	8082                	ret

00000000800022ae <reparent>:
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	e052                	sd	s4,0(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c0:	0000f497          	auipc	s1,0xf
    800022c4:	41048493          	addi	s1,s1,1040 # 800116d0 <proc>
      pp->parent = initproc;
    800022c8:	00007a17          	auipc	s4,0x7
    800022cc:	d60a0a13          	addi	s4,s4,-672 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d0:	00016997          	auipc	s3,0x16
    800022d4:	80098993          	addi	s3,s3,-2048 # 80017ad0 <tickslock>
    800022d8:	a029                	j	800022e2 <reparent+0x34>
    800022da:	19048493          	addi	s1,s1,400
    800022de:	01348d63          	beq	s1,s3,800022f8 <reparent+0x4a>
    if(pp->parent == p){
    800022e2:	7c9c                	ld	a5,56(s1)
    800022e4:	ff279be3          	bne	a5,s2,800022da <reparent+0x2c>
      pp->parent = initproc;
    800022e8:	000a3503          	ld	a0,0(s4)
    800022ec:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	f4a080e7          	jalr	-182(ra) # 80002238 <wakeup>
    800022f6:	b7d5                	j	800022da <reparent+0x2c>
}
    800022f8:	70a2                	ld	ra,40(sp)
    800022fa:	7402                	ld	s0,32(sp)
    800022fc:	64e2                	ld	s1,24(sp)
    800022fe:	6942                	ld	s2,16(sp)
    80002300:	69a2                	ld	s3,8(sp)
    80002302:	6a02                	ld	s4,0(sp)
    80002304:	6145                	addi	sp,sp,48
    80002306:	8082                	ret

0000000080002308 <exit>:
{
    80002308:	7179                	addi	sp,sp,-48
    8000230a:	f406                	sd	ra,40(sp)
    8000230c:	f022                	sd	s0,32(sp)
    8000230e:	ec26                	sd	s1,24(sp)
    80002310:	e84a                	sd	s2,16(sp)
    80002312:	e44e                	sd	s3,8(sp)
    80002314:	e052                	sd	s4,0(sp)
    80002316:	1800                	addi	s0,sp,48
    80002318:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	696080e7          	jalr	1686(ra) # 800019b0 <myproc>
    80002322:	89aa                	mv	s3,a0
  if(p == initproc)
    80002324:	00007797          	auipc	a5,0x7
    80002328:	d047b783          	ld	a5,-764(a5) # 80009028 <initproc>
    8000232c:	0d050493          	addi	s1,a0,208
    80002330:	15050913          	addi	s2,a0,336
    80002334:	02a79363          	bne	a5,a0,8000235a <exit+0x52>
    panic("init exiting");
    80002338:	00006517          	auipc	a0,0x6
    8000233c:	f2850513          	addi	a0,a0,-216 # 80008260 <digits+0x220>
    80002340:	ffffe097          	auipc	ra,0xffffe
    80002344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>
      fileclose(f);
    80002348:	00002097          	auipc	ra,0x2
    8000234c:	3a6080e7          	jalr	934(ra) # 800046ee <fileclose>
      p->ofile[fd] = 0;
    80002350:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002354:	04a1                	addi	s1,s1,8
    80002356:	01248563          	beq	s1,s2,80002360 <exit+0x58>
    if(p->ofile[fd]){
    8000235a:	6088                	ld	a0,0(s1)
    8000235c:	f575                	bnez	a0,80002348 <exit+0x40>
    8000235e:	bfdd                	j	80002354 <exit+0x4c>
  begin_op();
    80002360:	00002097          	auipc	ra,0x2
    80002364:	ec2080e7          	jalr	-318(ra) # 80004222 <begin_op>
  iput(p->cwd);
    80002368:	1509b503          	ld	a0,336(s3)
    8000236c:	00001097          	auipc	ra,0x1
    80002370:	69e080e7          	jalr	1694(ra) # 80003a0a <iput>
  end_op();
    80002374:	00002097          	auipc	ra,0x2
    80002378:	f2e080e7          	jalr	-210(ra) # 800042a2 <end_op>
  p->cwd = 0;
    8000237c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002380:	0000f497          	auipc	s1,0xf
    80002384:	f3848493          	addi	s1,s1,-200 # 800112b8 <wait_lock>
    80002388:	8526                	mv	a0,s1
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	85a080e7          	jalr	-1958(ra) # 80000be4 <acquire>
  reparent(p);
    80002392:	854e                	mv	a0,s3
    80002394:	00000097          	auipc	ra,0x0
    80002398:	f1a080e7          	jalr	-230(ra) # 800022ae <reparent>
  wakeup(p->parent);
    8000239c:	0389b503          	ld	a0,56(s3)
    800023a0:	00000097          	auipc	ra,0x0
    800023a4:	e98080e7          	jalr	-360(ra) # 80002238 <wakeup>
  acquire(&p->lock);
    800023a8:	854e                	mv	a0,s3
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023b2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023b6:	4795                	li	a5,5
    800023b8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8da080e7          	jalr	-1830(ra) # 80000c98 <release>
  sched();
    800023c6:	00000097          	auipc	ra,0x0
    800023ca:	bd4080e7          	jalr	-1068(ra) # 80001f9a <sched>
  panic("zombie exit");
    800023ce:	00006517          	auipc	a0,0x6
    800023d2:	ea250513          	addi	a0,a0,-350 # 80008270 <digits+0x230>
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	168080e7          	jalr	360(ra) # 8000053e <panic>

00000000800023de <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023de:	7179                	addi	sp,sp,-48
    800023e0:	f406                	sd	ra,40(sp)
    800023e2:	f022                	sd	s0,32(sp)
    800023e4:	ec26                	sd	s1,24(sp)
    800023e6:	e84a                	sd	s2,16(sp)
    800023e8:	e44e                	sd	s3,8(sp)
    800023ea:	1800                	addi	s0,sp,48
    800023ec:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	2e248493          	addi	s1,s1,738 # 800116d0 <proc>
    800023f6:	00015997          	auipc	s3,0x15
    800023fa:	6da98993          	addi	s3,s3,1754 # 80017ad0 <tickslock>
    acquire(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7e4080e7          	jalr	2020(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002408:	589c                	lw	a5,48(s1)
    8000240a:	01278d63          	beq	a5,s2,80002424 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	888080e7          	jalr	-1912(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002418:	19048493          	addi	s1,s1,400
    8000241c:	ff3491e3          	bne	s1,s3,800023fe <kill+0x20>
  }
  return -1;
    80002420:	557d                	li	a0,-1
    80002422:	a829                	j	8000243c <kill+0x5e>
      p->killed = 1;
    80002424:	4785                	li	a5,1
    80002426:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002428:	4c98                	lw	a4,24(s1)
    8000242a:	4789                	li	a5,2
    8000242c:	00f70f63          	beq	a4,a5,8000244a <kill+0x6c>
      release(&p->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
      return 0;
    8000243a:	4501                	li	a0,0
}
    8000243c:	70a2                	ld	ra,40(sp)
    8000243e:	7402                	ld	s0,32(sp)
    80002440:	64e2                	ld	s1,24(sp)
    80002442:	6942                	ld	s2,16(sp)
    80002444:	69a2                	ld	s3,8(sp)
    80002446:	6145                	addi	sp,sp,48
    80002448:	8082                	ret
        p->state = RUNNABLE;
    8000244a:	478d                	li	a5,3
    8000244c:	cc9c                	sw	a5,24(s1)
    8000244e:	b7cd                	j	80002430 <kill+0x52>

0000000080002450 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	e052                	sd	s4,0(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	84aa                	mv	s1,a0
    80002462:	892e                	mv	s2,a1
    80002464:	89b2                	mv	s3,a2
    80002466:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	548080e7          	jalr	1352(ra) # 800019b0 <myproc>
  if(user_dst){
    80002470:	c08d                	beqz	s1,80002492 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002472:	86d2                	mv	a3,s4
    80002474:	864e                	mv	a2,s3
    80002476:	85ca                	mv	a1,s2
    80002478:	6928                	ld	a0,80(a0)
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	1f8080e7          	jalr	504(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    memmove((char *)dst, src, len);
    80002492:	000a061b          	sext.w	a2,s4
    80002496:	85ce                	mv	a1,s3
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	8a6080e7          	jalr	-1882(ra) # 80000d40 <memmove>
    return 0;
    800024a2:	8526                	mv	a0,s1
    800024a4:	bff9                	j	80002482 <either_copyout+0x32>

00000000800024a6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	892a                	mv	s2,a0
    800024b8:	84ae                	mv	s1,a1
    800024ba:	89b2                	mv	s3,a2
    800024bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	4f2080e7          	jalr	1266(ra) # 800019b0 <myproc>
  if(user_src){
    800024c6:	c08d                	beqz	s1,800024e8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024c8:	86d2                	mv	a3,s4
    800024ca:	864e                	mv	a2,s3
    800024cc:	85ca                	mv	a1,s2
    800024ce:	6928                	ld	a0,80(a0)
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	22e080e7          	jalr	558(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024d8:	70a2                	ld	ra,40(sp)
    800024da:	7402                	ld	s0,32(sp)
    800024dc:	64e2                	ld	s1,24(sp)
    800024de:	6942                	ld	s2,16(sp)
    800024e0:	69a2                	ld	s3,8(sp)
    800024e2:	6a02                	ld	s4,0(sp)
    800024e4:	6145                	addi	sp,sp,48
    800024e6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024e8:	000a061b          	sext.w	a2,s4
    800024ec:	85ce                	mv	a1,s3
    800024ee:	854a                	mv	a0,s2
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	850080e7          	jalr	-1968(ra) # 80000d40 <memmove>
    return 0;
    800024f8:	8526                	mv	a0,s1
    800024fa:	bff9                	j	800024d8 <either_copyin+0x32>

00000000800024fc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024fc:	711d                	addi	sp,sp,-96
    800024fe:	ec86                	sd	ra,88(sp)
    80002500:	e8a2                	sd	s0,80(sp)
    80002502:	e4a6                	sd	s1,72(sp)
    80002504:	e0ca                	sd	s2,64(sp)
    80002506:	fc4e                	sd	s3,56(sp)
    80002508:	f852                	sd	s4,48(sp)
    8000250a:	f456                	sd	s5,40(sp)
    8000250c:	f05a                	sd	s6,32(sp)
    8000250e:	ec5e                	sd	s7,24(sp)
    80002510:	e862                	sd	s8,16(sp)
    80002512:	e466                	sd	s9,8(sp)
    80002514:	e06a                	sd	s10,0(sp)
    80002516:	1080                	addi	s0,sp,96
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002518:	00006517          	auipc	a0,0x6
    8000251c:	bb050513          	addi	a0,a0,-1104 # 800080c8 <digits+0x88>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	068080e7          	jalr	104(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002528:	0000f497          	auipc	s1,0xf
    8000252c:	30048493          	addi	s1,s1,768 # 80011828 <proc+0x158>
    80002530:	00015997          	auipc	s3,0x15
    80002534:	6f898993          	addi	s3,s3,1784 # 80017c28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002538:	4c15                	li	s8,5
      state = states[p->state];
    else
      state = "???";
    8000253a:	00006a17          	auipc	s4,0x6
    8000253e:	d46a0a13          	addi	s4,s4,-698 # 80008280 <digits+0x240>
    #if defined FCFS || ROUNDROBIN
    printf("PID state name\n");
    80002542:	00006b97          	auipc	s7,0x6
    80002546:	d46b8b93          	addi	s7,s7,-698 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    8000254a:	00006b17          	auipc	s6,0x6
    8000254e:	d4eb0b13          	addi	s6,s6,-690 # 80008298 <digits+0x258>
    printf("\n");
    80002552:	00006a97          	auipc	s5,0x6
    80002556:	b76a8a93          	addi	s5,s5,-1162 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255a:	00006c97          	auipc	s9,0x6
    8000255e:	dd6c8c93          	addi	s9,s9,-554 # 80008330 <states.1723>
    80002562:	a805                	j	80002592 <procdump+0x96>
    printf("PID state name\n");
    80002564:	855e                	mv	a0,s7
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	022080e7          	jalr	34(ra) # 80000588 <printf>
    printf("%d %s %s", p->pid, state, p->name);
    8000256e:	86ca                	mv	a3,s2
    80002570:	866a                	mv	a2,s10
    80002572:	ed892583          	lw	a1,-296(s2)
    80002576:	855a                	mv	a0,s6
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	010080e7          	jalr	16(ra) # 80000588 <printf>
    printf("\n");
    80002580:	8556                	mv	a0,s5
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	006080e7          	jalr	6(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258a:	19048493          	addi	s1,s1,400
    8000258e:	03348363          	beq	s1,s3,800025b4 <procdump+0xb8>
    if(p->state == UNUSED)
    80002592:	8926                	mv	s2,s1
    80002594:	ec04a783          	lw	a5,-320(s1)
    80002598:	dbed                	beqz	a5,8000258a <procdump+0x8e>
      state = "???";
    8000259a:	8d52                	mv	s10,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259c:	fcfc64e3          	bltu	s8,a5,80002564 <procdump+0x68>
    800025a0:	1782                	slli	a5,a5,0x20
    800025a2:	9381                	srli	a5,a5,0x20
    800025a4:	078e                	slli	a5,a5,0x3
    800025a6:	97e6                	add	a5,a5,s9
    800025a8:	0007bd03          	ld	s10,0(a5)
    800025ac:	fa0d1ce3          	bnez	s10,80002564 <procdump+0x68>
      state = "???";
    800025b0:	8d52                	mv	s10,s4
    800025b2:	bf4d                	j	80002564 <procdump+0x68>
    #if defined PBS
    printf("PID    Priority    State    rtime    wtime   nrun");
    printf("%d    %d    %s    %d    %d    %d", p->pid, p->static_priority, state, p->rtime, p->etime - p->ctime - p->rtime, p->no_of_proc);
    #endif
  }
}
    800025b4:	60e6                	ld	ra,88(sp)
    800025b6:	6446                	ld	s0,80(sp)
    800025b8:	64a6                	ld	s1,72(sp)
    800025ba:	6906                	ld	s2,64(sp)
    800025bc:	79e2                	ld	s3,56(sp)
    800025be:	7a42                	ld	s4,48(sp)
    800025c0:	7aa2                	ld	s5,40(sp)
    800025c2:	7b02                	ld	s6,32(sp)
    800025c4:	6be2                	ld	s7,24(sp)
    800025c6:	6c42                	ld	s8,16(sp)
    800025c8:	6ca2                	ld	s9,8(sp)
    800025ca:	6d02                	ld	s10,0(sp)
    800025cc:	6125                	addi	sp,sp,96
    800025ce:	8082                	ret

00000000800025d0 <trace>:
int trace(int mask)
{
    800025d0:	1101                	addi	sp,sp,-32
    800025d2:	ec06                	sd	ra,24(sp)
    800025d4:	e822                	sd	s0,16(sp)
    800025d6:	e426                	sd	s1,8(sp)
    800025d8:	1000                	addi	s0,sp,32
    800025da:	84aa                	mv	s1,a0
  myproc()->mask=mask;
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	3d4080e7          	jalr	980(ra) # 800019b0 <myproc>
    800025e4:	16952423          	sw	s1,360(a0)
  return 0;
}
    800025e8:	4501                	li	a0,0
    800025ea:	60e2                	ld	ra,24(sp)
    800025ec:	6442                	ld	s0,16(sp)
    800025ee:	64a2                	ld	s1,8(sp)
    800025f0:	6105                	addi	sp,sp,32
    800025f2:	8082                	ret

00000000800025f4 <set_priority>:
int 
set_priority(int priority, int pid)
{
    800025f4:	7179                	addi	sp,sp,-48
    800025f6:	f406                	sd	ra,40(sp)
    800025f8:	f022                	sd	s0,32(sp)
    800025fa:	ec26                	sd	s1,24(sp)
    800025fc:	e84a                	sd	s2,16(sp)
    800025fe:	e44e                	sd	s3,8(sp)
    80002600:	1800                	addi	s0,sp,48
  struct proc *p;
  int old_sp = 0;

  if (priority < 0 || priority > 100) {
    80002602:	89aa                	mv	s3,a0
    80002604:	06400713          	li	a4,100
    printf("set_priority: Invalid priority. 0 <= priority <= 100\n");
    return -1;
  }

  int i = 0;
    80002608:	4781                	li	a5,0
  for (p = proc; p < &proc[NPROC]; p++){
    8000260a:	0000f497          	auipc	s1,0xf
    8000260e:	0c648493          	addi	s1,s1,198 # 800116d0 <proc>
    80002612:	00015697          	auipc	a3,0x15
    80002616:	4be68693          	addi	a3,a3,1214 # 80017ad0 <tickslock>
  if (priority < 0 || priority > 100) {
    8000261a:	04a76763          	bltu	a4,a0,80002668 <set_priority+0x74>
    if (p->pid == pid){
    8000261e:	5898                	lw	a4,48(s1)
    80002620:	00b70763          	beq	a4,a1,8000262e <set_priority+0x3a>
      break;
    }
    i++;
    80002624:	2785                	addiw	a5,a5,1
  for (p = proc; p < &proc[NPROC]; p++){
    80002626:	19048493          	addi	s1,s1,400
    8000262a:	fed49ae3          	bne	s1,a3,8000261e <set_priority+0x2a>
  }
  if (i >= NPROC) {
    8000262e:	03f00713          	li	a4,63
    80002632:	04f74563          	blt	a4,a5,8000267c <set_priority+0x88>
    printf("set_priority: No such process exists\n");
    return -1;
  }
  acquire(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	5ac080e7          	jalr	1452(ra) # 80000be4 <acquire>
  old_sp = p->static_priority;
    80002640:	17c4a903          	lw	s2,380(s1)
  p->static_priority = priority;
    80002644:	1734ae23          	sw	s3,380(s1)
  p->niceness = 5;
    80002648:	4795                	li	a5,5
    8000264a:	18f4a223          	sw	a5,388(s1)
  release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	648080e7          	jalr	1608(ra) # 80000c98 <release>
  return old_sp;
    80002658:	854a                	mv	a0,s2
    8000265a:	70a2                	ld	ra,40(sp)
    8000265c:	7402                	ld	s0,32(sp)
    8000265e:	64e2                	ld	s1,24(sp)
    80002660:	6942                	ld	s2,16(sp)
    80002662:	69a2                	ld	s3,8(sp)
    80002664:	6145                	addi	sp,sp,48
    80002666:	8082                	ret
    printf("set_priority: Invalid priority. 0 <= priority <= 100\n");
    80002668:	00006517          	auipc	a0,0x6
    8000266c:	c4050513          	addi	a0,a0,-960 # 800082a8 <digits+0x268>
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	f18080e7          	jalr	-232(ra) # 80000588 <printf>
    return -1;
    80002678:	597d                	li	s2,-1
    8000267a:	bff9                	j	80002658 <set_priority+0x64>
    printf("set_priority: No such process exists\n");
    8000267c:	00006517          	auipc	a0,0x6
    80002680:	c6450513          	addi	a0,a0,-924 # 800082e0 <digits+0x2a0>
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	f04080e7          	jalr	-252(ra) # 80000588 <printf>
    return -1;
    8000268c:	597d                	li	s2,-1
    8000268e:	b7e9                	j	80002658 <set_priority+0x64>

0000000080002690 <swtch>:
    80002690:	00153023          	sd	ra,0(a0)
    80002694:	00253423          	sd	sp,8(a0)
    80002698:	e900                	sd	s0,16(a0)
    8000269a:	ed04                	sd	s1,24(a0)
    8000269c:	03253023          	sd	s2,32(a0)
    800026a0:	03353423          	sd	s3,40(a0)
    800026a4:	03453823          	sd	s4,48(a0)
    800026a8:	03553c23          	sd	s5,56(a0)
    800026ac:	05653023          	sd	s6,64(a0)
    800026b0:	05753423          	sd	s7,72(a0)
    800026b4:	05853823          	sd	s8,80(a0)
    800026b8:	05953c23          	sd	s9,88(a0)
    800026bc:	07a53023          	sd	s10,96(a0)
    800026c0:	07b53423          	sd	s11,104(a0)
    800026c4:	0005b083          	ld	ra,0(a1)
    800026c8:	0085b103          	ld	sp,8(a1)
    800026cc:	6980                	ld	s0,16(a1)
    800026ce:	6d84                	ld	s1,24(a1)
    800026d0:	0205b903          	ld	s2,32(a1)
    800026d4:	0285b983          	ld	s3,40(a1)
    800026d8:	0305ba03          	ld	s4,48(a1)
    800026dc:	0385ba83          	ld	s5,56(a1)
    800026e0:	0405bb03          	ld	s6,64(a1)
    800026e4:	0485bb83          	ld	s7,72(a1)
    800026e8:	0505bc03          	ld	s8,80(a1)
    800026ec:	0585bc83          	ld	s9,88(a1)
    800026f0:	0605bd03          	ld	s10,96(a1)
    800026f4:	0685bd83          	ld	s11,104(a1)
    800026f8:	8082                	ret

00000000800026fa <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026fa:	1141                	addi	sp,sp,-16
    800026fc:	e406                	sd	ra,8(sp)
    800026fe:	e022                	sd	s0,0(sp)
    80002700:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002702:	00006597          	auipc	a1,0x6
    80002706:	c5e58593          	addi	a1,a1,-930 # 80008360 <states.1723+0x30>
    8000270a:	00015517          	auipc	a0,0x15
    8000270e:	3c650513          	addi	a0,a0,966 # 80017ad0 <tickslock>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	442080e7          	jalr	1090(ra) # 80000b54 <initlock>
}
    8000271a:	60a2                	ld	ra,8(sp)
    8000271c:	6402                	ld	s0,0(sp)
    8000271e:	0141                	addi	sp,sp,16
    80002720:	8082                	ret

0000000080002722 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002722:	1141                	addi	sp,sp,-16
    80002724:	e422                	sd	s0,8(sp)
    80002726:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002728:	00003797          	auipc	a5,0x3
    8000272c:	5e878793          	addi	a5,a5,1512 # 80005d10 <kernelvec>
    80002730:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002734:	6422                	ld	s0,8(sp)
    80002736:	0141                	addi	sp,sp,16
    80002738:	8082                	ret

000000008000273a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000273a:	1141                	addi	sp,sp,-16
    8000273c:	e406                	sd	ra,8(sp)
    8000273e:	e022                	sd	s0,0(sp)
    80002740:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002742:	fffff097          	auipc	ra,0xfffff
    80002746:	26e080e7          	jalr	622(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000274a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000274e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002750:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002754:	00005617          	auipc	a2,0x5
    80002758:	8ac60613          	addi	a2,a2,-1876 # 80007000 <_trampoline>
    8000275c:	00005697          	auipc	a3,0x5
    80002760:	8a468693          	addi	a3,a3,-1884 # 80007000 <_trampoline>
    80002764:	8e91                	sub	a3,a3,a2
    80002766:	040007b7          	lui	a5,0x4000
    8000276a:	17fd                	addi	a5,a5,-1
    8000276c:	07b2                	slli	a5,a5,0xc
    8000276e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002770:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002774:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002776:	180026f3          	csrr	a3,satp
    8000277a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000277c:	6d38                	ld	a4,88(a0)
    8000277e:	6134                	ld	a3,64(a0)
    80002780:	6585                	lui	a1,0x1
    80002782:	96ae                	add	a3,a3,a1
    80002784:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002786:	6d38                	ld	a4,88(a0)
    80002788:	00000697          	auipc	a3,0x0
    8000278c:	13868693          	addi	a3,a3,312 # 800028c0 <usertrap>
    80002790:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002792:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002794:	8692                	mv	a3,tp
    80002796:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002798:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000279c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027a0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027aa:	6f18                	ld	a4,24(a4)
    800027ac:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027b0:	692c                	ld	a1,80(a0)
    800027b2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027b4:	00005717          	auipc	a4,0x5
    800027b8:	8dc70713          	addi	a4,a4,-1828 # 80007090 <userret>
    800027bc:	8f11                	sub	a4,a4,a2
    800027be:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027c0:	577d                	li	a4,-1
    800027c2:	177e                	slli	a4,a4,0x3f
    800027c4:	8dd9                	or	a1,a1,a4
    800027c6:	02000537          	lui	a0,0x2000
    800027ca:	157d                	addi	a0,a0,-1
    800027cc:	0536                	slli	a0,a0,0xd
    800027ce:	9782                	jalr	a5
}
    800027d0:	60a2                	ld	ra,8(sp)
    800027d2:	6402                	ld	s0,0(sp)
    800027d4:	0141                	addi	sp,sp,16
    800027d6:	8082                	ret

00000000800027d8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d8:	1101                	addi	sp,sp,-32
    800027da:	ec06                	sd	ra,24(sp)
    800027dc:	e822                	sd	s0,16(sp)
    800027de:	e426                	sd	s1,8(sp)
    800027e0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027e2:	00015497          	auipc	s1,0x15
    800027e6:	2ee48493          	addi	s1,s1,750 # 80017ad0 <tickslock>
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	3f8080e7          	jalr	1016(ra) # 80000be4 <acquire>
  ticks++;
    800027f4:	00007517          	auipc	a0,0x7
    800027f8:	83c50513          	addi	a0,a0,-1988 # 80009030 <ticks>
    800027fc:	411c                	lw	a5,0(a0)
    800027fe:	2785                	addiw	a5,a5,1
    80002800:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002802:	00000097          	auipc	ra,0x0
    80002806:	a36080e7          	jalr	-1482(ra) # 80002238 <wakeup>
  release(&tickslock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	48c080e7          	jalr	1164(ra) # 80000c98 <release>
}
    80002814:	60e2                	ld	ra,24(sp)
    80002816:	6442                	ld	s0,16(sp)
    80002818:	64a2                	ld	s1,8(sp)
    8000281a:	6105                	addi	sp,sp,32
    8000281c:	8082                	ret

000000008000281e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000281e:	1101                	addi	sp,sp,-32
    80002820:	ec06                	sd	ra,24(sp)
    80002822:	e822                	sd	s0,16(sp)
    80002824:	e426                	sd	s1,8(sp)
    80002826:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002828:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000282c:	00074d63          	bltz	a4,80002846 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002830:	57fd                	li	a5,-1
    80002832:	17fe                	slli	a5,a5,0x3f
    80002834:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002836:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002838:	06f70363          	beq	a4,a5,8000289e <devintr+0x80>
  }
}
    8000283c:	60e2                	ld	ra,24(sp)
    8000283e:	6442                	ld	s0,16(sp)
    80002840:	64a2                	ld	s1,8(sp)
    80002842:	6105                	addi	sp,sp,32
    80002844:	8082                	ret
     (scause & 0xff) == 9){
    80002846:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000284a:	46a5                	li	a3,9
    8000284c:	fed792e3          	bne	a5,a3,80002830 <devintr+0x12>
    int irq = plic_claim();
    80002850:	00003097          	auipc	ra,0x3
    80002854:	5c8080e7          	jalr	1480(ra) # 80005e18 <plic_claim>
    80002858:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000285a:	47a9                	li	a5,10
    8000285c:	02f50763          	beq	a0,a5,8000288a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002860:	4785                	li	a5,1
    80002862:	02f50963          	beq	a0,a5,80002894 <devintr+0x76>
    return 1;
    80002866:	4505                	li	a0,1
    } else if(irq){
    80002868:	d8f1                	beqz	s1,8000283c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000286a:	85a6                	mv	a1,s1
    8000286c:	00006517          	auipc	a0,0x6
    80002870:	afc50513          	addi	a0,a0,-1284 # 80008368 <states.1723+0x38>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	d14080e7          	jalr	-748(ra) # 80000588 <printf>
      plic_complete(irq);
    8000287c:	8526                	mv	a0,s1
    8000287e:	00003097          	auipc	ra,0x3
    80002882:	5be080e7          	jalr	1470(ra) # 80005e3c <plic_complete>
    return 1;
    80002886:	4505                	li	a0,1
    80002888:	bf55                	j	8000283c <devintr+0x1e>
      uartintr();
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	11e080e7          	jalr	286(ra) # 800009a8 <uartintr>
    80002892:	b7ed                	j	8000287c <devintr+0x5e>
      virtio_disk_intr();
    80002894:	00004097          	auipc	ra,0x4
    80002898:	a88080e7          	jalr	-1400(ra) # 8000631c <virtio_disk_intr>
    8000289c:	b7c5                	j	8000287c <devintr+0x5e>
    if(cpuid() == 0){
    8000289e:	fffff097          	auipc	ra,0xfffff
    800028a2:	0e6080e7          	jalr	230(ra) # 80001984 <cpuid>
    800028a6:	c901                	beqz	a0,800028b6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028ac:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ae:	14479073          	csrw	sip,a5
    return 2;
    800028b2:	4509                	li	a0,2
    800028b4:	b761                	j	8000283c <devintr+0x1e>
      clockintr();
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	f22080e7          	jalr	-222(ra) # 800027d8 <clockintr>
    800028be:	b7ed                	j	800028a8 <devintr+0x8a>

00000000800028c0 <usertrap>:
{
    800028c0:	1101                	addi	sp,sp,-32
    800028c2:	ec06                	sd	ra,24(sp)
    800028c4:	e822                	sd	s0,16(sp)
    800028c6:	e426                	sd	s1,8(sp)
    800028c8:	e04a                	sd	s2,0(sp)
    800028ca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028cc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028d0:	1007f793          	andi	a5,a5,256
    800028d4:	e3ad                	bnez	a5,80002936 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d6:	00003797          	auipc	a5,0x3
    800028da:	43a78793          	addi	a5,a5,1082 # 80005d10 <kernelvec>
    800028de:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	0ce080e7          	jalr	206(ra) # 800019b0 <myproc>
    800028ea:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ec:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ee:	14102773          	csrr	a4,sepc
    800028f2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f8:	47a1                	li	a5,8
    800028fa:	04f71c63          	bne	a4,a5,80002952 <usertrap+0x92>
    if(p->killed)
    800028fe:	551c                	lw	a5,40(a0)
    80002900:	e3b9                	bnez	a5,80002946 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002902:	6cb8                	ld	a4,88(s1)
    80002904:	6f1c                	ld	a5,24(a4)
    80002906:	0791                	addi	a5,a5,4
    80002908:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002912:	10079073          	csrw	sstatus,a5
    syscall();
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	2e0080e7          	jalr	736(ra) # 80002bf6 <syscall>
  if(p->killed)
    8000291e:	549c                	lw	a5,40(s1)
    80002920:	ebc1                	bnez	a5,800029b0 <usertrap+0xf0>
  usertrapret();
    80002922:	00000097          	auipc	ra,0x0
    80002926:	e18080e7          	jalr	-488(ra) # 8000273a <usertrapret>
}
    8000292a:	60e2                	ld	ra,24(sp)
    8000292c:	6442                	ld	s0,16(sp)
    8000292e:	64a2                	ld	s1,8(sp)
    80002930:	6902                	ld	s2,0(sp)
    80002932:	6105                	addi	sp,sp,32
    80002934:	8082                	ret
    panic("usertrap: not from user mode");
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a5250513          	addi	a0,a0,-1454 # 80008388 <states.1723+0x58>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>
      exit(-1);
    80002946:	557d                	li	a0,-1
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	9c0080e7          	jalr	-1600(ra) # 80002308 <exit>
    80002950:	bf4d                	j	80002902 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002952:	00000097          	auipc	ra,0x0
    80002956:	ecc080e7          	jalr	-308(ra) # 8000281e <devintr>
    8000295a:	892a                	mv	s2,a0
    8000295c:	c501                	beqz	a0,80002964 <usertrap+0xa4>
  if(p->killed)
    8000295e:	549c                	lw	a5,40(s1)
    80002960:	c3a1                	beqz	a5,800029a0 <usertrap+0xe0>
    80002962:	a815                	j	80002996 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002964:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002968:	5890                	lw	a2,48(s1)
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	a3e50513          	addi	a0,a0,-1474 # 800083a8 <states.1723+0x78>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	c16080e7          	jalr	-1002(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002982:	00006517          	auipc	a0,0x6
    80002986:	a5650513          	addi	a0,a0,-1450 # 800083d8 <states.1723+0xa8>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bfe080e7          	jalr	-1026(ra) # 80000588 <printf>
    p->killed = 1;
    80002992:	4785                	li	a5,1
    80002994:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002996:	557d                	li	a0,-1
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	970080e7          	jalr	-1680(ra) # 80002308 <exit>
  if(which_dev == 2)
    800029a0:	4789                	li	a5,2
    800029a2:	f8f910e3          	bne	s2,a5,80002922 <usertrap+0x62>
    yield();
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	6ca080e7          	jalr	1738(ra) # 80002070 <yield>
    800029ae:	bf95                	j	80002922 <usertrap+0x62>
  int which_dev = 0;
    800029b0:	4901                	li	s2,0
    800029b2:	b7d5                	j	80002996 <usertrap+0xd6>

00000000800029b4 <kerneltrap>:
{
    800029b4:	7179                	addi	sp,sp,-48
    800029b6:	f406                	sd	ra,40(sp)
    800029b8:	f022                	sd	s0,32(sp)
    800029ba:	ec26                	sd	s1,24(sp)
    800029bc:	e84a                	sd	s2,16(sp)
    800029be:	e44e                	sd	s3,8(sp)
    800029c0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ca:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ce:	1004f793          	andi	a5,s1,256
    800029d2:	cb85                	beqz	a5,80002a02 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029da:	ef85                	bnez	a5,80002a12 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	e42080e7          	jalr	-446(ra) # 8000281e <devintr>
    800029e4:	cd1d                	beqz	a0,80002a22 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e6:	4789                	li	a5,2
    800029e8:	06f50a63          	beq	a0,a5,80002a5c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ec:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f0:	10049073          	csrw	sstatus,s1
}
    800029f4:	70a2                	ld	ra,40(sp)
    800029f6:	7402                	ld	s0,32(sp)
    800029f8:	64e2                	ld	s1,24(sp)
    800029fa:	6942                	ld	s2,16(sp)
    800029fc:	69a2                	ld	s3,8(sp)
    800029fe:	6145                	addi	sp,sp,48
    80002a00:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	9f650513          	addi	a0,a0,-1546 # 800083f8 <states.1723+0xc8>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	a0e50513          	addi	a0,a0,-1522 # 80008420 <states.1723+0xf0>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b24080e7          	jalr	-1244(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a22:	85ce                	mv	a1,s3
    80002a24:	00006517          	auipc	a0,0x6
    80002a28:	a1c50513          	addi	a0,a0,-1508 # 80008440 <states.1723+0x110>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	b5c080e7          	jalr	-1188(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a38:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	a1450513          	addi	a0,a0,-1516 # 80008450 <states.1723+0x120>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	b44080e7          	jalr	-1212(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	a1c50513          	addi	a0,a0,-1508 # 80008468 <states.1723+0x138>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	f54080e7          	jalr	-172(ra) # 800019b0 <myproc>
    80002a64:	d541                	beqz	a0,800029ec <kerneltrap+0x38>
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	f4a080e7          	jalr	-182(ra) # 800019b0 <myproc>
    80002a6e:	4d18                	lw	a4,24(a0)
    80002a70:	4791                	li	a5,4
    80002a72:	f6f71de3          	bne	a4,a5,800029ec <kerneltrap+0x38>
    yield();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	5fa080e7          	jalr	1530(ra) # 80002070 <yield>
    80002a7e:	b7bd                	j	800029ec <kerneltrap+0x38>

0000000080002a80 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a80:	1101                	addi	sp,sp,-32
    80002a82:	ec06                	sd	ra,24(sp)
    80002a84:	e822                	sd	s0,16(sp)
    80002a86:	e426                	sd	s1,8(sp)
    80002a88:	1000                	addi	s0,sp,32
    80002a8a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	f24080e7          	jalr	-220(ra) # 800019b0 <myproc>
  switch (n) {
    80002a94:	4795                	li	a5,5
    80002a96:	0497e163          	bltu	a5,s1,80002ad8 <argraw+0x58>
    80002a9a:	048a                	slli	s1,s1,0x2
    80002a9c:	00006717          	auipc	a4,0x6
    80002aa0:	aec70713          	addi	a4,a4,-1300 # 80008588 <states.1723+0x258>
    80002aa4:	94ba                	add	s1,s1,a4
    80002aa6:	409c                	lw	a5,0(s1)
    80002aa8:	97ba                	add	a5,a5,a4
    80002aaa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
    return p->trapframe->a1;
    80002aba:	6d3c                	ld	a5,88(a0)
    80002abc:	7fa8                	ld	a0,120(a5)
    80002abe:	bfcd                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a2;
    80002ac0:	6d3c                	ld	a5,88(a0)
    80002ac2:	63c8                	ld	a0,128(a5)
    80002ac4:	b7f5                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a3;
    80002ac6:	6d3c                	ld	a5,88(a0)
    80002ac8:	67c8                	ld	a0,136(a5)
    80002aca:	b7dd                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a4;
    80002acc:	6d3c                	ld	a5,88(a0)
    80002ace:	6bc8                	ld	a0,144(a5)
    80002ad0:	b7c5                	j	80002ab0 <argraw+0x30>
    return p->trapframe->a5;
    80002ad2:	6d3c                	ld	a5,88(a0)
    80002ad4:	6fc8                	ld	a0,152(a5)
    80002ad6:	bfe9                	j	80002ab0 <argraw+0x30>
  panic("argraw");
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	9a050513          	addi	a0,a0,-1632 # 80008478 <states.1723+0x148>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	a5e080e7          	jalr	-1442(ra) # 8000053e <panic>

0000000080002ae8 <fetchaddr>:
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	e04a                	sd	s2,0(sp)
    80002af2:	1000                	addi	s0,sp,32
    80002af4:	84aa                	mv	s1,a0
    80002af6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	eb8080e7          	jalr	-328(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b00:	653c                	ld	a5,72(a0)
    80002b02:	02f4f863          	bgeu	s1,a5,80002b32 <fetchaddr+0x4a>
    80002b06:	00848713          	addi	a4,s1,8
    80002b0a:	02e7e663          	bltu	a5,a4,80002b36 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0e:	46a1                	li	a3,8
    80002b10:	8626                	mv	a2,s1
    80002b12:	85ca                	mv	a1,s2
    80002b14:	6928                	ld	a0,80(a0)
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	be8080e7          	jalr	-1048(ra) # 800016fe <copyin>
    80002b1e:	00a03533          	snez	a0,a0
    80002b22:	40a00533          	neg	a0,a0
}
    80002b26:	60e2                	ld	ra,24(sp)
    80002b28:	6442                	ld	s0,16(sp)
    80002b2a:	64a2                	ld	s1,8(sp)
    80002b2c:	6902                	ld	s2,0(sp)
    80002b2e:	6105                	addi	sp,sp,32
    80002b30:	8082                	ret
    return -1;
    80002b32:	557d                	li	a0,-1
    80002b34:	bfcd                	j	80002b26 <fetchaddr+0x3e>
    80002b36:	557d                	li	a0,-1
    80002b38:	b7fd                	j	80002b26 <fetchaddr+0x3e>

0000000080002b3a <fetchstr>:
{
    80002b3a:	7179                	addi	sp,sp,-48
    80002b3c:	f406                	sd	ra,40(sp)
    80002b3e:	f022                	sd	s0,32(sp)
    80002b40:	ec26                	sd	s1,24(sp)
    80002b42:	e84a                	sd	s2,16(sp)
    80002b44:	e44e                	sd	s3,8(sp)
    80002b46:	1800                	addi	s0,sp,48
    80002b48:	892a                	mv	s2,a0
    80002b4a:	84ae                	mv	s1,a1
    80002b4c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	e62080e7          	jalr	-414(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b56:	86ce                	mv	a3,s3
    80002b58:	864a                	mv	a2,s2
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	6928                	ld	a0,80(a0)
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	c2c080e7          	jalr	-980(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b66:	00054763          	bltz	a0,80002b74 <fetchstr+0x3a>
  return strlen(buf);
    80002b6a:	8526                	mv	a0,s1
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	2f8080e7          	jalr	760(ra) # 80000e64 <strlen>
}
    80002b74:	70a2                	ld	ra,40(sp)
    80002b76:	7402                	ld	s0,32(sp)
    80002b78:	64e2                	ld	s1,24(sp)
    80002b7a:	6942                	ld	s2,16(sp)
    80002b7c:	69a2                	ld	s3,8(sp)
    80002b7e:	6145                	addi	sp,sp,48
    80002b80:	8082                	ret

0000000080002b82 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
    80002b8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	ef2080e7          	jalr	-270(ra) # 80002a80 <argraw>
    80002b96:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b98:	4501                	li	a0,0
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	1000                	addi	s0,sp,32
    80002bae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	ed0080e7          	jalr	-304(ra) # 80002a80 <argraw>
    80002bb8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bba:	4501                	li	a0,0
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret

0000000080002bc6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	e04a                	sd	s2,0(sp)
    80002bd0:	1000                	addi	s0,sp,32
    80002bd2:	84ae                	mv	s1,a1
    80002bd4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	eaa080e7          	jalr	-342(ra) # 80002a80 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bde:	864a                	mv	a2,s2
    80002be0:	85a6                	mv	a1,s1
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	f58080e7          	jalr	-168(ra) # 80002b3a <fetchstr>
}
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6902                	ld	s2,0(sp)
    80002bf2:	6105                	addi	sp,sp,32
    80002bf4:	8082                	ret

0000000080002bf6 <syscall>:

int system_argc[] = {-1, 0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1, 2};

void
syscall(void)
{
    80002bf6:	715d                	addi	sp,sp,-80
    80002bf8:	e486                	sd	ra,72(sp)
    80002bfa:	e0a2                	sd	s0,64(sp)
    80002bfc:	fc26                	sd	s1,56(sp)
    80002bfe:	f84a                	sd	s2,48(sp)
    80002c00:	f44e                	sd	s3,40(sp)
    80002c02:	f052                	sd	s4,32(sp)
    80002c04:	ec56                	sd	s5,24(sp)
    80002c06:	0880                	addi	s0,sp,80
  int num, fstarg = 0, mask = 0;
  struct proc *p = myproc();
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	da8080e7          	jalr	-600(ra) # 800019b0 <myproc>
    80002c10:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c12:	05853903          	ld	s2,88(a0)
    80002c16:	0a893783          	ld	a5,168(s2)
    80002c1a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c1e:	37fd                	addiw	a5,a5,-1
    80002c20:	4759                	li	a4,22
    80002c22:	0ef76a63          	bltu	a4,a5,80002d16 <syscall+0x120>
    80002c26:	00399713          	slli	a4,s3,0x3
    80002c2a:	00006797          	auipc	a5,0x6
    80002c2e:	97678793          	addi	a5,a5,-1674 # 800085a0 <syscalls>
    80002c32:	97ba                	add	a5,a5,a4
    80002c34:	639c                	ld	a5,0(a5)
    80002c36:	c3e5                	beqz	a5,80002d16 <syscall+0x120>
    // numargs = system_call_argc[num];
    fstarg = p->trapframe->a0;
    80002c38:	07093a83          	ld	s5,112(s2)

    p->trapframe->a0 = syscalls[num]();
    80002c3c:	9782                	jalr	a5
    80002c3e:	06a93823          	sd	a0,112(s2)
    mask = p->mask;
    if ((mask >> num) & 0x1) {
    80002c42:	1684a903          	lw	s2,360(s1)
    80002c46:	4139593b          	sraw	s2,s2,s3
    80002c4a:	00197913          	andi	s2,s2,1
    80002c4e:	0e090363          	beqz	s2,80002d34 <syscall+0x13e>
      printf("%d: syscall %s ", p->pid, system_call_name[num]);
    80002c52:	00006a17          	auipc	s4,0x6
    80002c56:	d66a0a13          	addi	s4,s4,-666 # 800089b8 <system_call_name>
    80002c5a:	00399793          	slli	a5,s3,0x3
    80002c5e:	97d2                	add	a5,a5,s4
    80002c60:	6390                	ld	a2,0(a5)
    80002c62:	588c                	lw	a1,48(s1)
    80002c64:	00006517          	auipc	a0,0x6
    80002c68:	81c50513          	addi	a0,a0,-2020 # 80008480 <states.1723+0x150>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	91c080e7          	jalr	-1764(ra) # 80000588 <printf>
      if (system_argc[num] > 0) {
    80002c74:	00299793          	slli	a5,s3,0x2
    80002c78:	9a3e                	add	s4,s4,a5
    80002c7a:	0c0a2783          	lw	a5,192(s4)
    80002c7e:	00f04d63          	bgtz	a5,80002c98 <syscall+0xa2>
          printf("%d ", x);
        }
        argint(i, &x);
        printf("%d) ", x);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002c82:	6cbc                	ld	a5,88(s1)
    80002c84:	7bac                	ld	a1,112(a5)
    80002c86:	00006517          	auipc	a0,0x6
    80002c8a:	82250513          	addi	a0,a0,-2014 # 800084a8 <states.1723+0x178>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	8fa080e7          	jalr	-1798(ra) # 80000588 <printf>
    80002c96:	a879                	j	80002d34 <syscall+0x13e>
        printf("(%d ", fstarg);
    80002c98:	000a859b          	sext.w	a1,s5
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	7f450513          	addi	a0,a0,2036 # 80008490 <states.1723+0x160>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	8e4080e7          	jalr	-1820(ra) # 80000588 <printf>
        for (i = 1; i < system_argc[num] - 1; i++) {
    80002cac:	0c0a2703          	lw	a4,192(s4)
    80002cb0:	4789                	li	a5,2
    80002cb2:	04e7d063          	bge	a5,a4,80002cf2 <syscall+0xfc>
          printf("%d ", x);
    80002cb6:	00005a17          	auipc	s4,0x5
    80002cba:	7e2a0a13          	addi	s4,s4,2018 # 80008498 <states.1723+0x168>
        for (i = 1; i < system_argc[num] - 1; i++) {
    80002cbe:	098a                	slli	s3,s3,0x2
    80002cc0:	00006797          	auipc	a5,0x6
    80002cc4:	cf878793          	addi	a5,a5,-776 # 800089b8 <system_call_name>
    80002cc8:	99be                	add	s3,s3,a5
          argint(i, &x);
    80002cca:	fbc40593          	addi	a1,s0,-68
    80002cce:	854a                	mv	a0,s2
    80002cd0:	00000097          	auipc	ra,0x0
    80002cd4:	eb2080e7          	jalr	-334(ra) # 80002b82 <argint>
          printf("%d ", x);
    80002cd8:	fbc42583          	lw	a1,-68(s0)
    80002cdc:	8552                	mv	a0,s4
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8aa080e7          	jalr	-1878(ra) # 80000588 <printf>
        for (i = 1; i < system_argc[num] - 1; i++) {
    80002ce6:	2905                	addiw	s2,s2,1
    80002ce8:	0c09a783          	lw	a5,192(s3)
    80002cec:	37fd                	addiw	a5,a5,-1
    80002cee:	fcf94ee3          	blt	s2,a5,80002cca <syscall+0xd4>
        argint(i, &x);
    80002cf2:	fbc40593          	addi	a1,s0,-68
    80002cf6:	854a                	mv	a0,s2
    80002cf8:	00000097          	auipc	ra,0x0
    80002cfc:	e8a080e7          	jalr	-374(ra) # 80002b82 <argint>
        printf("%d) ", x);
    80002d00:	fbc42583          	lw	a1,-68(s0)
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	79c50513          	addi	a0,a0,1948 # 800084a0 <states.1723+0x170>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	87c080e7          	jalr	-1924(ra) # 80000588 <printf>
    80002d14:	b7bd                	j	80002c82 <syscall+0x8c>
    } 
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d16:	86ce                	mv	a3,s3
    80002d18:	15848613          	addi	a2,s1,344
    80002d1c:	588c                	lw	a1,48(s1)
    80002d1e:	00005517          	auipc	a0,0x5
    80002d22:	79250513          	addi	a0,a0,1938 # 800084b0 <states.1723+0x180>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	862080e7          	jalr	-1950(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d2e:	6cbc                	ld	a5,88(s1)
    80002d30:	577d                	li	a4,-1
    80002d32:	fbb8                	sd	a4,112(a5)
  }
}
    80002d34:	60a6                	ld	ra,72(sp)
    80002d36:	6406                	ld	s0,64(sp)
    80002d38:	74e2                	ld	s1,56(sp)
    80002d3a:	7942                	ld	s2,48(sp)
    80002d3c:	79a2                	ld	s3,40(sp)
    80002d3e:	7a02                	ld	s4,32(sp)
    80002d40:	6ae2                	ld	s5,24(sp)
    80002d42:	6161                	addi	sp,sp,80
    80002d44:	8082                	ret

0000000080002d46 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d4e:	fec40593          	addi	a1,s0,-20
    80002d52:	4501                	li	a0,0
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	e2e080e7          	jalr	-466(ra) # 80002b82 <argint>
    return -1;
    80002d5c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d5e:	00054963          	bltz	a0,80002d70 <sys_exit+0x2a>
  exit(n);
    80002d62:	fec42503          	lw	a0,-20(s0)
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	5a2080e7          	jalr	1442(ra) # 80002308 <exit>
  return 0;  // not reached
    80002d6e:	4781                	li	a5,0
}
    80002d70:	853e                	mv	a0,a5
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret

0000000080002d7a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d7a:	1141                	addi	sp,sp,-16
    80002d7c:	e406                	sd	ra,8(sp)
    80002d7e:	e022                	sd	s0,0(sp)
    80002d80:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	c2e080e7          	jalr	-978(ra) # 800019b0 <myproc>
}
    80002d8a:	5908                	lw	a0,48(a0)
    80002d8c:	60a2                	ld	ra,8(sp)
    80002d8e:	6402                	ld	s0,0(sp)
    80002d90:	0141                	addi	sp,sp,16
    80002d92:	8082                	ret

0000000080002d94 <sys_fork>:

uint64
sys_fork(void)
{
    80002d94:	1141                	addi	sp,sp,-16
    80002d96:	e406                	sd	ra,8(sp)
    80002d98:	e022                	sd	s0,0(sp)
    80002d9a:	0800                	addi	s0,sp,16
  return fork();
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	028080e7          	jalr	40(ra) # 80001dc4 <fork>
}
    80002da4:	60a2                	ld	ra,8(sp)
    80002da6:	6402                	ld	s0,0(sp)
    80002da8:	0141                	addi	sp,sp,16
    80002daa:	8082                	ret

0000000080002dac <sys_wait>:

uint64
sys_wait(void)
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002db4:	fe840593          	addi	a1,s0,-24
    80002db8:	4501                	li	a0,0
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	dea080e7          	jalr	-534(ra) # 80002ba4 <argaddr>
    80002dc2:	87aa                	mv	a5,a0
    return -1;
    80002dc4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dc6:	0007c863          	bltz	a5,80002dd6 <sys_wait+0x2a>
  return wait(p);
    80002dca:	fe843503          	ld	a0,-24(s0)
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	342080e7          	jalr	834(ra) # 80002110 <wait>
}
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret

0000000080002dde <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dde:	7179                	addi	sp,sp,-48
    80002de0:	f406                	sd	ra,40(sp)
    80002de2:	f022                	sd	s0,32(sp)
    80002de4:	ec26                	sd	s1,24(sp)
    80002de6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002de8:	fdc40593          	addi	a1,s0,-36
    80002dec:	4501                	li	a0,0
    80002dee:	00000097          	auipc	ra,0x0
    80002df2:	d94080e7          	jalr	-620(ra) # 80002b82 <argint>
    80002df6:	87aa                	mv	a5,a0
    return -1;
    80002df8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dfa:	0207c063          	bltz	a5,80002e1a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	bb2080e7          	jalr	-1102(ra) # 800019b0 <myproc>
    80002e06:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e08:	fdc42503          	lw	a0,-36(s0)
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	f44080e7          	jalr	-188(ra) # 80001d50 <growproc>
    80002e14:	00054863          	bltz	a0,80002e24 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e18:	8526                	mv	a0,s1
}
    80002e1a:	70a2                	ld	ra,40(sp)
    80002e1c:	7402                	ld	s0,32(sp)
    80002e1e:	64e2                	ld	s1,24(sp)
    80002e20:	6145                	addi	sp,sp,48
    80002e22:	8082                	ret
    return -1;
    80002e24:	557d                	li	a0,-1
    80002e26:	bfd5                	j	80002e1a <sys_sbrk+0x3c>

0000000080002e28 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e28:	7139                	addi	sp,sp,-64
    80002e2a:	fc06                	sd	ra,56(sp)
    80002e2c:	f822                	sd	s0,48(sp)
    80002e2e:	f426                	sd	s1,40(sp)
    80002e30:	f04a                	sd	s2,32(sp)
    80002e32:	ec4e                	sd	s3,24(sp)
    80002e34:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e36:	fcc40593          	addi	a1,s0,-52
    80002e3a:	4501                	li	a0,0
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	d46080e7          	jalr	-698(ra) # 80002b82 <argint>
    return -1;
    80002e44:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e46:	06054563          	bltz	a0,80002eb0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e4a:	00015517          	auipc	a0,0x15
    80002e4e:	c8650513          	addi	a0,a0,-890 # 80017ad0 <tickslock>
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	d92080e7          	jalr	-622(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e5a:	00006917          	auipc	s2,0x6
    80002e5e:	1d692903          	lw	s2,470(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e62:	fcc42783          	lw	a5,-52(s0)
    80002e66:	cf85                	beqz	a5,80002e9e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e68:	00015997          	auipc	s3,0x15
    80002e6c:	c6898993          	addi	s3,s3,-920 # 80017ad0 <tickslock>
    80002e70:	00006497          	auipc	s1,0x6
    80002e74:	1c048493          	addi	s1,s1,448 # 80009030 <ticks>
    if(myproc()->killed){
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	b38080e7          	jalr	-1224(ra) # 800019b0 <myproc>
    80002e80:	551c                	lw	a5,40(a0)
    80002e82:	ef9d                	bnez	a5,80002ec0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e84:	85ce                	mv	a1,s3
    80002e86:	8526                	mv	a0,s1
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	224080e7          	jalr	548(ra) # 800020ac <sleep>
  while(ticks - ticks0 < n){
    80002e90:	409c                	lw	a5,0(s1)
    80002e92:	412787bb          	subw	a5,a5,s2
    80002e96:	fcc42703          	lw	a4,-52(s0)
    80002e9a:	fce7efe3          	bltu	a5,a4,80002e78 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e9e:	00015517          	auipc	a0,0x15
    80002ea2:	c3250513          	addi	a0,a0,-974 # 80017ad0 <tickslock>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	df2080e7          	jalr	-526(ra) # 80000c98 <release>
  return 0;
    80002eae:	4781                	li	a5,0
}
    80002eb0:	853e                	mv	a0,a5
    80002eb2:	70e2                	ld	ra,56(sp)
    80002eb4:	7442                	ld	s0,48(sp)
    80002eb6:	74a2                	ld	s1,40(sp)
    80002eb8:	7902                	ld	s2,32(sp)
    80002eba:	69e2                	ld	s3,24(sp)
    80002ebc:	6121                	addi	sp,sp,64
    80002ebe:	8082                	ret
      release(&tickslock);
    80002ec0:	00015517          	auipc	a0,0x15
    80002ec4:	c1050513          	addi	a0,a0,-1008 # 80017ad0 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
      return -1;
    80002ed0:	57fd                	li	a5,-1
    80002ed2:	bff9                	j	80002eb0 <sys_sleep+0x88>

0000000080002ed4 <sys_kill>:

uint64
sys_kill(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002edc:	fec40593          	addi	a1,s0,-20
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	ca0080e7          	jalr	-864(ra) # 80002b82 <argint>
    80002eea:	87aa                	mv	a5,a0
    return -1;
    80002eec:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002eee:	0007c863          	bltz	a5,80002efe <sys_kill+0x2a>
  return kill(pid);
    80002ef2:	fec42503          	lw	a0,-20(s0)
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	4e8080e7          	jalr	1256(ra) # 800023de <kill>
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	e426                	sd	s1,8(sp)
    80002f0e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f10:	00015517          	auipc	a0,0x15
    80002f14:	bc050513          	addi	a0,a0,-1088 # 80017ad0 <tickslock>
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	ccc080e7          	jalr	-820(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f20:	00006497          	auipc	s1,0x6
    80002f24:	1104a483          	lw	s1,272(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f28:	00015517          	auipc	a0,0x15
    80002f2c:	ba850513          	addi	a0,a0,-1112 # 80017ad0 <tickslock>
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	d68080e7          	jalr	-664(ra) # 80000c98 <release>
  return xticks;
}
    80002f38:	02049513          	slli	a0,s1,0x20
    80002f3c:	9101                	srli	a0,a0,0x20
    80002f3e:	60e2                	ld	ra,24(sp)
    80002f40:	6442                	ld	s0,16(sp)
    80002f42:	64a2                	ld	s1,8(sp)
    80002f44:	6105                	addi	sp,sp,32
    80002f46:	8082                	ret

0000000080002f48 <sys_trace>:

//implements the new system call by remembering its argument in a new variable in the proc structure 
uint64
sys_trace(void)
{
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	1000                	addi	s0,sp,32
  int mask;
  argint(0, &mask);
    80002f50:	fec40593          	addi	a1,s0,-20
    80002f54:	4501                	li	a0,0
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	c2c080e7          	jalr	-980(ra) # 80002b82 <argint>
  trace(mask);
    80002f5e:	fec42503          	lw	a0,-20(s0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	66e080e7          	jalr	1646(ra) # 800025d0 <trace>
  return 0; 
}
    80002f6a:	4501                	li	a0,0
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	6105                	addi	sp,sp,32
    80002f72:	8082                	ret

0000000080002f74 <sys_set_priority>:
uint64
sys_set_priority(void)
{
    80002f74:	1101                	addi	sp,sp,-32
    80002f76:	ec06                	sd	ra,24(sp)
    80002f78:	e822                	sd	s0,16(sp)
    80002f7a:	1000                	addi	s0,sp,32
  int priority, pid;
  if(argint(0, &priority) < 0)
    80002f7c:	fec40593          	addi	a1,s0,-20
    80002f80:	4501                	li	a0,0
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	c00080e7          	jalr	-1024(ra) # 80002b82 <argint>
    return -1;
    80002f8a:	57fd                	li	a5,-1
  if(argint(0, &priority) < 0)
    80002f8c:	02054563          	bltz	a0,80002fb6 <sys_set_priority+0x42>
  if(argint(1, &pid) < 0)
    80002f90:	fe840593          	addi	a1,s0,-24
    80002f94:	4505                	li	a0,1
    80002f96:	00000097          	auipc	ra,0x0
    80002f9a:	bec080e7          	jalr	-1044(ra) # 80002b82 <argint>
    return -1;
    80002f9e:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    80002fa0:	00054b63          	bltz	a0,80002fb6 <sys_set_priority+0x42>
  set_priority(priority, pid);
    80002fa4:	fe842583          	lw	a1,-24(s0)
    80002fa8:	fec42503          	lw	a0,-20(s0)
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	648080e7          	jalr	1608(ra) # 800025f4 <set_priority>
  return 0;
    80002fb4:	4781                	li	a5,0
    80002fb6:	853e                	mv	a0,a5
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	6105                	addi	sp,sp,32
    80002fbe:	8082                	ret

0000000080002fc0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fc0:	7179                	addi	sp,sp,-48
    80002fc2:	f406                	sd	ra,40(sp)
    80002fc4:	f022                	sd	s0,32(sp)
    80002fc6:	ec26                	sd	s1,24(sp)
    80002fc8:	e84a                	sd	s2,16(sp)
    80002fca:	e44e                	sd	s3,8(sp)
    80002fcc:	e052                	sd	s4,0(sp)
    80002fce:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fd0:	00005597          	auipc	a1,0x5
    80002fd4:	69058593          	addi	a1,a1,1680 # 80008660 <syscalls+0xc0>
    80002fd8:	00015517          	auipc	a0,0x15
    80002fdc:	b1050513          	addi	a0,a0,-1264 # 80017ae8 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	b74080e7          	jalr	-1164(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fe8:	0001d797          	auipc	a5,0x1d
    80002fec:	b0078793          	addi	a5,a5,-1280 # 8001fae8 <bcache+0x8000>
    80002ff0:	0001d717          	auipc	a4,0x1d
    80002ff4:	d6070713          	addi	a4,a4,-672 # 8001fd50 <bcache+0x8268>
    80002ff8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ffc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003000:	00015497          	auipc	s1,0x15
    80003004:	b0048493          	addi	s1,s1,-1280 # 80017b00 <bcache+0x18>
    b->next = bcache.head.next;
    80003008:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000300a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000300c:	00005a17          	auipc	s4,0x5
    80003010:	65ca0a13          	addi	s4,s4,1628 # 80008668 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003014:	2b893783          	ld	a5,696(s2)
    80003018:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000301a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000301e:	85d2                	mv	a1,s4
    80003020:	01048513          	addi	a0,s1,16
    80003024:	00001097          	auipc	ra,0x1
    80003028:	4bc080e7          	jalr	1212(ra) # 800044e0 <initsleeplock>
    bcache.head.next->prev = b;
    8000302c:	2b893783          	ld	a5,696(s2)
    80003030:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003032:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003036:	45848493          	addi	s1,s1,1112
    8000303a:	fd349de3          	bne	s1,s3,80003014 <binit+0x54>
  }
}
    8000303e:	70a2                	ld	ra,40(sp)
    80003040:	7402                	ld	s0,32(sp)
    80003042:	64e2                	ld	s1,24(sp)
    80003044:	6942                	ld	s2,16(sp)
    80003046:	69a2                	ld	s3,8(sp)
    80003048:	6a02                	ld	s4,0(sp)
    8000304a:	6145                	addi	sp,sp,48
    8000304c:	8082                	ret

000000008000304e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000304e:	7179                	addi	sp,sp,-48
    80003050:	f406                	sd	ra,40(sp)
    80003052:	f022                	sd	s0,32(sp)
    80003054:	ec26                	sd	s1,24(sp)
    80003056:	e84a                	sd	s2,16(sp)
    80003058:	e44e                	sd	s3,8(sp)
    8000305a:	1800                	addi	s0,sp,48
    8000305c:	89aa                	mv	s3,a0
    8000305e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003060:	00015517          	auipc	a0,0x15
    80003064:	a8850513          	addi	a0,a0,-1400 # 80017ae8 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	b7c080e7          	jalr	-1156(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003070:	0001d497          	auipc	s1,0x1d
    80003074:	d304b483          	ld	s1,-720(s1) # 8001fda0 <bcache+0x82b8>
    80003078:	0001d797          	auipc	a5,0x1d
    8000307c:	cd878793          	addi	a5,a5,-808 # 8001fd50 <bcache+0x8268>
    80003080:	02f48f63          	beq	s1,a5,800030be <bread+0x70>
    80003084:	873e                	mv	a4,a5
    80003086:	a021                	j	8000308e <bread+0x40>
    80003088:	68a4                	ld	s1,80(s1)
    8000308a:	02e48a63          	beq	s1,a4,800030be <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000308e:	449c                	lw	a5,8(s1)
    80003090:	ff379ce3          	bne	a5,s3,80003088 <bread+0x3a>
    80003094:	44dc                	lw	a5,12(s1)
    80003096:	ff2799e3          	bne	a5,s2,80003088 <bread+0x3a>
      b->refcnt++;
    8000309a:	40bc                	lw	a5,64(s1)
    8000309c:	2785                	addiw	a5,a5,1
    8000309e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030a0:	00015517          	auipc	a0,0x15
    800030a4:	a4850513          	addi	a0,a0,-1464 # 80017ae8 <bcache>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	bf0080e7          	jalr	-1040(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030b0:	01048513          	addi	a0,s1,16
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	466080e7          	jalr	1126(ra) # 8000451a <acquiresleep>
      return b;
    800030bc:	a8b9                	j	8000311a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030be:	0001d497          	auipc	s1,0x1d
    800030c2:	cda4b483          	ld	s1,-806(s1) # 8001fd98 <bcache+0x82b0>
    800030c6:	0001d797          	auipc	a5,0x1d
    800030ca:	c8a78793          	addi	a5,a5,-886 # 8001fd50 <bcache+0x8268>
    800030ce:	00f48863          	beq	s1,a5,800030de <bread+0x90>
    800030d2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030d4:	40bc                	lw	a5,64(s1)
    800030d6:	cf81                	beqz	a5,800030ee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d8:	64a4                	ld	s1,72(s1)
    800030da:	fee49de3          	bne	s1,a4,800030d4 <bread+0x86>
  panic("bget: no buffers");
    800030de:	00005517          	auipc	a0,0x5
    800030e2:	59250513          	addi	a0,a0,1426 # 80008670 <syscalls+0xd0>
    800030e6:	ffffd097          	auipc	ra,0xffffd
    800030ea:	458080e7          	jalr	1112(ra) # 8000053e <panic>
      b->dev = dev;
    800030ee:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030f2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030f6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030fa:	4785                	li	a5,1
    800030fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030fe:	00015517          	auipc	a0,0x15
    80003102:	9ea50513          	addi	a0,a0,-1558 # 80017ae8 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	b92080e7          	jalr	-1134(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000310e:	01048513          	addi	a0,s1,16
    80003112:	00001097          	auipc	ra,0x1
    80003116:	408080e7          	jalr	1032(ra) # 8000451a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000311a:	409c                	lw	a5,0(s1)
    8000311c:	cb89                	beqz	a5,8000312e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000311e:	8526                	mv	a0,s1
    80003120:	70a2                	ld	ra,40(sp)
    80003122:	7402                	ld	s0,32(sp)
    80003124:	64e2                	ld	s1,24(sp)
    80003126:	6942                	ld	s2,16(sp)
    80003128:	69a2                	ld	s3,8(sp)
    8000312a:	6145                	addi	sp,sp,48
    8000312c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000312e:	4581                	li	a1,0
    80003130:	8526                	mv	a0,s1
    80003132:	00003097          	auipc	ra,0x3
    80003136:	f14080e7          	jalr	-236(ra) # 80006046 <virtio_disk_rw>
    b->valid = 1;
    8000313a:	4785                	li	a5,1
    8000313c:	c09c                	sw	a5,0(s1)
  return b;
    8000313e:	b7c5                	j	8000311e <bread+0xd0>

0000000080003140 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	1000                	addi	s0,sp,32
    8000314a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314c:	0541                	addi	a0,a0,16
    8000314e:	00001097          	auipc	ra,0x1
    80003152:	466080e7          	jalr	1126(ra) # 800045b4 <holdingsleep>
    80003156:	cd01                	beqz	a0,8000316e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003158:	4585                	li	a1,1
    8000315a:	8526                	mv	a0,s1
    8000315c:	00003097          	auipc	ra,0x3
    80003160:	eea080e7          	jalr	-278(ra) # 80006046 <virtio_disk_rw>
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	64a2                	ld	s1,8(sp)
    8000316a:	6105                	addi	sp,sp,32
    8000316c:	8082                	ret
    panic("bwrite");
    8000316e:	00005517          	auipc	a0,0x5
    80003172:	51a50513          	addi	a0,a0,1306 # 80008688 <syscalls+0xe8>
    80003176:	ffffd097          	auipc	ra,0xffffd
    8000317a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>

000000008000317e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	e04a                	sd	s2,0(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000318c:	01050913          	addi	s2,a0,16
    80003190:	854a                	mv	a0,s2
    80003192:	00001097          	auipc	ra,0x1
    80003196:	422080e7          	jalr	1058(ra) # 800045b4 <holdingsleep>
    8000319a:	c92d                	beqz	a0,8000320c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000319c:	854a                	mv	a0,s2
    8000319e:	00001097          	auipc	ra,0x1
    800031a2:	3d2080e7          	jalr	978(ra) # 80004570 <releasesleep>

  acquire(&bcache.lock);
    800031a6:	00015517          	auipc	a0,0x15
    800031aa:	94250513          	addi	a0,a0,-1726 # 80017ae8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	a36080e7          	jalr	-1482(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031b6:	40bc                	lw	a5,64(s1)
    800031b8:	37fd                	addiw	a5,a5,-1
    800031ba:	0007871b          	sext.w	a4,a5
    800031be:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031c0:	eb05                	bnez	a4,800031f0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031c2:	68bc                	ld	a5,80(s1)
    800031c4:	64b8                	ld	a4,72(s1)
    800031c6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031c8:	64bc                	ld	a5,72(s1)
    800031ca:	68b8                	ld	a4,80(s1)
    800031cc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031ce:	0001d797          	auipc	a5,0x1d
    800031d2:	91a78793          	addi	a5,a5,-1766 # 8001fae8 <bcache+0x8000>
    800031d6:	2b87b703          	ld	a4,696(a5)
    800031da:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031dc:	0001d717          	auipc	a4,0x1d
    800031e0:	b7470713          	addi	a4,a4,-1164 # 8001fd50 <bcache+0x8268>
    800031e4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031e6:	2b87b703          	ld	a4,696(a5)
    800031ea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031f0:	00015517          	auipc	a0,0x15
    800031f4:	8f850513          	addi	a0,a0,-1800 # 80017ae8 <bcache>
    800031f8:	ffffe097          	auipc	ra,0xffffe
    800031fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
}
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	64a2                	ld	s1,8(sp)
    80003206:	6902                	ld	s2,0(sp)
    80003208:	6105                	addi	sp,sp,32
    8000320a:	8082                	ret
    panic("brelse");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	48450513          	addi	a0,a0,1156 # 80008690 <syscalls+0xf0>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	32a080e7          	jalr	810(ra) # 8000053e <panic>

000000008000321c <bpin>:

void
bpin(struct buf *b) {
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	1000                	addi	s0,sp,32
    80003226:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003228:	00015517          	auipc	a0,0x15
    8000322c:	8c050513          	addi	a0,a0,-1856 # 80017ae8 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	9b4080e7          	jalr	-1612(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003238:	40bc                	lw	a5,64(s1)
    8000323a:	2785                	addiw	a5,a5,1
    8000323c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000323e:	00015517          	auipc	a0,0x15
    80003242:	8aa50513          	addi	a0,a0,-1878 # 80017ae8 <bcache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	a52080e7          	jalr	-1454(ra) # 80000c98 <release>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <bunpin>:

void
bunpin(struct buf *b) {
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	1000                	addi	s0,sp,32
    80003262:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003264:	00015517          	auipc	a0,0x15
    80003268:	88450513          	addi	a0,a0,-1916 # 80017ae8 <bcache>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	978080e7          	jalr	-1672(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003274:	40bc                	lw	a5,64(s1)
    80003276:	37fd                	addiw	a5,a5,-1
    80003278:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000327a:	00015517          	auipc	a0,0x15
    8000327e:	86e50513          	addi	a0,a0,-1938 # 80017ae8 <bcache>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	a16080e7          	jalr	-1514(ra) # 80000c98 <release>
}
    8000328a:	60e2                	ld	ra,24(sp)
    8000328c:	6442                	ld	s0,16(sp)
    8000328e:	64a2                	ld	s1,8(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret

0000000080003294 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003294:	1101                	addi	sp,sp,-32
    80003296:	ec06                	sd	ra,24(sp)
    80003298:	e822                	sd	s0,16(sp)
    8000329a:	e426                	sd	s1,8(sp)
    8000329c:	e04a                	sd	s2,0(sp)
    8000329e:	1000                	addi	s0,sp,32
    800032a0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032a2:	00d5d59b          	srliw	a1,a1,0xd
    800032a6:	0001d797          	auipc	a5,0x1d
    800032aa:	f1e7a783          	lw	a5,-226(a5) # 800201c4 <sb+0x1c>
    800032ae:	9dbd                	addw	a1,a1,a5
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	d9e080e7          	jalr	-610(ra) # 8000304e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032b8:	0074f713          	andi	a4,s1,7
    800032bc:	4785                	li	a5,1
    800032be:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032c2:	14ce                	slli	s1,s1,0x33
    800032c4:	90d9                	srli	s1,s1,0x36
    800032c6:	00950733          	add	a4,a0,s1
    800032ca:	05874703          	lbu	a4,88(a4)
    800032ce:	00e7f6b3          	and	a3,a5,a4
    800032d2:	c69d                	beqz	a3,80003300 <bfree+0x6c>
    800032d4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032d6:	94aa                	add	s1,s1,a0
    800032d8:	fff7c793          	not	a5,a5
    800032dc:	8ff9                	and	a5,a5,a4
    800032de:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032e2:	00001097          	auipc	ra,0x1
    800032e6:	118080e7          	jalr	280(ra) # 800043fa <log_write>
  brelse(bp);
    800032ea:	854a                	mv	a0,s2
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	e92080e7          	jalr	-366(ra) # 8000317e <brelse>
}
    800032f4:	60e2                	ld	ra,24(sp)
    800032f6:	6442                	ld	s0,16(sp)
    800032f8:	64a2                	ld	s1,8(sp)
    800032fa:	6902                	ld	s2,0(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret
    panic("freeing free block");
    80003300:	00005517          	auipc	a0,0x5
    80003304:	39850513          	addi	a0,a0,920 # 80008698 <syscalls+0xf8>
    80003308:	ffffd097          	auipc	ra,0xffffd
    8000330c:	236080e7          	jalr	566(ra) # 8000053e <panic>

0000000080003310 <balloc>:
{
    80003310:	711d                	addi	sp,sp,-96
    80003312:	ec86                	sd	ra,88(sp)
    80003314:	e8a2                	sd	s0,80(sp)
    80003316:	e4a6                	sd	s1,72(sp)
    80003318:	e0ca                	sd	s2,64(sp)
    8000331a:	fc4e                	sd	s3,56(sp)
    8000331c:	f852                	sd	s4,48(sp)
    8000331e:	f456                	sd	s5,40(sp)
    80003320:	f05a                	sd	s6,32(sp)
    80003322:	ec5e                	sd	s7,24(sp)
    80003324:	e862                	sd	s8,16(sp)
    80003326:	e466                	sd	s9,8(sp)
    80003328:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000332a:	0001d797          	auipc	a5,0x1d
    8000332e:	e827a783          	lw	a5,-382(a5) # 800201ac <sb+0x4>
    80003332:	cbd1                	beqz	a5,800033c6 <balloc+0xb6>
    80003334:	8baa                	mv	s7,a0
    80003336:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003338:	0001db17          	auipc	s6,0x1d
    8000333c:	e70b0b13          	addi	s6,s6,-400 # 800201a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003340:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003342:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003344:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003346:	6c89                	lui	s9,0x2
    80003348:	a831                	j	80003364 <balloc+0x54>
    brelse(bp);
    8000334a:	854a                	mv	a0,s2
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	e32080e7          	jalr	-462(ra) # 8000317e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003354:	015c87bb          	addw	a5,s9,s5
    80003358:	00078a9b          	sext.w	s5,a5
    8000335c:	004b2703          	lw	a4,4(s6)
    80003360:	06eaf363          	bgeu	s5,a4,800033c6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003364:	41fad79b          	sraiw	a5,s5,0x1f
    80003368:	0137d79b          	srliw	a5,a5,0x13
    8000336c:	015787bb          	addw	a5,a5,s5
    80003370:	40d7d79b          	sraiw	a5,a5,0xd
    80003374:	01cb2583          	lw	a1,28(s6)
    80003378:	9dbd                	addw	a1,a1,a5
    8000337a:	855e                	mv	a0,s7
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	cd2080e7          	jalr	-814(ra) # 8000304e <bread>
    80003384:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003386:	004b2503          	lw	a0,4(s6)
    8000338a:	000a849b          	sext.w	s1,s5
    8000338e:	8662                	mv	a2,s8
    80003390:	faa4fde3          	bgeu	s1,a0,8000334a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003394:	41f6579b          	sraiw	a5,a2,0x1f
    80003398:	01d7d69b          	srliw	a3,a5,0x1d
    8000339c:	00c6873b          	addw	a4,a3,a2
    800033a0:	00777793          	andi	a5,a4,7
    800033a4:	9f95                	subw	a5,a5,a3
    800033a6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033aa:	4037571b          	sraiw	a4,a4,0x3
    800033ae:	00e906b3          	add	a3,s2,a4
    800033b2:	0586c683          	lbu	a3,88(a3)
    800033b6:	00d7f5b3          	and	a1,a5,a3
    800033ba:	cd91                	beqz	a1,800033d6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033bc:	2605                	addiw	a2,a2,1
    800033be:	2485                	addiw	s1,s1,1
    800033c0:	fd4618e3          	bne	a2,s4,80003390 <balloc+0x80>
    800033c4:	b759                	j	8000334a <balloc+0x3a>
  panic("balloc: out of blocks");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	2ea50513          	addi	a0,a0,746 # 800086b0 <syscalls+0x110>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033d6:	974a                	add	a4,a4,s2
    800033d8:	8fd5                	or	a5,a5,a3
    800033da:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033de:	854a                	mv	a0,s2
    800033e0:	00001097          	auipc	ra,0x1
    800033e4:	01a080e7          	jalr	26(ra) # 800043fa <log_write>
        brelse(bp);
    800033e8:	854a                	mv	a0,s2
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	d94080e7          	jalr	-620(ra) # 8000317e <brelse>
  bp = bread(dev, bno);
    800033f2:	85a6                	mv	a1,s1
    800033f4:	855e                	mv	a0,s7
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	c58080e7          	jalr	-936(ra) # 8000304e <bread>
    800033fe:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003400:	40000613          	li	a2,1024
    80003404:	4581                	li	a1,0
    80003406:	05850513          	addi	a0,a0,88
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	8d6080e7          	jalr	-1834(ra) # 80000ce0 <memset>
  log_write(bp);
    80003412:	854a                	mv	a0,s2
    80003414:	00001097          	auipc	ra,0x1
    80003418:	fe6080e7          	jalr	-26(ra) # 800043fa <log_write>
  brelse(bp);
    8000341c:	854a                	mv	a0,s2
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	d60080e7          	jalr	-672(ra) # 8000317e <brelse>
}
    80003426:	8526                	mv	a0,s1
    80003428:	60e6                	ld	ra,88(sp)
    8000342a:	6446                	ld	s0,80(sp)
    8000342c:	64a6                	ld	s1,72(sp)
    8000342e:	6906                	ld	s2,64(sp)
    80003430:	79e2                	ld	s3,56(sp)
    80003432:	7a42                	ld	s4,48(sp)
    80003434:	7aa2                	ld	s5,40(sp)
    80003436:	7b02                	ld	s6,32(sp)
    80003438:	6be2                	ld	s7,24(sp)
    8000343a:	6c42                	ld	s8,16(sp)
    8000343c:	6ca2                	ld	s9,8(sp)
    8000343e:	6125                	addi	sp,sp,96
    80003440:	8082                	ret

0000000080003442 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003442:	7179                	addi	sp,sp,-48
    80003444:	f406                	sd	ra,40(sp)
    80003446:	f022                	sd	s0,32(sp)
    80003448:	ec26                	sd	s1,24(sp)
    8000344a:	e84a                	sd	s2,16(sp)
    8000344c:	e44e                	sd	s3,8(sp)
    8000344e:	e052                	sd	s4,0(sp)
    80003450:	1800                	addi	s0,sp,48
    80003452:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003454:	47ad                	li	a5,11
    80003456:	04b7fe63          	bgeu	a5,a1,800034b2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000345a:	ff45849b          	addiw	s1,a1,-12
    8000345e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003462:	0ff00793          	li	a5,255
    80003466:	0ae7e363          	bltu	a5,a4,8000350c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000346a:	08052583          	lw	a1,128(a0)
    8000346e:	c5ad                	beqz	a1,800034d8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003470:	00092503          	lw	a0,0(s2)
    80003474:	00000097          	auipc	ra,0x0
    80003478:	bda080e7          	jalr	-1062(ra) # 8000304e <bread>
    8000347c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000347e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003482:	02049593          	slli	a1,s1,0x20
    80003486:	9181                	srli	a1,a1,0x20
    80003488:	058a                	slli	a1,a1,0x2
    8000348a:	00b784b3          	add	s1,a5,a1
    8000348e:	0004a983          	lw	s3,0(s1)
    80003492:	04098d63          	beqz	s3,800034ec <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003496:	8552                	mv	a0,s4
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	ce6080e7          	jalr	-794(ra) # 8000317e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034a0:	854e                	mv	a0,s3
    800034a2:	70a2                	ld	ra,40(sp)
    800034a4:	7402                	ld	s0,32(sp)
    800034a6:	64e2                	ld	s1,24(sp)
    800034a8:	6942                	ld	s2,16(sp)
    800034aa:	69a2                	ld	s3,8(sp)
    800034ac:	6a02                	ld	s4,0(sp)
    800034ae:	6145                	addi	sp,sp,48
    800034b0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034b2:	02059493          	slli	s1,a1,0x20
    800034b6:	9081                	srli	s1,s1,0x20
    800034b8:	048a                	slli	s1,s1,0x2
    800034ba:	94aa                	add	s1,s1,a0
    800034bc:	0504a983          	lw	s3,80(s1)
    800034c0:	fe0990e3          	bnez	s3,800034a0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034c4:	4108                	lw	a0,0(a0)
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	e4a080e7          	jalr	-438(ra) # 80003310 <balloc>
    800034ce:	0005099b          	sext.w	s3,a0
    800034d2:	0534a823          	sw	s3,80(s1)
    800034d6:	b7e9                	j	800034a0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034d8:	4108                	lw	a0,0(a0)
    800034da:	00000097          	auipc	ra,0x0
    800034de:	e36080e7          	jalr	-458(ra) # 80003310 <balloc>
    800034e2:	0005059b          	sext.w	a1,a0
    800034e6:	08b92023          	sw	a1,128(s2)
    800034ea:	b759                	j	80003470 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034ec:	00092503          	lw	a0,0(s2)
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	e20080e7          	jalr	-480(ra) # 80003310 <balloc>
    800034f8:	0005099b          	sext.w	s3,a0
    800034fc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003500:	8552                	mv	a0,s4
    80003502:	00001097          	auipc	ra,0x1
    80003506:	ef8080e7          	jalr	-264(ra) # 800043fa <log_write>
    8000350a:	b771                	j	80003496 <bmap+0x54>
  panic("bmap: out of range");
    8000350c:	00005517          	auipc	a0,0x5
    80003510:	1bc50513          	addi	a0,a0,444 # 800086c8 <syscalls+0x128>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	02a080e7          	jalr	42(ra) # 8000053e <panic>

000000008000351c <iget>:
{
    8000351c:	7179                	addi	sp,sp,-48
    8000351e:	f406                	sd	ra,40(sp)
    80003520:	f022                	sd	s0,32(sp)
    80003522:	ec26                	sd	s1,24(sp)
    80003524:	e84a                	sd	s2,16(sp)
    80003526:	e44e                	sd	s3,8(sp)
    80003528:	e052                	sd	s4,0(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	89aa                	mv	s3,a0
    8000352e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003530:	0001d517          	auipc	a0,0x1d
    80003534:	c9850513          	addi	a0,a0,-872 # 800201c8 <itable>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	6ac080e7          	jalr	1708(ra) # 80000be4 <acquire>
  empty = 0;
    80003540:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003542:	0001d497          	auipc	s1,0x1d
    80003546:	c9e48493          	addi	s1,s1,-866 # 800201e0 <itable+0x18>
    8000354a:	0001e697          	auipc	a3,0x1e
    8000354e:	72668693          	addi	a3,a3,1830 # 80021c70 <log>
    80003552:	a039                	j	80003560 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003554:	02090b63          	beqz	s2,8000358a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003558:	08848493          	addi	s1,s1,136
    8000355c:	02d48a63          	beq	s1,a3,80003590 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003560:	449c                	lw	a5,8(s1)
    80003562:	fef059e3          	blez	a5,80003554 <iget+0x38>
    80003566:	4098                	lw	a4,0(s1)
    80003568:	ff3716e3          	bne	a4,s3,80003554 <iget+0x38>
    8000356c:	40d8                	lw	a4,4(s1)
    8000356e:	ff4713e3          	bne	a4,s4,80003554 <iget+0x38>
      ip->ref++;
    80003572:	2785                	addiw	a5,a5,1
    80003574:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003576:	0001d517          	auipc	a0,0x1d
    8000357a:	c5250513          	addi	a0,a0,-942 # 800201c8 <itable>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	71a080e7          	jalr	1818(ra) # 80000c98 <release>
      return ip;
    80003586:	8926                	mv	s2,s1
    80003588:	a03d                	j	800035b6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358a:	f7f9                	bnez	a5,80003558 <iget+0x3c>
    8000358c:	8926                	mv	s2,s1
    8000358e:	b7e9                	j	80003558 <iget+0x3c>
  if(empty == 0)
    80003590:	02090c63          	beqz	s2,800035c8 <iget+0xac>
  ip->dev = dev;
    80003594:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003598:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000359c:	4785                	li	a5,1
    8000359e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035a6:	0001d517          	auipc	a0,0x1d
    800035aa:	c2250513          	addi	a0,a0,-990 # 800201c8 <itable>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
}
    800035b6:	854a                	mv	a0,s2
    800035b8:	70a2                	ld	ra,40(sp)
    800035ba:	7402                	ld	s0,32(sp)
    800035bc:	64e2                	ld	s1,24(sp)
    800035be:	6942                	ld	s2,16(sp)
    800035c0:	69a2                	ld	s3,8(sp)
    800035c2:	6a02                	ld	s4,0(sp)
    800035c4:	6145                	addi	sp,sp,48
    800035c6:	8082                	ret
    panic("iget: no inodes");
    800035c8:	00005517          	auipc	a0,0x5
    800035cc:	11850513          	addi	a0,a0,280 # 800086e0 <syscalls+0x140>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>

00000000800035d8 <fsinit>:
fsinit(int dev) {
    800035d8:	7179                	addi	sp,sp,-48
    800035da:	f406                	sd	ra,40(sp)
    800035dc:	f022                	sd	s0,32(sp)
    800035de:	ec26                	sd	s1,24(sp)
    800035e0:	e84a                	sd	s2,16(sp)
    800035e2:	e44e                	sd	s3,8(sp)
    800035e4:	1800                	addi	s0,sp,48
    800035e6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035e8:	4585                	li	a1,1
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	a64080e7          	jalr	-1436(ra) # 8000304e <bread>
    800035f2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035f4:	0001d997          	auipc	s3,0x1d
    800035f8:	bb498993          	addi	s3,s3,-1100 # 800201a8 <sb>
    800035fc:	02000613          	li	a2,32
    80003600:	05850593          	addi	a1,a0,88
    80003604:	854e                	mv	a0,s3
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	73a080e7          	jalr	1850(ra) # 80000d40 <memmove>
  brelse(bp);
    8000360e:	8526                	mv	a0,s1
    80003610:	00000097          	auipc	ra,0x0
    80003614:	b6e080e7          	jalr	-1170(ra) # 8000317e <brelse>
  if(sb.magic != FSMAGIC)
    80003618:	0009a703          	lw	a4,0(s3)
    8000361c:	102037b7          	lui	a5,0x10203
    80003620:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003624:	02f71263          	bne	a4,a5,80003648 <fsinit+0x70>
  initlog(dev, &sb);
    80003628:	0001d597          	auipc	a1,0x1d
    8000362c:	b8058593          	addi	a1,a1,-1152 # 800201a8 <sb>
    80003630:	854a                	mv	a0,s2
    80003632:	00001097          	auipc	ra,0x1
    80003636:	b4c080e7          	jalr	-1204(ra) # 8000417e <initlog>
}
    8000363a:	70a2                	ld	ra,40(sp)
    8000363c:	7402                	ld	s0,32(sp)
    8000363e:	64e2                	ld	s1,24(sp)
    80003640:	6942                	ld	s2,16(sp)
    80003642:	69a2                	ld	s3,8(sp)
    80003644:	6145                	addi	sp,sp,48
    80003646:	8082                	ret
    panic("invalid file system");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	0a850513          	addi	a0,a0,168 # 800086f0 <syscalls+0x150>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>

0000000080003658 <iinit>:
{
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003666:	00005597          	auipc	a1,0x5
    8000366a:	0a258593          	addi	a1,a1,162 # 80008708 <syscalls+0x168>
    8000366e:	0001d517          	auipc	a0,0x1d
    80003672:	b5a50513          	addi	a0,a0,-1190 # 800201c8 <itable>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	4de080e7          	jalr	1246(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000367e:	0001d497          	auipc	s1,0x1d
    80003682:	b7248493          	addi	s1,s1,-1166 # 800201f0 <itable+0x28>
    80003686:	0001e997          	auipc	s3,0x1e
    8000368a:	5fa98993          	addi	s3,s3,1530 # 80021c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000368e:	00005917          	auipc	s2,0x5
    80003692:	08290913          	addi	s2,s2,130 # 80008710 <syscalls+0x170>
    80003696:	85ca                	mv	a1,s2
    80003698:	8526                	mv	a0,s1
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	e46080e7          	jalr	-442(ra) # 800044e0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a2:	08848493          	addi	s1,s1,136
    800036a6:	ff3498e3          	bne	s1,s3,80003696 <iinit+0x3e>
}
    800036aa:	70a2                	ld	ra,40(sp)
    800036ac:	7402                	ld	s0,32(sp)
    800036ae:	64e2                	ld	s1,24(sp)
    800036b0:	6942                	ld	s2,16(sp)
    800036b2:	69a2                	ld	s3,8(sp)
    800036b4:	6145                	addi	sp,sp,48
    800036b6:	8082                	ret

00000000800036b8 <ialloc>:
{
    800036b8:	715d                	addi	sp,sp,-80
    800036ba:	e486                	sd	ra,72(sp)
    800036bc:	e0a2                	sd	s0,64(sp)
    800036be:	fc26                	sd	s1,56(sp)
    800036c0:	f84a                	sd	s2,48(sp)
    800036c2:	f44e                	sd	s3,40(sp)
    800036c4:	f052                	sd	s4,32(sp)
    800036c6:	ec56                	sd	s5,24(sp)
    800036c8:	e85a                	sd	s6,16(sp)
    800036ca:	e45e                	sd	s7,8(sp)
    800036cc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ce:	0001d717          	auipc	a4,0x1d
    800036d2:	ae672703          	lw	a4,-1306(a4) # 800201b4 <sb+0xc>
    800036d6:	4785                	li	a5,1
    800036d8:	04e7fa63          	bgeu	a5,a4,8000372c <ialloc+0x74>
    800036dc:	8aaa                	mv	s5,a0
    800036de:	8bae                	mv	s7,a1
    800036e0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e2:	0001da17          	auipc	s4,0x1d
    800036e6:	ac6a0a13          	addi	s4,s4,-1338 # 800201a8 <sb>
    800036ea:	00048b1b          	sext.w	s6,s1
    800036ee:	0044d593          	srli	a1,s1,0x4
    800036f2:	018a2783          	lw	a5,24(s4)
    800036f6:	9dbd                	addw	a1,a1,a5
    800036f8:	8556                	mv	a0,s5
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	954080e7          	jalr	-1708(ra) # 8000304e <bread>
    80003702:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003704:	05850993          	addi	s3,a0,88
    80003708:	00f4f793          	andi	a5,s1,15
    8000370c:	079a                	slli	a5,a5,0x6
    8000370e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003710:	00099783          	lh	a5,0(s3)
    80003714:	c785                	beqz	a5,8000373c <ialloc+0x84>
    brelse(bp);
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	a68080e7          	jalr	-1432(ra) # 8000317e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000371e:	0485                	addi	s1,s1,1
    80003720:	00ca2703          	lw	a4,12(s4)
    80003724:	0004879b          	sext.w	a5,s1
    80003728:	fce7e1e3          	bltu	a5,a4,800036ea <ialloc+0x32>
  panic("ialloc: no inodes");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	fec50513          	addi	a0,a0,-20 # 80008718 <syscalls+0x178>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e0a080e7          	jalr	-502(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000373c:	04000613          	li	a2,64
    80003740:	4581                	li	a1,0
    80003742:	854e                	mv	a0,s3
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	59c080e7          	jalr	1436(ra) # 80000ce0 <memset>
      dip->type = type;
    8000374c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003750:	854a                	mv	a0,s2
    80003752:	00001097          	auipc	ra,0x1
    80003756:	ca8080e7          	jalr	-856(ra) # 800043fa <log_write>
      brelse(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	a22080e7          	jalr	-1502(ra) # 8000317e <brelse>
      return iget(dev, inum);
    80003764:	85da                	mv	a1,s6
    80003766:	8556                	mv	a0,s5
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	db4080e7          	jalr	-588(ra) # 8000351c <iget>
}
    80003770:	60a6                	ld	ra,72(sp)
    80003772:	6406                	ld	s0,64(sp)
    80003774:	74e2                	ld	s1,56(sp)
    80003776:	7942                	ld	s2,48(sp)
    80003778:	79a2                	ld	s3,40(sp)
    8000377a:	7a02                	ld	s4,32(sp)
    8000377c:	6ae2                	ld	s5,24(sp)
    8000377e:	6b42                	ld	s6,16(sp)
    80003780:	6ba2                	ld	s7,8(sp)
    80003782:	6161                	addi	sp,sp,80
    80003784:	8082                	ret

0000000080003786 <iupdate>:
{
    80003786:	1101                	addi	sp,sp,-32
    80003788:	ec06                	sd	ra,24(sp)
    8000378a:	e822                	sd	s0,16(sp)
    8000378c:	e426                	sd	s1,8(sp)
    8000378e:	e04a                	sd	s2,0(sp)
    80003790:	1000                	addi	s0,sp,32
    80003792:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003794:	415c                	lw	a5,4(a0)
    80003796:	0047d79b          	srliw	a5,a5,0x4
    8000379a:	0001d597          	auipc	a1,0x1d
    8000379e:	a265a583          	lw	a1,-1498(a1) # 800201c0 <sb+0x18>
    800037a2:	9dbd                	addw	a1,a1,a5
    800037a4:	4108                	lw	a0,0(a0)
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	8a8080e7          	jalr	-1880(ra) # 8000304e <bread>
    800037ae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b0:	05850793          	addi	a5,a0,88
    800037b4:	40c8                	lw	a0,4(s1)
    800037b6:	893d                	andi	a0,a0,15
    800037b8:	051a                	slli	a0,a0,0x6
    800037ba:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037bc:	04449703          	lh	a4,68(s1)
    800037c0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037c4:	04649703          	lh	a4,70(s1)
    800037c8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037cc:	04849703          	lh	a4,72(s1)
    800037d0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037d4:	04a49703          	lh	a4,74(s1)
    800037d8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037dc:	44f8                	lw	a4,76(s1)
    800037de:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037e0:	03400613          	li	a2,52
    800037e4:	05048593          	addi	a1,s1,80
    800037e8:	0531                	addi	a0,a0,12
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	556080e7          	jalr	1366(ra) # 80000d40 <memmove>
  log_write(bp);
    800037f2:	854a                	mv	a0,s2
    800037f4:	00001097          	auipc	ra,0x1
    800037f8:	c06080e7          	jalr	-1018(ra) # 800043fa <log_write>
  brelse(bp);
    800037fc:	854a                	mv	a0,s2
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	980080e7          	jalr	-1664(ra) # 8000317e <brelse>
}
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6902                	ld	s2,0(sp)
    8000380e:	6105                	addi	sp,sp,32
    80003810:	8082                	ret

0000000080003812 <idup>:
{
    80003812:	1101                	addi	sp,sp,-32
    80003814:	ec06                	sd	ra,24(sp)
    80003816:	e822                	sd	s0,16(sp)
    80003818:	e426                	sd	s1,8(sp)
    8000381a:	1000                	addi	s0,sp,32
    8000381c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000381e:	0001d517          	auipc	a0,0x1d
    80003822:	9aa50513          	addi	a0,a0,-1622 # 800201c8 <itable>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	3be080e7          	jalr	958(ra) # 80000be4 <acquire>
  ip->ref++;
    8000382e:	449c                	lw	a5,8(s1)
    80003830:	2785                	addiw	a5,a5,1
    80003832:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003834:	0001d517          	auipc	a0,0x1d
    80003838:	99450513          	addi	a0,a0,-1644 # 800201c8 <itable>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	45c080e7          	jalr	1116(ra) # 80000c98 <release>
}
    80003844:	8526                	mv	a0,s1
    80003846:	60e2                	ld	ra,24(sp)
    80003848:	6442                	ld	s0,16(sp)
    8000384a:	64a2                	ld	s1,8(sp)
    8000384c:	6105                	addi	sp,sp,32
    8000384e:	8082                	ret

0000000080003850 <ilock>:
{
    80003850:	1101                	addi	sp,sp,-32
    80003852:	ec06                	sd	ra,24(sp)
    80003854:	e822                	sd	s0,16(sp)
    80003856:	e426                	sd	s1,8(sp)
    80003858:	e04a                	sd	s2,0(sp)
    8000385a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000385c:	c115                	beqz	a0,80003880 <ilock+0x30>
    8000385e:	84aa                	mv	s1,a0
    80003860:	451c                	lw	a5,8(a0)
    80003862:	00f05f63          	blez	a5,80003880 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003866:	0541                	addi	a0,a0,16
    80003868:	00001097          	auipc	ra,0x1
    8000386c:	cb2080e7          	jalr	-846(ra) # 8000451a <acquiresleep>
  if(ip->valid == 0){
    80003870:	40bc                	lw	a5,64(s1)
    80003872:	cf99                	beqz	a5,80003890 <ilock+0x40>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6902                	ld	s2,0(sp)
    8000387c:	6105                	addi	sp,sp,32
    8000387e:	8082                	ret
    panic("ilock");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	eb050513          	addi	a0,a0,-336 # 80008730 <syscalls+0x190>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cb6080e7          	jalr	-842(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003890:	40dc                	lw	a5,4(s1)
    80003892:	0047d79b          	srliw	a5,a5,0x4
    80003896:	0001d597          	auipc	a1,0x1d
    8000389a:	92a5a583          	lw	a1,-1750(a1) # 800201c0 <sb+0x18>
    8000389e:	9dbd                	addw	a1,a1,a5
    800038a0:	4088                	lw	a0,0(s1)
    800038a2:	fffff097          	auipc	ra,0xfffff
    800038a6:	7ac080e7          	jalr	1964(ra) # 8000304e <bread>
    800038aa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ac:	05850593          	addi	a1,a0,88
    800038b0:	40dc                	lw	a5,4(s1)
    800038b2:	8bbd                	andi	a5,a5,15
    800038b4:	079a                	slli	a5,a5,0x6
    800038b6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038b8:	00059783          	lh	a5,0(a1)
    800038bc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038c0:	00259783          	lh	a5,2(a1)
    800038c4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038c8:	00459783          	lh	a5,4(a1)
    800038cc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038d0:	00659783          	lh	a5,6(a1)
    800038d4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038d8:	459c                	lw	a5,8(a1)
    800038da:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038dc:	03400613          	li	a2,52
    800038e0:	05b1                	addi	a1,a1,12
    800038e2:	05048513          	addi	a0,s1,80
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	45a080e7          	jalr	1114(ra) # 80000d40 <memmove>
    brelse(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	88e080e7          	jalr	-1906(ra) # 8000317e <brelse>
    ip->valid = 1;
    800038f8:	4785                	li	a5,1
    800038fa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038fc:	04449783          	lh	a5,68(s1)
    80003900:	fbb5                	bnez	a5,80003874 <ilock+0x24>
      panic("ilock: no type");
    80003902:	00005517          	auipc	a0,0x5
    80003906:	e3650513          	addi	a0,a0,-458 # 80008738 <syscalls+0x198>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>

0000000080003912 <iunlock>:
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	e04a                	sd	s2,0(sp)
    8000391c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000391e:	c905                	beqz	a0,8000394e <iunlock+0x3c>
    80003920:	84aa                	mv	s1,a0
    80003922:	01050913          	addi	s2,a0,16
    80003926:	854a                	mv	a0,s2
    80003928:	00001097          	auipc	ra,0x1
    8000392c:	c8c080e7          	jalr	-884(ra) # 800045b4 <holdingsleep>
    80003930:	cd19                	beqz	a0,8000394e <iunlock+0x3c>
    80003932:	449c                	lw	a5,8(s1)
    80003934:	00f05d63          	blez	a5,8000394e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003938:	854a                	mv	a0,s2
    8000393a:	00001097          	auipc	ra,0x1
    8000393e:	c36080e7          	jalr	-970(ra) # 80004570 <releasesleep>
}
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6902                	ld	s2,0(sp)
    8000394a:	6105                	addi	sp,sp,32
    8000394c:	8082                	ret
    panic("iunlock");
    8000394e:	00005517          	auipc	a0,0x5
    80003952:	dfa50513          	addi	a0,a0,-518 # 80008748 <syscalls+0x1a8>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	be8080e7          	jalr	-1048(ra) # 8000053e <panic>

000000008000395e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000395e:	7179                	addi	sp,sp,-48
    80003960:	f406                	sd	ra,40(sp)
    80003962:	f022                	sd	s0,32(sp)
    80003964:	ec26                	sd	s1,24(sp)
    80003966:	e84a                	sd	s2,16(sp)
    80003968:	e44e                	sd	s3,8(sp)
    8000396a:	e052                	sd	s4,0(sp)
    8000396c:	1800                	addi	s0,sp,48
    8000396e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003970:	05050493          	addi	s1,a0,80
    80003974:	08050913          	addi	s2,a0,128
    80003978:	a021                	j	80003980 <itrunc+0x22>
    8000397a:	0491                	addi	s1,s1,4
    8000397c:	01248d63          	beq	s1,s2,80003996 <itrunc+0x38>
    if(ip->addrs[i]){
    80003980:	408c                	lw	a1,0(s1)
    80003982:	dde5                	beqz	a1,8000397a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003984:	0009a503          	lw	a0,0(s3)
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	90c080e7          	jalr	-1780(ra) # 80003294 <bfree>
      ip->addrs[i] = 0;
    80003990:	0004a023          	sw	zero,0(s1)
    80003994:	b7dd                	j	8000397a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003996:	0809a583          	lw	a1,128(s3)
    8000399a:	e185                	bnez	a1,800039ba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000399c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039a0:	854e                	mv	a0,s3
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	de4080e7          	jalr	-540(ra) # 80003786 <iupdate>
}
    800039aa:	70a2                	ld	ra,40(sp)
    800039ac:	7402                	ld	s0,32(sp)
    800039ae:	64e2                	ld	s1,24(sp)
    800039b0:	6942                	ld	s2,16(sp)
    800039b2:	69a2                	ld	s3,8(sp)
    800039b4:	6a02                	ld	s4,0(sp)
    800039b6:	6145                	addi	sp,sp,48
    800039b8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039ba:	0009a503          	lw	a0,0(s3)
    800039be:	fffff097          	auipc	ra,0xfffff
    800039c2:	690080e7          	jalr	1680(ra) # 8000304e <bread>
    800039c6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039c8:	05850493          	addi	s1,a0,88
    800039cc:	45850913          	addi	s2,a0,1112
    800039d0:	a811                	j	800039e4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039d2:	0009a503          	lw	a0,0(s3)
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	8be080e7          	jalr	-1858(ra) # 80003294 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039de:	0491                	addi	s1,s1,4
    800039e0:	01248563          	beq	s1,s2,800039ea <itrunc+0x8c>
      if(a[j])
    800039e4:	408c                	lw	a1,0(s1)
    800039e6:	dde5                	beqz	a1,800039de <itrunc+0x80>
    800039e8:	b7ed                	j	800039d2 <itrunc+0x74>
    brelse(bp);
    800039ea:	8552                	mv	a0,s4
    800039ec:	fffff097          	auipc	ra,0xfffff
    800039f0:	792080e7          	jalr	1938(ra) # 8000317e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039f4:	0809a583          	lw	a1,128(s3)
    800039f8:	0009a503          	lw	a0,0(s3)
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	898080e7          	jalr	-1896(ra) # 80003294 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a04:	0809a023          	sw	zero,128(s3)
    80003a08:	bf51                	j	8000399c <itrunc+0x3e>

0000000080003a0a <iput>:
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	e04a                	sd	s2,0(sp)
    80003a14:	1000                	addi	s0,sp,32
    80003a16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a18:	0001c517          	auipc	a0,0x1c
    80003a1c:	7b050513          	addi	a0,a0,1968 # 800201c8 <itable>
    80003a20:	ffffd097          	auipc	ra,0xffffd
    80003a24:	1c4080e7          	jalr	452(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a28:	4498                	lw	a4,8(s1)
    80003a2a:	4785                	li	a5,1
    80003a2c:	02f70363          	beq	a4,a5,80003a52 <iput+0x48>
  ip->ref--;
    80003a30:	449c                	lw	a5,8(s1)
    80003a32:	37fd                	addiw	a5,a5,-1
    80003a34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a36:	0001c517          	auipc	a0,0x1c
    80003a3a:	79250513          	addi	a0,a0,1938 # 800201c8 <itable>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	25a080e7          	jalr	602(ra) # 80000c98 <release>
}
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	64a2                	ld	s1,8(sp)
    80003a4c:	6902                	ld	s2,0(sp)
    80003a4e:	6105                	addi	sp,sp,32
    80003a50:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a52:	40bc                	lw	a5,64(s1)
    80003a54:	dff1                	beqz	a5,80003a30 <iput+0x26>
    80003a56:	04a49783          	lh	a5,74(s1)
    80003a5a:	fbf9                	bnez	a5,80003a30 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a5c:	01048913          	addi	s2,s1,16
    80003a60:	854a                	mv	a0,s2
    80003a62:	00001097          	auipc	ra,0x1
    80003a66:	ab8080e7          	jalr	-1352(ra) # 8000451a <acquiresleep>
    release(&itable.lock);
    80003a6a:	0001c517          	auipc	a0,0x1c
    80003a6e:	75e50513          	addi	a0,a0,1886 # 800201c8 <itable>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
    itrunc(ip);
    80003a7a:	8526                	mv	a0,s1
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	ee2080e7          	jalr	-286(ra) # 8000395e <itrunc>
    ip->type = 0;
    80003a84:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a88:	8526                	mv	a0,s1
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	cfc080e7          	jalr	-772(ra) # 80003786 <iupdate>
    ip->valid = 0;
    80003a92:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	ad8080e7          	jalr	-1320(ra) # 80004570 <releasesleep>
    acquire(&itable.lock);
    80003aa0:	0001c517          	auipc	a0,0x1c
    80003aa4:	72850513          	addi	a0,a0,1832 # 800201c8 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	13c080e7          	jalr	316(ra) # 80000be4 <acquire>
    80003ab0:	b741                	j	80003a30 <iput+0x26>

0000000080003ab2 <iunlockput>:
{
    80003ab2:	1101                	addi	sp,sp,-32
    80003ab4:	ec06                	sd	ra,24(sp)
    80003ab6:	e822                	sd	s0,16(sp)
    80003ab8:	e426                	sd	s1,8(sp)
    80003aba:	1000                	addi	s0,sp,32
    80003abc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	e54080e7          	jalr	-428(ra) # 80003912 <iunlock>
  iput(ip);
    80003ac6:	8526                	mv	a0,s1
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	f42080e7          	jalr	-190(ra) # 80003a0a <iput>
}
    80003ad0:	60e2                	ld	ra,24(sp)
    80003ad2:	6442                	ld	s0,16(sp)
    80003ad4:	64a2                	ld	s1,8(sp)
    80003ad6:	6105                	addi	sp,sp,32
    80003ad8:	8082                	ret

0000000080003ada <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ada:	1141                	addi	sp,sp,-16
    80003adc:	e422                	sd	s0,8(sp)
    80003ade:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ae0:	411c                	lw	a5,0(a0)
    80003ae2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ae4:	415c                	lw	a5,4(a0)
    80003ae6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ae8:	04451783          	lh	a5,68(a0)
    80003aec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003af0:	04a51783          	lh	a5,74(a0)
    80003af4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003af8:	04c56783          	lwu	a5,76(a0)
    80003afc:	e99c                	sd	a5,16(a1)
}
    80003afe:	6422                	ld	s0,8(sp)
    80003b00:	0141                	addi	sp,sp,16
    80003b02:	8082                	ret

0000000080003b04 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b04:	457c                	lw	a5,76(a0)
    80003b06:	0ed7e963          	bltu	a5,a3,80003bf8 <readi+0xf4>
{
    80003b0a:	7159                	addi	sp,sp,-112
    80003b0c:	f486                	sd	ra,104(sp)
    80003b0e:	f0a2                	sd	s0,96(sp)
    80003b10:	eca6                	sd	s1,88(sp)
    80003b12:	e8ca                	sd	s2,80(sp)
    80003b14:	e4ce                	sd	s3,72(sp)
    80003b16:	e0d2                	sd	s4,64(sp)
    80003b18:	fc56                	sd	s5,56(sp)
    80003b1a:	f85a                	sd	s6,48(sp)
    80003b1c:	f45e                	sd	s7,40(sp)
    80003b1e:	f062                	sd	s8,32(sp)
    80003b20:	ec66                	sd	s9,24(sp)
    80003b22:	e86a                	sd	s10,16(sp)
    80003b24:	e46e                	sd	s11,8(sp)
    80003b26:	1880                	addi	s0,sp,112
    80003b28:	8baa                	mv	s7,a0
    80003b2a:	8c2e                	mv	s8,a1
    80003b2c:	8ab2                	mv	s5,a2
    80003b2e:	84b6                	mv	s1,a3
    80003b30:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b32:	9f35                	addw	a4,a4,a3
    return 0;
    80003b34:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b36:	0ad76063          	bltu	a4,a3,80003bd6 <readi+0xd2>
  if(off + n > ip->size)
    80003b3a:	00e7f463          	bgeu	a5,a4,80003b42 <readi+0x3e>
    n = ip->size - off;
    80003b3e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b42:	0a0b0963          	beqz	s6,80003bf4 <readi+0xf0>
    80003b46:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b48:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b4c:	5cfd                	li	s9,-1
    80003b4e:	a82d                	j	80003b88 <readi+0x84>
    80003b50:	020a1d93          	slli	s11,s4,0x20
    80003b54:	020ddd93          	srli	s11,s11,0x20
    80003b58:	05890613          	addi	a2,s2,88
    80003b5c:	86ee                	mv	a3,s11
    80003b5e:	963a                	add	a2,a2,a4
    80003b60:	85d6                	mv	a1,s5
    80003b62:	8562                	mv	a0,s8
    80003b64:	fffff097          	auipc	ra,0xfffff
    80003b68:	8ec080e7          	jalr	-1812(ra) # 80002450 <either_copyout>
    80003b6c:	05950d63          	beq	a0,s9,80003bc6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b70:	854a                	mv	a0,s2
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	60c080e7          	jalr	1548(ra) # 8000317e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7a:	013a09bb          	addw	s3,s4,s3
    80003b7e:	009a04bb          	addw	s1,s4,s1
    80003b82:	9aee                	add	s5,s5,s11
    80003b84:	0569f763          	bgeu	s3,s6,80003bd2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b88:	000ba903          	lw	s2,0(s7)
    80003b8c:	00a4d59b          	srliw	a1,s1,0xa
    80003b90:	855e                	mv	a0,s7
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	8b0080e7          	jalr	-1872(ra) # 80003442 <bmap>
    80003b9a:	0005059b          	sext.w	a1,a0
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	4ae080e7          	jalr	1198(ra) # 8000304e <bread>
    80003ba8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003baa:	3ff4f713          	andi	a4,s1,1023
    80003bae:	40ed07bb          	subw	a5,s10,a4
    80003bb2:	413b06bb          	subw	a3,s6,s3
    80003bb6:	8a3e                	mv	s4,a5
    80003bb8:	2781                	sext.w	a5,a5
    80003bba:	0006861b          	sext.w	a2,a3
    80003bbe:	f8f679e3          	bgeu	a2,a5,80003b50 <readi+0x4c>
    80003bc2:	8a36                	mv	s4,a3
    80003bc4:	b771                	j	80003b50 <readi+0x4c>
      brelse(bp);
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	5b6080e7          	jalr	1462(ra) # 8000317e <brelse>
      tot = -1;
    80003bd0:	59fd                	li	s3,-1
  }
  return tot;
    80003bd2:	0009851b          	sext.w	a0,s3
}
    80003bd6:	70a6                	ld	ra,104(sp)
    80003bd8:	7406                	ld	s0,96(sp)
    80003bda:	64e6                	ld	s1,88(sp)
    80003bdc:	6946                	ld	s2,80(sp)
    80003bde:	69a6                	ld	s3,72(sp)
    80003be0:	6a06                	ld	s4,64(sp)
    80003be2:	7ae2                	ld	s5,56(sp)
    80003be4:	7b42                	ld	s6,48(sp)
    80003be6:	7ba2                	ld	s7,40(sp)
    80003be8:	7c02                	ld	s8,32(sp)
    80003bea:	6ce2                	ld	s9,24(sp)
    80003bec:	6d42                	ld	s10,16(sp)
    80003bee:	6da2                	ld	s11,8(sp)
    80003bf0:	6165                	addi	sp,sp,112
    80003bf2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf4:	89da                	mv	s3,s6
    80003bf6:	bff1                	j	80003bd2 <readi+0xce>
    return 0;
    80003bf8:	4501                	li	a0,0
}
    80003bfa:	8082                	ret

0000000080003bfc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bfc:	457c                	lw	a5,76(a0)
    80003bfe:	10d7e863          	bltu	a5,a3,80003d0e <writei+0x112>
{
    80003c02:	7159                	addi	sp,sp,-112
    80003c04:	f486                	sd	ra,104(sp)
    80003c06:	f0a2                	sd	s0,96(sp)
    80003c08:	eca6                	sd	s1,88(sp)
    80003c0a:	e8ca                	sd	s2,80(sp)
    80003c0c:	e4ce                	sd	s3,72(sp)
    80003c0e:	e0d2                	sd	s4,64(sp)
    80003c10:	fc56                	sd	s5,56(sp)
    80003c12:	f85a                	sd	s6,48(sp)
    80003c14:	f45e                	sd	s7,40(sp)
    80003c16:	f062                	sd	s8,32(sp)
    80003c18:	ec66                	sd	s9,24(sp)
    80003c1a:	e86a                	sd	s10,16(sp)
    80003c1c:	e46e                	sd	s11,8(sp)
    80003c1e:	1880                	addi	s0,sp,112
    80003c20:	8b2a                	mv	s6,a0
    80003c22:	8c2e                	mv	s8,a1
    80003c24:	8ab2                	mv	s5,a2
    80003c26:	8936                	mv	s2,a3
    80003c28:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c2a:	00e687bb          	addw	a5,a3,a4
    80003c2e:	0ed7e263          	bltu	a5,a3,80003d12 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c32:	00043737          	lui	a4,0x43
    80003c36:	0ef76063          	bltu	a4,a5,80003d16 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3a:	0c0b8863          	beqz	s7,80003d0a <writei+0x10e>
    80003c3e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c40:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c44:	5cfd                	li	s9,-1
    80003c46:	a091                	j	80003c8a <writei+0x8e>
    80003c48:	02099d93          	slli	s11,s3,0x20
    80003c4c:	020ddd93          	srli	s11,s11,0x20
    80003c50:	05848513          	addi	a0,s1,88
    80003c54:	86ee                	mv	a3,s11
    80003c56:	8656                	mv	a2,s5
    80003c58:	85e2                	mv	a1,s8
    80003c5a:	953a                	add	a0,a0,a4
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	84a080e7          	jalr	-1974(ra) # 800024a6 <either_copyin>
    80003c64:	07950263          	beq	a0,s9,80003cc8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c68:	8526                	mv	a0,s1
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	790080e7          	jalr	1936(ra) # 800043fa <log_write>
    brelse(bp);
    80003c72:	8526                	mv	a0,s1
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	50a080e7          	jalr	1290(ra) # 8000317e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7c:	01498a3b          	addw	s4,s3,s4
    80003c80:	0129893b          	addw	s2,s3,s2
    80003c84:	9aee                	add	s5,s5,s11
    80003c86:	057a7663          	bgeu	s4,s7,80003cd2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c8a:	000b2483          	lw	s1,0(s6)
    80003c8e:	00a9559b          	srliw	a1,s2,0xa
    80003c92:	855a                	mv	a0,s6
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	7ae080e7          	jalr	1966(ra) # 80003442 <bmap>
    80003c9c:	0005059b          	sext.w	a1,a0
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	3ac080e7          	jalr	940(ra) # 8000304e <bread>
    80003caa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cac:	3ff97713          	andi	a4,s2,1023
    80003cb0:	40ed07bb          	subw	a5,s10,a4
    80003cb4:	414b86bb          	subw	a3,s7,s4
    80003cb8:	89be                	mv	s3,a5
    80003cba:	2781                	sext.w	a5,a5
    80003cbc:	0006861b          	sext.w	a2,a3
    80003cc0:	f8f674e3          	bgeu	a2,a5,80003c48 <writei+0x4c>
    80003cc4:	89b6                	mv	s3,a3
    80003cc6:	b749                	j	80003c48 <writei+0x4c>
      brelse(bp);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	4b4080e7          	jalr	1204(ra) # 8000317e <brelse>
  }

  if(off > ip->size)
    80003cd2:	04cb2783          	lw	a5,76(s6)
    80003cd6:	0127f463          	bgeu	a5,s2,80003cde <writei+0xe2>
    ip->size = off;
    80003cda:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cde:	855a                	mv	a0,s6
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	aa6080e7          	jalr	-1370(ra) # 80003786 <iupdate>

  return tot;
    80003ce8:	000a051b          	sext.w	a0,s4
}
    80003cec:	70a6                	ld	ra,104(sp)
    80003cee:	7406                	ld	s0,96(sp)
    80003cf0:	64e6                	ld	s1,88(sp)
    80003cf2:	6946                	ld	s2,80(sp)
    80003cf4:	69a6                	ld	s3,72(sp)
    80003cf6:	6a06                	ld	s4,64(sp)
    80003cf8:	7ae2                	ld	s5,56(sp)
    80003cfa:	7b42                	ld	s6,48(sp)
    80003cfc:	7ba2                	ld	s7,40(sp)
    80003cfe:	7c02                	ld	s8,32(sp)
    80003d00:	6ce2                	ld	s9,24(sp)
    80003d02:	6d42                	ld	s10,16(sp)
    80003d04:	6da2                	ld	s11,8(sp)
    80003d06:	6165                	addi	sp,sp,112
    80003d08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0a:	8a5e                	mv	s4,s7
    80003d0c:	bfc9                	j	80003cde <writei+0xe2>
    return -1;
    80003d0e:	557d                	li	a0,-1
}
    80003d10:	8082                	ret
    return -1;
    80003d12:	557d                	li	a0,-1
    80003d14:	bfe1                	j	80003cec <writei+0xf0>
    return -1;
    80003d16:	557d                	li	a0,-1
    80003d18:	bfd1                	j	80003cec <writei+0xf0>

0000000080003d1a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d1a:	1141                	addi	sp,sp,-16
    80003d1c:	e406                	sd	ra,8(sp)
    80003d1e:	e022                	sd	s0,0(sp)
    80003d20:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d22:	4639                	li	a2,14
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	094080e7          	jalr	148(ra) # 80000db8 <strncmp>
}
    80003d2c:	60a2                	ld	ra,8(sp)
    80003d2e:	6402                	ld	s0,0(sp)
    80003d30:	0141                	addi	sp,sp,16
    80003d32:	8082                	ret

0000000080003d34 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d34:	7139                	addi	sp,sp,-64
    80003d36:	fc06                	sd	ra,56(sp)
    80003d38:	f822                	sd	s0,48(sp)
    80003d3a:	f426                	sd	s1,40(sp)
    80003d3c:	f04a                	sd	s2,32(sp)
    80003d3e:	ec4e                	sd	s3,24(sp)
    80003d40:	e852                	sd	s4,16(sp)
    80003d42:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d44:	04451703          	lh	a4,68(a0)
    80003d48:	4785                	li	a5,1
    80003d4a:	00f71a63          	bne	a4,a5,80003d5e <dirlookup+0x2a>
    80003d4e:	892a                	mv	s2,a0
    80003d50:	89ae                	mv	s3,a1
    80003d52:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d54:	457c                	lw	a5,76(a0)
    80003d56:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d58:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5a:	e79d                	bnez	a5,80003d88 <dirlookup+0x54>
    80003d5c:	a8a5                	j	80003dd4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d5e:	00005517          	auipc	a0,0x5
    80003d62:	9f250513          	addi	a0,a0,-1550 # 80008750 <syscalls+0x1b0>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d6e:	00005517          	auipc	a0,0x5
    80003d72:	9fa50513          	addi	a0,a0,-1542 # 80008768 <syscalls+0x1c8>
    80003d76:	ffffc097          	auipc	ra,0xffffc
    80003d7a:	7c8080e7          	jalr	1992(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7e:	24c1                	addiw	s1,s1,16
    80003d80:	04c92783          	lw	a5,76(s2)
    80003d84:	04f4f763          	bgeu	s1,a5,80003dd2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d88:	4741                	li	a4,16
    80003d8a:	86a6                	mv	a3,s1
    80003d8c:	fc040613          	addi	a2,s0,-64
    80003d90:	4581                	li	a1,0
    80003d92:	854a                	mv	a0,s2
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	d70080e7          	jalr	-656(ra) # 80003b04 <readi>
    80003d9c:	47c1                	li	a5,16
    80003d9e:	fcf518e3          	bne	a0,a5,80003d6e <dirlookup+0x3a>
    if(de.inum == 0)
    80003da2:	fc045783          	lhu	a5,-64(s0)
    80003da6:	dfe1                	beqz	a5,80003d7e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003da8:	fc240593          	addi	a1,s0,-62
    80003dac:	854e                	mv	a0,s3
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	f6c080e7          	jalr	-148(ra) # 80003d1a <namecmp>
    80003db6:	f561                	bnez	a0,80003d7e <dirlookup+0x4a>
      if(poff)
    80003db8:	000a0463          	beqz	s4,80003dc0 <dirlookup+0x8c>
        *poff = off;
    80003dbc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dc0:	fc045583          	lhu	a1,-64(s0)
    80003dc4:	00092503          	lw	a0,0(s2)
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	754080e7          	jalr	1876(ra) # 8000351c <iget>
    80003dd0:	a011                	j	80003dd4 <dirlookup+0xa0>
  return 0;
    80003dd2:	4501                	li	a0,0
}
    80003dd4:	70e2                	ld	ra,56(sp)
    80003dd6:	7442                	ld	s0,48(sp)
    80003dd8:	74a2                	ld	s1,40(sp)
    80003dda:	7902                	ld	s2,32(sp)
    80003ddc:	69e2                	ld	s3,24(sp)
    80003dde:	6a42                	ld	s4,16(sp)
    80003de0:	6121                	addi	sp,sp,64
    80003de2:	8082                	ret

0000000080003de4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de4:	711d                	addi	sp,sp,-96
    80003de6:	ec86                	sd	ra,88(sp)
    80003de8:	e8a2                	sd	s0,80(sp)
    80003dea:	e4a6                	sd	s1,72(sp)
    80003dec:	e0ca                	sd	s2,64(sp)
    80003dee:	fc4e                	sd	s3,56(sp)
    80003df0:	f852                	sd	s4,48(sp)
    80003df2:	f456                	sd	s5,40(sp)
    80003df4:	f05a                	sd	s6,32(sp)
    80003df6:	ec5e                	sd	s7,24(sp)
    80003df8:	e862                	sd	s8,16(sp)
    80003dfa:	e466                	sd	s9,8(sp)
    80003dfc:	1080                	addi	s0,sp,96
    80003dfe:	84aa                	mv	s1,a0
    80003e00:	8b2e                	mv	s6,a1
    80003e02:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e04:	00054703          	lbu	a4,0(a0)
    80003e08:	02f00793          	li	a5,47
    80003e0c:	02f70363          	beq	a4,a5,80003e32 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e10:	ffffe097          	auipc	ra,0xffffe
    80003e14:	ba0080e7          	jalr	-1120(ra) # 800019b0 <myproc>
    80003e18:	15053503          	ld	a0,336(a0)
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	9f6080e7          	jalr	-1546(ra) # 80003812 <idup>
    80003e24:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e26:	02f00913          	li	s2,47
  len = path - s;
    80003e2a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e2c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e2e:	4c05                	li	s8,1
    80003e30:	a865                	j	80003ee8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e32:	4585                	li	a1,1
    80003e34:	4505                	li	a0,1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	6e6080e7          	jalr	1766(ra) # 8000351c <iget>
    80003e3e:	89aa                	mv	s3,a0
    80003e40:	b7dd                	j	80003e26 <namex+0x42>
      iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	c6e080e7          	jalr	-914(ra) # 80003ab2 <iunlockput>
      return 0;
    80003e4c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e4e:	854e                	mv	a0,s3
    80003e50:	60e6                	ld	ra,88(sp)
    80003e52:	6446                	ld	s0,80(sp)
    80003e54:	64a6                	ld	s1,72(sp)
    80003e56:	6906                	ld	s2,64(sp)
    80003e58:	79e2                	ld	s3,56(sp)
    80003e5a:	7a42                	ld	s4,48(sp)
    80003e5c:	7aa2                	ld	s5,40(sp)
    80003e5e:	7b02                	ld	s6,32(sp)
    80003e60:	6be2                	ld	s7,24(sp)
    80003e62:	6c42                	ld	s8,16(sp)
    80003e64:	6ca2                	ld	s9,8(sp)
    80003e66:	6125                	addi	sp,sp,96
    80003e68:	8082                	ret
      iunlock(ip);
    80003e6a:	854e                	mv	a0,s3
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	aa6080e7          	jalr	-1370(ra) # 80003912 <iunlock>
      return ip;
    80003e74:	bfe9                	j	80003e4e <namex+0x6a>
      iunlockput(ip);
    80003e76:	854e                	mv	a0,s3
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	c3a080e7          	jalr	-966(ra) # 80003ab2 <iunlockput>
      return 0;
    80003e80:	89d2                	mv	s3,s4
    80003e82:	b7f1                	j	80003e4e <namex+0x6a>
  len = path - s;
    80003e84:	40b48633          	sub	a2,s1,a1
    80003e88:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e8c:	094cd463          	bge	s9,s4,80003f14 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e90:	4639                	li	a2,14
    80003e92:	8556                	mv	a0,s5
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	eac080e7          	jalr	-340(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	01279763          	bne	a5,s2,80003eae <namex+0xca>
    path++;
    80003ea4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ea6:	0004c783          	lbu	a5,0(s1)
    80003eaa:	ff278de3          	beq	a5,s2,80003ea4 <namex+0xc0>
    ilock(ip);
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	9a0080e7          	jalr	-1632(ra) # 80003850 <ilock>
    if(ip->type != T_DIR){
    80003eb8:	04499783          	lh	a5,68(s3)
    80003ebc:	f98793e3          	bne	a5,s8,80003e42 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ec0:	000b0563          	beqz	s6,80003eca <namex+0xe6>
    80003ec4:	0004c783          	lbu	a5,0(s1)
    80003ec8:	d3cd                	beqz	a5,80003e6a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eca:	865e                	mv	a2,s7
    80003ecc:	85d6                	mv	a1,s5
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	e64080e7          	jalr	-412(ra) # 80003d34 <dirlookup>
    80003ed8:	8a2a                	mv	s4,a0
    80003eda:	dd51                	beqz	a0,80003e76 <namex+0x92>
    iunlockput(ip);
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	bd4080e7          	jalr	-1068(ra) # 80003ab2 <iunlockput>
    ip = next;
    80003ee6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ee8:	0004c783          	lbu	a5,0(s1)
    80003eec:	05279763          	bne	a5,s2,80003f3a <namex+0x156>
    path++;
    80003ef0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef2:	0004c783          	lbu	a5,0(s1)
    80003ef6:	ff278de3          	beq	a5,s2,80003ef0 <namex+0x10c>
  if(*path == 0)
    80003efa:	c79d                	beqz	a5,80003f28 <namex+0x144>
    path++;
    80003efc:	85a6                	mv	a1,s1
  len = path - s;
    80003efe:	8a5e                	mv	s4,s7
    80003f00:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f02:	01278963          	beq	a5,s2,80003f14 <namex+0x130>
    80003f06:	dfbd                	beqz	a5,80003e84 <namex+0xa0>
    path++;
    80003f08:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f0a:	0004c783          	lbu	a5,0(s1)
    80003f0e:	ff279ce3          	bne	a5,s2,80003f06 <namex+0x122>
    80003f12:	bf8d                	j	80003e84 <namex+0xa0>
    memmove(name, s, len);
    80003f14:	2601                	sext.w	a2,a2
    80003f16:	8556                	mv	a0,s5
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	e28080e7          	jalr	-472(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f20:	9a56                	add	s4,s4,s5
    80003f22:	000a0023          	sb	zero,0(s4)
    80003f26:	bf9d                	j	80003e9c <namex+0xb8>
  if(nameiparent){
    80003f28:	f20b03e3          	beqz	s6,80003e4e <namex+0x6a>
    iput(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	adc080e7          	jalr	-1316(ra) # 80003a0a <iput>
    return 0;
    80003f36:	4981                	li	s3,0
    80003f38:	bf19                	j	80003e4e <namex+0x6a>
  if(*path == 0)
    80003f3a:	d7fd                	beqz	a5,80003f28 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f3c:	0004c783          	lbu	a5,0(s1)
    80003f40:	85a6                	mv	a1,s1
    80003f42:	b7d1                	j	80003f06 <namex+0x122>

0000000080003f44 <dirlink>:
{
    80003f44:	7139                	addi	sp,sp,-64
    80003f46:	fc06                	sd	ra,56(sp)
    80003f48:	f822                	sd	s0,48(sp)
    80003f4a:	f426                	sd	s1,40(sp)
    80003f4c:	f04a                	sd	s2,32(sp)
    80003f4e:	ec4e                	sd	s3,24(sp)
    80003f50:	e852                	sd	s4,16(sp)
    80003f52:	0080                	addi	s0,sp,64
    80003f54:	892a                	mv	s2,a0
    80003f56:	8a2e                	mv	s4,a1
    80003f58:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f5a:	4601                	li	a2,0
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	dd8080e7          	jalr	-552(ra) # 80003d34 <dirlookup>
    80003f64:	e93d                	bnez	a0,80003fda <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f66:	04c92483          	lw	s1,76(s2)
    80003f6a:	c49d                	beqz	s1,80003f98 <dirlink+0x54>
    80003f6c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f6e:	4741                	li	a4,16
    80003f70:	86a6                	mv	a3,s1
    80003f72:	fc040613          	addi	a2,s0,-64
    80003f76:	4581                	li	a1,0
    80003f78:	854a                	mv	a0,s2
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	b8a080e7          	jalr	-1142(ra) # 80003b04 <readi>
    80003f82:	47c1                	li	a5,16
    80003f84:	06f51163          	bne	a0,a5,80003fe6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f88:	fc045783          	lhu	a5,-64(s0)
    80003f8c:	c791                	beqz	a5,80003f98 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f8e:	24c1                	addiw	s1,s1,16
    80003f90:	04c92783          	lw	a5,76(s2)
    80003f94:	fcf4ede3          	bltu	s1,a5,80003f6e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f98:	4639                	li	a2,14
    80003f9a:	85d2                	mv	a1,s4
    80003f9c:	fc240513          	addi	a0,s0,-62
    80003fa0:	ffffd097          	auipc	ra,0xffffd
    80003fa4:	e54080e7          	jalr	-428(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fa8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fac:	4741                	li	a4,16
    80003fae:	86a6                	mv	a3,s1
    80003fb0:	fc040613          	addi	a2,s0,-64
    80003fb4:	4581                	li	a1,0
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	c44080e7          	jalr	-956(ra) # 80003bfc <writei>
    80003fc0:	872a                	mv	a4,a0
    80003fc2:	47c1                	li	a5,16
  return 0;
    80003fc4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc6:	02f71863          	bne	a4,a5,80003ff6 <dirlink+0xb2>
}
    80003fca:	70e2                	ld	ra,56(sp)
    80003fcc:	7442                	ld	s0,48(sp)
    80003fce:	74a2                	ld	s1,40(sp)
    80003fd0:	7902                	ld	s2,32(sp)
    80003fd2:	69e2                	ld	s3,24(sp)
    80003fd4:	6a42                	ld	s4,16(sp)
    80003fd6:	6121                	addi	sp,sp,64
    80003fd8:	8082                	ret
    iput(ip);
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	a30080e7          	jalr	-1488(ra) # 80003a0a <iput>
    return -1;
    80003fe2:	557d                	li	a0,-1
    80003fe4:	b7dd                	j	80003fca <dirlink+0x86>
      panic("dirlink read");
    80003fe6:	00004517          	auipc	a0,0x4
    80003fea:	79250513          	addi	a0,a0,1938 # 80008778 <syscalls+0x1d8>
    80003fee:	ffffc097          	auipc	ra,0xffffc
    80003ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    panic("dirlink");
    80003ff6:	00005517          	auipc	a0,0x5
    80003ffa:	88a50513          	addi	a0,a0,-1910 # 80008880 <syscalls+0x2e0>
    80003ffe:	ffffc097          	auipc	ra,0xffffc
    80004002:	540080e7          	jalr	1344(ra) # 8000053e <panic>

0000000080004006 <namei>:

struct inode*
namei(char *path)
{
    80004006:	1101                	addi	sp,sp,-32
    80004008:	ec06                	sd	ra,24(sp)
    8000400a:	e822                	sd	s0,16(sp)
    8000400c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000400e:	fe040613          	addi	a2,s0,-32
    80004012:	4581                	li	a1,0
    80004014:	00000097          	auipc	ra,0x0
    80004018:	dd0080e7          	jalr	-560(ra) # 80003de4 <namex>
}
    8000401c:	60e2                	ld	ra,24(sp)
    8000401e:	6442                	ld	s0,16(sp)
    80004020:	6105                	addi	sp,sp,32
    80004022:	8082                	ret

0000000080004024 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004024:	1141                	addi	sp,sp,-16
    80004026:	e406                	sd	ra,8(sp)
    80004028:	e022                	sd	s0,0(sp)
    8000402a:	0800                	addi	s0,sp,16
    8000402c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000402e:	4585                	li	a1,1
    80004030:	00000097          	auipc	ra,0x0
    80004034:	db4080e7          	jalr	-588(ra) # 80003de4 <namex>
}
    80004038:	60a2                	ld	ra,8(sp)
    8000403a:	6402                	ld	s0,0(sp)
    8000403c:	0141                	addi	sp,sp,16
    8000403e:	8082                	ret

0000000080004040 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004040:	1101                	addi	sp,sp,-32
    80004042:	ec06                	sd	ra,24(sp)
    80004044:	e822                	sd	s0,16(sp)
    80004046:	e426                	sd	s1,8(sp)
    80004048:	e04a                	sd	s2,0(sp)
    8000404a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000404c:	0001e917          	auipc	s2,0x1e
    80004050:	c2490913          	addi	s2,s2,-988 # 80021c70 <log>
    80004054:	01892583          	lw	a1,24(s2)
    80004058:	02892503          	lw	a0,40(s2)
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	ff2080e7          	jalr	-14(ra) # 8000304e <bread>
    80004064:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004066:	02c92683          	lw	a3,44(s2)
    8000406a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000406c:	02d05763          	blez	a3,8000409a <write_head+0x5a>
    80004070:	0001e797          	auipc	a5,0x1e
    80004074:	c3078793          	addi	a5,a5,-976 # 80021ca0 <log+0x30>
    80004078:	05c50713          	addi	a4,a0,92
    8000407c:	36fd                	addiw	a3,a3,-1
    8000407e:	1682                	slli	a3,a3,0x20
    80004080:	9281                	srli	a3,a3,0x20
    80004082:	068a                	slli	a3,a3,0x2
    80004084:	0001e617          	auipc	a2,0x1e
    80004088:	c2060613          	addi	a2,a2,-992 # 80021ca4 <log+0x34>
    8000408c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000408e:	4390                	lw	a2,0(a5)
    80004090:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004092:	0791                	addi	a5,a5,4
    80004094:	0711                	addi	a4,a4,4
    80004096:	fed79ce3          	bne	a5,a3,8000408e <write_head+0x4e>
  }
  bwrite(buf);
    8000409a:	8526                	mv	a0,s1
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	0a4080e7          	jalr	164(ra) # 80003140 <bwrite>
  brelse(buf);
    800040a4:	8526                	mv	a0,s1
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	0d8080e7          	jalr	216(ra) # 8000317e <brelse>
}
    800040ae:	60e2                	ld	ra,24(sp)
    800040b0:	6442                	ld	s0,16(sp)
    800040b2:	64a2                	ld	s1,8(sp)
    800040b4:	6902                	ld	s2,0(sp)
    800040b6:	6105                	addi	sp,sp,32
    800040b8:	8082                	ret

00000000800040ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ba:	0001e797          	auipc	a5,0x1e
    800040be:	be27a783          	lw	a5,-1054(a5) # 80021c9c <log+0x2c>
    800040c2:	0af05d63          	blez	a5,8000417c <install_trans+0xc2>
{
    800040c6:	7139                	addi	sp,sp,-64
    800040c8:	fc06                	sd	ra,56(sp)
    800040ca:	f822                	sd	s0,48(sp)
    800040cc:	f426                	sd	s1,40(sp)
    800040ce:	f04a                	sd	s2,32(sp)
    800040d0:	ec4e                	sd	s3,24(sp)
    800040d2:	e852                	sd	s4,16(sp)
    800040d4:	e456                	sd	s5,8(sp)
    800040d6:	e05a                	sd	s6,0(sp)
    800040d8:	0080                	addi	s0,sp,64
    800040da:	8b2a                	mv	s6,a0
    800040dc:	0001ea97          	auipc	s5,0x1e
    800040e0:	bc4a8a93          	addi	s5,s5,-1084 # 80021ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040e6:	0001e997          	auipc	s3,0x1e
    800040ea:	b8a98993          	addi	s3,s3,-1142 # 80021c70 <log>
    800040ee:	a035                	j	8000411a <install_trans+0x60>
      bunpin(dbuf);
    800040f0:	8526                	mv	a0,s1
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	166080e7          	jalr	358(ra) # 80003258 <bunpin>
    brelse(lbuf);
    800040fa:	854a                	mv	a0,s2
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	082080e7          	jalr	130(ra) # 8000317e <brelse>
    brelse(dbuf);
    80004104:	8526                	mv	a0,s1
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	078080e7          	jalr	120(ra) # 8000317e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410e:	2a05                	addiw	s4,s4,1
    80004110:	0a91                	addi	s5,s5,4
    80004112:	02c9a783          	lw	a5,44(s3)
    80004116:	04fa5963          	bge	s4,a5,80004168 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000411a:	0189a583          	lw	a1,24(s3)
    8000411e:	014585bb          	addw	a1,a1,s4
    80004122:	2585                	addiw	a1,a1,1
    80004124:	0289a503          	lw	a0,40(s3)
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	f26080e7          	jalr	-218(ra) # 8000304e <bread>
    80004130:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004132:	000aa583          	lw	a1,0(s5)
    80004136:	0289a503          	lw	a0,40(s3)
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	f14080e7          	jalr	-236(ra) # 8000304e <bread>
    80004142:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004144:	40000613          	li	a2,1024
    80004148:	05890593          	addi	a1,s2,88
    8000414c:	05850513          	addi	a0,a0,88
    80004150:	ffffd097          	auipc	ra,0xffffd
    80004154:	bf0080e7          	jalr	-1040(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004158:	8526                	mv	a0,s1
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	fe6080e7          	jalr	-26(ra) # 80003140 <bwrite>
    if(recovering == 0)
    80004162:	f80b1ce3          	bnez	s6,800040fa <install_trans+0x40>
    80004166:	b769                	j	800040f0 <install_trans+0x36>
}
    80004168:	70e2                	ld	ra,56(sp)
    8000416a:	7442                	ld	s0,48(sp)
    8000416c:	74a2                	ld	s1,40(sp)
    8000416e:	7902                	ld	s2,32(sp)
    80004170:	69e2                	ld	s3,24(sp)
    80004172:	6a42                	ld	s4,16(sp)
    80004174:	6aa2                	ld	s5,8(sp)
    80004176:	6b02                	ld	s6,0(sp)
    80004178:	6121                	addi	sp,sp,64
    8000417a:	8082                	ret
    8000417c:	8082                	ret

000000008000417e <initlog>:
{
    8000417e:	7179                	addi	sp,sp,-48
    80004180:	f406                	sd	ra,40(sp)
    80004182:	f022                	sd	s0,32(sp)
    80004184:	ec26                	sd	s1,24(sp)
    80004186:	e84a                	sd	s2,16(sp)
    80004188:	e44e                	sd	s3,8(sp)
    8000418a:	1800                	addi	s0,sp,48
    8000418c:	892a                	mv	s2,a0
    8000418e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004190:	0001e497          	auipc	s1,0x1e
    80004194:	ae048493          	addi	s1,s1,-1312 # 80021c70 <log>
    80004198:	00004597          	auipc	a1,0x4
    8000419c:	5f058593          	addi	a1,a1,1520 # 80008788 <syscalls+0x1e8>
    800041a0:	8526                	mv	a0,s1
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	9b2080e7          	jalr	-1614(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041aa:	0149a583          	lw	a1,20(s3)
    800041ae:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041b0:	0109a783          	lw	a5,16(s3)
    800041b4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041b6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041ba:	854a                	mv	a0,s2
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	e92080e7          	jalr	-366(ra) # 8000304e <bread>
  log.lh.n = lh->n;
    800041c4:	4d3c                	lw	a5,88(a0)
    800041c6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041c8:	02f05563          	blez	a5,800041f2 <initlog+0x74>
    800041cc:	05c50713          	addi	a4,a0,92
    800041d0:	0001e697          	auipc	a3,0x1e
    800041d4:	ad068693          	addi	a3,a3,-1328 # 80021ca0 <log+0x30>
    800041d8:	37fd                	addiw	a5,a5,-1
    800041da:	1782                	slli	a5,a5,0x20
    800041dc:	9381                	srli	a5,a5,0x20
    800041de:	078a                	slli	a5,a5,0x2
    800041e0:	06050613          	addi	a2,a0,96
    800041e4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041e6:	4310                	lw	a2,0(a4)
    800041e8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041ea:	0711                	addi	a4,a4,4
    800041ec:	0691                	addi	a3,a3,4
    800041ee:	fef71ce3          	bne	a4,a5,800041e6 <initlog+0x68>
  brelse(buf);
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	f8c080e7          	jalr	-116(ra) # 8000317e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041fa:	4505                	li	a0,1
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	ebe080e7          	jalr	-322(ra) # 800040ba <install_trans>
  log.lh.n = 0;
    80004204:	0001e797          	auipc	a5,0x1e
    80004208:	a807ac23          	sw	zero,-1384(a5) # 80021c9c <log+0x2c>
  write_head(); // clear the log
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	e34080e7          	jalr	-460(ra) # 80004040 <write_head>
}
    80004214:	70a2                	ld	ra,40(sp)
    80004216:	7402                	ld	s0,32(sp)
    80004218:	64e2                	ld	s1,24(sp)
    8000421a:	6942                	ld	s2,16(sp)
    8000421c:	69a2                	ld	s3,8(sp)
    8000421e:	6145                	addi	sp,sp,48
    80004220:	8082                	ret

0000000080004222 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004222:	1101                	addi	sp,sp,-32
    80004224:	ec06                	sd	ra,24(sp)
    80004226:	e822                	sd	s0,16(sp)
    80004228:	e426                	sd	s1,8(sp)
    8000422a:	e04a                	sd	s2,0(sp)
    8000422c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000422e:	0001e517          	auipc	a0,0x1e
    80004232:	a4250513          	addi	a0,a0,-1470 # 80021c70 <log>
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	9ae080e7          	jalr	-1618(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000423e:	0001e497          	auipc	s1,0x1e
    80004242:	a3248493          	addi	s1,s1,-1486 # 80021c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004246:	4979                	li	s2,30
    80004248:	a039                	j	80004256 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000424a:	85a6                	mv	a1,s1
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffe097          	auipc	ra,0xffffe
    80004252:	e5e080e7          	jalr	-418(ra) # 800020ac <sleep>
    if(log.committing){
    80004256:	50dc                	lw	a5,36(s1)
    80004258:	fbed                	bnez	a5,8000424a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000425a:	509c                	lw	a5,32(s1)
    8000425c:	0017871b          	addiw	a4,a5,1
    80004260:	0007069b          	sext.w	a3,a4
    80004264:	0027179b          	slliw	a5,a4,0x2
    80004268:	9fb9                	addw	a5,a5,a4
    8000426a:	0017979b          	slliw	a5,a5,0x1
    8000426e:	54d8                	lw	a4,44(s1)
    80004270:	9fb9                	addw	a5,a5,a4
    80004272:	00f95963          	bge	s2,a5,80004284 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004276:	85a6                	mv	a1,s1
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffe097          	auipc	ra,0xffffe
    8000427e:	e32080e7          	jalr	-462(ra) # 800020ac <sleep>
    80004282:	bfd1                	j	80004256 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004284:	0001e517          	auipc	a0,0x1e
    80004288:	9ec50513          	addi	a0,a0,-1556 # 80021c70 <log>
    8000428c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	a0a080e7          	jalr	-1526(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004296:	60e2                	ld	ra,24(sp)
    80004298:	6442                	ld	s0,16(sp)
    8000429a:	64a2                	ld	s1,8(sp)
    8000429c:	6902                	ld	s2,0(sp)
    8000429e:	6105                	addi	sp,sp,32
    800042a0:	8082                	ret

00000000800042a2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042a2:	7139                	addi	sp,sp,-64
    800042a4:	fc06                	sd	ra,56(sp)
    800042a6:	f822                	sd	s0,48(sp)
    800042a8:	f426                	sd	s1,40(sp)
    800042aa:	f04a                	sd	s2,32(sp)
    800042ac:	ec4e                	sd	s3,24(sp)
    800042ae:	e852                	sd	s4,16(sp)
    800042b0:	e456                	sd	s5,8(sp)
    800042b2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042b4:	0001e497          	auipc	s1,0x1e
    800042b8:	9bc48493          	addi	s1,s1,-1604 # 80021c70 <log>
    800042bc:	8526                	mv	a0,s1
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042c6:	509c                	lw	a5,32(s1)
    800042c8:	37fd                	addiw	a5,a5,-1
    800042ca:	0007891b          	sext.w	s2,a5
    800042ce:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042d0:	50dc                	lw	a5,36(s1)
    800042d2:	efb9                	bnez	a5,80004330 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042d4:	06091663          	bnez	s2,80004340 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042d8:	0001e497          	auipc	s1,0x1e
    800042dc:	99848493          	addi	s1,s1,-1640 # 80021c70 <log>
    800042e0:	4785                	li	a5,1
    800042e2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042e4:	8526                	mv	a0,s1
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	9b2080e7          	jalr	-1614(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042ee:	54dc                	lw	a5,44(s1)
    800042f0:	06f04763          	bgtz	a5,8000435e <end_op+0xbc>
    acquire(&log.lock);
    800042f4:	0001e497          	auipc	s1,0x1e
    800042f8:	97c48493          	addi	s1,s1,-1668 # 80021c70 <log>
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	8e6080e7          	jalr	-1818(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004306:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000430a:	8526                	mv	a0,s1
    8000430c:	ffffe097          	auipc	ra,0xffffe
    80004310:	f2c080e7          	jalr	-212(ra) # 80002238 <wakeup>
    release(&log.lock);
    80004314:	8526                	mv	a0,s1
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	982080e7          	jalr	-1662(ra) # 80000c98 <release>
}
    8000431e:	70e2                	ld	ra,56(sp)
    80004320:	7442                	ld	s0,48(sp)
    80004322:	74a2                	ld	s1,40(sp)
    80004324:	7902                	ld	s2,32(sp)
    80004326:	69e2                	ld	s3,24(sp)
    80004328:	6a42                	ld	s4,16(sp)
    8000432a:	6aa2                	ld	s5,8(sp)
    8000432c:	6121                	addi	sp,sp,64
    8000432e:	8082                	ret
    panic("log.committing");
    80004330:	00004517          	auipc	a0,0x4
    80004334:	46050513          	addi	a0,a0,1120 # 80008790 <syscalls+0x1f0>
    80004338:	ffffc097          	auipc	ra,0xffffc
    8000433c:	206080e7          	jalr	518(ra) # 8000053e <panic>
    wakeup(&log);
    80004340:	0001e497          	auipc	s1,0x1e
    80004344:	93048493          	addi	s1,s1,-1744 # 80021c70 <log>
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffe097          	auipc	ra,0xffffe
    8000434e:	eee080e7          	jalr	-274(ra) # 80002238 <wakeup>
  release(&log.lock);
    80004352:	8526                	mv	a0,s1
    80004354:	ffffd097          	auipc	ra,0xffffd
    80004358:	944080e7          	jalr	-1724(ra) # 80000c98 <release>
  if(do_commit){
    8000435c:	b7c9                	j	8000431e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000435e:	0001ea97          	auipc	s5,0x1e
    80004362:	942a8a93          	addi	s5,s5,-1726 # 80021ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004366:	0001ea17          	auipc	s4,0x1e
    8000436a:	90aa0a13          	addi	s4,s4,-1782 # 80021c70 <log>
    8000436e:	018a2583          	lw	a1,24(s4)
    80004372:	012585bb          	addw	a1,a1,s2
    80004376:	2585                	addiw	a1,a1,1
    80004378:	028a2503          	lw	a0,40(s4)
    8000437c:	fffff097          	auipc	ra,0xfffff
    80004380:	cd2080e7          	jalr	-814(ra) # 8000304e <bread>
    80004384:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004386:	000aa583          	lw	a1,0(s5)
    8000438a:	028a2503          	lw	a0,40(s4)
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	cc0080e7          	jalr	-832(ra) # 8000304e <bread>
    80004396:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004398:	40000613          	li	a2,1024
    8000439c:	05850593          	addi	a1,a0,88
    800043a0:	05848513          	addi	a0,s1,88
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	99c080e7          	jalr	-1636(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043ac:	8526                	mv	a0,s1
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	d92080e7          	jalr	-622(ra) # 80003140 <bwrite>
    brelse(from);
    800043b6:	854e                	mv	a0,s3
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	dc6080e7          	jalr	-570(ra) # 8000317e <brelse>
    brelse(to);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	dbc080e7          	jalr	-580(ra) # 8000317e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ca:	2905                	addiw	s2,s2,1
    800043cc:	0a91                	addi	s5,s5,4
    800043ce:	02ca2783          	lw	a5,44(s4)
    800043d2:	f8f94ee3          	blt	s2,a5,8000436e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	c6a080e7          	jalr	-918(ra) # 80004040 <write_head>
    install_trans(0); // Now install writes to home locations
    800043de:	4501                	li	a0,0
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	cda080e7          	jalr	-806(ra) # 800040ba <install_trans>
    log.lh.n = 0;
    800043e8:	0001e797          	auipc	a5,0x1e
    800043ec:	8a07aa23          	sw	zero,-1868(a5) # 80021c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	c50080e7          	jalr	-944(ra) # 80004040 <write_head>
    800043f8:	bdf5                	j	800042f4 <end_op+0x52>

00000000800043fa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043fa:	1101                	addi	sp,sp,-32
    800043fc:	ec06                	sd	ra,24(sp)
    800043fe:	e822                	sd	s0,16(sp)
    80004400:	e426                	sd	s1,8(sp)
    80004402:	e04a                	sd	s2,0(sp)
    80004404:	1000                	addi	s0,sp,32
    80004406:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004408:	0001e917          	auipc	s2,0x1e
    8000440c:	86890913          	addi	s2,s2,-1944 # 80021c70 <log>
    80004410:	854a                	mv	a0,s2
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	7d2080e7          	jalr	2002(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000441a:	02c92603          	lw	a2,44(s2)
    8000441e:	47f5                	li	a5,29
    80004420:	06c7c563          	blt	a5,a2,8000448a <log_write+0x90>
    80004424:	0001e797          	auipc	a5,0x1e
    80004428:	8687a783          	lw	a5,-1944(a5) # 80021c8c <log+0x1c>
    8000442c:	37fd                	addiw	a5,a5,-1
    8000442e:	04f65e63          	bge	a2,a5,8000448a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004432:	0001e797          	auipc	a5,0x1e
    80004436:	85e7a783          	lw	a5,-1954(a5) # 80021c90 <log+0x20>
    8000443a:	06f05063          	blez	a5,8000449a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000443e:	4781                	li	a5,0
    80004440:	06c05563          	blez	a2,800044aa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004444:	44cc                	lw	a1,12(s1)
    80004446:	0001e717          	auipc	a4,0x1e
    8000444a:	85a70713          	addi	a4,a4,-1958 # 80021ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000444e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004450:	4314                	lw	a3,0(a4)
    80004452:	04b68c63          	beq	a3,a1,800044aa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004456:	2785                	addiw	a5,a5,1
    80004458:	0711                	addi	a4,a4,4
    8000445a:	fef61be3          	bne	a2,a5,80004450 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000445e:	0621                	addi	a2,a2,8
    80004460:	060a                	slli	a2,a2,0x2
    80004462:	0001e797          	auipc	a5,0x1e
    80004466:	80e78793          	addi	a5,a5,-2034 # 80021c70 <log>
    8000446a:	963e                	add	a2,a2,a5
    8000446c:	44dc                	lw	a5,12(s1)
    8000446e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	daa080e7          	jalr	-598(ra) # 8000321c <bpin>
    log.lh.n++;
    8000447a:	0001d717          	auipc	a4,0x1d
    8000447e:	7f670713          	addi	a4,a4,2038 # 80021c70 <log>
    80004482:	575c                	lw	a5,44(a4)
    80004484:	2785                	addiw	a5,a5,1
    80004486:	d75c                	sw	a5,44(a4)
    80004488:	a835                	j	800044c4 <log_write+0xca>
    panic("too big a transaction");
    8000448a:	00004517          	auipc	a0,0x4
    8000448e:	31650513          	addi	a0,a0,790 # 800087a0 <syscalls+0x200>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	0ac080e7          	jalr	172(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000449a:	00004517          	auipc	a0,0x4
    8000449e:	31e50513          	addi	a0,a0,798 # 800087b8 <syscalls+0x218>
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	09c080e7          	jalr	156(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044aa:	00878713          	addi	a4,a5,8
    800044ae:	00271693          	slli	a3,a4,0x2
    800044b2:	0001d717          	auipc	a4,0x1d
    800044b6:	7be70713          	addi	a4,a4,1982 # 80021c70 <log>
    800044ba:	9736                	add	a4,a4,a3
    800044bc:	44d4                	lw	a3,12(s1)
    800044be:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044c0:	faf608e3          	beq	a2,a5,80004470 <log_write+0x76>
  }
  release(&log.lock);
    800044c4:	0001d517          	auipc	a0,0x1d
    800044c8:	7ac50513          	addi	a0,a0,1964 # 80021c70 <log>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044e0:	1101                	addi	sp,sp,-32
    800044e2:	ec06                	sd	ra,24(sp)
    800044e4:	e822                	sd	s0,16(sp)
    800044e6:	e426                	sd	s1,8(sp)
    800044e8:	e04a                	sd	s2,0(sp)
    800044ea:	1000                	addi	s0,sp,32
    800044ec:	84aa                	mv	s1,a0
    800044ee:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044f0:	00004597          	auipc	a1,0x4
    800044f4:	2e858593          	addi	a1,a1,744 # 800087d8 <syscalls+0x238>
    800044f8:	0521                	addi	a0,a0,8
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	65a080e7          	jalr	1626(ra) # 80000b54 <initlock>
  lk->name = name;
    80004502:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004506:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000450a:	0204a423          	sw	zero,40(s1)
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	64a2                	ld	s1,8(sp)
    80004514:	6902                	ld	s2,0(sp)
    80004516:	6105                	addi	sp,sp,32
    80004518:	8082                	ret

000000008000451a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000451a:	1101                	addi	sp,sp,-32
    8000451c:	ec06                	sd	ra,24(sp)
    8000451e:	e822                	sd	s0,16(sp)
    80004520:	e426                	sd	s1,8(sp)
    80004522:	e04a                	sd	s2,0(sp)
    80004524:	1000                	addi	s0,sp,32
    80004526:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004528:	00850913          	addi	s2,a0,8
    8000452c:	854a                	mv	a0,s2
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004536:	409c                	lw	a5,0(s1)
    80004538:	cb89                	beqz	a5,8000454a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000453a:	85ca                	mv	a1,s2
    8000453c:	8526                	mv	a0,s1
    8000453e:	ffffe097          	auipc	ra,0xffffe
    80004542:	b6e080e7          	jalr	-1170(ra) # 800020ac <sleep>
  while (lk->locked) {
    80004546:	409c                	lw	a5,0(s1)
    80004548:	fbed                	bnez	a5,8000453a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000454a:	4785                	li	a5,1
    8000454c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000454e:	ffffd097          	auipc	ra,0xffffd
    80004552:	462080e7          	jalr	1122(ra) # 800019b0 <myproc>
    80004556:	591c                	lw	a5,48(a0)
    80004558:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000455a:	854a                	mv	a0,s2
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	73c080e7          	jalr	1852(ra) # 80000c98 <release>
}
    80004564:	60e2                	ld	ra,24(sp)
    80004566:	6442                	ld	s0,16(sp)
    80004568:	64a2                	ld	s1,8(sp)
    8000456a:	6902                	ld	s2,0(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret

0000000080004570 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004570:	1101                	addi	sp,sp,-32
    80004572:	ec06                	sd	ra,24(sp)
    80004574:	e822                	sd	s0,16(sp)
    80004576:	e426                	sd	s1,8(sp)
    80004578:	e04a                	sd	s2,0(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000457e:	00850913          	addi	s2,a0,8
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000458c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004590:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004594:	8526                	mv	a0,s1
    80004596:	ffffe097          	auipc	ra,0xffffe
    8000459a:	ca2080e7          	jalr	-862(ra) # 80002238 <wakeup>
  release(&lk->lk);
    8000459e:	854a                	mv	a0,s2
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>
}
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	64a2                	ld	s1,8(sp)
    800045ae:	6902                	ld	s2,0(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret

00000000800045b4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045b4:	7179                	addi	sp,sp,-48
    800045b6:	f406                	sd	ra,40(sp)
    800045b8:	f022                	sd	s0,32(sp)
    800045ba:	ec26                	sd	s1,24(sp)
    800045bc:	e84a                	sd	s2,16(sp)
    800045be:	e44e                	sd	s3,8(sp)
    800045c0:	1800                	addi	s0,sp,48
    800045c2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045c4:	00850913          	addi	s2,a0,8
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	61a080e7          	jalr	1562(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d2:	409c                	lw	a5,0(s1)
    800045d4:	ef99                	bnez	a5,800045f2 <holdingsleep+0x3e>
    800045d6:	4481                	li	s1,0
  release(&lk->lk);
    800045d8:	854a                	mv	a0,s2
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
  return r;
}
    800045e2:	8526                	mv	a0,s1
    800045e4:	70a2                	ld	ra,40(sp)
    800045e6:	7402                	ld	s0,32(sp)
    800045e8:	64e2                	ld	s1,24(sp)
    800045ea:	6942                	ld	s2,16(sp)
    800045ec:	69a2                	ld	s3,8(sp)
    800045ee:	6145                	addi	sp,sp,48
    800045f0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045f2:	0284a983          	lw	s3,40(s1)
    800045f6:	ffffd097          	auipc	ra,0xffffd
    800045fa:	3ba080e7          	jalr	954(ra) # 800019b0 <myproc>
    800045fe:	5904                	lw	s1,48(a0)
    80004600:	413484b3          	sub	s1,s1,s3
    80004604:	0014b493          	seqz	s1,s1
    80004608:	bfc1                	j	800045d8 <holdingsleep+0x24>

000000008000460a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000460a:	1141                	addi	sp,sp,-16
    8000460c:	e406                	sd	ra,8(sp)
    8000460e:	e022                	sd	s0,0(sp)
    80004610:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004612:	00004597          	auipc	a1,0x4
    80004616:	1d658593          	addi	a1,a1,470 # 800087e8 <syscalls+0x248>
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	79e50513          	addi	a0,a0,1950 # 80021db8 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	532080e7          	jalr	1330(ra) # 80000b54 <initlock>
}
    8000462a:	60a2                	ld	ra,8(sp)
    8000462c:	6402                	ld	s0,0(sp)
    8000462e:	0141                	addi	sp,sp,16
    80004630:	8082                	ret

0000000080004632 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004632:	1101                	addi	sp,sp,-32
    80004634:	ec06                	sd	ra,24(sp)
    80004636:	e822                	sd	s0,16(sp)
    80004638:	e426                	sd	s1,8(sp)
    8000463a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000463c:	0001d517          	auipc	a0,0x1d
    80004640:	77c50513          	addi	a0,a0,1916 # 80021db8 <ftable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	5a0080e7          	jalr	1440(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000464c:	0001d497          	auipc	s1,0x1d
    80004650:	78448493          	addi	s1,s1,1924 # 80021dd0 <ftable+0x18>
    80004654:	0001e717          	auipc	a4,0x1e
    80004658:	71c70713          	addi	a4,a4,1820 # 80022d70 <ftable+0xfb8>
    if(f->ref == 0){
    8000465c:	40dc                	lw	a5,4(s1)
    8000465e:	cf99                	beqz	a5,8000467c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004660:	02848493          	addi	s1,s1,40
    80004664:	fee49ce3          	bne	s1,a4,8000465c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004668:	0001d517          	auipc	a0,0x1d
    8000466c:	75050513          	addi	a0,a0,1872 # 80021db8 <ftable>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	628080e7          	jalr	1576(ra) # 80000c98 <release>
  return 0;
    80004678:	4481                	li	s1,0
    8000467a:	a819                	j	80004690 <filealloc+0x5e>
      f->ref = 1;
    8000467c:	4785                	li	a5,1
    8000467e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004680:	0001d517          	auipc	a0,0x1d
    80004684:	73850513          	addi	a0,a0,1848 # 80021db8 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	610080e7          	jalr	1552(ra) # 80000c98 <release>
}
    80004690:	8526                	mv	a0,s1
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	64a2                	ld	s1,8(sp)
    80004698:	6105                	addi	sp,sp,32
    8000469a:	8082                	ret

000000008000469c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000469c:	1101                	addi	sp,sp,-32
    8000469e:	ec06                	sd	ra,24(sp)
    800046a0:	e822                	sd	s0,16(sp)
    800046a2:	e426                	sd	s1,8(sp)
    800046a4:	1000                	addi	s0,sp,32
    800046a6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046a8:	0001d517          	auipc	a0,0x1d
    800046ac:	71050513          	addi	a0,a0,1808 # 80021db8 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	534080e7          	jalr	1332(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046b8:	40dc                	lw	a5,4(s1)
    800046ba:	02f05263          	blez	a5,800046de <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046be:	2785                	addiw	a5,a5,1
    800046c0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046c2:	0001d517          	auipc	a0,0x1d
    800046c6:	6f650513          	addi	a0,a0,1782 # 80021db8 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
  return f;
}
    800046d2:	8526                	mv	a0,s1
    800046d4:	60e2                	ld	ra,24(sp)
    800046d6:	6442                	ld	s0,16(sp)
    800046d8:	64a2                	ld	s1,8(sp)
    800046da:	6105                	addi	sp,sp,32
    800046dc:	8082                	ret
    panic("filedup");
    800046de:	00004517          	auipc	a0,0x4
    800046e2:	11250513          	addi	a0,a0,274 # 800087f0 <syscalls+0x250>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	e58080e7          	jalr	-424(ra) # 8000053e <panic>

00000000800046ee <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046ee:	7139                	addi	sp,sp,-64
    800046f0:	fc06                	sd	ra,56(sp)
    800046f2:	f822                	sd	s0,48(sp)
    800046f4:	f426                	sd	s1,40(sp)
    800046f6:	f04a                	sd	s2,32(sp)
    800046f8:	ec4e                	sd	s3,24(sp)
    800046fa:	e852                	sd	s4,16(sp)
    800046fc:	e456                	sd	s5,8(sp)
    800046fe:	0080                	addi	s0,sp,64
    80004700:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	6b650513          	addi	a0,a0,1718 # 80021db8 <ftable>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004712:	40dc                	lw	a5,4(s1)
    80004714:	06f05163          	blez	a5,80004776 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004718:	37fd                	addiw	a5,a5,-1
    8000471a:	0007871b          	sext.w	a4,a5
    8000471e:	c0dc                	sw	a5,4(s1)
    80004720:	06e04363          	bgtz	a4,80004786 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004724:	0004a903          	lw	s2,0(s1)
    80004728:	0094ca83          	lbu	s5,9(s1)
    8000472c:	0104ba03          	ld	s4,16(s1)
    80004730:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004734:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004738:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000473c:	0001d517          	auipc	a0,0x1d
    80004740:	67c50513          	addi	a0,a0,1660 # 80021db8 <ftable>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	554080e7          	jalr	1364(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000474c:	4785                	li	a5,1
    8000474e:	04f90d63          	beq	s2,a5,800047a8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004752:	3979                	addiw	s2,s2,-2
    80004754:	4785                	li	a5,1
    80004756:	0527e063          	bltu	a5,s2,80004796 <fileclose+0xa8>
    begin_op();
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	ac8080e7          	jalr	-1336(ra) # 80004222 <begin_op>
    iput(ff.ip);
    80004762:	854e                	mv	a0,s3
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	2a6080e7          	jalr	678(ra) # 80003a0a <iput>
    end_op();
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	b36080e7          	jalr	-1226(ra) # 800042a2 <end_op>
    80004774:	a00d                	j	80004796 <fileclose+0xa8>
    panic("fileclose");
    80004776:	00004517          	auipc	a0,0x4
    8000477a:	08250513          	addi	a0,a0,130 # 800087f8 <syscalls+0x258>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	dc0080e7          	jalr	-576(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004786:	0001d517          	auipc	a0,0x1d
    8000478a:	63250513          	addi	a0,a0,1586 # 80021db8 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	50a080e7          	jalr	1290(ra) # 80000c98 <release>
  }
}
    80004796:	70e2                	ld	ra,56(sp)
    80004798:	7442                	ld	s0,48(sp)
    8000479a:	74a2                	ld	s1,40(sp)
    8000479c:	7902                	ld	s2,32(sp)
    8000479e:	69e2                	ld	s3,24(sp)
    800047a0:	6a42                	ld	s4,16(sp)
    800047a2:	6aa2                	ld	s5,8(sp)
    800047a4:	6121                	addi	sp,sp,64
    800047a6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047a8:	85d6                	mv	a1,s5
    800047aa:	8552                	mv	a0,s4
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	34c080e7          	jalr	844(ra) # 80004af8 <pipeclose>
    800047b4:	b7cd                	j	80004796 <fileclose+0xa8>

00000000800047b6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047b6:	715d                	addi	sp,sp,-80
    800047b8:	e486                	sd	ra,72(sp)
    800047ba:	e0a2                	sd	s0,64(sp)
    800047bc:	fc26                	sd	s1,56(sp)
    800047be:	f84a                	sd	s2,48(sp)
    800047c0:	f44e                	sd	s3,40(sp)
    800047c2:	0880                	addi	s0,sp,80
    800047c4:	84aa                	mv	s1,a0
    800047c6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047c8:	ffffd097          	auipc	ra,0xffffd
    800047cc:	1e8080e7          	jalr	488(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047d0:	409c                	lw	a5,0(s1)
    800047d2:	37f9                	addiw	a5,a5,-2
    800047d4:	4705                	li	a4,1
    800047d6:	04f76763          	bltu	a4,a5,80004824 <filestat+0x6e>
    800047da:	892a                	mv	s2,a0
    ilock(f->ip);
    800047dc:	6c88                	ld	a0,24(s1)
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	072080e7          	jalr	114(ra) # 80003850 <ilock>
    stati(f->ip, &st);
    800047e6:	fb840593          	addi	a1,s0,-72
    800047ea:	6c88                	ld	a0,24(s1)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	2ee080e7          	jalr	750(ra) # 80003ada <stati>
    iunlock(f->ip);
    800047f4:	6c88                	ld	a0,24(s1)
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	11c080e7          	jalr	284(ra) # 80003912 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047fe:	46e1                	li	a3,24
    80004800:	fb840613          	addi	a2,s0,-72
    80004804:	85ce                	mv	a1,s3
    80004806:	05093503          	ld	a0,80(s2)
    8000480a:	ffffd097          	auipc	ra,0xffffd
    8000480e:	e68080e7          	jalr	-408(ra) # 80001672 <copyout>
    80004812:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004816:	60a6                	ld	ra,72(sp)
    80004818:	6406                	ld	s0,64(sp)
    8000481a:	74e2                	ld	s1,56(sp)
    8000481c:	7942                	ld	s2,48(sp)
    8000481e:	79a2                	ld	s3,40(sp)
    80004820:	6161                	addi	sp,sp,80
    80004822:	8082                	ret
  return -1;
    80004824:	557d                	li	a0,-1
    80004826:	bfc5                	j	80004816 <filestat+0x60>

0000000080004828 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004828:	7179                	addi	sp,sp,-48
    8000482a:	f406                	sd	ra,40(sp)
    8000482c:	f022                	sd	s0,32(sp)
    8000482e:	ec26                	sd	s1,24(sp)
    80004830:	e84a                	sd	s2,16(sp)
    80004832:	e44e                	sd	s3,8(sp)
    80004834:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004836:	00854783          	lbu	a5,8(a0)
    8000483a:	c3d5                	beqz	a5,800048de <fileread+0xb6>
    8000483c:	84aa                	mv	s1,a0
    8000483e:	89ae                	mv	s3,a1
    80004840:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004842:	411c                	lw	a5,0(a0)
    80004844:	4705                	li	a4,1
    80004846:	04e78963          	beq	a5,a4,80004898 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000484a:	470d                	li	a4,3
    8000484c:	04e78d63          	beq	a5,a4,800048a6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004850:	4709                	li	a4,2
    80004852:	06e79e63          	bne	a5,a4,800048ce <fileread+0xa6>
    ilock(f->ip);
    80004856:	6d08                	ld	a0,24(a0)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	ff8080e7          	jalr	-8(ra) # 80003850 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004860:	874a                	mv	a4,s2
    80004862:	5094                	lw	a3,32(s1)
    80004864:	864e                	mv	a2,s3
    80004866:	4585                	li	a1,1
    80004868:	6c88                	ld	a0,24(s1)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	29a080e7          	jalr	666(ra) # 80003b04 <readi>
    80004872:	892a                	mv	s2,a0
    80004874:	00a05563          	blez	a0,8000487e <fileread+0x56>
      f->off += r;
    80004878:	509c                	lw	a5,32(s1)
    8000487a:	9fa9                	addw	a5,a5,a0
    8000487c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000487e:	6c88                	ld	a0,24(s1)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	092080e7          	jalr	146(ra) # 80003912 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004888:	854a                	mv	a0,s2
    8000488a:	70a2                	ld	ra,40(sp)
    8000488c:	7402                	ld	s0,32(sp)
    8000488e:	64e2                	ld	s1,24(sp)
    80004890:	6942                	ld	s2,16(sp)
    80004892:	69a2                	ld	s3,8(sp)
    80004894:	6145                	addi	sp,sp,48
    80004896:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004898:	6908                	ld	a0,16(a0)
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	3c8080e7          	jalr	968(ra) # 80004c62 <piperead>
    800048a2:	892a                	mv	s2,a0
    800048a4:	b7d5                	j	80004888 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048a6:	02451783          	lh	a5,36(a0)
    800048aa:	03079693          	slli	a3,a5,0x30
    800048ae:	92c1                	srli	a3,a3,0x30
    800048b0:	4725                	li	a4,9
    800048b2:	02d76863          	bltu	a4,a3,800048e2 <fileread+0xba>
    800048b6:	0792                	slli	a5,a5,0x4
    800048b8:	0001d717          	auipc	a4,0x1d
    800048bc:	46070713          	addi	a4,a4,1120 # 80021d18 <devsw>
    800048c0:	97ba                	add	a5,a5,a4
    800048c2:	639c                	ld	a5,0(a5)
    800048c4:	c38d                	beqz	a5,800048e6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048c6:	4505                	li	a0,1
    800048c8:	9782                	jalr	a5
    800048ca:	892a                	mv	s2,a0
    800048cc:	bf75                	j	80004888 <fileread+0x60>
    panic("fileread");
    800048ce:	00004517          	auipc	a0,0x4
    800048d2:	f3a50513          	addi	a0,a0,-198 # 80008808 <syscalls+0x268>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>
    return -1;
    800048de:	597d                	li	s2,-1
    800048e0:	b765                	j	80004888 <fileread+0x60>
      return -1;
    800048e2:	597d                	li	s2,-1
    800048e4:	b755                	j	80004888 <fileread+0x60>
    800048e6:	597d                	li	s2,-1
    800048e8:	b745                	j	80004888 <fileread+0x60>

00000000800048ea <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048ea:	715d                	addi	sp,sp,-80
    800048ec:	e486                	sd	ra,72(sp)
    800048ee:	e0a2                	sd	s0,64(sp)
    800048f0:	fc26                	sd	s1,56(sp)
    800048f2:	f84a                	sd	s2,48(sp)
    800048f4:	f44e                	sd	s3,40(sp)
    800048f6:	f052                	sd	s4,32(sp)
    800048f8:	ec56                	sd	s5,24(sp)
    800048fa:	e85a                	sd	s6,16(sp)
    800048fc:	e45e                	sd	s7,8(sp)
    800048fe:	e062                	sd	s8,0(sp)
    80004900:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004902:	00954783          	lbu	a5,9(a0)
    80004906:	10078663          	beqz	a5,80004a12 <filewrite+0x128>
    8000490a:	892a                	mv	s2,a0
    8000490c:	8aae                	mv	s5,a1
    8000490e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004910:	411c                	lw	a5,0(a0)
    80004912:	4705                	li	a4,1
    80004914:	02e78263          	beq	a5,a4,80004938 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004918:	470d                	li	a4,3
    8000491a:	02e78663          	beq	a5,a4,80004946 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000491e:	4709                	li	a4,2
    80004920:	0ee79163          	bne	a5,a4,80004a02 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004924:	0ac05d63          	blez	a2,800049de <filewrite+0xf4>
    int i = 0;
    80004928:	4981                	li	s3,0
    8000492a:	6b05                	lui	s6,0x1
    8000492c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004930:	6b85                	lui	s7,0x1
    80004932:	c00b8b9b          	addiw	s7,s7,-1024
    80004936:	a861                	j	800049ce <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004938:	6908                	ld	a0,16(a0)
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	22e080e7          	jalr	558(ra) # 80004b68 <pipewrite>
    80004942:	8a2a                	mv	s4,a0
    80004944:	a045                	j	800049e4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004946:	02451783          	lh	a5,36(a0)
    8000494a:	03079693          	slli	a3,a5,0x30
    8000494e:	92c1                	srli	a3,a3,0x30
    80004950:	4725                	li	a4,9
    80004952:	0cd76263          	bltu	a4,a3,80004a16 <filewrite+0x12c>
    80004956:	0792                	slli	a5,a5,0x4
    80004958:	0001d717          	auipc	a4,0x1d
    8000495c:	3c070713          	addi	a4,a4,960 # 80021d18 <devsw>
    80004960:	97ba                	add	a5,a5,a4
    80004962:	679c                	ld	a5,8(a5)
    80004964:	cbdd                	beqz	a5,80004a1a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004966:	4505                	li	a0,1
    80004968:	9782                	jalr	a5
    8000496a:	8a2a                	mv	s4,a0
    8000496c:	a8a5                	j	800049e4 <filewrite+0xfa>
    8000496e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004972:	00000097          	auipc	ra,0x0
    80004976:	8b0080e7          	jalr	-1872(ra) # 80004222 <begin_op>
      ilock(f->ip);
    8000497a:	01893503          	ld	a0,24(s2)
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	ed2080e7          	jalr	-302(ra) # 80003850 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004986:	8762                	mv	a4,s8
    80004988:	02092683          	lw	a3,32(s2)
    8000498c:	01598633          	add	a2,s3,s5
    80004990:	4585                	li	a1,1
    80004992:	01893503          	ld	a0,24(s2)
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	266080e7          	jalr	614(ra) # 80003bfc <writei>
    8000499e:	84aa                	mv	s1,a0
    800049a0:	00a05763          	blez	a0,800049ae <filewrite+0xc4>
        f->off += r;
    800049a4:	02092783          	lw	a5,32(s2)
    800049a8:	9fa9                	addw	a5,a5,a0
    800049aa:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049ae:	01893503          	ld	a0,24(s2)
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	f60080e7          	jalr	-160(ra) # 80003912 <iunlock>
      end_op();
    800049ba:	00000097          	auipc	ra,0x0
    800049be:	8e8080e7          	jalr	-1816(ra) # 800042a2 <end_op>

      if(r != n1){
    800049c2:	009c1f63          	bne	s8,s1,800049e0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049c6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049ca:	0149db63          	bge	s3,s4,800049e0 <filewrite+0xf6>
      int n1 = n - i;
    800049ce:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049d2:	84be                	mv	s1,a5
    800049d4:	2781                	sext.w	a5,a5
    800049d6:	f8fb5ce3          	bge	s6,a5,8000496e <filewrite+0x84>
    800049da:	84de                	mv	s1,s7
    800049dc:	bf49                	j	8000496e <filewrite+0x84>
    int i = 0;
    800049de:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049e0:	013a1f63          	bne	s4,s3,800049fe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049e4:	8552                	mv	a0,s4
    800049e6:	60a6                	ld	ra,72(sp)
    800049e8:	6406                	ld	s0,64(sp)
    800049ea:	74e2                	ld	s1,56(sp)
    800049ec:	7942                	ld	s2,48(sp)
    800049ee:	79a2                	ld	s3,40(sp)
    800049f0:	7a02                	ld	s4,32(sp)
    800049f2:	6ae2                	ld	s5,24(sp)
    800049f4:	6b42                	ld	s6,16(sp)
    800049f6:	6ba2                	ld	s7,8(sp)
    800049f8:	6c02                	ld	s8,0(sp)
    800049fa:	6161                	addi	sp,sp,80
    800049fc:	8082                	ret
    ret = (i == n ? n : -1);
    800049fe:	5a7d                	li	s4,-1
    80004a00:	b7d5                	j	800049e4 <filewrite+0xfa>
    panic("filewrite");
    80004a02:	00004517          	auipc	a0,0x4
    80004a06:	e1650513          	addi	a0,a0,-490 # 80008818 <syscalls+0x278>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>
    return -1;
    80004a12:	5a7d                	li	s4,-1
    80004a14:	bfc1                	j	800049e4 <filewrite+0xfa>
      return -1;
    80004a16:	5a7d                	li	s4,-1
    80004a18:	b7f1                	j	800049e4 <filewrite+0xfa>
    80004a1a:	5a7d                	li	s4,-1
    80004a1c:	b7e1                	j	800049e4 <filewrite+0xfa>

0000000080004a1e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a1e:	7179                	addi	sp,sp,-48
    80004a20:	f406                	sd	ra,40(sp)
    80004a22:	f022                	sd	s0,32(sp)
    80004a24:	ec26                	sd	s1,24(sp)
    80004a26:	e84a                	sd	s2,16(sp)
    80004a28:	e44e                	sd	s3,8(sp)
    80004a2a:	e052                	sd	s4,0(sp)
    80004a2c:	1800                	addi	s0,sp,48
    80004a2e:	84aa                	mv	s1,a0
    80004a30:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a32:	0005b023          	sd	zero,0(a1)
    80004a36:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	bf8080e7          	jalr	-1032(ra) # 80004632 <filealloc>
    80004a42:	e088                	sd	a0,0(s1)
    80004a44:	c551                	beqz	a0,80004ad0 <pipealloc+0xb2>
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	bec080e7          	jalr	-1044(ra) # 80004632 <filealloc>
    80004a4e:	00aa3023          	sd	a0,0(s4)
    80004a52:	c92d                	beqz	a0,80004ac4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	0a0080e7          	jalr	160(ra) # 80000af4 <kalloc>
    80004a5c:	892a                	mv	s2,a0
    80004a5e:	c125                	beqz	a0,80004abe <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a60:	4985                	li	s3,1
    80004a62:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a66:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a6a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a6e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a72:	00004597          	auipc	a1,0x4
    80004a76:	a7658593          	addi	a1,a1,-1418 # 800084e8 <states.1723+0x1b8>
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	0da080e7          	jalr	218(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a82:	609c                	ld	a5,0(s1)
    80004a84:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a88:	609c                	ld	a5,0(s1)
    80004a8a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a8e:	609c                	ld	a5,0(s1)
    80004a90:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a94:	609c                	ld	a5,0(s1)
    80004a96:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a9a:	000a3783          	ld	a5,0(s4)
    80004a9e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aa2:	000a3783          	ld	a5,0(s4)
    80004aa6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aaa:	000a3783          	ld	a5,0(s4)
    80004aae:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ab2:	000a3783          	ld	a5,0(s4)
    80004ab6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aba:	4501                	li	a0,0
    80004abc:	a025                	j	80004ae4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004abe:	6088                	ld	a0,0(s1)
    80004ac0:	e501                	bnez	a0,80004ac8 <pipealloc+0xaa>
    80004ac2:	a039                	j	80004ad0 <pipealloc+0xb2>
    80004ac4:	6088                	ld	a0,0(s1)
    80004ac6:	c51d                	beqz	a0,80004af4 <pipealloc+0xd6>
    fileclose(*f0);
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	c26080e7          	jalr	-986(ra) # 800046ee <fileclose>
  if(*f1)
    80004ad0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ad4:	557d                	li	a0,-1
  if(*f1)
    80004ad6:	c799                	beqz	a5,80004ae4 <pipealloc+0xc6>
    fileclose(*f1);
    80004ad8:	853e                	mv	a0,a5
    80004ada:	00000097          	auipc	ra,0x0
    80004ade:	c14080e7          	jalr	-1004(ra) # 800046ee <fileclose>
  return -1;
    80004ae2:	557d                	li	a0,-1
}
    80004ae4:	70a2                	ld	ra,40(sp)
    80004ae6:	7402                	ld	s0,32(sp)
    80004ae8:	64e2                	ld	s1,24(sp)
    80004aea:	6942                	ld	s2,16(sp)
    80004aec:	69a2                	ld	s3,8(sp)
    80004aee:	6a02                	ld	s4,0(sp)
    80004af0:	6145                	addi	sp,sp,48
    80004af2:	8082                	ret
  return -1;
    80004af4:	557d                	li	a0,-1
    80004af6:	b7fd                	j	80004ae4 <pipealloc+0xc6>

0000000080004af8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004af8:	1101                	addi	sp,sp,-32
    80004afa:	ec06                	sd	ra,24(sp)
    80004afc:	e822                	sd	s0,16(sp)
    80004afe:	e426                	sd	s1,8(sp)
    80004b00:	e04a                	sd	s2,0(sp)
    80004b02:	1000                	addi	s0,sp,32
    80004b04:	84aa                	mv	s1,a0
    80004b06:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  if(writable){
    80004b10:	02090d63          	beqz	s2,80004b4a <pipeclose+0x52>
    pi->writeopen = 0;
    80004b14:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b18:	21848513          	addi	a0,s1,536
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	71c080e7          	jalr	1820(ra) # 80002238 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b24:	2204b783          	ld	a5,544(s1)
    80004b28:	eb95                	bnez	a5,80004b5c <pipeclose+0x64>
    release(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16c080e7          	jalr	364(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	ec2080e7          	jalr	-318(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6902                	ld	s2,0(sp)
    80004b46:	6105                	addi	sp,sp,32
    80004b48:	8082                	ret
    pi->readopen = 0;
    80004b4a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b4e:	21c48513          	addi	a0,s1,540
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	6e6080e7          	jalr	1766(ra) # 80002238 <wakeup>
    80004b5a:	b7e9                	j	80004b24 <pipeclose+0x2c>
    release(&pi->lock);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	13a080e7          	jalr	314(ra) # 80000c98 <release>
}
    80004b66:	bfe1                	j	80004b3e <pipeclose+0x46>

0000000080004b68 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b68:	7159                	addi	sp,sp,-112
    80004b6a:	f486                	sd	ra,104(sp)
    80004b6c:	f0a2                	sd	s0,96(sp)
    80004b6e:	eca6                	sd	s1,88(sp)
    80004b70:	e8ca                	sd	s2,80(sp)
    80004b72:	e4ce                	sd	s3,72(sp)
    80004b74:	e0d2                	sd	s4,64(sp)
    80004b76:	fc56                	sd	s5,56(sp)
    80004b78:	f85a                	sd	s6,48(sp)
    80004b7a:	f45e                	sd	s7,40(sp)
    80004b7c:	f062                	sd	s8,32(sp)
    80004b7e:	ec66                	sd	s9,24(sp)
    80004b80:	1880                	addi	s0,sp,112
    80004b82:	84aa                	mv	s1,a0
    80004b84:	8aae                	mv	s5,a1
    80004b86:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	e28080e7          	jalr	-472(ra) # 800019b0 <myproc>
    80004b90:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	050080e7          	jalr	80(ra) # 80000be4 <acquire>
  while(i < n){
    80004b9c:	0d405163          	blez	s4,80004c5e <pipewrite+0xf6>
    80004ba0:	8ba6                	mv	s7,s1
  int i = 0;
    80004ba2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ba6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004baa:	21c48c13          	addi	s8,s1,540
    80004bae:	a08d                	j	80004c10 <pipewrite+0xa8>
      release(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
      return -1;
    80004bba:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bbc:	854a                	mv	a0,s2
    80004bbe:	70a6                	ld	ra,104(sp)
    80004bc0:	7406                	ld	s0,96(sp)
    80004bc2:	64e6                	ld	s1,88(sp)
    80004bc4:	6946                	ld	s2,80(sp)
    80004bc6:	69a6                	ld	s3,72(sp)
    80004bc8:	6a06                	ld	s4,64(sp)
    80004bca:	7ae2                	ld	s5,56(sp)
    80004bcc:	7b42                	ld	s6,48(sp)
    80004bce:	7ba2                	ld	s7,40(sp)
    80004bd0:	7c02                	ld	s8,32(sp)
    80004bd2:	6ce2                	ld	s9,24(sp)
    80004bd4:	6165                	addi	sp,sp,112
    80004bd6:	8082                	ret
      wakeup(&pi->nread);
    80004bd8:	8566                	mv	a0,s9
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	65e080e7          	jalr	1630(ra) # 80002238 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004be2:	85de                	mv	a1,s7
    80004be4:	8562                	mv	a0,s8
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	4c6080e7          	jalr	1222(ra) # 800020ac <sleep>
    80004bee:	a839                	j	80004c0c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bf0:	21c4a783          	lw	a5,540(s1)
    80004bf4:	0017871b          	addiw	a4,a5,1
    80004bf8:	20e4ae23          	sw	a4,540(s1)
    80004bfc:	1ff7f793          	andi	a5,a5,511
    80004c00:	97a6                	add	a5,a5,s1
    80004c02:	f9f44703          	lbu	a4,-97(s0)
    80004c06:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c0a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c0c:	03495d63          	bge	s2,s4,80004c46 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c10:	2204a783          	lw	a5,544(s1)
    80004c14:	dfd1                	beqz	a5,80004bb0 <pipewrite+0x48>
    80004c16:	0289a783          	lw	a5,40(s3)
    80004c1a:	fbd9                	bnez	a5,80004bb0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c1c:	2184a783          	lw	a5,536(s1)
    80004c20:	21c4a703          	lw	a4,540(s1)
    80004c24:	2007879b          	addiw	a5,a5,512
    80004c28:	faf708e3          	beq	a4,a5,80004bd8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c2c:	4685                	li	a3,1
    80004c2e:	01590633          	add	a2,s2,s5
    80004c32:	f9f40593          	addi	a1,s0,-97
    80004c36:	0509b503          	ld	a0,80(s3)
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	ac4080e7          	jalr	-1340(ra) # 800016fe <copyin>
    80004c42:	fb6517e3          	bne	a0,s6,80004bf0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c46:	21848513          	addi	a0,s1,536
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	5ee080e7          	jalr	1518(ra) # 80002238 <wakeup>
  release(&pi->lock);
    80004c52:	8526                	mv	a0,s1
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	044080e7          	jalr	68(ra) # 80000c98 <release>
  return i;
    80004c5c:	b785                	j	80004bbc <pipewrite+0x54>
  int i = 0;
    80004c5e:	4901                	li	s2,0
    80004c60:	b7dd                	j	80004c46 <pipewrite+0xde>

0000000080004c62 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c62:	715d                	addi	sp,sp,-80
    80004c64:	e486                	sd	ra,72(sp)
    80004c66:	e0a2                	sd	s0,64(sp)
    80004c68:	fc26                	sd	s1,56(sp)
    80004c6a:	f84a                	sd	s2,48(sp)
    80004c6c:	f44e                	sd	s3,40(sp)
    80004c6e:	f052                	sd	s4,32(sp)
    80004c70:	ec56                	sd	s5,24(sp)
    80004c72:	e85a                	sd	s6,16(sp)
    80004c74:	0880                	addi	s0,sp,80
    80004c76:	84aa                	mv	s1,a0
    80004c78:	892e                	mv	s2,a1
    80004c7a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	d34080e7          	jalr	-716(ra) # 800019b0 <myproc>
    80004c84:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c86:	8b26                	mv	s6,s1
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	f5a080e7          	jalr	-166(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c92:	2184a703          	lw	a4,536(s1)
    80004c96:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c9a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c9e:	02f71463          	bne	a4,a5,80004cc6 <piperead+0x64>
    80004ca2:	2244a783          	lw	a5,548(s1)
    80004ca6:	c385                	beqz	a5,80004cc6 <piperead+0x64>
    if(pr->killed){
    80004ca8:	028a2783          	lw	a5,40(s4)
    80004cac:	ebc1                	bnez	a5,80004d3c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cae:	85da                	mv	a1,s6
    80004cb0:	854e                	mv	a0,s3
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	3fa080e7          	jalr	1018(ra) # 800020ac <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cba:	2184a703          	lw	a4,536(s1)
    80004cbe:	21c4a783          	lw	a5,540(s1)
    80004cc2:	fef700e3          	beq	a4,a5,80004ca2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc6:	09505263          	blez	s5,80004d4a <piperead+0xe8>
    80004cca:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ccc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cce:	2184a783          	lw	a5,536(s1)
    80004cd2:	21c4a703          	lw	a4,540(s1)
    80004cd6:	02f70d63          	beq	a4,a5,80004d10 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cda:	0017871b          	addiw	a4,a5,1
    80004cde:	20e4ac23          	sw	a4,536(s1)
    80004ce2:	1ff7f793          	andi	a5,a5,511
    80004ce6:	97a6                	add	a5,a5,s1
    80004ce8:	0187c783          	lbu	a5,24(a5)
    80004cec:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf0:	4685                	li	a3,1
    80004cf2:	fbf40613          	addi	a2,s0,-65
    80004cf6:	85ca                	mv	a1,s2
    80004cf8:	050a3503          	ld	a0,80(s4)
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	976080e7          	jalr	-1674(ra) # 80001672 <copyout>
    80004d04:	01650663          	beq	a0,s6,80004d10 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d08:	2985                	addiw	s3,s3,1
    80004d0a:	0905                	addi	s2,s2,1
    80004d0c:	fd3a91e3          	bne	s5,s3,80004cce <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d10:	21c48513          	addi	a0,s1,540
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	524080e7          	jalr	1316(ra) # 80002238 <wakeup>
  release(&pi->lock);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	f7a080e7          	jalr	-134(ra) # 80000c98 <release>
  return i;
}
    80004d26:	854e                	mv	a0,s3
    80004d28:	60a6                	ld	ra,72(sp)
    80004d2a:	6406                	ld	s0,64(sp)
    80004d2c:	74e2                	ld	s1,56(sp)
    80004d2e:	7942                	ld	s2,48(sp)
    80004d30:	79a2                	ld	s3,40(sp)
    80004d32:	7a02                	ld	s4,32(sp)
    80004d34:	6ae2                	ld	s5,24(sp)
    80004d36:	6b42                	ld	s6,16(sp)
    80004d38:	6161                	addi	sp,sp,80
    80004d3a:	8082                	ret
      release(&pi->lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
      return -1;
    80004d46:	59fd                	li	s3,-1
    80004d48:	bff9                	j	80004d26 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d4a:	4981                	li	s3,0
    80004d4c:	b7d1                	j	80004d10 <piperead+0xae>

0000000080004d4e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d4e:	df010113          	addi	sp,sp,-528
    80004d52:	20113423          	sd	ra,520(sp)
    80004d56:	20813023          	sd	s0,512(sp)
    80004d5a:	ffa6                	sd	s1,504(sp)
    80004d5c:	fbca                	sd	s2,496(sp)
    80004d5e:	f7ce                	sd	s3,488(sp)
    80004d60:	f3d2                	sd	s4,480(sp)
    80004d62:	efd6                	sd	s5,472(sp)
    80004d64:	ebda                	sd	s6,464(sp)
    80004d66:	e7de                	sd	s7,456(sp)
    80004d68:	e3e2                	sd	s8,448(sp)
    80004d6a:	ff66                	sd	s9,440(sp)
    80004d6c:	fb6a                	sd	s10,432(sp)
    80004d6e:	f76e                	sd	s11,424(sp)
    80004d70:	0c00                	addi	s0,sp,528
    80004d72:	84aa                	mv	s1,a0
    80004d74:	dea43c23          	sd	a0,-520(s0)
    80004d78:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	c34080e7          	jalr	-972(ra) # 800019b0 <myproc>
    80004d84:	892a                	mv	s2,a0

  begin_op();
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	49c080e7          	jalr	1180(ra) # 80004222 <begin_op>

  if((ip = namei(path)) == 0){
    80004d8e:	8526                	mv	a0,s1
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	276080e7          	jalr	630(ra) # 80004006 <namei>
    80004d98:	c92d                	beqz	a0,80004e0a <exec+0xbc>
    80004d9a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	ab4080e7          	jalr	-1356(ra) # 80003850 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004da4:	04000713          	li	a4,64
    80004da8:	4681                	li	a3,0
    80004daa:	e5040613          	addi	a2,s0,-432
    80004dae:	4581                	li	a1,0
    80004db0:	8526                	mv	a0,s1
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	d52080e7          	jalr	-686(ra) # 80003b04 <readi>
    80004dba:	04000793          	li	a5,64
    80004dbe:	00f51a63          	bne	a0,a5,80004dd2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dc2:	e5042703          	lw	a4,-432(s0)
    80004dc6:	464c47b7          	lui	a5,0x464c4
    80004dca:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dce:	04f70463          	beq	a4,a5,80004e16 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	cde080e7          	jalr	-802(ra) # 80003ab2 <iunlockput>
    end_op();
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	4c6080e7          	jalr	1222(ra) # 800042a2 <end_op>
  }
  return -1;
    80004de4:	557d                	li	a0,-1
}
    80004de6:	20813083          	ld	ra,520(sp)
    80004dea:	20013403          	ld	s0,512(sp)
    80004dee:	74fe                	ld	s1,504(sp)
    80004df0:	795e                	ld	s2,496(sp)
    80004df2:	79be                	ld	s3,488(sp)
    80004df4:	7a1e                	ld	s4,480(sp)
    80004df6:	6afe                	ld	s5,472(sp)
    80004df8:	6b5e                	ld	s6,464(sp)
    80004dfa:	6bbe                	ld	s7,456(sp)
    80004dfc:	6c1e                	ld	s8,448(sp)
    80004dfe:	7cfa                	ld	s9,440(sp)
    80004e00:	7d5a                	ld	s10,432(sp)
    80004e02:	7dba                	ld	s11,424(sp)
    80004e04:	21010113          	addi	sp,sp,528
    80004e08:	8082                	ret
    end_op();
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	498080e7          	jalr	1176(ra) # 800042a2 <end_op>
    return -1;
    80004e12:	557d                	li	a0,-1
    80004e14:	bfc9                	j	80004de6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e16:	854a                	mv	a0,s2
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	c5c080e7          	jalr	-932(ra) # 80001a74 <proc_pagetable>
    80004e20:	8baa                	mv	s7,a0
    80004e22:	d945                	beqz	a0,80004dd2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e24:	e7042983          	lw	s3,-400(s0)
    80004e28:	e8845783          	lhu	a5,-376(s0)
    80004e2c:	c7ad                	beqz	a5,80004e96 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e30:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e32:	6c85                	lui	s9,0x1
    80004e34:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e38:	def43823          	sd	a5,-528(s0)
    80004e3c:	a42d                	j	80005066 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e3e:	00004517          	auipc	a0,0x4
    80004e42:	9ea50513          	addi	a0,a0,-1558 # 80008828 <syscalls+0x288>
    80004e46:	ffffb097          	auipc	ra,0xffffb
    80004e4a:	6f8080e7          	jalr	1784(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e4e:	8756                	mv	a4,s5
    80004e50:	012d86bb          	addw	a3,s11,s2
    80004e54:	4581                	li	a1,0
    80004e56:	8526                	mv	a0,s1
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	cac080e7          	jalr	-852(ra) # 80003b04 <readi>
    80004e60:	2501                	sext.w	a0,a0
    80004e62:	1aaa9963          	bne	s5,a0,80005014 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e66:	6785                	lui	a5,0x1
    80004e68:	0127893b          	addw	s2,a5,s2
    80004e6c:	77fd                	lui	a5,0xfffff
    80004e6e:	01478a3b          	addw	s4,a5,s4
    80004e72:	1f897163          	bgeu	s2,s8,80005054 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e76:	02091593          	slli	a1,s2,0x20
    80004e7a:	9181                	srli	a1,a1,0x20
    80004e7c:	95ea                	add	a1,a1,s10
    80004e7e:	855e                	mv	a0,s7
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	1ee080e7          	jalr	494(ra) # 8000106e <walkaddr>
    80004e88:	862a                	mv	a2,a0
    if(pa == 0)
    80004e8a:	d955                	beqz	a0,80004e3e <exec+0xf0>
      n = PGSIZE;
    80004e8c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e8e:	fd9a70e3          	bgeu	s4,s9,80004e4e <exec+0x100>
      n = sz - i;
    80004e92:	8ad2                	mv	s5,s4
    80004e94:	bf6d                	j	80004e4e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e96:	4901                	li	s2,0
  iunlockput(ip);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	c18080e7          	jalr	-1000(ra) # 80003ab2 <iunlockput>
  end_op();
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	400080e7          	jalr	1024(ra) # 800042a2 <end_op>
  p = myproc();
    80004eaa:	ffffd097          	auipc	ra,0xffffd
    80004eae:	b06080e7          	jalr	-1274(ra) # 800019b0 <myproc>
    80004eb2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eb4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eb8:	6785                	lui	a5,0x1
    80004eba:	17fd                	addi	a5,a5,-1
    80004ebc:	993e                	add	s2,s2,a5
    80004ebe:	757d                	lui	a0,0xfffff
    80004ec0:	00a977b3          	and	a5,s2,a0
    80004ec4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ec8:	6609                	lui	a2,0x2
    80004eca:	963e                	add	a2,a2,a5
    80004ecc:	85be                	mv	a1,a5
    80004ece:	855e                	mv	a0,s7
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	552080e7          	jalr	1362(ra) # 80001422 <uvmalloc>
    80004ed8:	8b2a                	mv	s6,a0
  ip = 0;
    80004eda:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004edc:	12050c63          	beqz	a0,80005014 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ee0:	75f9                	lui	a1,0xffffe
    80004ee2:	95aa                	add	a1,a1,a0
    80004ee4:	855e                	mv	a0,s7
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	75a080e7          	jalr	1882(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004eee:	7c7d                	lui	s8,0xfffff
    80004ef0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ef2:	e0043783          	ld	a5,-512(s0)
    80004ef6:	6388                	ld	a0,0(a5)
    80004ef8:	c535                	beqz	a0,80004f64 <exec+0x216>
    80004efa:	e9040993          	addi	s3,s0,-368
    80004efe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f02:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	f60080e7          	jalr	-160(ra) # 80000e64 <strlen>
    80004f0c:	2505                	addiw	a0,a0,1
    80004f0e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f12:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f16:	13896363          	bltu	s2,s8,8000503c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f1a:	e0043d83          	ld	s11,-512(s0)
    80004f1e:	000dba03          	ld	s4,0(s11)
    80004f22:	8552                	mv	a0,s4
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	f40080e7          	jalr	-192(ra) # 80000e64 <strlen>
    80004f2c:	0015069b          	addiw	a3,a0,1
    80004f30:	8652                	mv	a2,s4
    80004f32:	85ca                	mv	a1,s2
    80004f34:	855e                	mv	a0,s7
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	73c080e7          	jalr	1852(ra) # 80001672 <copyout>
    80004f3e:	10054363          	bltz	a0,80005044 <exec+0x2f6>
    ustack[argc] = sp;
    80004f42:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f46:	0485                	addi	s1,s1,1
    80004f48:	008d8793          	addi	a5,s11,8
    80004f4c:	e0f43023          	sd	a5,-512(s0)
    80004f50:	008db503          	ld	a0,8(s11)
    80004f54:	c911                	beqz	a0,80004f68 <exec+0x21a>
    if(argc >= MAXARG)
    80004f56:	09a1                	addi	s3,s3,8
    80004f58:	fb3c96e3          	bne	s9,s3,80004f04 <exec+0x1b6>
  sz = sz1;
    80004f5c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f60:	4481                	li	s1,0
    80004f62:	a84d                	j	80005014 <exec+0x2c6>
  sp = sz;
    80004f64:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f66:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f68:	00349793          	slli	a5,s1,0x3
    80004f6c:	f9040713          	addi	a4,s0,-112
    80004f70:	97ba                	add	a5,a5,a4
    80004f72:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f76:	00148693          	addi	a3,s1,1
    80004f7a:	068e                	slli	a3,a3,0x3
    80004f7c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f80:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f84:	01897663          	bgeu	s2,s8,80004f90 <exec+0x242>
  sz = sz1;
    80004f88:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8c:	4481                	li	s1,0
    80004f8e:	a059                	j	80005014 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f90:	e9040613          	addi	a2,s0,-368
    80004f94:	85ca                	mv	a1,s2
    80004f96:	855e                	mv	a0,s7
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	6da080e7          	jalr	1754(ra) # 80001672 <copyout>
    80004fa0:	0a054663          	bltz	a0,8000504c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fa4:	058ab783          	ld	a5,88(s5)
    80004fa8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fac:	df843783          	ld	a5,-520(s0)
    80004fb0:	0007c703          	lbu	a4,0(a5)
    80004fb4:	cf11                	beqz	a4,80004fd0 <exec+0x282>
    80004fb6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fb8:	02f00693          	li	a3,47
    80004fbc:	a039                	j	80004fca <exec+0x27c>
      last = s+1;
    80004fbe:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fc2:	0785                	addi	a5,a5,1
    80004fc4:	fff7c703          	lbu	a4,-1(a5)
    80004fc8:	c701                	beqz	a4,80004fd0 <exec+0x282>
    if(*s == '/')
    80004fca:	fed71ce3          	bne	a4,a3,80004fc2 <exec+0x274>
    80004fce:	bfc5                	j	80004fbe <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fd0:	4641                	li	a2,16
    80004fd2:	df843583          	ld	a1,-520(s0)
    80004fd6:	158a8513          	addi	a0,s5,344
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	e58080e7          	jalr	-424(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fe2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fe6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fea:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fee:	058ab783          	ld	a5,88(s5)
    80004ff2:	e6843703          	ld	a4,-408(s0)
    80004ff6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ff8:	058ab783          	ld	a5,88(s5)
    80004ffc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005000:	85ea                	mv	a1,s10
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	b0e080e7          	jalr	-1266(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000500a:	0004851b          	sext.w	a0,s1
    8000500e:	bbe1                	j	80004de6 <exec+0x98>
    80005010:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005014:	e0843583          	ld	a1,-504(s0)
    80005018:	855e                	mv	a0,s7
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	af6080e7          	jalr	-1290(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005022:	da0498e3          	bnez	s1,80004dd2 <exec+0x84>
  return -1;
    80005026:	557d                	li	a0,-1
    80005028:	bb7d                	j	80004de6 <exec+0x98>
    8000502a:	e1243423          	sd	s2,-504(s0)
    8000502e:	b7dd                	j	80005014 <exec+0x2c6>
    80005030:	e1243423          	sd	s2,-504(s0)
    80005034:	b7c5                	j	80005014 <exec+0x2c6>
    80005036:	e1243423          	sd	s2,-504(s0)
    8000503a:	bfe9                	j	80005014 <exec+0x2c6>
  sz = sz1;
    8000503c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005040:	4481                	li	s1,0
    80005042:	bfc9                	j	80005014 <exec+0x2c6>
  sz = sz1;
    80005044:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005048:	4481                	li	s1,0
    8000504a:	b7e9                	j	80005014 <exec+0x2c6>
  sz = sz1;
    8000504c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005050:	4481                	li	s1,0
    80005052:	b7c9                	j	80005014 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005054:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005058:	2b05                	addiw	s6,s6,1
    8000505a:	0389899b          	addiw	s3,s3,56
    8000505e:	e8845783          	lhu	a5,-376(s0)
    80005062:	e2fb5be3          	bge	s6,a5,80004e98 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005066:	2981                	sext.w	s3,s3
    80005068:	03800713          	li	a4,56
    8000506c:	86ce                	mv	a3,s3
    8000506e:	e1840613          	addi	a2,s0,-488
    80005072:	4581                	li	a1,0
    80005074:	8526                	mv	a0,s1
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	a8e080e7          	jalr	-1394(ra) # 80003b04 <readi>
    8000507e:	03800793          	li	a5,56
    80005082:	f8f517e3          	bne	a0,a5,80005010 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005086:	e1842783          	lw	a5,-488(s0)
    8000508a:	4705                	li	a4,1
    8000508c:	fce796e3          	bne	a5,a4,80005058 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005090:	e4043603          	ld	a2,-448(s0)
    80005094:	e3843783          	ld	a5,-456(s0)
    80005098:	f8f669e3          	bltu	a2,a5,8000502a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000509c:	e2843783          	ld	a5,-472(s0)
    800050a0:	963e                	add	a2,a2,a5
    800050a2:	f8f667e3          	bltu	a2,a5,80005030 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050a6:	85ca                	mv	a1,s2
    800050a8:	855e                	mv	a0,s7
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	378080e7          	jalr	888(ra) # 80001422 <uvmalloc>
    800050b2:	e0a43423          	sd	a0,-504(s0)
    800050b6:	d141                	beqz	a0,80005036 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050b8:	e2843d03          	ld	s10,-472(s0)
    800050bc:	df043783          	ld	a5,-528(s0)
    800050c0:	00fd77b3          	and	a5,s10,a5
    800050c4:	fba1                	bnez	a5,80005014 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050c6:	e2042d83          	lw	s11,-480(s0)
    800050ca:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050ce:	f80c03e3          	beqz	s8,80005054 <exec+0x306>
    800050d2:	8a62                	mv	s4,s8
    800050d4:	4901                	li	s2,0
    800050d6:	b345                	j	80004e76 <exec+0x128>

00000000800050d8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050d8:	7179                	addi	sp,sp,-48
    800050da:	f406                	sd	ra,40(sp)
    800050dc:	f022                	sd	s0,32(sp)
    800050de:	ec26                	sd	s1,24(sp)
    800050e0:	e84a                	sd	s2,16(sp)
    800050e2:	1800                	addi	s0,sp,48
    800050e4:	892e                	mv	s2,a1
    800050e6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050e8:	fdc40593          	addi	a1,s0,-36
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	a96080e7          	jalr	-1386(ra) # 80002b82 <argint>
    800050f4:	04054063          	bltz	a0,80005134 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050f8:	fdc42703          	lw	a4,-36(s0)
    800050fc:	47bd                	li	a5,15
    800050fe:	02e7ed63          	bltu	a5,a4,80005138 <argfd+0x60>
    80005102:	ffffd097          	auipc	ra,0xffffd
    80005106:	8ae080e7          	jalr	-1874(ra) # 800019b0 <myproc>
    8000510a:	fdc42703          	lw	a4,-36(s0)
    8000510e:	01a70793          	addi	a5,a4,26
    80005112:	078e                	slli	a5,a5,0x3
    80005114:	953e                	add	a0,a0,a5
    80005116:	611c                	ld	a5,0(a0)
    80005118:	c395                	beqz	a5,8000513c <argfd+0x64>
    return -1;
  if(pfd)
    8000511a:	00090463          	beqz	s2,80005122 <argfd+0x4a>
    *pfd = fd;
    8000511e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005122:	4501                	li	a0,0
  if(pf)
    80005124:	c091                	beqz	s1,80005128 <argfd+0x50>
    *pf = f;
    80005126:	e09c                	sd	a5,0(s1)
}
    80005128:	70a2                	ld	ra,40(sp)
    8000512a:	7402                	ld	s0,32(sp)
    8000512c:	64e2                	ld	s1,24(sp)
    8000512e:	6942                	ld	s2,16(sp)
    80005130:	6145                	addi	sp,sp,48
    80005132:	8082                	ret
    return -1;
    80005134:	557d                	li	a0,-1
    80005136:	bfcd                	j	80005128 <argfd+0x50>
    return -1;
    80005138:	557d                	li	a0,-1
    8000513a:	b7fd                	j	80005128 <argfd+0x50>
    8000513c:	557d                	li	a0,-1
    8000513e:	b7ed                	j	80005128 <argfd+0x50>

0000000080005140 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005140:	1101                	addi	sp,sp,-32
    80005142:	ec06                	sd	ra,24(sp)
    80005144:	e822                	sd	s0,16(sp)
    80005146:	e426                	sd	s1,8(sp)
    80005148:	1000                	addi	s0,sp,32
    8000514a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	864080e7          	jalr	-1948(ra) # 800019b0 <myproc>
    80005154:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005156:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000515a:	4501                	li	a0,0
    8000515c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000515e:	6398                	ld	a4,0(a5)
    80005160:	cb19                	beqz	a4,80005176 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005162:	2505                	addiw	a0,a0,1
    80005164:	07a1                	addi	a5,a5,8
    80005166:	fed51ce3          	bne	a0,a3,8000515e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000516a:	557d                	li	a0,-1
}
    8000516c:	60e2                	ld	ra,24(sp)
    8000516e:	6442                	ld	s0,16(sp)
    80005170:	64a2                	ld	s1,8(sp)
    80005172:	6105                	addi	sp,sp,32
    80005174:	8082                	ret
      p->ofile[fd] = f;
    80005176:	01a50793          	addi	a5,a0,26
    8000517a:	078e                	slli	a5,a5,0x3
    8000517c:	963e                	add	a2,a2,a5
    8000517e:	e204                	sd	s1,0(a2)
      return fd;
    80005180:	b7f5                	j	8000516c <fdalloc+0x2c>

0000000080005182 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005182:	715d                	addi	sp,sp,-80
    80005184:	e486                	sd	ra,72(sp)
    80005186:	e0a2                	sd	s0,64(sp)
    80005188:	fc26                	sd	s1,56(sp)
    8000518a:	f84a                	sd	s2,48(sp)
    8000518c:	f44e                	sd	s3,40(sp)
    8000518e:	f052                	sd	s4,32(sp)
    80005190:	ec56                	sd	s5,24(sp)
    80005192:	0880                	addi	s0,sp,80
    80005194:	89ae                	mv	s3,a1
    80005196:	8ab2                	mv	s5,a2
    80005198:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000519a:	fb040593          	addi	a1,s0,-80
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	e86080e7          	jalr	-378(ra) # 80004024 <nameiparent>
    800051a6:	892a                	mv	s2,a0
    800051a8:	12050f63          	beqz	a0,800052e6 <create+0x164>
    return 0;

  ilock(dp);
    800051ac:	ffffe097          	auipc	ra,0xffffe
    800051b0:	6a4080e7          	jalr	1700(ra) # 80003850 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051b4:	4601                	li	a2,0
    800051b6:	fb040593          	addi	a1,s0,-80
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	b78080e7          	jalr	-1160(ra) # 80003d34 <dirlookup>
    800051c4:	84aa                	mv	s1,a0
    800051c6:	c921                	beqz	a0,80005216 <create+0x94>
    iunlockput(dp);
    800051c8:	854a                	mv	a0,s2
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	8e8080e7          	jalr	-1816(ra) # 80003ab2 <iunlockput>
    ilock(ip);
    800051d2:	8526                	mv	a0,s1
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	67c080e7          	jalr	1660(ra) # 80003850 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051dc:	2981                	sext.w	s3,s3
    800051de:	4789                	li	a5,2
    800051e0:	02f99463          	bne	s3,a5,80005208 <create+0x86>
    800051e4:	0444d783          	lhu	a5,68(s1)
    800051e8:	37f9                	addiw	a5,a5,-2
    800051ea:	17c2                	slli	a5,a5,0x30
    800051ec:	93c1                	srli	a5,a5,0x30
    800051ee:	4705                	li	a4,1
    800051f0:	00f76c63          	bltu	a4,a5,80005208 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051f4:	8526                	mv	a0,s1
    800051f6:	60a6                	ld	ra,72(sp)
    800051f8:	6406                	ld	s0,64(sp)
    800051fa:	74e2                	ld	s1,56(sp)
    800051fc:	7942                	ld	s2,48(sp)
    800051fe:	79a2                	ld	s3,40(sp)
    80005200:	7a02                	ld	s4,32(sp)
    80005202:	6ae2                	ld	s5,24(sp)
    80005204:	6161                	addi	sp,sp,80
    80005206:	8082                	ret
    iunlockput(ip);
    80005208:	8526                	mv	a0,s1
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	8a8080e7          	jalr	-1880(ra) # 80003ab2 <iunlockput>
    return 0;
    80005212:	4481                	li	s1,0
    80005214:	b7c5                	j	800051f4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005216:	85ce                	mv	a1,s3
    80005218:	00092503          	lw	a0,0(s2)
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	49c080e7          	jalr	1180(ra) # 800036b8 <ialloc>
    80005224:	84aa                	mv	s1,a0
    80005226:	c529                	beqz	a0,80005270 <create+0xee>
  ilock(ip);
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	628080e7          	jalr	1576(ra) # 80003850 <ilock>
  ip->major = major;
    80005230:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005234:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005238:	4785                	li	a5,1
    8000523a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000523e:	8526                	mv	a0,s1
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	546080e7          	jalr	1350(ra) # 80003786 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005248:	2981                	sext.w	s3,s3
    8000524a:	4785                	li	a5,1
    8000524c:	02f98a63          	beq	s3,a5,80005280 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005250:	40d0                	lw	a2,4(s1)
    80005252:	fb040593          	addi	a1,s0,-80
    80005256:	854a                	mv	a0,s2
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	cec080e7          	jalr	-788(ra) # 80003f44 <dirlink>
    80005260:	06054b63          	bltz	a0,800052d6 <create+0x154>
  iunlockput(dp);
    80005264:	854a                	mv	a0,s2
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	84c080e7          	jalr	-1972(ra) # 80003ab2 <iunlockput>
  return ip;
    8000526e:	b759                	j	800051f4 <create+0x72>
    panic("create: ialloc");
    80005270:	00003517          	auipc	a0,0x3
    80005274:	5d850513          	addi	a0,a0,1496 # 80008848 <syscalls+0x2a8>
    80005278:	ffffb097          	auipc	ra,0xffffb
    8000527c:	2c6080e7          	jalr	710(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005280:	04a95783          	lhu	a5,74(s2)
    80005284:	2785                	addiw	a5,a5,1
    80005286:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000528a:	854a                	mv	a0,s2
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	4fa080e7          	jalr	1274(ra) # 80003786 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005294:	40d0                	lw	a2,4(s1)
    80005296:	00003597          	auipc	a1,0x3
    8000529a:	5c258593          	addi	a1,a1,1474 # 80008858 <syscalls+0x2b8>
    8000529e:	8526                	mv	a0,s1
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	ca4080e7          	jalr	-860(ra) # 80003f44 <dirlink>
    800052a8:	00054f63          	bltz	a0,800052c6 <create+0x144>
    800052ac:	00492603          	lw	a2,4(s2)
    800052b0:	00003597          	auipc	a1,0x3
    800052b4:	5b058593          	addi	a1,a1,1456 # 80008860 <syscalls+0x2c0>
    800052b8:	8526                	mv	a0,s1
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	c8a080e7          	jalr	-886(ra) # 80003f44 <dirlink>
    800052c2:	f80557e3          	bgez	a0,80005250 <create+0xce>
      panic("create dots");
    800052c6:	00003517          	auipc	a0,0x3
    800052ca:	5a250513          	addi	a0,a0,1442 # 80008868 <syscalls+0x2c8>
    800052ce:	ffffb097          	auipc	ra,0xffffb
    800052d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052d6:	00003517          	auipc	a0,0x3
    800052da:	5a250513          	addi	a0,a0,1442 # 80008878 <syscalls+0x2d8>
    800052de:	ffffb097          	auipc	ra,0xffffb
    800052e2:	260080e7          	jalr	608(ra) # 8000053e <panic>
    return 0;
    800052e6:	84aa                	mv	s1,a0
    800052e8:	b731                	j	800051f4 <create+0x72>

00000000800052ea <sys_dup>:
{
    800052ea:	7179                	addi	sp,sp,-48
    800052ec:	f406                	sd	ra,40(sp)
    800052ee:	f022                	sd	s0,32(sp)
    800052f0:	ec26                	sd	s1,24(sp)
    800052f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052f4:	fd840613          	addi	a2,s0,-40
    800052f8:	4581                	li	a1,0
    800052fa:	4501                	li	a0,0
    800052fc:	00000097          	auipc	ra,0x0
    80005300:	ddc080e7          	jalr	-548(ra) # 800050d8 <argfd>
    return -1;
    80005304:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005306:	02054363          	bltz	a0,8000532c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000530a:	fd843503          	ld	a0,-40(s0)
    8000530e:	00000097          	auipc	ra,0x0
    80005312:	e32080e7          	jalr	-462(ra) # 80005140 <fdalloc>
    80005316:	84aa                	mv	s1,a0
    return -1;
    80005318:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000531a:	00054963          	bltz	a0,8000532c <sys_dup+0x42>
  filedup(f);
    8000531e:	fd843503          	ld	a0,-40(s0)
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	37a080e7          	jalr	890(ra) # 8000469c <filedup>
  return fd;
    8000532a:	87a6                	mv	a5,s1
}
    8000532c:	853e                	mv	a0,a5
    8000532e:	70a2                	ld	ra,40(sp)
    80005330:	7402                	ld	s0,32(sp)
    80005332:	64e2                	ld	s1,24(sp)
    80005334:	6145                	addi	sp,sp,48
    80005336:	8082                	ret

0000000080005338 <sys_read>:
{
    80005338:	7179                	addi	sp,sp,-48
    8000533a:	f406                	sd	ra,40(sp)
    8000533c:	f022                	sd	s0,32(sp)
    8000533e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005340:	fe840613          	addi	a2,s0,-24
    80005344:	4581                	li	a1,0
    80005346:	4501                	li	a0,0
    80005348:	00000097          	auipc	ra,0x0
    8000534c:	d90080e7          	jalr	-624(ra) # 800050d8 <argfd>
    return -1;
    80005350:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005352:	04054163          	bltz	a0,80005394 <sys_read+0x5c>
    80005356:	fe440593          	addi	a1,s0,-28
    8000535a:	4509                	li	a0,2
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	826080e7          	jalr	-2010(ra) # 80002b82 <argint>
    return -1;
    80005364:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005366:	02054763          	bltz	a0,80005394 <sys_read+0x5c>
    8000536a:	fd840593          	addi	a1,s0,-40
    8000536e:	4505                	li	a0,1
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	834080e7          	jalr	-1996(ra) # 80002ba4 <argaddr>
    return -1;
    80005378:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537a:	00054d63          	bltz	a0,80005394 <sys_read+0x5c>
  return fileread(f, p, n);
    8000537e:	fe442603          	lw	a2,-28(s0)
    80005382:	fd843583          	ld	a1,-40(s0)
    80005386:	fe843503          	ld	a0,-24(s0)
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	49e080e7          	jalr	1182(ra) # 80004828 <fileread>
    80005392:	87aa                	mv	a5,a0
}
    80005394:	853e                	mv	a0,a5
    80005396:	70a2                	ld	ra,40(sp)
    80005398:	7402                	ld	s0,32(sp)
    8000539a:	6145                	addi	sp,sp,48
    8000539c:	8082                	ret

000000008000539e <sys_write>:
{
    8000539e:	7179                	addi	sp,sp,-48
    800053a0:	f406                	sd	ra,40(sp)
    800053a2:	f022                	sd	s0,32(sp)
    800053a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a6:	fe840613          	addi	a2,s0,-24
    800053aa:	4581                	li	a1,0
    800053ac:	4501                	li	a0,0
    800053ae:	00000097          	auipc	ra,0x0
    800053b2:	d2a080e7          	jalr	-726(ra) # 800050d8 <argfd>
    return -1;
    800053b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b8:	04054163          	bltz	a0,800053fa <sys_write+0x5c>
    800053bc:	fe440593          	addi	a1,s0,-28
    800053c0:	4509                	li	a0,2
    800053c2:	ffffd097          	auipc	ra,0xffffd
    800053c6:	7c0080e7          	jalr	1984(ra) # 80002b82 <argint>
    return -1;
    800053ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053cc:	02054763          	bltz	a0,800053fa <sys_write+0x5c>
    800053d0:	fd840593          	addi	a1,s0,-40
    800053d4:	4505                	li	a0,1
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	7ce080e7          	jalr	1998(ra) # 80002ba4 <argaddr>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e0:	00054d63          	bltz	a0,800053fa <sys_write+0x5c>
  return filewrite(f, p, n);
    800053e4:	fe442603          	lw	a2,-28(s0)
    800053e8:	fd843583          	ld	a1,-40(s0)
    800053ec:	fe843503          	ld	a0,-24(s0)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	4fa080e7          	jalr	1274(ra) # 800048ea <filewrite>
    800053f8:	87aa                	mv	a5,a0
}
    800053fa:	853e                	mv	a0,a5
    800053fc:	70a2                	ld	ra,40(sp)
    800053fe:	7402                	ld	s0,32(sp)
    80005400:	6145                	addi	sp,sp,48
    80005402:	8082                	ret

0000000080005404 <sys_close>:
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000540c:	fe040613          	addi	a2,s0,-32
    80005410:	fec40593          	addi	a1,s0,-20
    80005414:	4501                	li	a0,0
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	cc2080e7          	jalr	-830(ra) # 800050d8 <argfd>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005420:	02054463          	bltz	a0,80005448 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005424:	ffffc097          	auipc	ra,0xffffc
    80005428:	58c080e7          	jalr	1420(ra) # 800019b0 <myproc>
    8000542c:	fec42783          	lw	a5,-20(s0)
    80005430:	07e9                	addi	a5,a5,26
    80005432:	078e                	slli	a5,a5,0x3
    80005434:	97aa                	add	a5,a5,a0
    80005436:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000543a:	fe043503          	ld	a0,-32(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	2b0080e7          	jalr	688(ra) # 800046ee <fileclose>
  return 0;
    80005446:	4781                	li	a5,0
}
    80005448:	853e                	mv	a0,a5
    8000544a:	60e2                	ld	ra,24(sp)
    8000544c:	6442                	ld	s0,16(sp)
    8000544e:	6105                	addi	sp,sp,32
    80005450:	8082                	ret

0000000080005452 <sys_fstat>:
{
    80005452:	1101                	addi	sp,sp,-32
    80005454:	ec06                	sd	ra,24(sp)
    80005456:	e822                	sd	s0,16(sp)
    80005458:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545a:	fe840613          	addi	a2,s0,-24
    8000545e:	4581                	li	a1,0
    80005460:	4501                	li	a0,0
    80005462:	00000097          	auipc	ra,0x0
    80005466:	c76080e7          	jalr	-906(ra) # 800050d8 <argfd>
    return -1;
    8000546a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000546c:	02054563          	bltz	a0,80005496 <sys_fstat+0x44>
    80005470:	fe040593          	addi	a1,s0,-32
    80005474:	4505                	li	a0,1
    80005476:	ffffd097          	auipc	ra,0xffffd
    8000547a:	72e080e7          	jalr	1838(ra) # 80002ba4 <argaddr>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005480:	00054b63          	bltz	a0,80005496 <sys_fstat+0x44>
  return filestat(f, st);
    80005484:	fe043583          	ld	a1,-32(s0)
    80005488:	fe843503          	ld	a0,-24(s0)
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	32a080e7          	jalr	810(ra) # 800047b6 <filestat>
    80005494:	87aa                	mv	a5,a0
}
    80005496:	853e                	mv	a0,a5
    80005498:	60e2                	ld	ra,24(sp)
    8000549a:	6442                	ld	s0,16(sp)
    8000549c:	6105                	addi	sp,sp,32
    8000549e:	8082                	ret

00000000800054a0 <sys_link>:
{
    800054a0:	7169                	addi	sp,sp,-304
    800054a2:	f606                	sd	ra,296(sp)
    800054a4:	f222                	sd	s0,288(sp)
    800054a6:	ee26                	sd	s1,280(sp)
    800054a8:	ea4a                	sd	s2,272(sp)
    800054aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ac:	08000613          	li	a2,128
    800054b0:	ed040593          	addi	a1,s0,-304
    800054b4:	4501                	li	a0,0
    800054b6:	ffffd097          	auipc	ra,0xffffd
    800054ba:	710080e7          	jalr	1808(ra) # 80002bc6 <argstr>
    return -1;
    800054be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c0:	10054e63          	bltz	a0,800055dc <sys_link+0x13c>
    800054c4:	08000613          	li	a2,128
    800054c8:	f5040593          	addi	a1,s0,-176
    800054cc:	4505                	li	a0,1
    800054ce:	ffffd097          	auipc	ra,0xffffd
    800054d2:	6f8080e7          	jalr	1784(ra) # 80002bc6 <argstr>
    return -1;
    800054d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d8:	10054263          	bltz	a0,800055dc <sys_link+0x13c>
  begin_op();
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	d46080e7          	jalr	-698(ra) # 80004222 <begin_op>
  if((ip = namei(old)) == 0){
    800054e4:	ed040513          	addi	a0,s0,-304
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	b1e080e7          	jalr	-1250(ra) # 80004006 <namei>
    800054f0:	84aa                	mv	s1,a0
    800054f2:	c551                	beqz	a0,8000557e <sys_link+0xde>
  ilock(ip);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	35c080e7          	jalr	860(ra) # 80003850 <ilock>
  if(ip->type == T_DIR){
    800054fc:	04449703          	lh	a4,68(s1)
    80005500:	4785                	li	a5,1
    80005502:	08f70463          	beq	a4,a5,8000558a <sys_link+0xea>
  ip->nlink++;
    80005506:	04a4d783          	lhu	a5,74(s1)
    8000550a:	2785                	addiw	a5,a5,1
    8000550c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	274080e7          	jalr	628(ra) # 80003786 <iupdate>
  iunlock(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	3f6080e7          	jalr	1014(ra) # 80003912 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005524:	fd040593          	addi	a1,s0,-48
    80005528:	f5040513          	addi	a0,s0,-176
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	af8080e7          	jalr	-1288(ra) # 80004024 <nameiparent>
    80005534:	892a                	mv	s2,a0
    80005536:	c935                	beqz	a0,800055aa <sys_link+0x10a>
  ilock(dp);
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	318080e7          	jalr	792(ra) # 80003850 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005540:	00092703          	lw	a4,0(s2)
    80005544:	409c                	lw	a5,0(s1)
    80005546:	04f71d63          	bne	a4,a5,800055a0 <sys_link+0x100>
    8000554a:	40d0                	lw	a2,4(s1)
    8000554c:	fd040593          	addi	a1,s0,-48
    80005550:	854a                	mv	a0,s2
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	9f2080e7          	jalr	-1550(ra) # 80003f44 <dirlink>
    8000555a:	04054363          	bltz	a0,800055a0 <sys_link+0x100>
  iunlockput(dp);
    8000555e:	854a                	mv	a0,s2
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	552080e7          	jalr	1362(ra) # 80003ab2 <iunlockput>
  iput(ip);
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	4a0080e7          	jalr	1184(ra) # 80003a0a <iput>
  end_op();
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	d30080e7          	jalr	-720(ra) # 800042a2 <end_op>
  return 0;
    8000557a:	4781                	li	a5,0
    8000557c:	a085                	j	800055dc <sys_link+0x13c>
    end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	d24080e7          	jalr	-732(ra) # 800042a2 <end_op>
    return -1;
    80005586:	57fd                	li	a5,-1
    80005588:	a891                	j	800055dc <sys_link+0x13c>
    iunlockput(ip);
    8000558a:	8526                	mv	a0,s1
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	526080e7          	jalr	1318(ra) # 80003ab2 <iunlockput>
    end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	d0e080e7          	jalr	-754(ra) # 800042a2 <end_op>
    return -1;
    8000559c:	57fd                	li	a5,-1
    8000559e:	a83d                	j	800055dc <sys_link+0x13c>
    iunlockput(dp);
    800055a0:	854a                	mv	a0,s2
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	510080e7          	jalr	1296(ra) # 80003ab2 <iunlockput>
  ilock(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	2a4080e7          	jalr	676(ra) # 80003850 <ilock>
  ip->nlink--;
    800055b4:	04a4d783          	lhu	a5,74(s1)
    800055b8:	37fd                	addiw	a5,a5,-1
    800055ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	1c6080e7          	jalr	454(ra) # 80003786 <iupdate>
  iunlockput(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	4e8080e7          	jalr	1256(ra) # 80003ab2 <iunlockput>
  end_op();
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	cd0080e7          	jalr	-816(ra) # 800042a2 <end_op>
  return -1;
    800055da:	57fd                	li	a5,-1
}
    800055dc:	853e                	mv	a0,a5
    800055de:	70b2                	ld	ra,296(sp)
    800055e0:	7412                	ld	s0,288(sp)
    800055e2:	64f2                	ld	s1,280(sp)
    800055e4:	6952                	ld	s2,272(sp)
    800055e6:	6155                	addi	sp,sp,304
    800055e8:	8082                	ret

00000000800055ea <sys_unlink>:
{
    800055ea:	7151                	addi	sp,sp,-240
    800055ec:	f586                	sd	ra,232(sp)
    800055ee:	f1a2                	sd	s0,224(sp)
    800055f0:	eda6                	sd	s1,216(sp)
    800055f2:	e9ca                	sd	s2,208(sp)
    800055f4:	e5ce                	sd	s3,200(sp)
    800055f6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055f8:	08000613          	li	a2,128
    800055fc:	f3040593          	addi	a1,s0,-208
    80005600:	4501                	li	a0,0
    80005602:	ffffd097          	auipc	ra,0xffffd
    80005606:	5c4080e7          	jalr	1476(ra) # 80002bc6 <argstr>
    8000560a:	18054163          	bltz	a0,8000578c <sys_unlink+0x1a2>
  begin_op();
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	c14080e7          	jalr	-1004(ra) # 80004222 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005616:	fb040593          	addi	a1,s0,-80
    8000561a:	f3040513          	addi	a0,s0,-208
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	a06080e7          	jalr	-1530(ra) # 80004024 <nameiparent>
    80005626:	84aa                	mv	s1,a0
    80005628:	c979                	beqz	a0,800056fe <sys_unlink+0x114>
  ilock(dp);
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	226080e7          	jalr	550(ra) # 80003850 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005632:	00003597          	auipc	a1,0x3
    80005636:	22658593          	addi	a1,a1,550 # 80008858 <syscalls+0x2b8>
    8000563a:	fb040513          	addi	a0,s0,-80
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	6dc080e7          	jalr	1756(ra) # 80003d1a <namecmp>
    80005646:	14050a63          	beqz	a0,8000579a <sys_unlink+0x1b0>
    8000564a:	00003597          	auipc	a1,0x3
    8000564e:	21658593          	addi	a1,a1,534 # 80008860 <syscalls+0x2c0>
    80005652:	fb040513          	addi	a0,s0,-80
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	6c4080e7          	jalr	1732(ra) # 80003d1a <namecmp>
    8000565e:	12050e63          	beqz	a0,8000579a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005662:	f2c40613          	addi	a2,s0,-212
    80005666:	fb040593          	addi	a1,s0,-80
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	6c8080e7          	jalr	1736(ra) # 80003d34 <dirlookup>
    80005674:	892a                	mv	s2,a0
    80005676:	12050263          	beqz	a0,8000579a <sys_unlink+0x1b0>
  ilock(ip);
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	1d6080e7          	jalr	470(ra) # 80003850 <ilock>
  if(ip->nlink < 1)
    80005682:	04a91783          	lh	a5,74(s2)
    80005686:	08f05263          	blez	a5,8000570a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000568a:	04491703          	lh	a4,68(s2)
    8000568e:	4785                	li	a5,1
    80005690:	08f70563          	beq	a4,a5,8000571a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005694:	4641                	li	a2,16
    80005696:	4581                	li	a1,0
    80005698:	fc040513          	addi	a0,s0,-64
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	644080e7          	jalr	1604(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056a4:	4741                	li	a4,16
    800056a6:	f2c42683          	lw	a3,-212(s0)
    800056aa:	fc040613          	addi	a2,s0,-64
    800056ae:	4581                	li	a1,0
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	54a080e7          	jalr	1354(ra) # 80003bfc <writei>
    800056ba:	47c1                	li	a5,16
    800056bc:	0af51563          	bne	a0,a5,80005766 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056c0:	04491703          	lh	a4,68(s2)
    800056c4:	4785                	li	a5,1
    800056c6:	0af70863          	beq	a4,a5,80005776 <sys_unlink+0x18c>
  iunlockput(dp);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	3e6080e7          	jalr	998(ra) # 80003ab2 <iunlockput>
  ip->nlink--;
    800056d4:	04a95783          	lhu	a5,74(s2)
    800056d8:	37fd                	addiw	a5,a5,-1
    800056da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	0a6080e7          	jalr	166(ra) # 80003786 <iupdate>
  iunlockput(ip);
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	3c8080e7          	jalr	968(ra) # 80003ab2 <iunlockput>
  end_op();
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	bb0080e7          	jalr	-1104(ra) # 800042a2 <end_op>
  return 0;
    800056fa:	4501                	li	a0,0
    800056fc:	a84d                	j	800057ae <sys_unlink+0x1c4>
    end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	ba4080e7          	jalr	-1116(ra) # 800042a2 <end_op>
    return -1;
    80005706:	557d                	li	a0,-1
    80005708:	a05d                	j	800057ae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000570a:	00003517          	auipc	a0,0x3
    8000570e:	17e50513          	addi	a0,a0,382 # 80008888 <syscalls+0x2e8>
    80005712:	ffffb097          	auipc	ra,0xffffb
    80005716:	e2c080e7          	jalr	-468(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000571a:	04c92703          	lw	a4,76(s2)
    8000571e:	02000793          	li	a5,32
    80005722:	f6e7f9e3          	bgeu	a5,a4,80005694 <sys_unlink+0xaa>
    80005726:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000572a:	4741                	li	a4,16
    8000572c:	86ce                	mv	a3,s3
    8000572e:	f1840613          	addi	a2,s0,-232
    80005732:	4581                	li	a1,0
    80005734:	854a                	mv	a0,s2
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	3ce080e7          	jalr	974(ra) # 80003b04 <readi>
    8000573e:	47c1                	li	a5,16
    80005740:	00f51b63          	bne	a0,a5,80005756 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005744:	f1845783          	lhu	a5,-232(s0)
    80005748:	e7a1                	bnez	a5,80005790 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000574a:	29c1                	addiw	s3,s3,16
    8000574c:	04c92783          	lw	a5,76(s2)
    80005750:	fcf9ede3          	bltu	s3,a5,8000572a <sys_unlink+0x140>
    80005754:	b781                	j	80005694 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005756:	00003517          	auipc	a0,0x3
    8000575a:	14a50513          	addi	a0,a0,330 # 800088a0 <syscalls+0x300>
    8000575e:	ffffb097          	auipc	ra,0xffffb
    80005762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005766:	00003517          	auipc	a0,0x3
    8000576a:	15250513          	addi	a0,a0,338 # 800088b8 <syscalls+0x318>
    8000576e:	ffffb097          	auipc	ra,0xffffb
    80005772:	dd0080e7          	jalr	-560(ra) # 8000053e <panic>
    dp->nlink--;
    80005776:	04a4d783          	lhu	a5,74(s1)
    8000577a:	37fd                	addiw	a5,a5,-1
    8000577c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	004080e7          	jalr	4(ra) # 80003786 <iupdate>
    8000578a:	b781                	j	800056ca <sys_unlink+0xe0>
    return -1;
    8000578c:	557d                	li	a0,-1
    8000578e:	a005                	j	800057ae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005790:	854a                	mv	a0,s2
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	320080e7          	jalr	800(ra) # 80003ab2 <iunlockput>
  iunlockput(dp);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	316080e7          	jalr	790(ra) # 80003ab2 <iunlockput>
  end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	afe080e7          	jalr	-1282(ra) # 800042a2 <end_op>
  return -1;
    800057ac:	557d                	li	a0,-1
}
    800057ae:	70ae                	ld	ra,232(sp)
    800057b0:	740e                	ld	s0,224(sp)
    800057b2:	64ee                	ld	s1,216(sp)
    800057b4:	694e                	ld	s2,208(sp)
    800057b6:	69ae                	ld	s3,200(sp)
    800057b8:	616d                	addi	sp,sp,240
    800057ba:	8082                	ret

00000000800057bc <sys_open>:

uint64
sys_open(void)
{
    800057bc:	7131                	addi	sp,sp,-192
    800057be:	fd06                	sd	ra,184(sp)
    800057c0:	f922                	sd	s0,176(sp)
    800057c2:	f526                	sd	s1,168(sp)
    800057c4:	f14a                	sd	s2,160(sp)
    800057c6:	ed4e                	sd	s3,152(sp)
    800057c8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ca:	08000613          	li	a2,128
    800057ce:	f5040593          	addi	a1,s0,-176
    800057d2:	4501                	li	a0,0
    800057d4:	ffffd097          	auipc	ra,0xffffd
    800057d8:	3f2080e7          	jalr	1010(ra) # 80002bc6 <argstr>
    return -1;
    800057dc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057de:	0c054163          	bltz	a0,800058a0 <sys_open+0xe4>
    800057e2:	f4c40593          	addi	a1,s0,-180
    800057e6:	4505                	li	a0,1
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	39a080e7          	jalr	922(ra) # 80002b82 <argint>
    800057f0:	0a054863          	bltz	a0,800058a0 <sys_open+0xe4>

  begin_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	a2e080e7          	jalr	-1490(ra) # 80004222 <begin_op>

  if(omode & O_CREATE){
    800057fc:	f4c42783          	lw	a5,-180(s0)
    80005800:	2007f793          	andi	a5,a5,512
    80005804:	cbdd                	beqz	a5,800058ba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005806:	4681                	li	a3,0
    80005808:	4601                	li	a2,0
    8000580a:	4589                	li	a1,2
    8000580c:	f5040513          	addi	a0,s0,-176
    80005810:	00000097          	auipc	ra,0x0
    80005814:	972080e7          	jalr	-1678(ra) # 80005182 <create>
    80005818:	892a                	mv	s2,a0
    if(ip == 0){
    8000581a:	c959                	beqz	a0,800058b0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000581c:	04491703          	lh	a4,68(s2)
    80005820:	478d                	li	a5,3
    80005822:	00f71763          	bne	a4,a5,80005830 <sys_open+0x74>
    80005826:	04695703          	lhu	a4,70(s2)
    8000582a:	47a5                	li	a5,9
    8000582c:	0ce7ec63          	bltu	a5,a4,80005904 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	e02080e7          	jalr	-510(ra) # 80004632 <filealloc>
    80005838:	89aa                	mv	s3,a0
    8000583a:	10050263          	beqz	a0,8000593e <sys_open+0x182>
    8000583e:	00000097          	auipc	ra,0x0
    80005842:	902080e7          	jalr	-1790(ra) # 80005140 <fdalloc>
    80005846:	84aa                	mv	s1,a0
    80005848:	0e054663          	bltz	a0,80005934 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000584c:	04491703          	lh	a4,68(s2)
    80005850:	478d                	li	a5,3
    80005852:	0cf70463          	beq	a4,a5,8000591a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005856:	4789                	li	a5,2
    80005858:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000585c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005860:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005864:	f4c42783          	lw	a5,-180(s0)
    80005868:	0017c713          	xori	a4,a5,1
    8000586c:	8b05                	andi	a4,a4,1
    8000586e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005872:	0037f713          	andi	a4,a5,3
    80005876:	00e03733          	snez	a4,a4
    8000587a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000587e:	4007f793          	andi	a5,a5,1024
    80005882:	c791                	beqz	a5,8000588e <sys_open+0xd2>
    80005884:	04491703          	lh	a4,68(s2)
    80005888:	4789                	li	a5,2
    8000588a:	08f70f63          	beq	a4,a5,80005928 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	082080e7          	jalr	130(ra) # 80003912 <iunlock>
  end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	a0a080e7          	jalr	-1526(ra) # 800042a2 <end_op>

  return fd;
}
    800058a0:	8526                	mv	a0,s1
    800058a2:	70ea                	ld	ra,184(sp)
    800058a4:	744a                	ld	s0,176(sp)
    800058a6:	74aa                	ld	s1,168(sp)
    800058a8:	790a                	ld	s2,160(sp)
    800058aa:	69ea                	ld	s3,152(sp)
    800058ac:	6129                	addi	sp,sp,192
    800058ae:	8082                	ret
      end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	9f2080e7          	jalr	-1550(ra) # 800042a2 <end_op>
      return -1;
    800058b8:	b7e5                	j	800058a0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058ba:	f5040513          	addi	a0,s0,-176
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	748080e7          	jalr	1864(ra) # 80004006 <namei>
    800058c6:	892a                	mv	s2,a0
    800058c8:	c905                	beqz	a0,800058f8 <sys_open+0x13c>
    ilock(ip);
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	f86080e7          	jalr	-122(ra) # 80003850 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058d2:	04491703          	lh	a4,68(s2)
    800058d6:	4785                	li	a5,1
    800058d8:	f4f712e3          	bne	a4,a5,8000581c <sys_open+0x60>
    800058dc:	f4c42783          	lw	a5,-180(s0)
    800058e0:	dba1                	beqz	a5,80005830 <sys_open+0x74>
      iunlockput(ip);
    800058e2:	854a                	mv	a0,s2
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	1ce080e7          	jalr	462(ra) # 80003ab2 <iunlockput>
      end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	9b6080e7          	jalr	-1610(ra) # 800042a2 <end_op>
      return -1;
    800058f4:	54fd                	li	s1,-1
    800058f6:	b76d                	j	800058a0 <sys_open+0xe4>
      end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	9aa080e7          	jalr	-1622(ra) # 800042a2 <end_op>
      return -1;
    80005900:	54fd                	li	s1,-1
    80005902:	bf79                	j	800058a0 <sys_open+0xe4>
    iunlockput(ip);
    80005904:	854a                	mv	a0,s2
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	1ac080e7          	jalr	428(ra) # 80003ab2 <iunlockput>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	994080e7          	jalr	-1644(ra) # 800042a2 <end_op>
    return -1;
    80005916:	54fd                	li	s1,-1
    80005918:	b761                	j	800058a0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000591a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000591e:	04691783          	lh	a5,70(s2)
    80005922:	02f99223          	sh	a5,36(s3)
    80005926:	bf2d                	j	80005860 <sys_open+0xa4>
    itrunc(ip);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	034080e7          	jalr	52(ra) # 8000395e <itrunc>
    80005932:	bfb1                	j	8000588e <sys_open+0xd2>
      fileclose(f);
    80005934:	854e                	mv	a0,s3
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	db8080e7          	jalr	-584(ra) # 800046ee <fileclose>
    iunlockput(ip);
    8000593e:	854a                	mv	a0,s2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	172080e7          	jalr	370(ra) # 80003ab2 <iunlockput>
    end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	95a080e7          	jalr	-1702(ra) # 800042a2 <end_op>
    return -1;
    80005950:	54fd                	li	s1,-1
    80005952:	b7b9                	j	800058a0 <sys_open+0xe4>

0000000080005954 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005954:	7175                	addi	sp,sp,-144
    80005956:	e506                	sd	ra,136(sp)
    80005958:	e122                	sd	s0,128(sp)
    8000595a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	8c6080e7          	jalr	-1850(ra) # 80004222 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005964:	08000613          	li	a2,128
    80005968:	f7040593          	addi	a1,s0,-144
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	258080e7          	jalr	600(ra) # 80002bc6 <argstr>
    80005976:	02054963          	bltz	a0,800059a8 <sys_mkdir+0x54>
    8000597a:	4681                	li	a3,0
    8000597c:	4601                	li	a2,0
    8000597e:	4585                	li	a1,1
    80005980:	f7040513          	addi	a0,s0,-144
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	7fe080e7          	jalr	2046(ra) # 80005182 <create>
    8000598c:	cd11                	beqz	a0,800059a8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	124080e7          	jalr	292(ra) # 80003ab2 <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	90c080e7          	jalr	-1780(ra) # 800042a2 <end_op>
  return 0;
    8000599e:	4501                	li	a0,0
}
    800059a0:	60aa                	ld	ra,136(sp)
    800059a2:	640a                	ld	s0,128(sp)
    800059a4:	6149                	addi	sp,sp,144
    800059a6:	8082                	ret
    end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	8fa080e7          	jalr	-1798(ra) # 800042a2 <end_op>
    return -1;
    800059b0:	557d                	li	a0,-1
    800059b2:	b7fd                	j	800059a0 <sys_mkdir+0x4c>

00000000800059b4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059b4:	7135                	addi	sp,sp,-160
    800059b6:	ed06                	sd	ra,152(sp)
    800059b8:	e922                	sd	s0,144(sp)
    800059ba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	866080e7          	jalr	-1946(ra) # 80004222 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c4:	08000613          	li	a2,128
    800059c8:	f7040593          	addi	a1,s0,-144
    800059cc:	4501                	li	a0,0
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	1f8080e7          	jalr	504(ra) # 80002bc6 <argstr>
    800059d6:	04054a63          	bltz	a0,80005a2a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059da:	f6c40593          	addi	a1,s0,-148
    800059de:	4505                	li	a0,1
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	1a2080e7          	jalr	418(ra) # 80002b82 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059e8:	04054163          	bltz	a0,80005a2a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059ec:	f6840593          	addi	a1,s0,-152
    800059f0:	4509                	li	a0,2
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	190080e7          	jalr	400(ra) # 80002b82 <argint>
     argint(1, &major) < 0 ||
    800059fa:	02054863          	bltz	a0,80005a2a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059fe:	f6841683          	lh	a3,-152(s0)
    80005a02:	f6c41603          	lh	a2,-148(s0)
    80005a06:	458d                	li	a1,3
    80005a08:	f7040513          	addi	a0,s0,-144
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	776080e7          	jalr	1910(ra) # 80005182 <create>
     argint(2, &minor) < 0 ||
    80005a14:	c919                	beqz	a0,80005a2a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	09c080e7          	jalr	156(ra) # 80003ab2 <iunlockput>
  end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	884080e7          	jalr	-1916(ra) # 800042a2 <end_op>
  return 0;
    80005a26:	4501                	li	a0,0
    80005a28:	a031                	j	80005a34 <sys_mknod+0x80>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	878080e7          	jalr	-1928(ra) # 800042a2 <end_op>
    return -1;
    80005a32:	557d                	li	a0,-1
}
    80005a34:	60ea                	ld	ra,152(sp)
    80005a36:	644a                	ld	s0,144(sp)
    80005a38:	610d                	addi	sp,sp,160
    80005a3a:	8082                	ret

0000000080005a3c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a3c:	7135                	addi	sp,sp,-160
    80005a3e:	ed06                	sd	ra,152(sp)
    80005a40:	e922                	sd	s0,144(sp)
    80005a42:	e526                	sd	s1,136(sp)
    80005a44:	e14a                	sd	s2,128(sp)
    80005a46:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a48:	ffffc097          	auipc	ra,0xffffc
    80005a4c:	f68080e7          	jalr	-152(ra) # 800019b0 <myproc>
    80005a50:	892a                	mv	s2,a0
  
  begin_op();
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	7d0080e7          	jalr	2000(ra) # 80004222 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a5a:	08000613          	li	a2,128
    80005a5e:	f6040593          	addi	a1,s0,-160
    80005a62:	4501                	li	a0,0
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	162080e7          	jalr	354(ra) # 80002bc6 <argstr>
    80005a6c:	04054b63          	bltz	a0,80005ac2 <sys_chdir+0x86>
    80005a70:	f6040513          	addi	a0,s0,-160
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	592080e7          	jalr	1426(ra) # 80004006 <namei>
    80005a7c:	84aa                	mv	s1,a0
    80005a7e:	c131                	beqz	a0,80005ac2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	dd0080e7          	jalr	-560(ra) # 80003850 <ilock>
  if(ip->type != T_DIR){
    80005a88:	04449703          	lh	a4,68(s1)
    80005a8c:	4785                	li	a5,1
    80005a8e:	04f71063          	bne	a4,a5,80005ace <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	e7e080e7          	jalr	-386(ra) # 80003912 <iunlock>
  iput(p->cwd);
    80005a9c:	15093503          	ld	a0,336(s2)
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	f6a080e7          	jalr	-150(ra) # 80003a0a <iput>
  end_op();
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	7fa080e7          	jalr	2042(ra) # 800042a2 <end_op>
  p->cwd = ip;
    80005ab0:	14993823          	sd	s1,336(s2)
  return 0;
    80005ab4:	4501                	li	a0,0
}
    80005ab6:	60ea                	ld	ra,152(sp)
    80005ab8:	644a                	ld	s0,144(sp)
    80005aba:	64aa                	ld	s1,136(sp)
    80005abc:	690a                	ld	s2,128(sp)
    80005abe:	610d                	addi	sp,sp,160
    80005ac0:	8082                	ret
    end_op();
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	7e0080e7          	jalr	2016(ra) # 800042a2 <end_op>
    return -1;
    80005aca:	557d                	li	a0,-1
    80005acc:	b7ed                	j	80005ab6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ace:	8526                	mv	a0,s1
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	fe2080e7          	jalr	-30(ra) # 80003ab2 <iunlockput>
    end_op();
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	7ca080e7          	jalr	1994(ra) # 800042a2 <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	bfd1                	j	80005ab6 <sys_chdir+0x7a>

0000000080005ae4 <sys_exec>:

uint64
sys_exec(void)
{
    80005ae4:	7145                	addi	sp,sp,-464
    80005ae6:	e786                	sd	ra,456(sp)
    80005ae8:	e3a2                	sd	s0,448(sp)
    80005aea:	ff26                	sd	s1,440(sp)
    80005aec:	fb4a                	sd	s2,432(sp)
    80005aee:	f74e                	sd	s3,424(sp)
    80005af0:	f352                	sd	s4,416(sp)
    80005af2:	ef56                	sd	s5,408(sp)
    80005af4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005af6:	08000613          	li	a2,128
    80005afa:	f4040593          	addi	a1,s0,-192
    80005afe:	4501                	li	a0,0
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	0c6080e7          	jalr	198(ra) # 80002bc6 <argstr>
    return -1;
    80005b08:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b0a:	0c054a63          	bltz	a0,80005bde <sys_exec+0xfa>
    80005b0e:	e3840593          	addi	a1,s0,-456
    80005b12:	4505                	li	a0,1
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	090080e7          	jalr	144(ra) # 80002ba4 <argaddr>
    80005b1c:	0c054163          	bltz	a0,80005bde <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b20:	10000613          	li	a2,256
    80005b24:	4581                	li	a1,0
    80005b26:	e4040513          	addi	a0,s0,-448
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	1b6080e7          	jalr	438(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b32:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b36:	89a6                	mv	s3,s1
    80005b38:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b3a:	02000a13          	li	s4,32
    80005b3e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b42:	00391513          	slli	a0,s2,0x3
    80005b46:	e3040593          	addi	a1,s0,-464
    80005b4a:	e3843783          	ld	a5,-456(s0)
    80005b4e:	953e                	add	a0,a0,a5
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	f98080e7          	jalr	-104(ra) # 80002ae8 <fetchaddr>
    80005b58:	02054a63          	bltz	a0,80005b8c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b5c:	e3043783          	ld	a5,-464(s0)
    80005b60:	c3b9                	beqz	a5,80005ba6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b62:	ffffb097          	auipc	ra,0xffffb
    80005b66:	f92080e7          	jalr	-110(ra) # 80000af4 <kalloc>
    80005b6a:	85aa                	mv	a1,a0
    80005b6c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b70:	cd11                	beqz	a0,80005b8c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b72:	6605                	lui	a2,0x1
    80005b74:	e3043503          	ld	a0,-464(s0)
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	fc2080e7          	jalr	-62(ra) # 80002b3a <fetchstr>
    80005b80:	00054663          	bltz	a0,80005b8c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b84:	0905                	addi	s2,s2,1
    80005b86:	09a1                	addi	s3,s3,8
    80005b88:	fb491be3          	bne	s2,s4,80005b3e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8c:	10048913          	addi	s2,s1,256
    80005b90:	6088                	ld	a0,0(s1)
    80005b92:	c529                	beqz	a0,80005bdc <sys_exec+0xf8>
    kfree(argv[i]);
    80005b94:	ffffb097          	auipc	ra,0xffffb
    80005b98:	e64080e7          	jalr	-412(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9c:	04a1                	addi	s1,s1,8
    80005b9e:	ff2499e3          	bne	s1,s2,80005b90 <sys_exec+0xac>
  return -1;
    80005ba2:	597d                	li	s2,-1
    80005ba4:	a82d                	j	80005bde <sys_exec+0xfa>
      argv[i] = 0;
    80005ba6:	0a8e                	slli	s5,s5,0x3
    80005ba8:	fc040793          	addi	a5,s0,-64
    80005bac:	9abe                	add	s5,s5,a5
    80005bae:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bb2:	e4040593          	addi	a1,s0,-448
    80005bb6:	f4040513          	addi	a0,s0,-192
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	194080e7          	jalr	404(ra) # 80004d4e <exec>
    80005bc2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc4:	10048993          	addi	s3,s1,256
    80005bc8:	6088                	ld	a0,0(s1)
    80005bca:	c911                	beqz	a0,80005bde <sys_exec+0xfa>
    kfree(argv[i]);
    80005bcc:	ffffb097          	auipc	ra,0xffffb
    80005bd0:	e2c080e7          	jalr	-468(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd4:	04a1                	addi	s1,s1,8
    80005bd6:	ff3499e3          	bne	s1,s3,80005bc8 <sys_exec+0xe4>
    80005bda:	a011                	j	80005bde <sys_exec+0xfa>
  return -1;
    80005bdc:	597d                	li	s2,-1
}
    80005bde:	854a                	mv	a0,s2
    80005be0:	60be                	ld	ra,456(sp)
    80005be2:	641e                	ld	s0,448(sp)
    80005be4:	74fa                	ld	s1,440(sp)
    80005be6:	795a                	ld	s2,432(sp)
    80005be8:	79ba                	ld	s3,424(sp)
    80005bea:	7a1a                	ld	s4,416(sp)
    80005bec:	6afa                	ld	s5,408(sp)
    80005bee:	6179                	addi	sp,sp,464
    80005bf0:	8082                	ret

0000000080005bf2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bf2:	7139                	addi	sp,sp,-64
    80005bf4:	fc06                	sd	ra,56(sp)
    80005bf6:	f822                	sd	s0,48(sp)
    80005bf8:	f426                	sd	s1,40(sp)
    80005bfa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bfc:	ffffc097          	auipc	ra,0xffffc
    80005c00:	db4080e7          	jalr	-588(ra) # 800019b0 <myproc>
    80005c04:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c06:	fd840593          	addi	a1,s0,-40
    80005c0a:	4501                	li	a0,0
    80005c0c:	ffffd097          	auipc	ra,0xffffd
    80005c10:	f98080e7          	jalr	-104(ra) # 80002ba4 <argaddr>
    return -1;
    80005c14:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c16:	0e054063          	bltz	a0,80005cf6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c1a:	fc840593          	addi	a1,s0,-56
    80005c1e:	fd040513          	addi	a0,s0,-48
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	dfc080e7          	jalr	-516(ra) # 80004a1e <pipealloc>
    return -1;
    80005c2a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c2c:	0c054563          	bltz	a0,80005cf6 <sys_pipe+0x104>
  fd0 = -1;
    80005c30:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c34:	fd043503          	ld	a0,-48(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	508080e7          	jalr	1288(ra) # 80005140 <fdalloc>
    80005c40:	fca42223          	sw	a0,-60(s0)
    80005c44:	08054c63          	bltz	a0,80005cdc <sys_pipe+0xea>
    80005c48:	fc843503          	ld	a0,-56(s0)
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	4f4080e7          	jalr	1268(ra) # 80005140 <fdalloc>
    80005c54:	fca42023          	sw	a0,-64(s0)
    80005c58:	06054863          	bltz	a0,80005cc8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c5c:	4691                	li	a3,4
    80005c5e:	fc440613          	addi	a2,s0,-60
    80005c62:	fd843583          	ld	a1,-40(s0)
    80005c66:	68a8                	ld	a0,80(s1)
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	a0a080e7          	jalr	-1526(ra) # 80001672 <copyout>
    80005c70:	02054063          	bltz	a0,80005c90 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c74:	4691                	li	a3,4
    80005c76:	fc040613          	addi	a2,s0,-64
    80005c7a:	fd843583          	ld	a1,-40(s0)
    80005c7e:	0591                	addi	a1,a1,4
    80005c80:	68a8                	ld	a0,80(s1)
    80005c82:	ffffc097          	auipc	ra,0xffffc
    80005c86:	9f0080e7          	jalr	-1552(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c8a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c8c:	06055563          	bgez	a0,80005cf6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c90:	fc442783          	lw	a5,-60(s0)
    80005c94:	07e9                	addi	a5,a5,26
    80005c96:	078e                	slli	a5,a5,0x3
    80005c98:	97a6                	add	a5,a5,s1
    80005c9a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c9e:	fc042503          	lw	a0,-64(s0)
    80005ca2:	0569                	addi	a0,a0,26
    80005ca4:	050e                	slli	a0,a0,0x3
    80005ca6:	9526                	add	a0,a0,s1
    80005ca8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cac:	fd043503          	ld	a0,-48(s0)
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	a3e080e7          	jalr	-1474(ra) # 800046ee <fileclose>
    fileclose(wf);
    80005cb8:	fc843503          	ld	a0,-56(s0)
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	a32080e7          	jalr	-1486(ra) # 800046ee <fileclose>
    return -1;
    80005cc4:	57fd                	li	a5,-1
    80005cc6:	a805                	j	80005cf6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cc8:	fc442783          	lw	a5,-60(s0)
    80005ccc:	0007c863          	bltz	a5,80005cdc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cd0:	01a78513          	addi	a0,a5,26
    80005cd4:	050e                	slli	a0,a0,0x3
    80005cd6:	9526                	add	a0,a0,s1
    80005cd8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cdc:	fd043503          	ld	a0,-48(s0)
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	a0e080e7          	jalr	-1522(ra) # 800046ee <fileclose>
    fileclose(wf);
    80005ce8:	fc843503          	ld	a0,-56(s0)
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	a02080e7          	jalr	-1534(ra) # 800046ee <fileclose>
    return -1;
    80005cf4:	57fd                	li	a5,-1
}
    80005cf6:	853e                	mv	a0,a5
    80005cf8:	70e2                	ld	ra,56(sp)
    80005cfa:	7442                	ld	s0,48(sp)
    80005cfc:	74a2                	ld	s1,40(sp)
    80005cfe:	6121                	addi	sp,sp,64
    80005d00:	8082                	ret
	...

0000000080005d10 <kernelvec>:
    80005d10:	7111                	addi	sp,sp,-256
    80005d12:	e006                	sd	ra,0(sp)
    80005d14:	e40a                	sd	sp,8(sp)
    80005d16:	e80e                	sd	gp,16(sp)
    80005d18:	ec12                	sd	tp,24(sp)
    80005d1a:	f016                	sd	t0,32(sp)
    80005d1c:	f41a                	sd	t1,40(sp)
    80005d1e:	f81e                	sd	t2,48(sp)
    80005d20:	fc22                	sd	s0,56(sp)
    80005d22:	e0a6                	sd	s1,64(sp)
    80005d24:	e4aa                	sd	a0,72(sp)
    80005d26:	e8ae                	sd	a1,80(sp)
    80005d28:	ecb2                	sd	a2,88(sp)
    80005d2a:	f0b6                	sd	a3,96(sp)
    80005d2c:	f4ba                	sd	a4,104(sp)
    80005d2e:	f8be                	sd	a5,112(sp)
    80005d30:	fcc2                	sd	a6,120(sp)
    80005d32:	e146                	sd	a7,128(sp)
    80005d34:	e54a                	sd	s2,136(sp)
    80005d36:	e94e                	sd	s3,144(sp)
    80005d38:	ed52                	sd	s4,152(sp)
    80005d3a:	f156                	sd	s5,160(sp)
    80005d3c:	f55a                	sd	s6,168(sp)
    80005d3e:	f95e                	sd	s7,176(sp)
    80005d40:	fd62                	sd	s8,184(sp)
    80005d42:	e1e6                	sd	s9,192(sp)
    80005d44:	e5ea                	sd	s10,200(sp)
    80005d46:	e9ee                	sd	s11,208(sp)
    80005d48:	edf2                	sd	t3,216(sp)
    80005d4a:	f1f6                	sd	t4,224(sp)
    80005d4c:	f5fa                	sd	t5,232(sp)
    80005d4e:	f9fe                	sd	t6,240(sp)
    80005d50:	c65fc0ef          	jal	ra,800029b4 <kerneltrap>
    80005d54:	6082                	ld	ra,0(sp)
    80005d56:	6122                	ld	sp,8(sp)
    80005d58:	61c2                	ld	gp,16(sp)
    80005d5a:	7282                	ld	t0,32(sp)
    80005d5c:	7322                	ld	t1,40(sp)
    80005d5e:	73c2                	ld	t2,48(sp)
    80005d60:	7462                	ld	s0,56(sp)
    80005d62:	6486                	ld	s1,64(sp)
    80005d64:	6526                	ld	a0,72(sp)
    80005d66:	65c6                	ld	a1,80(sp)
    80005d68:	6666                	ld	a2,88(sp)
    80005d6a:	7686                	ld	a3,96(sp)
    80005d6c:	7726                	ld	a4,104(sp)
    80005d6e:	77c6                	ld	a5,112(sp)
    80005d70:	7866                	ld	a6,120(sp)
    80005d72:	688a                	ld	a7,128(sp)
    80005d74:	692a                	ld	s2,136(sp)
    80005d76:	69ca                	ld	s3,144(sp)
    80005d78:	6a6a                	ld	s4,152(sp)
    80005d7a:	7a8a                	ld	s5,160(sp)
    80005d7c:	7b2a                	ld	s6,168(sp)
    80005d7e:	7bca                	ld	s7,176(sp)
    80005d80:	7c6a                	ld	s8,184(sp)
    80005d82:	6c8e                	ld	s9,192(sp)
    80005d84:	6d2e                	ld	s10,200(sp)
    80005d86:	6dce                	ld	s11,208(sp)
    80005d88:	6e6e                	ld	t3,216(sp)
    80005d8a:	7e8e                	ld	t4,224(sp)
    80005d8c:	7f2e                	ld	t5,232(sp)
    80005d8e:	7fce                	ld	t6,240(sp)
    80005d90:	6111                	addi	sp,sp,256
    80005d92:	10200073          	sret
    80005d96:	00000013          	nop
    80005d9a:	00000013          	nop
    80005d9e:	0001                	nop

0000000080005da0 <timervec>:
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	e10c                	sd	a1,0(a0)
    80005da6:	e510                	sd	a2,8(a0)
    80005da8:	e914                	sd	a3,16(a0)
    80005daa:	6d0c                	ld	a1,24(a0)
    80005dac:	7110                	ld	a2,32(a0)
    80005dae:	6194                	ld	a3,0(a1)
    80005db0:	96b2                	add	a3,a3,a2
    80005db2:	e194                	sd	a3,0(a1)
    80005db4:	4589                	li	a1,2
    80005db6:	14459073          	csrw	sip,a1
    80005dba:	6914                	ld	a3,16(a0)
    80005dbc:	6510                	ld	a2,8(a0)
    80005dbe:	610c                	ld	a1,0(a0)
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	30200073          	mret
	...

0000000080005dca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dca:	1141                	addi	sp,sp,-16
    80005dcc:	e422                	sd	s0,8(sp)
    80005dce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dd0:	0c0007b7          	lui	a5,0xc000
    80005dd4:	4705                	li	a4,1
    80005dd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dd8:	c3d8                	sw	a4,4(a5)
}
    80005dda:	6422                	ld	s0,8(sp)
    80005ddc:	0141                	addi	sp,sp,16
    80005dde:	8082                	ret

0000000080005de0 <plicinithart>:

void
plicinithart(void)
{
    80005de0:	1141                	addi	sp,sp,-16
    80005de2:	e406                	sd	ra,8(sp)
    80005de4:	e022                	sd	s0,0(sp)
    80005de6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	b9c080e7          	jalr	-1124(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005df0:	0085171b          	slliw	a4,a0,0x8
    80005df4:	0c0027b7          	lui	a5,0xc002
    80005df8:	97ba                	add	a5,a5,a4
    80005dfa:	40200713          	li	a4,1026
    80005dfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e02:	00d5151b          	slliw	a0,a0,0xd
    80005e06:	0c2017b7          	lui	a5,0xc201
    80005e0a:	953e                	add	a0,a0,a5
    80005e0c:	00052023          	sw	zero,0(a0)
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret

0000000080005e18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e18:	1141                	addi	sp,sp,-16
    80005e1a:	e406                	sd	ra,8(sp)
    80005e1c:	e022                	sd	s0,0(sp)
    80005e1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	b64080e7          	jalr	-1180(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e28:	00d5179b          	slliw	a5,a0,0xd
    80005e2c:	0c201537          	lui	a0,0xc201
    80005e30:	953e                	add	a0,a0,a5
  return irq;
}
    80005e32:	4148                	lw	a0,4(a0)
    80005e34:	60a2                	ld	ra,8(sp)
    80005e36:	6402                	ld	s0,0(sp)
    80005e38:	0141                	addi	sp,sp,16
    80005e3a:	8082                	ret

0000000080005e3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e3c:	1101                	addi	sp,sp,-32
    80005e3e:	ec06                	sd	ra,24(sp)
    80005e40:	e822                	sd	s0,16(sp)
    80005e42:	e426                	sd	s1,8(sp)
    80005e44:	1000                	addi	s0,sp,32
    80005e46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	b3c080e7          	jalr	-1220(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e50:	00d5151b          	slliw	a0,a0,0xd
    80005e54:	0c2017b7          	lui	a5,0xc201
    80005e58:	97aa                	add	a5,a5,a0
    80005e5a:	c3c4                	sw	s1,4(a5)
}
    80005e5c:	60e2                	ld	ra,24(sp)
    80005e5e:	6442                	ld	s0,16(sp)
    80005e60:	64a2                	ld	s1,8(sp)
    80005e62:	6105                	addi	sp,sp,32
    80005e64:	8082                	ret

0000000080005e66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e66:	1141                	addi	sp,sp,-16
    80005e68:	e406                	sd	ra,8(sp)
    80005e6a:	e022                	sd	s0,0(sp)
    80005e6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e6e:	479d                	li	a5,7
    80005e70:	06a7c963          	blt	a5,a0,80005ee2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e74:	0001d797          	auipc	a5,0x1d
    80005e78:	18c78793          	addi	a5,a5,396 # 80023000 <disk>
    80005e7c:	00a78733          	add	a4,a5,a0
    80005e80:	6789                	lui	a5,0x2
    80005e82:	97ba                	add	a5,a5,a4
    80005e84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e88:	e7ad                	bnez	a5,80005ef2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e8a:	00451793          	slli	a5,a0,0x4
    80005e8e:	0001f717          	auipc	a4,0x1f
    80005e92:	17270713          	addi	a4,a4,370 # 80025000 <disk+0x2000>
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e9e:	6314                	ld	a3,0(a4)
    80005ea0:	96be                	add	a3,a3,a5
    80005ea2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ea6:	6314                	ld	a3,0(a4)
    80005ea8:	96be                	add	a3,a3,a5
    80005eaa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005eae:	6318                	ld	a4,0(a4)
    80005eb0:	97ba                	add	a5,a5,a4
    80005eb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005eb6:	0001d797          	auipc	a5,0x1d
    80005eba:	14a78793          	addi	a5,a5,330 # 80023000 <disk>
    80005ebe:	97aa                	add	a5,a5,a0
    80005ec0:	6509                	lui	a0,0x2
    80005ec2:	953e                	add	a0,a0,a5
    80005ec4:	4785                	li	a5,1
    80005ec6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eca:	0001f517          	auipc	a0,0x1f
    80005ece:	14e50513          	addi	a0,a0,334 # 80025018 <disk+0x2018>
    80005ed2:	ffffc097          	auipc	ra,0xffffc
    80005ed6:	366080e7          	jalr	870(ra) # 80002238 <wakeup>
}
    80005eda:	60a2                	ld	ra,8(sp)
    80005edc:	6402                	ld	s0,0(sp)
    80005ede:	0141                	addi	sp,sp,16
    80005ee0:	8082                	ret
    panic("free_desc 1");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	9e650513          	addi	a0,a0,-1562 # 800088c8 <syscalls+0x328>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	9e650513          	addi	a0,a0,-1562 # 800088d8 <syscalls+0x338>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	644080e7          	jalr	1604(ra) # 8000053e <panic>

0000000080005f02 <virtio_disk_init>:
{
    80005f02:	1101                	addi	sp,sp,-32
    80005f04:	ec06                	sd	ra,24(sp)
    80005f06:	e822                	sd	s0,16(sp)
    80005f08:	e426                	sd	s1,8(sp)
    80005f0a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f0c:	00003597          	auipc	a1,0x3
    80005f10:	9dc58593          	addi	a1,a1,-1572 # 800088e8 <syscalls+0x348>
    80005f14:	0001f517          	auipc	a0,0x1f
    80005f18:	21450513          	addi	a0,a0,532 # 80025128 <disk+0x2128>
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	c38080e7          	jalr	-968(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f24:	100017b7          	lui	a5,0x10001
    80005f28:	4398                	lw	a4,0(a5)
    80005f2a:	2701                	sext.w	a4,a4
    80005f2c:	747277b7          	lui	a5,0x74727
    80005f30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f34:	0ef71163          	bne	a4,a5,80006016 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	43dc                	lw	a5,4(a5)
    80005f3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f40:	4705                	li	a4,1
    80005f42:	0ce79a63          	bne	a5,a4,80006016 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f46:	100017b7          	lui	a5,0x10001
    80005f4a:	479c                	lw	a5,8(a5)
    80005f4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f4e:	4709                	li	a4,2
    80005f50:	0ce79363          	bne	a5,a4,80006016 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f54:	100017b7          	lui	a5,0x10001
    80005f58:	47d8                	lw	a4,12(a5)
    80005f5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f5c:	554d47b7          	lui	a5,0x554d4
    80005f60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f64:	0af71963          	bne	a4,a5,80006016 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f68:	100017b7          	lui	a5,0x10001
    80005f6c:	4705                	li	a4,1
    80005f6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f70:	470d                	li	a4,3
    80005f72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f76:	c7ffe737          	lui	a4,0xc7ffe
    80005f7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f80:	2701                	sext.w	a4,a4
    80005f82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f84:	472d                	li	a4,11
    80005f86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f88:	473d                	li	a4,15
    80005f8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f8c:	6705                	lui	a4,0x1
    80005f8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f94:	5bdc                	lw	a5,52(a5)
    80005f96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f98:	c7d9                	beqz	a5,80006026 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f9a:	471d                	li	a4,7
    80005f9c:	08f77d63          	bgeu	a4,a5,80006036 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fa0:	100014b7          	lui	s1,0x10001
    80005fa4:	47a1                	li	a5,8
    80005fa6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fa8:	6609                	lui	a2,0x2
    80005faa:	4581                	li	a1,0
    80005fac:	0001d517          	auipc	a0,0x1d
    80005fb0:	05450513          	addi	a0,a0,84 # 80023000 <disk>
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	d2c080e7          	jalr	-724(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fbc:	0001d717          	auipc	a4,0x1d
    80005fc0:	04470713          	addi	a4,a4,68 # 80023000 <disk>
    80005fc4:	00c75793          	srli	a5,a4,0xc
    80005fc8:	2781                	sext.w	a5,a5
    80005fca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fcc:	0001f797          	auipc	a5,0x1f
    80005fd0:	03478793          	addi	a5,a5,52 # 80025000 <disk+0x2000>
    80005fd4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fd6:	0001d717          	auipc	a4,0x1d
    80005fda:	0aa70713          	addi	a4,a4,170 # 80023080 <disk+0x80>
    80005fde:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fe0:	0001e717          	auipc	a4,0x1e
    80005fe4:	02070713          	addi	a4,a4,32 # 80024000 <disk+0x1000>
    80005fe8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fea:	4705                	li	a4,1
    80005fec:	00e78c23          	sb	a4,24(a5)
    80005ff0:	00e78ca3          	sb	a4,25(a5)
    80005ff4:	00e78d23          	sb	a4,26(a5)
    80005ff8:	00e78da3          	sb	a4,27(a5)
    80005ffc:	00e78e23          	sb	a4,28(a5)
    80006000:	00e78ea3          	sb	a4,29(a5)
    80006004:	00e78f23          	sb	a4,30(a5)
    80006008:	00e78fa3          	sb	a4,31(a5)
}
    8000600c:	60e2                	ld	ra,24(sp)
    8000600e:	6442                	ld	s0,16(sp)
    80006010:	64a2                	ld	s1,8(sp)
    80006012:	6105                	addi	sp,sp,32
    80006014:	8082                	ret
    panic("could not find virtio disk");
    80006016:	00003517          	auipc	a0,0x3
    8000601a:	8e250513          	addi	a0,a0,-1822 # 800088f8 <syscalls+0x358>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006026:	00003517          	auipc	a0,0x3
    8000602a:	8f250513          	addi	a0,a0,-1806 # 80008918 <syscalls+0x378>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	510080e7          	jalr	1296(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006036:	00003517          	auipc	a0,0x3
    8000603a:	90250513          	addi	a0,a0,-1790 # 80008938 <syscalls+0x398>
    8000603e:	ffffa097          	auipc	ra,0xffffa
    80006042:	500080e7          	jalr	1280(ra) # 8000053e <panic>

0000000080006046 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006046:	7159                	addi	sp,sp,-112
    80006048:	f486                	sd	ra,104(sp)
    8000604a:	f0a2                	sd	s0,96(sp)
    8000604c:	eca6                	sd	s1,88(sp)
    8000604e:	e8ca                	sd	s2,80(sp)
    80006050:	e4ce                	sd	s3,72(sp)
    80006052:	e0d2                	sd	s4,64(sp)
    80006054:	fc56                	sd	s5,56(sp)
    80006056:	f85a                	sd	s6,48(sp)
    80006058:	f45e                	sd	s7,40(sp)
    8000605a:	f062                	sd	s8,32(sp)
    8000605c:	ec66                	sd	s9,24(sp)
    8000605e:	e86a                	sd	s10,16(sp)
    80006060:	1880                	addi	s0,sp,112
    80006062:	892a                	mv	s2,a0
    80006064:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006066:	00c52c83          	lw	s9,12(a0)
    8000606a:	001c9c9b          	slliw	s9,s9,0x1
    8000606e:	1c82                	slli	s9,s9,0x20
    80006070:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006074:	0001f517          	auipc	a0,0x1f
    80006078:	0b450513          	addi	a0,a0,180 # 80025128 <disk+0x2128>
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006084:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006086:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006088:	0001db97          	auipc	s7,0x1d
    8000608c:	f78b8b93          	addi	s7,s7,-136 # 80023000 <disk>
    80006090:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006092:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006094:	8a4e                	mv	s4,s3
    80006096:	a051                	j	8000611a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006098:	00fb86b3          	add	a3,s7,a5
    8000609c:	96da                	add	a3,a3,s6
    8000609e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060a4:	0207c563          	bltz	a5,800060ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060a8:	2485                	addiw	s1,s1,1
    800060aa:	0711                	addi	a4,a4,4
    800060ac:	25548063          	beq	s1,s5,800062ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060b2:	0001f697          	auipc	a3,0x1f
    800060b6:	f6668693          	addi	a3,a3,-154 # 80025018 <disk+0x2018>
    800060ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060bc:	0006c583          	lbu	a1,0(a3)
    800060c0:	fde1                	bnez	a1,80006098 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060c2:	2785                	addiw	a5,a5,1
    800060c4:	0685                	addi	a3,a3,1
    800060c6:	ff879be3          	bne	a5,s8,800060bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ca:	57fd                	li	a5,-1
    800060cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060ce:	02905a63          	blez	s1,80006102 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060d2:	f9042503          	lw	a0,-112(s0)
    800060d6:	00000097          	auipc	ra,0x0
    800060da:	d90080e7          	jalr	-624(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    800060de:	4785                	li	a5,1
    800060e0:	0297d163          	bge	a5,s1,80006102 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060e4:	f9442503          	lw	a0,-108(s0)
    800060e8:	00000097          	auipc	ra,0x0
    800060ec:	d7e080e7          	jalr	-642(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    800060f0:	4789                	li	a5,2
    800060f2:	0097d863          	bge	a5,s1,80006102 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060f6:	f9842503          	lw	a0,-104(s0)
    800060fa:	00000097          	auipc	ra,0x0
    800060fe:	d6c080e7          	jalr	-660(ra) # 80005e66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006102:	0001f597          	auipc	a1,0x1f
    80006106:	02658593          	addi	a1,a1,38 # 80025128 <disk+0x2128>
    8000610a:	0001f517          	auipc	a0,0x1f
    8000610e:	f0e50513          	addi	a0,a0,-242 # 80025018 <disk+0x2018>
    80006112:	ffffc097          	auipc	ra,0xffffc
    80006116:	f9a080e7          	jalr	-102(ra) # 800020ac <sleep>
  for(int i = 0; i < 3; i++){
    8000611a:	f9040713          	addi	a4,s0,-112
    8000611e:	84ce                	mv	s1,s3
    80006120:	bf41                	j	800060b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006122:	20058713          	addi	a4,a1,512
    80006126:	00471693          	slli	a3,a4,0x4
    8000612a:	0001d717          	auipc	a4,0x1d
    8000612e:	ed670713          	addi	a4,a4,-298 # 80023000 <disk>
    80006132:	9736                	add	a4,a4,a3
    80006134:	4685                	li	a3,1
    80006136:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000613a:	20058713          	addi	a4,a1,512
    8000613e:	00471693          	slli	a3,a4,0x4
    80006142:	0001d717          	auipc	a4,0x1d
    80006146:	ebe70713          	addi	a4,a4,-322 # 80023000 <disk>
    8000614a:	9736                	add	a4,a4,a3
    8000614c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006150:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006154:	7679                	lui	a2,0xffffe
    80006156:	963e                	add	a2,a2,a5
    80006158:	0001f697          	auipc	a3,0x1f
    8000615c:	ea868693          	addi	a3,a3,-344 # 80025000 <disk+0x2000>
    80006160:	6298                	ld	a4,0(a3)
    80006162:	9732                	add	a4,a4,a2
    80006164:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006166:	6298                	ld	a4,0(a3)
    80006168:	9732                	add	a4,a4,a2
    8000616a:	4541                	li	a0,16
    8000616c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000616e:	6298                	ld	a4,0(a3)
    80006170:	9732                	add	a4,a4,a2
    80006172:	4505                	li	a0,1
    80006174:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f9442703          	lw	a4,-108(s0)
    8000617c:	6288                	ld	a0,0(a3)
    8000617e:	962a                	add	a2,a2,a0
    80006180:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	6290                	ld	a2,0(a3)
    80006188:	963a                	add	a2,a2,a4
    8000618a:	05890513          	addi	a0,s2,88
    8000618e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006190:	6294                	ld	a3,0(a3)
    80006192:	96ba                	add	a3,a3,a4
    80006194:	40000613          	li	a2,1024
    80006198:	c690                	sw	a2,8(a3)
  if(write)
    8000619a:	140d0063          	beqz	s10,800062da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000619e:	0001f697          	auipc	a3,0x1f
    800061a2:	e626b683          	ld	a3,-414(a3) # 80025000 <disk+0x2000>
    800061a6:	96ba                	add	a3,a3,a4
    800061a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ac:	0001d817          	auipc	a6,0x1d
    800061b0:	e5480813          	addi	a6,a6,-428 # 80023000 <disk>
    800061b4:	0001f517          	auipc	a0,0x1f
    800061b8:	e4c50513          	addi	a0,a0,-436 # 80025000 <disk+0x2000>
    800061bc:	6114                	ld	a3,0(a0)
    800061be:	96ba                	add	a3,a3,a4
    800061c0:	00c6d603          	lhu	a2,12(a3)
    800061c4:	00166613          	ori	a2,a2,1
    800061c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061cc:	f9842683          	lw	a3,-104(s0)
    800061d0:	6110                	ld	a2,0(a0)
    800061d2:	9732                	add	a4,a4,a2
    800061d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061d8:	20058613          	addi	a2,a1,512
    800061dc:	0612                	slli	a2,a2,0x4
    800061de:	9642                	add	a2,a2,a6
    800061e0:	577d                	li	a4,-1
    800061e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061e6:	00469713          	slli	a4,a3,0x4
    800061ea:	6114                	ld	a3,0(a0)
    800061ec:	96ba                	add	a3,a3,a4
    800061ee:	03078793          	addi	a5,a5,48
    800061f2:	97c2                	add	a5,a5,a6
    800061f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061f6:	611c                	ld	a5,0(a0)
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	4685                	li	a3,1
    800061fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061fe:	611c                	ld	a5,0(a0)
    80006200:	97ba                	add	a5,a5,a4
    80006202:	4809                	li	a6,2
    80006204:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006208:	611c                	ld	a5,0(a0)
    8000620a:	973e                	add	a4,a4,a5
    8000620c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006210:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006214:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006218:	6518                	ld	a4,8(a0)
    8000621a:	00275783          	lhu	a5,2(a4)
    8000621e:	8b9d                	andi	a5,a5,7
    80006220:	0786                	slli	a5,a5,0x1
    80006222:	97ba                	add	a5,a5,a4
    80006224:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006228:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000622c:	6518                	ld	a4,8(a0)
    8000622e:	00275783          	lhu	a5,2(a4)
    80006232:	2785                	addiw	a5,a5,1
    80006234:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006238:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000623c:	100017b7          	lui	a5,0x10001
    80006240:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006244:	00492703          	lw	a4,4(s2)
    80006248:	4785                	li	a5,1
    8000624a:	02f71163          	bne	a4,a5,8000626c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000624e:	0001f997          	auipc	s3,0x1f
    80006252:	eda98993          	addi	s3,s3,-294 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006256:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006258:	85ce                	mv	a1,s3
    8000625a:	854a                	mv	a0,s2
    8000625c:	ffffc097          	auipc	ra,0xffffc
    80006260:	e50080e7          	jalr	-432(ra) # 800020ac <sleep>
  while(b->disk == 1) {
    80006264:	00492783          	lw	a5,4(s2)
    80006268:	fe9788e3          	beq	a5,s1,80006258 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000626c:	f9042903          	lw	s2,-112(s0)
    80006270:	20090793          	addi	a5,s2,512
    80006274:	00479713          	slli	a4,a5,0x4
    80006278:	0001d797          	auipc	a5,0x1d
    8000627c:	d8878793          	addi	a5,a5,-632 # 80023000 <disk>
    80006280:	97ba                	add	a5,a5,a4
    80006282:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006286:	0001f997          	auipc	s3,0x1f
    8000628a:	d7a98993          	addi	s3,s3,-646 # 80025000 <disk+0x2000>
    8000628e:	00491713          	slli	a4,s2,0x4
    80006292:	0009b783          	ld	a5,0(s3)
    80006296:	97ba                	add	a5,a5,a4
    80006298:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000629c:	854a                	mv	a0,s2
    8000629e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062a2:	00000097          	auipc	ra,0x0
    800062a6:	bc4080e7          	jalr	-1084(ra) # 80005e66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062aa:	8885                	andi	s1,s1,1
    800062ac:	f0ed                	bnez	s1,8000628e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ae:	0001f517          	auipc	a0,0x1f
    800062b2:	e7a50513          	addi	a0,a0,-390 # 80025128 <disk+0x2128>
    800062b6:	ffffb097          	auipc	ra,0xffffb
    800062ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
}
    800062be:	70a6                	ld	ra,104(sp)
    800062c0:	7406                	ld	s0,96(sp)
    800062c2:	64e6                	ld	s1,88(sp)
    800062c4:	6946                	ld	s2,80(sp)
    800062c6:	69a6                	ld	s3,72(sp)
    800062c8:	6a06                	ld	s4,64(sp)
    800062ca:	7ae2                	ld	s5,56(sp)
    800062cc:	7b42                	ld	s6,48(sp)
    800062ce:	7ba2                	ld	s7,40(sp)
    800062d0:	7c02                	ld	s8,32(sp)
    800062d2:	6ce2                	ld	s9,24(sp)
    800062d4:	6d42                	ld	s10,16(sp)
    800062d6:	6165                	addi	sp,sp,112
    800062d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062da:	0001f697          	auipc	a3,0x1f
    800062de:	d266b683          	ld	a3,-730(a3) # 80025000 <disk+0x2000>
    800062e2:	96ba                	add	a3,a3,a4
    800062e4:	4609                	li	a2,2
    800062e6:	00c69623          	sh	a2,12(a3)
    800062ea:	b5c9                	j	800061ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062ec:	f9042583          	lw	a1,-112(s0)
    800062f0:	20058793          	addi	a5,a1,512
    800062f4:	0792                	slli	a5,a5,0x4
    800062f6:	0001d517          	auipc	a0,0x1d
    800062fa:	db250513          	addi	a0,a0,-590 # 800230a8 <disk+0xa8>
    800062fe:	953e                	add	a0,a0,a5
  if(write)
    80006300:	e20d11e3          	bnez	s10,80006122 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006304:	20058713          	addi	a4,a1,512
    80006308:	00471693          	slli	a3,a4,0x4
    8000630c:	0001d717          	auipc	a4,0x1d
    80006310:	cf470713          	addi	a4,a4,-780 # 80023000 <disk>
    80006314:	9736                	add	a4,a4,a3
    80006316:	0a072423          	sw	zero,168(a4)
    8000631a:	b505                	j	8000613a <virtio_disk_rw+0xf4>

000000008000631c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000631c:	1101                	addi	sp,sp,-32
    8000631e:	ec06                	sd	ra,24(sp)
    80006320:	e822                	sd	s0,16(sp)
    80006322:	e426                	sd	s1,8(sp)
    80006324:	e04a                	sd	s2,0(sp)
    80006326:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006328:	0001f517          	auipc	a0,0x1f
    8000632c:	e0050513          	addi	a0,a0,-512 # 80025128 <disk+0x2128>
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006338:	10001737          	lui	a4,0x10001
    8000633c:	533c                	lw	a5,96(a4)
    8000633e:	8b8d                	andi	a5,a5,3
    80006340:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006342:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006346:	0001f797          	auipc	a5,0x1f
    8000634a:	cba78793          	addi	a5,a5,-838 # 80025000 <disk+0x2000>
    8000634e:	6b94                	ld	a3,16(a5)
    80006350:	0207d703          	lhu	a4,32(a5)
    80006354:	0026d783          	lhu	a5,2(a3)
    80006358:	06f70163          	beq	a4,a5,800063ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000635c:	0001d917          	auipc	s2,0x1d
    80006360:	ca490913          	addi	s2,s2,-860 # 80023000 <disk>
    80006364:	0001f497          	auipc	s1,0x1f
    80006368:	c9c48493          	addi	s1,s1,-868 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000636c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006370:	6898                	ld	a4,16(s1)
    80006372:	0204d783          	lhu	a5,32(s1)
    80006376:	8b9d                	andi	a5,a5,7
    80006378:	078e                	slli	a5,a5,0x3
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000637e:	20078713          	addi	a4,a5,512
    80006382:	0712                	slli	a4,a4,0x4
    80006384:	974a                	add	a4,a4,s2
    80006386:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000638a:	e731                	bnez	a4,800063d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000638c:	20078793          	addi	a5,a5,512
    80006390:	0792                	slli	a5,a5,0x4
    80006392:	97ca                	add	a5,a5,s2
    80006394:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006396:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000639a:	ffffc097          	auipc	ra,0xffffc
    8000639e:	e9e080e7          	jalr	-354(ra) # 80002238 <wakeup>

    disk.used_idx += 1;
    800063a2:	0204d783          	lhu	a5,32(s1)
    800063a6:	2785                	addiw	a5,a5,1
    800063a8:	17c2                	slli	a5,a5,0x30
    800063aa:	93c1                	srli	a5,a5,0x30
    800063ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063b0:	6898                	ld	a4,16(s1)
    800063b2:	00275703          	lhu	a4,2(a4)
    800063b6:	faf71be3          	bne	a4,a5,8000636c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063ba:	0001f517          	auipc	a0,0x1f
    800063be:	d6e50513          	addi	a0,a0,-658 # 80025128 <disk+0x2128>
    800063c2:	ffffb097          	auipc	ra,0xffffb
    800063c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
}
    800063ca:	60e2                	ld	ra,24(sp)
    800063cc:	6442                	ld	s0,16(sp)
    800063ce:	64a2                	ld	s1,8(sp)
    800063d0:	6902                	ld	s2,0(sp)
    800063d2:	6105                	addi	sp,sp,32
    800063d4:	8082                	ret
      panic("virtio_disk_intr status");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	58250513          	addi	a0,a0,1410 # 80008958 <syscalls+0x3b8>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
