	include	custom.i
	include	blit.i

DMAB_BLTDONE	equ	14

init:		lea	$dff000,a5

		move.w	DMACONR(a5),d0
		or.w	#$8000,d0
		move.w	d0,olddmareq

		move.w	INTENAR(a5),d0
		or.w	#$8000,d0
		move.w	d0,oldintena

		move.w	INTREQR(a5),d0
		or.w	#$8000,d0
		move.w	d0,oldintreq

		move.w	ADKCONR(a5),d0
		or.w	#$8000,d0
		move.w	d0,oldadkcon

		move.l	$4,a6
		move.l	#gfxname,a1
		moveq	#0,d0
		jsr	-552(a6)
		move.l	d0,gfxbase
		move.l	d0,a6
		move.l	34(a6),oldview
		move.l	38(a6),oldcopper

		move.l	#0,a1
		jsr	-222(a6) ; LoadView
		jsr	-270(a6) ; WaitTOF
		jsr	-270(a6) ; WaitTOF

		move.l	$4,a6
		jsr	-132(a6) ; Forbid

		move	#$7fff,DMACON(a5)

		move.l	front_buffer,d0
		lea	copper,a0
		move	d0,6(a0)
		swap	d0
		move	d0,2(a0)

		move	#$1200,BPLCON0(a5)
		clr	BPLCON1(a5)
		clr	BPL1MOD(a5)
		clr	BPL2MOD(a5)
		move	#$2c81,DIWSTRT(a5)
		move	#$2cc1,DIWSTOP(a5)
		move	#$0038,DDFSTRT(a5)
		move	#$00d0,DDFSTOP(a5)

		lea	copper,a0
		move.l	a0,COP1LC(a5)
		move	COPJMP1(a5),d0

		move	#$83c0,DMACON(a5)
		move	#$7fff,INTENA(a5)

		move	#0,angle_z

mainloop:
waitVB1:	move.l	VPOSR(a5),d0
		and.l	#$1ff00,d0
		sub.l	#44<<8,d0
		bmi	waitVB1

		;move	#$050,COLOR(a5)

		jsr	clear_blit
		;jsr	waitblit

		;move	#$005,COLOR(a5)

		jsr	calc_screen_coords

		;move	#$990,COLOR(a5)

		jsr	draw_outlines
		;jsr	waitblit

		;move	#$422,COLOR(a5)

		jsr	area_fill
		;jsr	waitblit

		;move	#$055,COLOR(a5)

		move.l	back_buffer,d0
		move.l	front_buffer,d1
		move.l	d0,front_buffer
		move.l	d1,back_buffer
		lea	copper,a0
		move	d0,6(a0)
		swap	d0
		move	d0,2(a0)

waitVB2:	move.l	VPOSR(a5),d0
		and.l	#$1ff00,d0
		sub.l	#44<<8,d0
		bpl	waitVB2

		btst	#2,$016(a5)
		bne	normb

		; rmb is pressed
		tst	debounce
		bne	testlmb

		move	subpixel_enabled,d0
		add	#1,d0
		and	#1,d0
		move	d0,subpixel_enabled

		move	#$003,d1
		tst	d0
		beq	setcol0
		move	#$004,d1
setcol0:

		move	#1,debounce
		bra	testlmb

normb:		move	#0,debounce

testlmb:
		btst.b	#6,$bfe001
		bne	mainloop

exit:		move	#$7fff,DMACON(a5)

		move.l	oldcopper,COP1LC(a5)
		;move	COPJMP1(a5),d0

		move	olddmareq,DMACON(a5)

		move	#$7fff,INTENA(a5)
		move	oldintena,INTENA(a5)

		move	#$7fff,INTREQ(a5)
		move	oldintreq,INTREQ(a5)

		move	#$7fff,ADKCON(a5)
		move	oldadkcon,ADKCON(a5)

		move.l	gfxbase,a6
		move.l	oldview,a1
		jsr	-222(a6) ; LoadView
		jsr	-270(a6) ; WaitTOF
		jsr	-270(a6) ; WaitTOF

		move.l	$4,a6
		jsr	-138(a6) ; Permit
		rts

calc_screen_coords:
		lea	sin_tab,a0
		lea	screen_space_coords,a1
		move	angle_z,d2
		move	subpixel_enabled,d3

		move	d2,d0
		add	d0,d0
		move	(a0,d0),d0	; d0 = sin(angle) in 2.14

		move	#2048+512,d1
		sub	d2,d1
		and	#2047,d1
		add	d1,d1
		move	(a0,d1),d1	; d1 = cos(angle) in 2.14

		muls	#120<<6,d0	; d0 = x in 12.20
		muls	#120<<6,d1	; d1 = y in 12.20

		add.l	#(159<<20)+(1<<19)+(1<<15),d0
		add.l	#(127<<20)+(1<<19)+(1<<15),d1

		swap	d0		; x in 12.4
		swap	d1		; y in 12.4

		tst	d3
		bne	.spen1
		add	#1<<3,d0
		add	#1<<3,d1
		and	#$fff0,d0
		and	#$fff0,d1
.spen1:
		move	d0,(a1)+
		move	d1,(a1)+

		add	#683,d2
		and	#2047,d2

		move	d2,d0
		add	d0,d0
		move	(a0,d0),d0	; d0 = sin(angle) in 2.14

		move	#2048+512,d1
		sub	d2,d1
		and	#2047,d1
		add	d1,d1
		move	(a0,d1),d1	; d1 = cos(angle) in 2.14

		muls	#120<<6,d0	; d0 = x in 12.20
		muls	#120<<6,d1	; d1 = y in 12.20

		add.l	#(159<<20)+(1<<19)+(1<<15),d0
		add.l	#(127<<20)+(1<<19)+(1<<15),d1

		swap	d0		; x in 12.4
		swap	d1		; y in 12.4

		tst	d3
		bne	.spen2
		add	#1<<3,d0
		add	#1<<3,d1
		and	#$fff0,d0
		and	#$fff0,d1
.spen2:
		move	d0,(a1)+
		move	d1,(a1)+

		add	#682,d2
		and	#2047,d2

		move	d2,d0
		add	d0,d0
		move	(a0,d0),d0	; d0 = sin(angle) in 2.14

		move	#2048+512,d1
		sub	d2,d1
		and	#2047,d1
		add	d1,d1
		move	(a0,d1),d1	; d1 = cos(angle) in 2.14

		muls	#120<<6,d0	; d0 = x in 12.20
		muls	#120<<6,d1	; d1 = y in 12.20

		add.l	#(159<<20)+(1<<19)+(1<<15),d0
		add.l	#(127<<20)+(1<<19)+(1<<15),d1

		swap	d0		; x in 12.4
		swap	d1		; y in 12.4

		tst	d3
		bne	.spen3
		add	#1<<3,d0
		add	#1<<3,d1
		and	#$fff0,d0
		and	#$fff0,d1
