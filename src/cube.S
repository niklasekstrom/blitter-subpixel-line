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
		swap	d0
		add.l	#10240,d0
		move	d0,14(a0)
		swap	d0
		move	d0,10(a0)

		move	#$2200,BPLCON0(a5)
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

		move	#100,angle_x
		move	#0,angle_y
		move	#0,angle_z

mainloop:

waitVB1:	move.l	VPOSR(a5),d0
		and.l	#$1ff00,d0
		sub.l	#34<<8,d0
		bmi	waitVB1

		;move	#$050,COLOR(a5)

		jsr	clear_blit
		;jsr	waitblit

		;move	#$005,COLOR(a5)

		jsr	transform_coords
		jsr	cull_backface

		move	angle_x,d0
		add	#0,d0
		and	#2047,d0
		move	d0,angle_x

		move	angle_y,d0
		add	#1,d0
		and	#2047,d0
		move	d0,angle_y

		move	angle_z,d0
		add	#1,d0
		and	#2047,d0
		move	d0,angle_z

		;move	#$990,COLOR(a5)

		jsr	render_sides
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
		swap	d0
		add.l	#10240,d0
		move	d0,14(a0)
		swap	d0
		move	d0,10(a0)

waitVB2:	move.l	VPOSR(a5),d0
		and.l	#$1ff00,d0
		sub.l	#34<<8,d0
		bpl	waitVB2

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

transform_coords:
		lea	model_coords,a0
		lea	rot_coords,a1
		lea	sin_tab,a2
		move	angle_z,d2
		bsr	rot_z_axis

		lea	rot_coords,a0
		move.l	a0,a1
		move	angle_y,d2
		bsr	rot_y_axis

		lea	rot_coords,a0
		move.l	a0,a1
		move	angle_x,d2
		bsr	rot_x_axis

		lea	rot_coords,a0
		lea	camera_space_coords,a1
		lea	screen_space_coords,a2
		bsr	world_to_camera_and_screen
		rts

rot_x_axis:
		; a0 = source points in 12.4
		; a1 = destination points in 12.4
		; a2 = sinus table
		; d2 = angle

		move	d2,d0
		add	d0,d0
		move	(a2,d0),d0	; d0 = sin(angle)

		move	#2048+512,d1
		sub	d2,d1
		and	#2047,d1
		add	d1,d1
		move	(a2,d1),d1	; d1 = cos(angle)

		move	#8-1,d7
.loop:		move	2(a0),d2	; d2 = y
		move	4(a0),d3	; d3 = z

		add	d2,d2		; d2 = y in 11.5
		add	d3,d3		; d3 = z in 11.5

		move	d2,d4		; d4 = y
		move	d3,d5		; d5 = z

		muls	d0,d2		; d2 = sin(t) * y
		muls	d0,d3		; d3 = sin(t) * z
		muls	d1,d4		; d4 = cos(t) * y
		muls	d1,d5		; d5 = cos(t) * z

		sub.l	d3,d4		; d4 = y' = cos(t) * y - sin(t) * z
		add.l	d2,d5		; d5 = z' = sin(t) * y + cos(t) * z

		add.l	#1<<15,d4
		add.l	#1<<15,d5

		swap	d4
		swap	d5

		move	(a0),d3		; d3 = x'

		move	d3,(a1)+
		move	d4,(a1)+
		move	d5,(a1)+

		add	#6,a0

		dbra	d7,.loop
		rts

rot_y_axis:
		; a0 = source points in 12.4
		; a1 = destination points in 12.4
		; a2 = sinus table
		; d2 = angle

		move	d2,d0
		add	d0,d0
		move	(a2,d0),d0	; d0 = sin(angle)

		move	#2048+512,d1
		sub	d2,d1
		and	#2047,d1
		add	d1,d1
		move	(a2,d1),d1	; d1 = cos(angle)

		move	#8-1,d7
.loop:		move	0(a0),d2	; d2 = x
		move	4(a0),d3	; d3 = z

		add	d2,d2		; d2 = x in 11.5
		add	d3,d3		; d3 = z in 11.5

		move	d2,d4		; d4 = x
		move	d3,d5		; d5 = z

		muls	d0,d2		; d2 = sin(t) * x
		muls	d0,d3		; d3 = sin(t) * z
		muls	d1,d4		; d4 = cos(t) * x
		muls	d1,d5		; d5 = cos(t) * z

		add.l	d3,d4		; d4 = x' = cos(t) * x + sin(t) * z
		sub.l	d2,d5		; d5 = z' = cos(t) * x - sin(t) * y

		add.l	#1<<15,d4
		add.l	#1<<15,d5

		swap	d4
		swap	d5

		move	2(a0),d3	; d3 = y'

		move	d4,(a1)+
		move	d3,(a1)+
		move	d5,(a1)+

		add	#6,a0

		dbra	d7,.loop
		rts

rot_z_axis:
		; a0 = source points in 12.4
		; a1 = destination points in 12.4
		; a2 = sinus table
		; d2 = angle

		move	d2,d0
		add	d0,d0
		move	(a2,d0),d0	; d0 = sin(angle)

		move	#2048+512,d1
		sub	d2,d1
		and	#2047,d1
		add	d1,d1
		move	(a2,d1),d1	; d1 = cos(angle)

		move	#8-1,d7