.spen3:
		move	d0,(a1)+
		move	d1,(a1)+

		; Update angle for next frame.
		move	angle_z,d0
		add	#1,d0
		and	#2047,d0
		move	d0,angle_z

		rts

draw_outlines:
		;tst	subpixel_enabled
		;beq	draw_outlines_int

draw_outlines_subpixel:
		lea	screen_space_coords,a1
		move.l	back_buffer,a2

		move	(a1),d0
		move	2(a1),d1
		move	4(a1),d2
		move	6(a1),d3
		move.l	a2,a0
		jsr	polyline
		;jsr	intline

		move	4(a1),d0
		move	6(a1),d1
		move	8(a1),d2
		move	10(a1),d3
		move.l	a2,a0
		jsr	polyline
		;jsr	intline

		move	8(a1),d0
		move	10(a1),d1
		move	(a1),d2
		move	2(a1),d3
		move.l	a2,a0
		jsr	polyline
		;jsr	intline

		rts

draw_outlines_int:
		lea	screen_space_coords,a1
		move.l	back_buffer,a2

		move	(a1),d0
		move	2(a1),d1
		move	4(a1),d2
		move	6(a1),d3
		move.l	a2,a0
		;jsr	polyline
		jsr	intline

		move	4(a1),d0
		move	6(a1),d1
		move	8(a1),d2
		move	10(a1),d3
		move.l	a2,a0
		;jsr	polyline
		jsr	intline

		move	8(a1),d0
		move	10(a1),d1
		move	(a1),d2
		move	2(a1),d3
		move.l	a2,a0
		;jsr	polyline
		jsr	intline

		rts

polyline:
		cmp	d1,d3		; y2 - y1
		bpl	.is_down

		exg	d0,d2
		exg	d1,d3
.is_down:
		move	d2,d4
		move	d3,d5

		sub	d1,d5		; d5 = dy
		sub	d0,d4		; d4 = dx
		bmi	.oct_3_4

		cmp	d5,d4		; dx - dy
		bmi	.oct_2

.oct_1:
		move	d1,d4		; d4 = y1
		move	d3,d7		; d7 = y2

		sub	d1,d3		; d3 = dy

		add	#1<<4,d4
		and	#$fff0,d4	; d4 = ^y1 = floor(y1+1) - first row with pixel lit
		and	#$fff0,d7	; d7 = ^y2 = floor(y2)   - last row with pixel lit

		cmp	d4,d7		; ^y2 - ^y1
		bmi	.done

		move	d4,d6		; d6 = ^y1
		lsr	#4,d6
		mulu	#40,d6		; d6 = (^y1 in 16.0)*40
		add	d6,a0		; a0 = first byte in row

		sub	d1,d4		; d4 = ^y1 - y1
		sub	d1,d7		; d7 = ^y2 - y1

		sub	d0,d2		; d2 = dx

		move	d4,d6		; d6 = ^y1 - y1
		muls	d2,d6		; d6 = (^y1 - y1)*dx
		divs	d3,d6		; d6 = (^y1 - y1)*dx/dy
		add	d0,d6		; d6 = x1 + (^y1 - y1)*dx/dy
		and	#$fff0,d6	; d6 = ^x1 = floor(x1 + (^y1 - y1)*dx/dy)

		muls	d2,d7		; d7 = (^y2 - y1)*dx
		divs	d3,d7		; d7 = (^y2 - y1)*dx/dy
		add	d0,d7		; d7 = x1 + (^y2 - y1)*dx/dy
		and	#$fff0,d7	; d7 = ^x2 = floor(x1 + (^y2 - y1)*dx/dy)

		sub	d6,d7		; d7 = ^dx = ^x2 - ^x1
		lsl	#2,d7
		add	#$42,d7		; d7 = bltsize = (^dx+1)<<6 | 2

		sub	d6,d0		; d0 = x1 - ^x1
		neg	d0		; d0 = ^x1 - x1

		lsr	#4,d6		; d6 = ^x1 in 16.0
		move	d6,d5		; d5 = ^x1 in 16.0

		lsr	#3,d6		; number of bytes into this row
		;and	#$fffe,d6	; align to word - not necessary, the hardware does it automatically
		add	d6,a0		; a0 = word containing first pixel

		and	#$f,d5
		ror	#4,d5
		or	#$b4a,d5	; d5 = bltcon0

		add	#2<<4,d0	; d0 = (^x1 - x1) + 2
		muls	d3,d0		; d0 = ((^x1 - x1) + 2)*dy in 24.8

		add	#1<<4,d4	; d4 = (^y1 - y1) + 1
		muls	d2,d4		; d4 = ((^y1 - y1) + 1)*dx in 24.8

		sub.l	d4,d0		; d0 = ((^x1 - x1) + 2)*dy - ((^y1 - y1) + 1)*dx in 24.8

		add.l	#15,d0		; round to ceil
		asr.l	#4,d0		; d0 = ((^x1 - x1) + 2)*dy - ((^y1 - y1) + 1)*dx in 28.4
		sub.l	#1,d0

		add.l	d0,d0
		add	d2,d2
		add	d3,d3

		moveq	#OCTANT1,d6	; d6 = bltcon1
		bra	.wr_regs

.oct_2:
		move	d1,d4		; d4 = y1
		move	d3,d7		; d7 = y2

		sub	d1,d3		; d3 = dy

		add	#1<<4,d4
		and	#$fff0,d4	; d4 = ^y1 = floor(y1+1) - first row with pixel lit
		and	#$fff0,d7	; d7 = ^y2 = floor(y2)   - last row with pixel lit

		sub	d4,d7		; d7 = ^dy = ^y2 - ^y1
		bmi	.done

		lsl	#2,d7
		add	#$42,d7		; d7 = bltsize = (^dy+1)<<6 | 2

		move	d4,d6		; d6 = ^y1
		lsr	#4,d6
		mulu	#40,d6		; d6 = (^y1 in 16.0)*40
		add	d6,a0		; a0 = first byte in row

		sub	d1,d4		; d4 = ^y1 - y1

		sub	d0,d2		; d2 = dx

		move	d4,d6		; d6 = ^y1 - y1
		muls	d2,d6		; d6 = (^y1 - y1)*dx
		divs	d3,d6		; d6 = (^y1 - y1)*dx/dy
		add	d0,d6		; d6 = x1 + (^y1 - y1)*dx/dy
		and	#$fff0,d6	; d6 = ^x1 = floor(x1 + (^y1 - y1)*dx/dy)

		sub	d6,d0		; d0 = x1 - ^x1
		neg	d0		; d0 = ^x1 - x1

		lsr	#4,d6		; d6 = ^x1 in 16.0
		move	d6,d5		; d5 = ^x1 in 16.0

		lsr	#3,d6		; number of bytes into this row
		;and	#$fffe,d6	; align to word - not necessary, the hardware does it automatically
		add	d6,a0		; a0 = word containing first pixel

		and	#$f,d5
		ror	#4,d5
		or	#$b4a,d5	; d5 = bltcon0

		add	#1<<4,d4	; d4 = ^y1 - y1 + 1
		muls	d2,d4		; d4 = (^y1 - y1 + 1)*dx in 24.8

		add	#1<<4,d0	; d0 = ^x1 - x1 + 1
		muls	d3,d0		; d0 = (^x1 - x1 + 1)*dy in 24.8

		sub.l	d0,d4		; d4 = (^y1 - y1 + 1)*dx - (^x1 - x1 + 1)*dy in 24.8
		move.l	d4,d0		; d0 = (^y1 - y1 + 1)*dx - (^x1 - x1 + 1)*dy in 24.8

		add.l	#15,d0		; round to ceil
		asr.l	#4,d0		; d0 = (^y1 - y1 + 1)*dx - (^x1 - x1 + 1)*dy in 24.8

		exg	d2,d3

		add.l	d0,d0
		add	d2,d2
		add	d3,d3

		moveq	#OCTANT2,d6	; d6 = bltcon1
		bra	.wr_regs

.oct_3_4:
		neg	d4		; d4 = abs(dx)
		cmp	d5,d4		; abs(dx) - abs(dy)
		bmi	.oct_3

.oct_4:
		move	d1,d4		; d4 = y1
		move	d3,d7		; d7 = y2

		sub	d1,d3		; d3 = dy

		add	#1<<4,d4
		and	#$fff0,d4	; d4 = ^y1 = floor(y1+1) - first row with pixel lit
		and	#$fff0,d7	; d7 = ^y2 = floor(y2)   - last row with pixel lit

		cmp	d4,d7		; ^y2 - ^y1
		bmi	.done

		move	d4,d6		; d6 = ^y1
		lsr	#4,d6
		mulu	#40,d6		; d6 = (^y1 in 16.0)*40
		add	d6,a0		; a0 = first byte in row

		sub	d1,d4		; d4 = ^y1 - y1
		sub	d1,d7		; d7 = ^y2 - y1

		sub	d0,d2		; d2 = dx

		move	d4,d6		; d6 = ^y1 - y1
		muls	d2,d6		; d6 = (^y1 - y1)*dx

		ext.l	d3
		sub.l	d3,d6		; make div round to floor
		add.l	#1,d6

		divs	d3,d6		; d6 = (^y1 - y1)*dx/dy
		add	d0,d6		; d6 = x1 + (^y1 - y1)*dx/dy
		and	#$fff0,d6	; d6 = ^x1 = floor(x1 + (^y1 - y1)*dx/dy)

		muls	d2,d7		; d7 = (^y2 - y1)*dx

		sub.l	d3,d7		; make div round to floor
		add.l	#1,d7

		divs	d3,d7		; d7 = (^y2 - y1)*dx/dy
		add	d0,d7		; d7 = x1 + (^y2 - y1)*dx/dy
		and	#$fff0,d7	; d7 = ^x2 = floor(x1 + (^y2 - y1)*dx/dy)

		sub	d6,d7		; d7 = ^dx = ^x2 - ^x1
		neg	d7
		lsl	#2,d7
		add	#$42,d7		; d7 = bltsize = (^dx+1)<<6 | 2

		sub	d6,d0		; d0 = x1 - ^x1
		neg	d0		; d0 = ^x1 - x1

		lsr	#4,d6		; d6 = ^x1 in 16.0
		move	d6,d5		; d5 = ^x1 in 16.0

		lsr	#3,d6		; number of bytes into this row
		;and	#$fffe,d6	; align to word - not necessary, the hardware does it automatically
		add	d6,a0		; a0 = word containing first pixel

		and	#$f,d5
		ror	#4,d5
		or	#$b4a,d5	; d5 = bltcon0

		sub	#1<<4,d0	; d0 = (^x1 - x1) - 1
		muls	d3,d0		; d0 = ((^x1 - x1) + 1)*dy in 24.8

		add	#1<<4,d4	; d4 = (^y1 - y1) + 1
		muls	d2,d4		; d4 = ((^y1 - y1) + 1)*dx in 24.8

		sub.l	d0,d4		; d4 = ((^y1 - y1) + 1)*dx - ((^x1 - x1) - 1)*dy in 24.8
		move.l	d4,d0		; d0 = ((^y1 - y1) + 1)*dx - ((^x1 - x1) - 1)*dy in 24.8

		add.l	#15,d0		; round to ceil
		asr.l	#4,d0		; d0 = ((^y1 - y1) + 1)*dx - ((^x1 - x1) - 1)*dy in 28.4

		neg	d2

		add.l	d0,d0
		add	d2,d2
		add	d3,d3

		moveq	#OCTANT4,d6	; d6 = bltcon1
		bra	.wr_regs

.oct_3:
		move	d1,d4		; d4 = y1
		move	d3,d7		; d7 = y2

		sub	d1,d3		; d3 = dy

		add	#1<<4,d4
		and	#$fff0,d4	; d4 = ^y1 = floor(y1+1) - first row with pixel lit
		and	#$fff0,d7	; d7 = ^y2 = floor(y2)   - last row with pixel lit

		sub	d4,d7		; d7 = ^dy = ^y2 - ^y1
		bmi	.done

		lsl	#2,d7
		add	#$42,d7		; d7 = bltsize = (^dy+1)<<6 | 2

		move	d4,d6		; d6 = ^y1
		lsr	#4,d6
		mulu	#40,d6		; d6 = (^y1 in 16.0)*40
		add	d6,a0		; a0 = first byte in row

		sub	d1,d4		; d4 = ^y1 - y1

		sub	d0,d2		; d2 = dx

		move	d4,d6		; d6 = ^y1 - y1
		muls	d2,d6		; d6 = (^y1 - y1)*dx

		ext.l	d3
		sub.l	d3,d6		; make div round to floor
		add.l	#1,d6

		divs	d3,d6		; d6 = (^y1 - y1)*dx/dy
		add	d0,d6		; d6 = x1 + (^y1 - y1)*dx/dy
		and	#$fff0,d6	; d6 = ^x1 = floor(x1 + (^y1 - y1)*dx/dy)

		sub	d6,d0		; d0 = x1 - ^x1
		neg	d0		; d0 = ^x1 - x1

		lsr	#4,d6		; d6 = ^x1 in 16.0
		move	d6,d5		; d5 = ^x1 in 16.0

		lsr	#3,d6		; number of bytes into this row
		;and	#$fffe,d6	; align to word - not necessary, the hardware does it automatically
		add	d6,a0		; a0 = word containing first pixel

		and	#$f,d5
		ror	#4,d5
		or	#$b4a,d5	; d5 = bltcon0

		muls	d3,d0		; d0 = (^x1 - x1)*dy in 24.8

		add	#1<<4,d4	; d4 = ^y1 - y1 + 1
		muls	d2,d4		; d4 = (^y1 - y1 + 1)*dx in 24.8

		sub.l	d4,d0		; d0 = (^x1 - x1)*dy - (^y1 - y1 + 1)*dx in 24.8

		add.l	#15,d0		; round to ceil
		asr.l	#4,d0		; d0 = (^x1 - x1)*dy - (^y1 - y1 + 1)*dx in 24.8
		sub.l	#1,d0

		neg	d2
		exg	d2,d3

		add.l	d0,d0
		add	d2,d2
		add	d3,d3

		moveq	#OCTANT3,d6	; d6 = bltcon1
		;bra	.wr_regs