.loop:		move	0(a0),d2	; d2 = x
		move	2(a0),d3	; d3 = y

		add	d2,d2		; d2 = x in 11.5
		add	d3,d3		; d3 = y in 11.5

		move	d2,d4		; d4 = x
		move	d3,d5		; d5 = y

		muls	d0,d2		; d2 = sin(t) * x
		muls	d0,d3		; d3 = sin(t) * y
		muls	d1,d4		; d4 = cos(t) * x
		muls	d1,d5		; d5 = cos(t) * y

		sub.l	d3,d4		; d4 = x' = cos(t) * x - sin(t) * y
		add.l	d2,d5		; d5 = y' = sin(t) * x + cos(t) * y

		add.l	#1<<15,d4
		add.l	#1<<15,d5

		swap	d4
		swap	d5

		move	4(a0),d3	; d3 = z'

		move	d4,(a1)+
		move	d5,(a1)+
		move	d3,(a1)+

		add	#6,a0

		dbra	d7,.loop
		rts

world_to_camera_and_screen:
		; a0 = world points in 12.4
		; a1 = camera points in 12.4
		; a2 = screen space points in 12.4

		move	#8-1,d7
.loop:		move	(a0)+,d0
		move	(a0)+,d1
		move	(a0)+,d2

		add	#90<<4,d2

		move	d0,(a1)+
		move	d1,(a1)+
		move	d2,(a1)+

		muls	#640<<4,d0
		muls	#640<<4,d1
		divs	d2,d0
		divs	d2,d1

		add	#160<<4+8,d0
		add	#128<<4+8,d1

		move	d0,(a2)+
		move	d1,(a2)+
		addq	#2,a2

		dbra	d7,.loop
		rts

cull_backface:
		lea	sides,a0
		lea	camera_space_coords,a1
		lea	dotprod,a2
		lea	render_table,a3
		clr.l	d1
		move.l	d1,a4

		; Calculate which sides are facing the camera (or not).
		moveq	#6-1,d7

.loop2:		move	(a0)+,d5	; p0
		movem	(a1,d5),d3-d5
		neg	d3		; -p0.x
		neg	d4		; -p0.y
		neg	d5		; -p0.z

		move	(a0)+,d0	; p1
		movem	(a1,d0),d0-d2
		add	d3,d0		; d0 = v1.x = p1.x - p0.x
		add	d4,d1		; d1 = v1.y = p1.y - p0.y
		add	d5,d2		; d2 = v1.z = p1.z - p0.z

		move	(a0)+,d6	; p2
		add	0(a1,d6),d3	; d3 = v2.x = p2.x - p0.x
		add	2(a1,d6),d4	; d4 = v2.y = p2.y - p0.y
		add	4(a1,d6),d5	; d5 = v2.z = p2.z - p0.z

		move	d1,d6		; d6 = v1.y
		muls	d5,d1		; d1 = v1.y * v2.z

		swap	d6		; d6 = v1.y << 16
		move	d2,d6		; d6 = v1.y << 16 | v1.z

		muls	d4,d2		; d2 = v1.z * v2.y
		sub.l	d2,d1		; d1 = n.x = v1.y * v2.z - v1.z * v2.y

		move	d6,d2		; d2 = v1.z
		swap	d6		; d6 = v1.y

		muls	d0,d5		; d5 = v1.x * v2.z
		muls	d4,d0		; d0 = v1.x * v2.y

		muls	d3,d2		; d2 = v1.z * v2.x
		muls	d6,d3		; d3 = v1.y * v2.x

		sub.l	d5,d2		; d2 = n.y = v1.z * v2.x - v1.x * v2.z
		sub.l	d3,d0		; d0 = n.z = v1.x * v2.y - v1.y * v2.x

		asr.l	#4,d1		; d1 = n.x
		asr.l	#4,d2		; d2 = n.y
		asr.l	#4,d0		; d0 = n.z

		move	(a0)+,d5	; p3
		movem	(a1,d5),d3-d5

		muls	d1,d3		; d3 = p3.x * n.x
		muls	d2,d4		; d4 = p3.y * n.y
		muls	d0,d5		; d5 = p3.z * n.z
		add.l	d5,d4
		add.l	d4,d3		; d3 = p3 * n

		neg.l	d3
		bmi	.hidden

		swap	d3
		lsr	#3,d3
		move	d3,d4
		lsl	#4,d3
		or	d4,d3
		lsl	#4,d3
		or	d4,d3

		moveq	#5,d0
		sub	d7,d0		; d0 = index of side

		move	d0,(a3)+

		move.l	back_buffer,d1

		cmp	#0,a4
		bne	.not_zero

		move.l	d1,(a3)+
		addq	#1,a4
		move	d3,col1
		bra	.hidden

.not_zero:	cmp	#1,a4
		bne	.not_one

		add.l	#10240,d1
		move.l	d1,(a3)+
		addq	#1,a4
		move	d3,col2
		bra	.hidden