.wr_regs:
		;or	#LINEMODE,d6
		or	#LINEMODE+ONEDOT,d6

		bsr	waitblit

		move	d3,BLTBMOD(a5)	; bltbmod = dy

		move.l	d0,BLTAPT(a5)
		bpl	.not_sign

		or	#SIGNFLAG,d6

.not_sign:	sub	d2,d3		; d3 = dy - dx
		move	d3,BLTAMOD(a5)	; bltamod = dy - dx

		move	#40,BLTCMOD(a5)
		move	#40,BLTDMOD(a5)

		move	#$8000,BLTADAT(a5)
		move	#$ffff,BLTBDAT(a5)

		moveq.l	#-1,d0
		move.l	d0,BLTAFWM(a5)

		move.l	a0,BLTCPT(a5)
		move.l	a0,BLTDPT(a5)

		move	d5,BLTCON0(a5)
		move	d6,BLTCON1(a5)
		move	d7,BLTSIZE(a5)
.done:
		rts

intline:
		lsr	#4,d0
		lsr	#4,d1
		lsr	#4,d2
		lsr	#4,d3

		cmp	d1,d3		; y2 - y1
		beq	.done
		bpl	.no_yswap

		exg	d0,d2
		exg	d1,d3
.no_yswap:
		sub	d1,d3		; dy = y2 - y1
		sub	d0,d2		; dx = x2 - x1
		bmi	.negx

		cmp	d3,d2		; dx - dy
		bmi	.oct2

.oct1:		moveq	#OCTANT1,d6
		bra	.doline

.oct2:		moveq	#OCTANT2,d6
		exg	d2,d3		; d2 = abs(dy) = dl, d3 = abs(dx) = ds
		bra	.doline

.negx:		neg	d2		; d2 = -dx = abs(dx)

		cmp	d3,d2		; dx - dy
		bmi	.oct3

.oct4:		moveq	#OCTANT4,d6
		bra	.doline

.oct3:		moveq	#OCTANT3,d6
		exg	d2,d3		; d2 = abs(dy) = dl, d3 = abs(dx) = ds

.doline:
		mulu	#40,d1
		add	d1,a0

		move	d2,d7
		lsl	#6,d7
		add	#$42,d7

		move	d0,d5
		and	#$f,d5
		ror	#4,d5
		or	#$b4a,d5

		and	#$fff0,d0
		lsr	#3,d0
		add	d0,a0

		add	d2,d2		; d2 = 2*dl
		lsl	#2,d3		; d3 = 4*ds

		move	d3,d0
		sub	d2,d0
		ext.l	d0

		;or	#LINEMODE,d6
		or	#LINEMODE+ONEDOT,d6

		bsr	waitblit

		move	d3,BLTBMOD(a5)	; bltbmod = 4*ds

		move.l	d0,BLTAPT(a5)
		bpl	.not_sign

		or	#SIGNFLAG,d6

.not_sign:	add	d2,d2		; d2 = 4*dl
		sub	d2,d3		; d3 = 4*ds - 4*dl
		move	d3,BLTAMOD(a5)	; bltamod = 4*(ds - dl)

		move	#40,BLTCMOD(a5)
		move	#40,BLTDMOD(a5)

		move	#$8000,BLTADAT(a5)
		move	#$ffff,BLTBDAT(a5)

		moveq.l	#-1,d0
		move.l	d0,BLTAFWM(a5)

		move.l	a0,BLTCPT(a5)
		move.l	#scratch_pixel,BLTDPT(a5)

		move	d5,BLTCON0(a5)
		move	d6,BLTCON1(a5)
		move	d7,BLTSIZE(a5)
.done:		rts

clear_blit:	bsr	waitblit
		move.l	back_buffer,d0
		add.l	#4,d0
		move.l	d0,BLTDPT(a5)
		move	#8,BLTDMOD(a5)
		move	#DEST,BLTCON0(a5)
		clr	BLTCON1(a5)
		move	#256<<6+16,BLTSIZE(a5)
		rts

area_fill:
		bsr	waitblit
		move.l	back_buffer,d0
		add.l	#10240-2-4,d0
		move.l	d0,BLTAPT(a5)
		move.l	d0,BLTDPT(a5)
		moveq.l	#-1,d0
		move.l	d0,BLTAFWM(a5)
		move	#8,BLTAMOD(a5)
		move	#8,BLTDMOD(a5)
		move	#SRCA+DEST+$f0,BLTCON0(a5)
		move	#BLITREVERSE+FILL_XOR,BLTCON1(a5)
		move	#256<<6+16,BLTSIZE(a5)
		rts

waitblit:	btst	#DMAB_BLTDONE-8,DMACONR(a5)
wb_inner:	btst	#DMAB_BLTDONE-8,DMACONR(a5)
		bne	wb_inner
		rts

	CNOP 0,4
oldview:	dc.l	0
oldcopper:	dc.l	0
gfxbase:	dc.l	0
frame:		dc.l	0

front_buffer:	dc.l	bitplane1
back_buffer:	dc.l	bitplane2

	CNOP 0,4
olddmareq:	dc.w	0
oldintreq:	dc.w	0
oldintena:	dc.w	0
oldadkcon:	dc.w	0

angle_x:	dc.w	0
angle_y:	dc.w	0
angle_z:	dc.w	0

debounce:	dc.w	0
subpixel_enabled:	dc.w	1

screen_space_coords:
		blk.w	8*3