.not_one:	move.l	d1,(a3)+

		move	d0,(a3)+
		add.l	#10240,d1
		move.l	d1,(a3)+

		move	d3,col3

		clr.l	d7

.hidden:	dbra	d7,.loop2

		moveq	#-1,d0
		move	d0,(a3)
		rts

render_sides:
		lea	screen_space_coords,a1
		lea	sides,a2
		lea	render_table,a3

.loop:		move	(a3)+,d0
		cmp	#-1,d0
		beq	.done

		lsl	#3,d0		; index*8
		lea	(a2,d0),a4

		move	0(a4),d1
		move	(a1,d1),d0
		move	2(a1,d1),d1
		move	2(a4),d3
		move	(a1,d3),d2
		move	2(a1,d3),d3
		move.l	(a3),a0
		jsr	polyline

		move	2(a4),d1
		move	(a1,d1),d0
		move	2(a1,d1),d1
		move	4(a4),d3
		move	(a1,d3),d2
		move	2(a1,d3),d3
		move.l	(a3),a0
		jsr	polyline

		move	4(a4),d1
		move	(a1,d1),d0
		move	2(a1,d1),d1
		move	6(a4),d3
		move	(a1,d3),d2
		move	2(a1,d3),d3
		move.l	(a3),a0
		jsr	polyline

		move	6(a4),d1
		move	(a1,d1),d0
		move	2(a1,d1),d1
		move	0(a4),d3
		move	(a1,d3),d2
		move	2(a1,d3),d3
		move.l	(a3)+,a0
		jsr	polyline

		bra	.loop
.done:		rts

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

clear_blit:	bsr	waitblit
		move.l	back_buffer,d0
		add.l	#4,d0
		move.l	d0,BLTDPT(a5)
		move	#8,BLTDMOD(a5)
		move	#DEST,BLTCON0(a5)
		clr	BLTCON1(a5)
		move	#512<<6+16,BLTSIZE(a5)
		rts

area_fill:
		bsr	area_fill1
		bsr	area_fill2
		rts

area_fill1:	bsr	waitblit
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

area_fill2:	bsr	waitblit
		move.l	back_buffer,d0
		add.l	#10240*2-2-4,d0
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

model_coords:
		dc.w	10<<4,10<<4,-10<<4
		dc.w	10<<4,-10<<4,-10<<4
		dc.w	-10<<4,-10<<4,-10<<4
		dc.w	-10<<4,10<<4,-10<<4

		dc.w	10<<4,10<<4,10<<4
		dc.w	10<<4,-10<<4,10<<4
		dc.w	-10<<4,-10<<4,10<<4
		dc.w	-10<<4,10<<4,10<<4

rot_coords:	blk.w	8*3

camera_space_coords:
		blk.w	8*3

screen_space_coords:
		blk.w	8*3

sides:		dc.w	0*6,1*6,2*6,3*6
		dc.w	4*6,7*6,6*6,5*6
		dc.w	1*6,5*6,6*6,2*6
		dc.w	0*6,3*6,7*6,4*6
		dc.w	0*6,4*6,5*6,1*6
		dc.w	2*6,6*6,7*6,3*6

dotprod:	blk.w	6

render_table:	blk.w	6*3