sin_tab:
		dc.w	$0000, $0032, $0065, $0097, $00c9, $00fb, $012e, $0160, $0192, $01c4, $01f7, $0229, $025b, $028d, $02c0, $02f2
		dc.w	$0324, $0356, $0388, $03bb, $03ed, $041f, $0451, $0483, $04b5, $04e7, $051a, $054c, $057e, $05b0, $05e2, $0614
		dc.w	$0646, $0678, $06aa, $06dc, $070e, $0740, $0772, $07a4, $07d6, $0807, $0839, $086b, $089d, $08cf, $0901, $0932
		dc.w	$0964, $0996, $09c7, $09f9, $0a2b, $0a5c, $0a8e, $0ac0, $0af1, $0b23, $0b54, $0b85, $0bb7, $0be8, $0c1a, $0c4b
		dc.w	$0c7c, $0cae, $0cdf, $0d10, $0d41, $0d72, $0da4, $0dd5, $0e06, $0e37, $0e68, $0e99, $0eca, $0efb, $0f2b, $0f5c
		dc.w	$0f8d, $0fbe, $0fee, $101f, $1050, $1080, $10b1, $10e1, $1112, $1142, $1173, $11a3, $11d3, $1204, $1234, $1264
		dc.w	$1294, $12c4, $12f4, $1324, $1354, $1384, $13b4, $13e4, $1413, $1443, $1473, $14a2, $14d2, $1501, $1531, $1560
		dc.w	$1590, $15bf, $15ee, $161d, $164c, $167c, $16ab, $16da, $1709, $1737, $1766, $1795, $17c4, $17f2, $1821, $184f
		dc.w	$187e, $18ac, $18db, $1909, $1937, $1965, $1993, $19c1, $19ef, $1a1d, $1a4b, $1a79, $1aa7, $1ad4, $1b02, $1b30
		dc.w	$1b5d, $1b8a, $1bb8, $1be5, $1c12, $1c3f, $1c6c, $1c99, $1cc6, $1cf3, $1d20, $1d4d, $1d79, $1da6, $1dd3, $1dff
		dc.w	$1e2b, $1e58, $1e84, $1eb0, $1edc, $1f08, $1f34, $1f60, $1f8c, $1fb7, $1fe3, $200f, $203a, $2065, $2091, $20bc
		dc.w	$20e7, $2112, $213d, $2168, $2193, $21be, $21e8, $2213, $223d, $2268, $2292, $22bc, $22e7, $2311, $233b, $2365
		dc.w	$238e, $23b8, $23e2, $240b, $2435, $245e, $2488, $24b1, $24da, $2503, $252c, $2555, $257e, $25a6, $25cf, $25f8
		dc.w	$2620, $2648, $2671, $2699, $26c1, $26e9, $2711, $2738, $2760, $2788, $27af, $27d6, $27fe, $2825, $284c, $2873
		dc.w	$289a, $28c1, $28e7, $290e, $2935, $295b, $2981, $29a7, $29ce, $29f4, $2a1a, $2a3f, $2a65, $2a8b, $2ab0, $2ad6
		dc.w	$2afb, $2b20, $2b45, $2b6a, $2b8f, $2bb4, $2bd8, $2bfd, $2c21, $2c46, $2c6a, $2c8e, $2cb2, $2cd6, $2cfa, $2d1e
		dc.w	$2d41, $2d65, $2d88, $2dab, $2dcf, $2df2, $2e15, $2e37, $2e5a, $2e7d, $2e9f, $2ec2, $2ee4, $2f06, $2f28, $2f4a
		dc.w	$2f6c, $2f8d, $2faf, $2fd0, $2ff2, $3013, $3034, $3055, $3076, $3097, $30b8, $30d8, $30f9, $3119, $3139, $3159
		dc.w	$3179, $3199, $31b9, $31d8, $31f8, $3217, $3236, $3255, $3274, $3293, $32b2, $32d0, $32ef, $330d, $332c, $334a
		dc.w	$3368, $3386, $33a3, $33c1, $33df, $33fc, $3419, $3436, $3453, $3470, $348d, $34aa, $34c6, $34e2, $34ff, $351b
		dc.w	$3537, $3553, $356e, $358a, $35a5, $35c1, $35dc, $35f7, $3612, $362d, $3648, $3662, $367d, $3697, $36b1, $36cb
		dc.w	$36e5, $36ff, $3718, $3732, $374b, $3765, $377e, $3797, $37b0, $37c8, $37e1, $37f9, $3812, $382a, $3842, $385a
		dc.w	$3871, $3889, $38a1, $38b8, $38cf, $38e6, $38fd, $3914, $392b, $3941, $3958, $396e, $3984, $399a, $39b0, $39c5
		dc.w	$39db, $39f0, $3a06, $3a1b, $3a30, $3a45, $3a59, $3a6e, $3a82, $3a97, $3aab, $3abf, $3ad3, $3ae6, $3afa, $3b0e
		dc.w	$3b21, $3b34, $3b47, $3b5a, $3b6d, $3b7f, $3b92, $3ba4, $3bb6, $3bc8, $3bda, $3bec, $3bfd, $3c0f, $3c20, $3c31
		dc.w	$3c42, $3c53, $3c64, $3c74, $3c85, $3c95, $3ca5, $3cb5, $3cc5, $3cd5, $3ce4, $3cf4, $3d03, $3d12, $3d21, $3d30
		dc.w	$3d3f, $3d4d, $3d5b, $3d6a, $3d78, $3d86, $3d93, $3da1, $3daf, $3dbc, $3dc9, $3dd6, $3de3, $3df0, $3dfc, $3e09
		dc.w	$3e15, $3e21, $3e2d, $3e39, $3e45, $3e50, $3e5c, $3e67, $3e72, $3e7d, $3e88, $3e92, $3e9d, $3ea7, $3eb1, $3ebb
		dc.w	$3ec5, $3ecf, $3ed8, $3ee2, $3eeb, $3ef4, $3efd, $3f06, $3f0f, $3f17, $3f20, $3f28, $3f30, $3f38, $3f40, $3f47
		dc.w	$3f4f, $3f56, $3f5d, $3f64, $3f6b, $3f72, $3f78, $3f7f, $3f85, $3f8b, $3f91, $3f97, $3f9c, $3fa2, $3fa7, $3fac
		dc.w	$3fb1, $3fb6, $3fbb, $3fbf, $3fc4, $3fc8, $3fcc, $3fd0, $3fd4, $3fd7, $3fdb, $3fde, $3fe1, $3fe4, $3fe7, $3fea
		dc.w	$3fec, $3fef, $3ff1, $3ff3, $3ff5, $3ff7, $3ff8, $3ffa, $3ffb, $3ffc, $3ffd, $3ffe, $3fff, $3fff, $4000, $4000
		dc.w	$4000, $4000, $4000, $3fff, $3fff, $3ffe, $3ffd, $3ffc, $3ffb, $3ffa, $3ff8, $3ff7, $3ff5, $3ff3, $3ff1, $3fef
		dc.w	$3fec, $3fea, $3fe7, $3fe4, $3fe1, $3fde, $3fdb, $3fd7, $3fd4, $3fd0, $3fcc, $3fc8, $3fc4, $3fbf, $3fbb, $3fb6
		dc.w	$3fb1, $3fac, $3fa7, $3fa2, $3f9c, $3f97, $3f91, $3f8b, $3f85, $3f7f, $3f78, $3f72, $3f6b, $3f64, $3f5d, $3f56
		dc.w	$3f4f, $3f47, $3f40, $3f38, $3f30, $3f28, $3f20, $3f17, $3f0f, $3f06, $3efd, $3ef4, $3eeb, $3ee2, $3ed8, $3ecf
		dc.w	$3ec5, $3ebb, $3eb1, $3ea7, $3e9d, $3e92, $3e88, $3e7d, $3e72, $3e67, $3e5c, $3e50, $3e45, $3e39, $3e2d, $3e21
		dc.w	$3e15, $3e09, $3dfc, $3df0, $3de3, $3dd6, $3dc9, $3dbc, $3daf, $3da1, $3d93, $3d86, $3d78, $3d6a, $3d5b, $3d4d
		dc.w	$3d3f, $3d30, $3d21, $3d12, $3d03, $3cf4, $3ce4, $3cd5, $3cc5, $3cb5, $3ca5, $3c95, $3c85, $3c74, $3c64, $3c53
		dc.w	$3c42, $3c31, $3c20, $3c0f, $3bfd, $3bec, $3bda, $3bc8, $3bb6, $3ba4, $3b92, $3b7f, $3b6d, $3b5a, $3b47, $3b34
		dc.w	$3b21, $3b0e, $3afa, $3ae6, $3ad3, $3abf, $3aab, $3a97, $3a82, $3a6e, $3a59, $3a45, $3a30, $3a1b, $3a06, $39f0
		dc.w	$39db, $39c5, $39b0, $399a, $3984, $396e, $3958, $3941, $392b, $3914, $38fd, $38e6, $38cf, $38b8, $38a1, $3889
		dc.w	$3871, $385a, $3842, $382a, $3812, $37f9, $37e1, $37c8, $37b0, $3797, $377e, $3765, $374b, $3732, $3718, $36ff
		dc.w	$36e5, $36cb, $36b1, $3697, $367d, $3662, $3648, $362d, $3612, $35f7, $35dc, $35c1, $35a5, $358a, $356e, $3553
		dc.w	$3537, $351b, $34ff, $34e2, $34c6, $34aa, $348d, $3470, $3453, $3436, $3419, $33fc, $33df, $33c1, $33a3, $3386
		dc.w	$3368, $334a, $332c, $330d, $32ef, $32d0, $32b2, $3293, $3274, $3255, $3236, $3217, $31f8, $31d8, $31b9, $3199
		dc.w	$3179, $3159, $3139, $3119, $30f9, $30d8, $30b8, $3097, $3076, $3055, $3034, $3013, $2ff2, $2fd0, $2faf, $2f8d
		dc.w	$2f6c, $2f4a, $2f28, $2f06, $2ee4, $2ec2, $2e9f, $2e7d, $2e5a, $2e37, $2e15, $2df2, $2dcf, $2dab, $2d88, $2d65
		dc.w	$2d41, $2d1e, $2cfa, $2cd6, $2cb2, $2c8e, $2c6a, $2c46, $2c21, $2bfd, $2bd8, $2bb4, $2b8f, $2b6a, $2b45, $2b20
		dc.w	$2afb, $2ad6, $2ab0, $2a8b, $2a65, $2a3f, $2a1a, $29f4, $29ce, $29a7, $2981, $295b, $2935, $290e, $28e7, $28c1
		dc.w	$289a, $2873, $284c, $2825, $27fe, $27d6, $27af, $2788, $2760, $2738, $2711, $26e9, $26c1, $2699, $2671, $2648
		dc.w	$2620, $25f8, $25cf, $25a6, $257e, $2555, $252c, $2503, $24da, $24b1, $2488, $245e, $2435, $240b, $23e2, $23b8
		dc.w	$238e, $2365, $233b, $2311, $22e7, $22bc, $2292, $2268, $223d, $2213, $21e8, $21be, $2193, $2168, $213d, $2112
		dc.w	$20e7, $20bc, $2091, $2065, $203a, $200f, $1fe3, $1fb7, $1f8c, $1f60, $1f34, $1f08, $1edc, $1eb0, $1e84, $1e58
		dc.w	$1e2b, $1dff, $1dd3, $1da6, $1d79, $1d4d, $1d20, $1cf3, $1cc6, $1c99, $1c6c, $1c3f, $1c12, $1be5, $1bb8, $1b8a
		dc.w	$1b5d, $1b30, $1b02, $1ad4, $1aa7, $1a79, $1a4b, $1a1d, $19ef, $19c1, $1993, $1965, $1937, $1909, $18db, $18ac
		dc.w	$187e, $184f, $1821, $17f2, $17c4, $1795, $1766, $1737, $1709, $16da, $16ab, $167c, $164c, $161d, $15ee, $15bf
		dc.w	$1590, $1560, $1531, $1501, $14d2, $14a2, $1473, $1443, $1413, $13e4, $13b4, $1384, $1354, $1324, $12f4, $12c4
		dc.w	$1294, $1264, $1234, $1204, $11d3, $11a3, $1173, $1142, $1112, $10e1, $10b1, $1080, $1050, $101f, $0fee, $0fbe
		dc.w	$0f8d, $0f5c, $0f2b, $0efb, $0eca, $0e99, $0e68, $0e37, $0e06, $0dd5, $0da4, $0d72, $0d41, $0d10, $0cdf, $0cae
		dc.w	$0c7c, $0c4b, $0c1a, $0be8, $0bb7, $0b85, $0b54, $0b23, $0af1, $0ac0, $0a8e, $0a5c, $0a2b, $09f9, $09c7, $0996
		dc.w	$0964, $0932, $0901, $08cf, $089d, $086b, $0839, $0807, $07d6, $07a4, $0772, $0740, $070e, $06dc, $06aa, $0678
		dc.w	$0646, $0614, $05e2, $05b0, $057e, $054c, $051a, $04e7, $04b5, $0483, $0451, $041f, $03ed, $03bb, $0388, $0356
		dc.w	$0324, $02f2, $02c0, $028d, $025b, $0229, $01f7, $01c4, $0192, $0160, $012e, $00fb, $00c9, $0097, $0065, $0032
		dc.w	$0000, $ffce, $ff9b, $ff69, $ff37, $ff05, $fed2, $fea0, $fe6e, $fe3c, $fe09, $fdd7, $fda5, $fd73, $fd40, $fd0e
		dc.w	$fcdc, $fcaa, $fc78, $fc45, $fc13, $fbe1, $fbaf, $fb7d, $fb4b, $fb19, $fae6, $fab4, $fa82, $fa50, $fa1e, $f9ec
		dc.w	$f9ba, $f988, $f956, $f924, $f8f2, $f8c0, $f88e, $f85c, $f82a, $f7f9, $f7c7, $f795, $f763, $f731, $f6ff, $f6ce
		dc.w	$f69c, $f66a, $f639, $f607, $f5d5, $f5a4, $f572, $f540, $f50f, $f4dd, $f4ac, $f47b, $f449, $f418, $f3e6, $f3b5
		dc.w	$f384, $f352, $f321, $f2f0, $f2bf, $f28e, $f25c, $f22b, $f1fa, $f1c9, $f198, $f167, $f136, $f105, $f0d5, $f0a4
		dc.w	$f073, $f042, $f012, $efe1, $efb0, $ef80, $ef4f, $ef1f, $eeee, $eebe, $ee8d, $ee5d, $ee2d, $edfc, $edcc, $ed9c
		dc.w	$ed6c, $ed3c, $ed0c, $ecdc, $ecac, $ec7c, $ec4c, $ec1c, $ebed, $ebbd, $eb8d, $eb5e, $eb2e, $eaff, $eacf, $eaa0
		dc.w	$ea70, $ea41, $ea12, $e9e3, $e9b4, $e984, $e955, $e926, $e8f7, $e8c9, $e89a, $e86b, $e83c, $e80e, $e7df, $e7b1
		dc.w	$e782, $e754, $e725, $e6f7, $e6c9, $e69b, $e66d, $e63f, $e611, $e5e3, $e5b5, $e587, $e559, $e52c, $e4fe, $e4d0
		dc.w	$e4a3, $e476, $e448, $e41b, $e3ee, $e3c1, $e394, $e367, $e33a, $e30d, $e2e0, $e2b3, $e287, $e25a, $e22d, $e201
		dc.w	$e1d5, $e1a8, $e17c, $e150, $e124, $e0f8, $e0cc, $e0a0, $e074, $e049, $e01d, $dff1, $dfc6, $df9b, $df6f, $df44
		dc.w	$df19, $deee, $dec3, $de98, $de6d, $de42, $de18, $dded, $ddc3, $dd98, $dd6e, $dd44, $dd19, $dcef, $dcc5, $dc9b
		dc.w	$dc72, $dc48, $dc1e, $dbf5, $dbcb, $dba2, $db78, $db4f, $db26, $dafd, $dad4, $daab, $da82, $da5a, $da31, $da08
		dc.w	$d9e0, $d9b8, $d98f, $d967, $d93f, $d917, $d8ef, $d8c8, $d8a0, $d878, $d851, $d82a, $d802, $d7db, $d7b4, $d78d
		dc.w	$d766, $d73f, $d719, $d6f2, $d6cb, $d6a5, $d67f, $d659, $d632, $d60c, $d5e6, $d5c1, $d59b, $d575, $d550, $d52a
		dc.w	$d505, $d4e0, $d4bb, $d496, $d471, $d44c, $d428, $d403, $d3df, $d3ba, $d396, $d372, $d34e, $d32a, $d306, $d2e2
		dc.w	$d2bf, $d29b, $d278, $d255, $d231, $d20e, $d1eb, $d1c9, $d1a6, $d183, $d161, $d13e, $d11c, $d0fa, $d0d8, $d0b6
		dc.w	$d094, $d073, $d051, $d030, $d00e, $cfed, $cfcc, $cfab, $cf8a, $cf69, $cf48, $cf28, $cf07, $cee7, $cec7, $cea7
		dc.w	$ce87, $ce67, $ce47, $ce28, $ce08, $cde9, $cdca, $cdab, $cd8c, $cd6d, $cd4e, $cd30, $cd11, $ccf3, $ccd4, $ccb6
		dc.w	$cc98, $cc7a, $cc5d, $cc3f, $cc21, $cc04, $cbe7, $cbca, $cbad, $cb90, $cb73, $cb56, $cb3a, $cb1e, $cb01, $cae5
		dc.w	$cac9, $caad, $ca92, $ca76, $ca5b, $ca3f, $ca24, $ca09, $c9ee, $c9d3, $c9b8, $c99e, $c983, $c969, $c94f, $c935
		dc.w	$c91b, $c901, $c8e8, $c8ce, $c8b5, $c89b, $c882, $c869, $c850, $c838, $c81f, $c807, $c7ee, $c7d6, $c7be, $c7a6
		dc.w	$c78f, $c777, $c75f, $c748, $c731, $c71a, $c703, $c6ec, $c6d5, $c6bf, $c6a8, $c692, $c67c, $c666, $c650, $c63b
		dc.w	$c625, $c610, $c5fa, $c5e5, $c5d0, $c5bb, $c5a7, $c592, $c57e, $c569, $c555, $c541, $c52d, $c51a, $c506, $c4f2
		dc.w	$c4df, $c4cc, $c4b9, $c4a6, $c493, $c481, $c46e, $c45c, $c44a, $c438, $c426, $c414, $c403, $c3f1, $c3e0, $c3cf
		dc.w	$c3be, $c3ad, $c39c, $c38c, $c37b, $c36b, $c35b, $c34b, $c33b, $c32b, $c31c, $c30c, $c2fd, $c2ee, $c2df, $c2d0
		dc.w	$c2c1, $c2b3, $c2a5, $c296, $c288, $c27a, $c26d, $c25f, $c251, $c244, $c237, $c22a, $c21d, $c210, $c204, $c1f7
		dc.w	$c1eb, $c1df, $c1d3, $c1c7, $c1bb, $c1b0, $c1a4, $c199, $c18e, $c183, $c178, $c16e, $c163, $c159, $c14f, $c145
		dc.w	$c13b, $c131, $c128, $c11e, $c115, $c10c, $c103, $c0fa, $c0f1, $c0e9, $c0e0, $c0d8, $c0d0, $c0c8, $c0c0, $c0b9
		dc.w	$c0b1, $c0aa, $c0a3, $c09c, $c095, $c08e, $c088, $c081, $c07b, $c075, $c06f, $c069, $c064, $c05e, $c059, $c054
		dc.w	$c04f, $c04a, $c045, $c041, $c03c, $c038, $c034, $c030, $c02c, $c029, $c025, $c022, $c01f, $c01c, $c019, $c016
		dc.w	$c014, $c011, $c00f, $c00d, $c00b, $c009, $c008, $c006, $c005, $c004, $c003, $c002, $c001, $c001, $c000, $c000
		dc.w	$c000, $c000, $c000, $c001, $c001, $c002, $c003, $c004, $c005, $c006, $c008, $c009, $c00b, $c00d, $c00f, $c011
		dc.w	$c014, $c016, $c019, $c01c, $c01f, $c022, $c025, $c029, $c02c, $c030, $c034, $c038, $c03c, $c041, $c045, $c04a
		dc.w	$c04f, $c054, $c059, $c05e, $c064, $c069, $c06f, $c075, $c07b, $c081, $c088, $c08e, $c095, $c09c, $c0a3, $c0aa
		dc.w	$c0b1, $c0b9, $c0c0, $c0c8, $c0d0, $c0d8, $c0e0, $c0e9, $c0f1, $c0fa, $c103, $c10c, $c115, $c11e, $c128, $c131
		dc.w	$c13b, $c145, $c14f, $c159, $c163, $c16e, $c178, $c183, $c18e, $c199, $c1a4, $c1b0, $c1bb, $c1c7, $c1d3, $c1df
		dc.w	$c1eb, $c1f7, $c204, $c210, $c21d, $c22a, $c237, $c244, $c251, $c25f, $c26d, $c27a, $c288, $c296, $c2a5, $c2b3
		dc.w	$c2c1, $c2d0, $c2df, $c2ee, $c2fd, $c30c, $c31c, $c32b, $c33b, $c34b, $c35b, $c36b, $c37b, $c38c, $c39c, $c3ad
		dc.w	$c3be, $c3cf, $c3e0, $c3f1, $c403, $c414, $c426, $c438, $c44a, $c45c, $c46e, $c481, $c493, $c4a6, $c4b9, $c4cc
		dc.w	$c4df, $c4f2, $c506, $c51a, $c52d, $c541, $c555, $c569, $c57e, $c592, $c5a7, $c5bb, $c5d0, $c5e5, $c5fa, $c610
		dc.w	$c625, $c63b, $c650, $c666, $c67c, $c692, $c6a8, $c6bf, $c6d5, $c6ec, $c703, $c71a, $c731, $c748, $c75f, $c777
		dc.w	$c78f, $c7a6, $c7be, $c7d6, $c7ee, $c807, $c81f, $c838, $c850, $c869, $c882, $c89b, $c8b5, $c8ce, $c8e8, $c901
		dc.w	$c91b, $c935, $c94f, $c969, $c983, $c99e, $c9b8, $c9d3, $c9ee, $ca09, $ca24, $ca3f, $ca5b, $ca76, $ca92, $caad
		dc.w	$cac9, $cae5, $cb01, $cb1e, $cb3a, $cb56, $cb73, $cb90, $cbad, $cbca, $cbe7, $cc04, $cc21, $cc3f, $cc5d, $cc7a
		dc.w	$cc98, $ccb6, $ccd4, $ccf3, $cd11, $cd30, $cd4e, $cd6d, $cd8c, $cdab, $cdca, $cde9, $ce08, $ce28, $ce47, $ce67
		dc.w	$ce87, $cea7, $cec7, $cee7, $cf07, $cf28, $cf48, $cf69, $cf8a, $cfab, $cfcc, $cfed, $d00e, $d030, $d051, $d073
		dc.w	$d094, $d0b6, $d0d8, $d0fa, $d11c, $d13e, $d161, $d183, $d1a6, $d1c9, $d1eb, $d20e, $d231, $d255, $d278, $d29b
		dc.w	$d2bf, $d2e2, $d306, $d32a, $d34e, $d372, $d396, $d3ba, $d3df, $d403, $d428, $d44c, $d471, $d496, $d4bb, $d4e0
		dc.w	$d505, $d52a, $d550, $d575, $d59b, $d5c1, $d5e6, $d60c, $d632, $d659, $d67f, $d6a5, $d6cb, $d6f2, $d719, $d73f
		dc.w	$d766, $d78d, $d7b4, $d7db, $d802, $d82a, $d851, $d878, $d8a0, $d8c8, $d8ef, $d917, $d93f, $d967, $d98f, $d9b8
		dc.w	$d9e0, $da08, $da31, $da5a, $da82, $daab, $dad4, $dafd, $db26, $db4f, $db78, $dba2, $dbcb, $dbf5, $dc1e, $dc48
		dc.w	$dc72, $dc9b, $dcc5, $dcef, $dd19, $dd44, $dd6e, $dd98, $ddc3, $dded, $de18, $de42, $de6d, $de98, $dec3, $deee
		dc.w	$df19, $df44, $df6f, $df9b, $dfc6, $dff1, $e01d, $e049, $e074, $e0a0, $e0cc, $e0f8, $e124, $e150, $e17c, $e1a8
		dc.w	$e1d5, $e201, $e22d, $e25a, $e287, $e2b3, $e2e0, $e30d, $e33a, $e367, $e394, $e3c1, $e3ee, $e41b, $e448, $e476
		dc.w	$e4a3, $e4d0, $e4fe, $e52c, $e559, $e587, $e5b5, $e5e3, $e611, $e63f, $e66d, $e69b, $e6c9, $e6f7, $e725, $e754
		dc.w	$e782, $e7b1, $e7df, $e80e, $e83c, $e86b, $e89a, $e8c9, $e8f7, $e926, $e955, $e984, $e9b4, $e9e3, $ea12, $ea41
		dc.w	$ea70, $eaa0, $eacf, $eaff, $eb2e, $eb5e, $eb8d, $ebbd, $ebed, $ec1c, $ec4c, $ec7c, $ecac, $ecdc, $ed0c, $ed3c
		dc.w	$ed6c, $ed9c, $edcc, $edfc, $ee2d, $ee5d, $ee8d, $eebe, $eeee, $ef1f, $ef4f, $ef80, $efb0, $efe1, $f012, $f042
		dc.w	$f073, $f0a4, $f0d5, $f105, $f136, $f167, $f198, $f1c9, $f1fa, $f22b, $f25c, $f28e, $f2bf, $f2f0, $f321, $f352
		dc.w	$f384, $f3b5, $f3e6, $f418, $f449, $f47b, $f4ac, $f4dd, $f50f, $f540, $f572, $f5a4, $f5d5, $f607, $f639, $f66a
		dc.w	$f69c, $f6ce, $f6ff, $f731, $f763, $f795, $f7c7, $f7f9, $f82a, $f85c, $f88e, $f8c0, $f8f2, $f924, $f956, $f988
		dc.w	$f9ba, $f9ec, $fa1e, $fa50, $fa82, $fab4, $fae6, $fb19, $fb4b, $fb7d, $fbaf, $fbe1, $fc13, $fc45, $fc78, $fcaa
		dc.w	$fcdc, $fd0e, $fd40, $fd73, $fda5, $fdd7, $fe09, $fe3c, $fe6e, $fea0, $fed2, $ff05, $ff37, $ff69, $ff9b, $ffce

	CNOP 0,4
gfxname:	dc.b	'graphics.library',0

	section ChipRAM,data_c

	CNOP 0,4
scratch_pixel:	dc.w	0

	CNOP 0,4
bitplane1:	blk.b	10240,0
bitplane2:	blk.b	10240,0

	CNOP 0,4
copper:		dc.w	$00e0,$0000
		dc.w	$00e2,$0000
		dc.w	$0180
col0:		dc.w	$0004
		dc.w	$0182,$0fff
		dc.w	$ffff,$fffe