sin_tab:
		dc.w	$0000, $0065, $00c9, $012e, $0192, $01f7, $025b, $02c0, $0324, $0389, $03ed, $0452, $04b6, $051b, $057f, $05e3
		dc.w	$0648, $06ac, $0711, $0775, $07d9, $083e, $08a2, $0906, $096b, $09cf, $0a33, $0a97, $0afb, $0b60, $0bc4, $0c28
		dc.w	$0c8c, $0cf0, $0d54, $0db8, $0e1c, $0e80, $0ee4, $0f47, $0fab, $100f, $1073, $10d6, $113a, $119e, $1201, $1265
		dc.w	$12c8, $132b, $138f, $13f2, $1455, $14b9, $151c, $157f, $15e2, $1645, $16a8, $170b, $176e, $17d1, $1833, $1896
		dc.w	$18f9, $195b, $19be, $1a20, $1a83, $1ae5, $1b47, $1ba9, $1c0c, $1c6e, $1cd0, $1d31, $1d93, $1df5, $1e57, $1eb8
		dc.w	$1f1a, $1f7b, $1fdd, $203e, $209f, $2101, $2162, $21c3, $2224, $2284, $22e5, $2346, $23a7, $2407, $2467, $24c8
		dc.w	$2528, $2588, $25e8, $2648, $26a8, $2708, $2768, $27c7, $2827, $2886, $28e5, $2945, $29a4, $2a03, $2a62, $2ac1
		dc.w	$2b1f, $2b7e, $2bdc, $2c3b, $2c99, $2cf7, $2d55, $2db3, $2e11, $2e6f, $2ecc, $2f2a, $2f87, $2fe5, $3042, $309f
		dc.w	$30fc, $3159, $31b5, $3212, $326e, $32cb, $3327, $3383, $33df, $343b, $3497, $34f2, $354e, $35a9, $3604, $365f
		dc.w	$36ba, $3715, $3770, $37ca, $3825, $387f, $38d9, $3933, $398d, $39e7, $3a40, $3a9a, $3af3, $3b4c, $3ba5, $3bfe
		dc.w	$3c57, $3caf, $3d08, $3d60, $3db8, $3e10, $3e68, $3ec0, $3f17, $3f6f, $3fc6, $401d, $4074, $40cb, $4121, $4178
		dc.w	$41ce, $4224, $427a, $42d0, $4326, $437b, $43d1, $4426, $447b, $44d0, $4524, $4579, $45cd, $4621, $4675, $46c9
		dc.w	$471d, $4770, $47c4, $4817, $486a, $48bd, $490f, $4962, $49b4, $4a06, $4a58, $4aaa, $4afb, $4b4d, $4b9e, $4bef
		dc.w	$4c40, $4c91, $4ce1, $4d31, $4d81, $4dd1, $4e21, $4e71, $4ec0, $4f0f, $4f5e, $4fad, $4ffb, $504a, $5098, $50e6
		dc.w	$5134, $5181, $51cf, $521c, $5269, $52b6, $5303, $534f, $539b, $53e7, $5433, $547f, $54ca, $5515, $5560, $55ab
		dc.w	$55f6, $5640, $568a, $56d4, $571e, $5767, $57b1, $57fa, $5843, $588c, $58d4, $591c, $5964, $59ac, $59f4, $5a3b
		dc.w	$5a82, $5ac9, $5b10, $5b57, $5b9d, $5be3, $5c29, $5c6f, $5cb4, $5cf9, $5d3e, $5d83, $5dc8, $5e0c, $5e50, $5e94
		dc.w	$5ed7, $5f1b, $5f5e, $5fa1, $5fe4, $6026, $6068, $60aa, $60ec, $612e, $616f, $61b0, $61f1, $6232, $6272, $62b2
		dc.w	$62f2, $6332, $6371, $63b0, $63ef, $642e, $646c, $64ab, $64e9, $6526, $6564, $65a1, $65de, $661b, $6657, $6693
		dc.w	$66d0, $670b, $6747, $6782, $67bd, $67f8, $6832, $686d, $68a7, $68e0, $691a, $6953, $698c, $69c5, $69fd, $6a36
		dc.w	$6a6e, $6aa5, $6add, $6b14, $6b4b, $6b82, $6bb8, $6bee, $6c24, $6c5a, $6c8f, $6cc4, $6cf9, $6d2e, $6d62, $6d96
		dc.w	$6dca, $6dfe, $6e31, $6e64, $6e97, $6ec9, $6efb, $6f2d, $6f5f, $6f90, $6fc2, $6ff2, $7023, $7053, $7083, $70b3
		dc.w	$70e3, $7112, $7141, $7170, $719e, $71cc, $71fa, $7228, $7255, $7282, $72af, $72dc, $7308, $7334, $735f, $738b
		dc.w	$73b6, $73e1, $740b, $7436, $7460, $7489, $74b3, $74dc, $7505, $752d, $7556, $757e, $75a6, $75cd, $75f4, $761b
		dc.w	$7642, $7668, $768e, $76b4, $76d9, $76fe, $7723, $7748, $776c, $7790, $77b4, $77d8, $77fb, $781e, $7840, $7863
		dc.w	$7885, $78a6, $78c8, $78e9, $790a, $792a, $794a, $796a, $798a, $79aa, $79c9, $79e7, $7a06, $7a24, $7a42, $7a60
		dc.w	$7a7d, $7a9a, $7ab7, $7ad3, $7aef, $7b0b, $7b27, $7b42, $7b5d, $7b78, $7b92, $7bac, $7bc6, $7bdf, $7bf9, $7c11
		dc.w	$7c2a, $7c42, $7c5a, $7c72, $7c89, $7ca0, $7cb7, $7cce, $7ce4, $7cfa, $7d0f, $7d25, $7d3a, $7d4e, $7d63, $7d77
		dc.w	$7d8a, $7d9e, $7db1, $7dc4, $7dd6, $7de9, $7dfb, $7e0c, $7e1e, $7e2f, $7e3f, $7e50, $7e60, $7e70, $7e7f, $7e8e
		dc.w	$7e9d, $7eac, $7eba, $7ec8, $7ed6, $7ee3, $7ef0, $7efd, $7f0a, $7f16, $7f22, $7f2d, $7f38, $7f43, $7f4e, $7f58
		dc.w	$7f62, $7f6c, $7f75, $7f7e, $7f87, $7f90, $7f98, $7fa0, $7fa7, $7fae, $7fb5, $7fbc, $7fc2, $7fc8, $7fce, $7fd3
		dc.w	$7fd9, $7fdd, $7fe2, $7fe6, $7fea, $7fed, $7ff1, $7ff4, $7ff6, $7ff8, $7ffa, $7ffc, $7ffe, $7fff, $7fff, $7fff
		dc.w	$7fff, $7fff, $7fff, $7fff, $7ffe, $7ffc, $7ffa, $7ff8, $7ff6, $7ff4, $7ff1, $7fed, $7fea, $7fe6, $7fe2, $7fdd
		dc.w	$7fd9, $7fd3, $7fce, $7fc8, $7fc2, $7fbc, $7fb5, $7fae, $7fa7, $7fa0, $7f98, $7f90, $7f87, $7f7e, $7f75, $7f6c
		dc.w	$7f62, $7f58, $7f4e, $7f43, $7f38, $7f2d, $7f22, $7f16, $7f0a, $7efd, $7ef0, $7ee3, $7ed6, $7ec8, $7eba, $7eac
		dc.w	$7e9d, $7e8e, $7e7f, $7e70, $7e60, $7e50, $7e3f, $7e2f, $7e1e, $7e0c, $7dfb, $7de9, $7dd6, $7dc4, $7db1, $7d9e
		dc.w	$7d8a, $7d77, $7d63, $7d4e, $7d3a, $7d25, $7d0f, $7cfa, $7ce4, $7cce, $7cb7, $7ca0, $7c89, $7c72, $7c5a, $7c42
		dc.w	$7c2a, $7c11, $7bf9, $7bdf, $7bc6, $7bac, $7b92, $7b78, $7b5d, $7b42, $7b27, $7b0b, $7aef, $7ad3, $7ab7, $7a9a
		dc.w	$7a7d, $7a60, $7a42, $7a24, $7a06, $79e7, $79c9, $79aa, $798a, $796a, $794a, $792a, $790a, $78e9, $78c8, $78a6
		dc.w	$7885, $7863, $7840, $781e, $77fb, $77d8, $77b4, $7790, $776c, $7748, $7723, $76fe, $76d9, $76b4, $768e, $7668
		dc.w	$7642, $761b, $75f4, $75cd, $75a6, $757e, $7556, $752d, $7505, $74dc, $74b3, $7489, $7460, $7436, $740b, $73e1
		dc.w	$73b6, $738b, $735f, $7334, $7308, $72dc, $72af, $7282, $7255, $7228, $71fa, $71cc, $719e, $7170, $7141, $7112
		dc.w	$70e3, $70b3, $7083, $7053, $7023, $6ff2, $6fc2, $6f90, $6f5f, $6f2d, $6efb, $6ec9, $6e97, $6e64, $6e31, $6dfe
		dc.w	$6dca, $6d96, $6d62, $6d2e, $6cf9, $6cc4, $6c8f, $6c5a, $6c24, $6bee, $6bb8, $6b82, $6b4b, $6b14, $6add, $6aa5
		dc.w	$6a6e, $6a36, $69fd, $69c5, $698c, $6953, $691a, $68e0, $68a7, $686d, $6832, $67f8, $67bd, $6782, $6747, $670b
		dc.w	$66d0, $6693, $6657, $661b, $65de, $65a1, $6564, $6526, $64e9, $64ab, $646c, $642e, $63ef, $63b0, $6371, $6332
		dc.w	$62f2, $62b2, $6272, $6232, $61f1, $61b0, $616f, $612e, $60ec, $60aa, $6068, $6026, $5fe4, $5fa1, $5f5e, $5f1b
		dc.w	$5ed7, $5e94, $5e50, $5e0c, $5dc8, $5d83, $5d3e, $5cf9, $5cb4, $5c6f, $5c29, $5be3, $5b9d, $5b57, $5b10, $5ac9
		dc.w	$5a82, $5a3b, $59f4, $59ac, $5964, $591c, $58d4, $588c, $5843, $57fa, $57b1, $5767, $571e, $56d4, $568a, $5640
		dc.w	$55f6, $55ab, $5560, $5515, $54ca, $547f, $5433, $53e7, $539b, $534f, $5303, $52b6, $5269, $521c, $51cf, $5181
		dc.w	$5134, $50e6, $5098, $504a, $4ffb, $4fad, $4f5e, $4f0f, $4ec0, $4e71, $4e21, $4dd1, $4d81, $4d31, $4ce1, $4c91
		dc.w	$4c40, $4bef, $4b9e, $4b4d, $4afb, $4aaa, $4a58, $4a06, $49b4, $4962, $490f, $48bd, $486a, $4817, $47c4, $4770
		dc.w	$471d, $46c9, $4675, $4621, $45cd, $4579, $4524, $44d0, $447b, $4426, $43d1, $437b, $4326, $42d0, $427a, $4224
		dc.w	$41ce, $4178, $4121, $40cb, $4074, $401d, $3fc6, $3f6f, $3f17, $3ec0, $3e68, $3e10, $3db8, $3d60, $3d08, $3caf
		dc.w	$3c57, $3bfe, $3ba5, $3b4c, $3af3, $3a9a, $3a40, $39e7, $398d, $3933, $38d9, $387f, $3825, $37ca, $3770, $3715
		dc.w	$36ba, $365f, $3604, $35a9, $354e, $34f2, $3497, $343b, $33df, $3383, $3327, $32cb, $326e, $3212, $31b5, $3159
		dc.w	$30fc, $309f, $3042, $2fe5, $2f87, $2f2a, $2ecc, $2e6f, $2e11, $2db3, $2d55, $2cf7, $2c99, $2c3b, $2bdc, $2b7e
		dc.w	$2b1f, $2ac1, $2a62, $2a03, $29a4, $2945, $28e5, $2886, $2827, $27c7, $2768, $2708, $26a8, $2648, $25e8, $2588
		dc.w	$2528, $24c8, $2467, $2407, $23a7, $2346, $22e5, $2284, $2224, $21c3, $2162, $2101, $209f, $203e, $1fdd, $1f7b
		dc.w	$1f1a, $1eb8, $1e57, $1df5, $1d93, $1d31, $1cd0, $1c6e, $1c0c, $1ba9, $1b47, $1ae5, $1a83, $1a20, $19be, $195b
		dc.w	$18f9, $1896, $1833, $17d1, $176e, $170b, $16a8, $1645, $15e2, $157f, $151c, $14b9, $1455, $13f2, $138f, $132b
		dc.w	$12c8, $1265, $1201, $119e, $113a, $10d6, $1073, $100f, $0fab, $0f47, $0ee4, $0e80, $0e1c, $0db8, $0d54, $0cf0
		dc.w	$0c8c, $0c28, $0bc4, $0b60, $0afb, $0a97, $0a33, $09cf, $096b, $0906, $08a2, $083e, $07d9, $0775, $0711, $06ac
		dc.w	$0648, $05e3, $057f, $051b, $04b6, $0452, $03ed, $0389, $0324, $02c0, $025b, $01f7, $0192, $012e, $00c9, $0065
		dc.w	$0000, $ff9b, $ff37, $fed2, $fe6e, $fe09, $fda5, $fd40, $fcdc, $fc77, $fc13, $fbae, $fb4a, $fae5, $fa81, $fa1d
		dc.w	$f9b8, $f954, $f8ef, $f88b, $f827, $f7c2, $f75e, $f6fa, $f695, $f631, $f5cd, $f569, $f505, $f4a0, $f43c, $f3d8
		dc.w	$f374, $f310, $f2ac, $f248, $f1e4, $f180, $f11c, $f0b9, $f055, $eff1, $ef8d, $ef2a, $eec6, $ee62, $edff, $ed9b
		dc.w	$ed38, $ecd5, $ec71, $ec0e, $ebab, $eb47, $eae4, $ea81, $ea1e, $e9bb, $e958, $e8f5, $e892, $e82f, $e7cd, $e76a
		dc.w	$e707, $e6a5, $e642, $e5e0, $e57d, $e51b, $e4b9, $e457, $e3f4, $e392, $e330, $e2cf, $e26d, $e20b, $e1a9, $e148
		dc.w	$e0e6, $e085, $e023, $dfc2, $df61, $deff, $de9e, $de3d, $dddc, $dd7c, $dd1b, $dcba, $dc59, $dbf9, $db99, $db38
		dc.w	$dad8, $da78, $da18, $d9b8, $d958, $d8f8, $d898, $d839, $d7d9, $d77a, $d71b, $d6bb, $d65c, $d5fd, $d59e, $d53f
		dc.w	$d4e1, $d482, $d424, $d3c5, $d367, $d309, $d2ab, $d24d, $d1ef, $d191, $d134, $d0d6, $d079, $d01b, $cfbe, $cf61
		dc.w	$cf04, $cea7, $ce4b, $cdee, $cd92, $cd35, $ccd9, $cc7d, $cc21, $cbc5, $cb69, $cb0e, $cab2, $ca57, $c9fc, $c9a1
		dc.w	$c946, $c8eb, $c890, $c836, $c7db, $c781, $c727, $c6cd, $c673, $c619, $c5c0, $c566, $c50d, $c4b4, $c45b, $c402
		dc.w	$c3a9, $c351, $c2f8, $c2a0, $c248, $c1f0, $c198, $c140, $c0e9, $c091, $c03a, $bfe3, $bf8c, $bf35, $bedf, $be88
		dc.w	$be32, $bddc, $bd86, $bd30, $bcda, $bc85, $bc2f, $bbda, $bb85, $bb30, $badc, $ba87, $ba33, $b9df, $b98b, $b937
		dc.w	$b8e3, $b890, $b83c, $b7e9, $b796, $b743, $b6f1, $b69e, $b64c, $b5fa, $b5a8, $b556, $b505, $b4b3, $b462, $b411
		dc.w	$b3c0, $b36f, $b31f, $b2cf, $b27f, $b22f, $b1df, $b18f, $b140, $b0f1, $b0a2, $b053, $b005, $afb6, $af68, $af1a
		dc.w	$aecc, $ae7f, $ae31, $ade4, $ad97, $ad4a, $acfd, $acb1, $ac65, $ac19, $abcd, $ab81, $ab36, $aaeb, $aaa0, $aa55
		dc.w	$aa0a, $a9c0, $a976, $a92c, $a8e2, $a899, $a84f, $a806, $a7bd, $a774, $a72c, $a6e4, $a69c, $a654, $a60c, $a5c5
		dc.w	$a57e, $a537, $a4f0, $a4a9, $a463, $a41d, $a3d7, $a391, $a34c, $a307, $a2c2, $a27d, $a238, $a1f4, $a1b0, $a16c
		dc.w	$a129, $a0e5, $a0a2, $a05f, $a01c, $9fda, $9f98, $9f56, $9f14, $9ed2, $9e91, $9e50, $9e0f, $9dce, $9d8e, $9d4e
		dc.w	$9d0e, $9cce, $9c8f, $9c50, $9c11, $9bd2, $9b94, $9b55, $9b17, $9ada, $9a9c, $9a5f, $9a22, $99e5, $99a9, $996d
		dc.w	$9930, $98f5, $98b9, $987e, $9843, $9808, $97ce, $9793, $9759, $9720, $96e6, $96ad, $9674, $963b, $9603, $95ca
		dc.w	$9592, $955b, $9523, $94ec, $94b5, $947e, $9448, $9412, $93dc, $93a6, $9371, $933c, $9307, $92d2, $929e, $926a
		dc.w	$9236, $9202, $91cf, $919c, $9169, $9137, $9105, $90d3, $90a1, $9070, $903e, $900e, $8fdd, $8fad, $8f7d, $8f4d
		dc.w	$8f1d, $8eee, $8ebf, $8e90, $8e62, $8e34, $8e06, $8dd8, $8dab, $8d7e, $8d51, $8d24, $8cf8, $8ccc, $8ca1, $8c75
		dc.w	$8c4a, $8c1f, $8bf5, $8bca, $8ba0, $8b77, $8b4d, $8b24, $8afb, $8ad3, $8aaa, $8a82, $8a5a, $8a33, $8a0c, $89e5
		dc.w	$89be, $8998, $8972, $894c, $8927, $8902, $88dd, $88b8, $8894, $8870, $884c, $8828, $8805, $87e2, $87c0, $879d
		dc.w	$877b, $875a, $8738, $8717, $86f6, $86d6, $86b6, $8696, $8676, $8656, $8637, $8619, $85fa, $85dc, $85be, $85a0
		dc.w	$8583, $8566, $8549, $852d, $8511, $84f5, $84d9, $84be, $84a3, $8488, $846e, $8454, $843a, $8421, $8407, $83ef
		dc.w	$83d6, $83be, $83a6, $838e, $8377, $8360, $8349, $8332, $831c, $8306, $82f1, $82db, $82c6, $82b2, $829d, $8289
		dc.w	$8276, $8262, $824f, $823c, $822a, $8217, $8205, $81f4, $81e2, $81d1, $81c1, $81b0, $81a0, $8190, $8181, $8172
		dc.w	$8163, $8154, $8146, $8138, $812a, $811d, $8110, $8103, $80f6, $80ea, $80de, $80d3, $80c8, $80bd, $80b2, $80a8
		dc.w	$809e, $8094, $808b, $8082, $8079, $8070, $8068, $8060, $8059, $8052, $804b, $8044, $803e, $8038, $8032, $802d
		dc.w	$8027, $8023, $801e, $801a, $8016, $8013, $800f, $800c, $800a, $8008, $8006, $8004, $8002, $8001, $8001, $8000
		dc.w	$8000, $8000, $8001, $8001, $8002, $8004, $8006, $8008, $800a, $800c, $800f, $8013, $8016, $801a, $801e, $8023
		dc.w	$8027, $802d, $8032, $8038, $803e, $8044, $804b, $8052, $8059, $8060, $8068, $8070, $8079, $8082, $808b, $8094
		dc.w	$809e, $80a8, $80b2, $80bd, $80c8, $80d3, $80de, $80ea, $80f6, $8103, $8110, $811d, $812a, $8138, $8146, $8154
		dc.w	$8163, $8172, $8181, $8190, $81a0, $81b0, $81c1, $81d1, $81e2, $81f4, $8205, $8217, $822a, $823c, $824f, $8262
		dc.w	$8276, $8289, $829d, $82b2, $82c6, $82db, $82f1, $8306, $831c, $8332, $8349, $8360, $8377, $838e, $83a6, $83be
		dc.w	$83d6, $83ef, $8407, $8421, $843a, $8454, $846e, $8488, $84a3, $84be, $84d9, $84f5, $8511, $852d, $8549, $8566
		dc.w	$8583, $85a0, $85be, $85dc, $85fa, $8619, $8637, $8656, $8676, $8696, $86b6, $86d6, $86f6, $8717, $8738, $875a
		dc.w	$877b, $879d, $87c0, $87e2, $8805, $8828, $884c, $8870, $8894, $88b8, $88dd, $8902, $8927, $894c, $8972, $8998
		dc.w	$89be, $89e5, $8a0c, $8a33, $8a5a, $8a82, $8aaa, $8ad3, $8afb, $8b24, $8b4d, $8b77, $8ba0, $8bca, $8bf5, $8c1f
		dc.w	$8c4a, $8c75, $8ca1, $8ccc, $8cf8, $8d24, $8d51, $8d7e, $8dab, $8dd8, $8e06, $8e34, $8e62, $8e90, $8ebf, $8eee
		dc.w	$8f1d, $8f4d, $8f7d, $8fad, $8fdd, $900e, $903e, $9070, $90a1, $90d3, $9105, $9137, $9169, $919c, $91cf, $9202
		dc.w	$9236, $926a, $929e, $92d2, $9307, $933c, $9371, $93a6, $93dc, $9412, $9448, $947e, $94b5, $94ec, $9523, $955b
		dc.w	$9592, $95ca, $9603, $963b, $9674, $96ad, $96e6, $9720, $9759, $9793, $97ce, $9808, $9843, $987e, $98b9, $98f5
		dc.w	$9930, $996d, $99a9, $99e5, $9a22, $9a5f, $9a9c, $9ada, $9b17, $9b55, $9b94, $9bd2, $9c11, $9c50, $9c8f, $9cce
		dc.w	$9d0e, $9d4e, $9d8e, $9dce, $9e0f, $9e50, $9e91, $9ed2, $9f14, $9f56, $9f98, $9fda, $a01c, $a05f, $a0a2, $a0e5
		dc.w	$a129, $a16c, $a1b0, $a1f4, $a238, $a27d, $a2c2, $a307, $a34c, $a391, $a3d7, $a41d, $a463, $a4a9, $a4f0, $a537
		dc.w	$a57e, $a5c5, $a60c, $a654, $a69c, $a6e4, $a72c, $a774, $a7bd, $a806, $a84f, $a899, $a8e2, $a92c, $a976, $a9c0
		dc.w	$aa0a, $aa55, $aaa0, $aaeb, $ab36, $ab81, $abcd, $ac19, $ac65, $acb1, $acfd, $ad4a, $ad97, $ade4, $ae31, $ae7f
		dc.w	$aecc, $af1a, $af68, $afb6, $b005, $b053, $b0a2, $b0f1, $b140, $b18f, $b1df, $b22f, $b27f, $b2cf, $b31f, $b36f
		dc.w	$b3c0, $b411, $b462, $b4b3, $b505, $b556, $b5a8, $b5fa, $b64c, $b69e, $b6f1, $b743, $b796, $b7e9, $b83c, $b890
		dc.w	$b8e3, $b937, $b98b, $b9df, $ba33, $ba87, $badc, $bb30, $bb85, $bbda, $bc2f, $bc85, $bcda, $bd30, $bd86, $bddc
		dc.w	$be32, $be88, $bedf, $bf35, $bf8c, $bfe3, $c03a, $c091, $c0e9, $c140, $c198, $c1f0, $c248, $c2a0, $c2f8, $c351
		dc.w	$c3a9, $c402, $c45b, $c4b4, $c50d, $c566, $c5c0, $c619, $c673, $c6cd, $c727, $c781, $c7db, $c836, $c890, $c8eb
		dc.w	$c946, $c9a1, $c9fc, $ca57, $cab2, $cb0e, $cb69, $cbc5, $cc21, $cc7d, $ccd9, $cd35, $cd92, $cdee, $ce4b, $cea7
		dc.w	$cf04, $cf61, $cfbe, $d01b, $d079, $d0d6, $d134, $d191, $d1ef, $d24d, $d2ab, $d309, $d367, $d3c5, $d424, $d482
		dc.w	$d4e1, $d53f, $d59e, $d5fd, $d65c, $d6bb, $d71b, $d77a, $d7d9, $d839, $d898, $d8f8, $d958, $d9b8, $da18, $da78
		dc.w	$dad8, $db38, $db99, $dbf9, $dc59, $dcba, $dd1b, $dd7c, $dddc, $de3d, $de9e, $deff, $df61, $dfc2, $e023, $e085
		dc.w	$e0e6, $e148, $e1a9, $e20b, $e26d, $e2cf, $e330, $e392, $e3f4, $e457, $e4b9, $e51b, $e57d, $e5e0, $e642, $e6a5
		dc.w	$e707, $e76a, $e7cd, $e82f, $e892, $e8f5, $e958, $e9bb, $ea1e, $ea81, $eae4, $eb47, $ebab, $ec0e, $ec71, $ecd5
		dc.w	$ed38, $ed9b, $edff, $ee62, $eec6, $ef2a, $ef8d, $eff1, $f055, $f0b9, $f11c, $f180, $f1e4, $f248, $f2ac, $f310
		dc.w	$f374, $f3d8, $f43c, $f4a0, $f505, $f569, $f5cd, $f631, $f695, $f6fa, $f75e, $f7c2, $f827, $f88b, $f8ef, $f954
		dc.w	$f9b8, $fa1d, $fa81, $fae5, $fb4a, $fbae, $fc13, $fc77, $fcdc, $fd40, $fda5, $fe09, $fe6e, $fed2, $ff37, $ff9b

	CNOP 0,4
gfxname:	dc.b	'graphics.library',0

	section ChipRAM,data_c

	CNOP 0,4
bitplane1:	blk.b	10240*2,0
bitplane2:	blk.b	10240*2,0

	CNOP 0,4
copper:		dc.w	$00e0,$0000
		dc.w	$00e2,$0000
		dc.w	$00e4,$0000
		dc.w	$00e6,$0000
		dc.w	$0180,$0004
		dc.w	$0182
col1:		dc.w	$0fff
		dc.w	$0184
col2:		dc.w	$0f00
		dc.w	$0186
col3:		dc.w	$00f0
		;dc.w	$9601,$ff00
		;dc.w	$0180,$0800
		dc.w	$ffff,$fffe
