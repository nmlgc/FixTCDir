	.286
	.model tiny, pascal
	.code
	org 100h

print	macro	stuff:vararg
	for string, <stuff>
		mov	dx, string
		mov	ah, 09h
		int	21h
	endm
endm

string_declare	macro	sym, val:vararg
	sym	db	val
	sym&_len	dw $-sym
endm

file_seek	macro	hi, lo
	mov	ax, 4200h
	mov	cx, hi
	mov	dx, lo
	int	21h
endm

file_write	macro	stuff:vararg
	for string, <stuff>
		mov	ah, 40h
		mov	cx, string&_len
		mov	dx, offset string
		int	21h
	endm
endm

entry:	jmp	check


dos_string_terminate	proc string:word
	mov	di, cs
	mov	es, di
	mov	di, string
	xor	al, al
	xor	cx, cx	; Set maximum number of characters to FFFF.
	dec	cx	; Yes, this matters.
	cld
	repne	scasb
	dec	di
	mov	byte ptr es:[di], '$'
	ret
dos_string_terminate	endp


file_check	proc	fn:word
	mov	ax, 3d01h
	mov	dx, fn
	int	21h
	pushf
	mov	bx, ax
	mov	ah, 3eh	; Close test file
	int	21h
	popf
	ret
file_check	endp


file_open	proc	fn:word
	mov	ax, 3d01h
	mov	dx, fn
	int	21h
	pushf
	mov	bx, ax
	invoke	dos_string_terminate, fn
	print	offset msg_bullet, fn, offset msg_crlf
	ret
file_open	endp


file_write_link	proc
	file_write	dash_L, full, dir_lib, crlf
	ret
file_write_link	endp


file_close	proc
	mov	ah, 40h
	xor	cx, cx
	int	21h
	mov	ah, 3eh
	int	21h
	ret
file_close	endp

wrong:	print	offset msg_wrong
	ret


check:	for string, <bcroot_fn, thelp_fn, tlink_fn, turboc_fn, tc_fn>
		invoke	file_check, offset string
		jb	wrong
	endm


fix:	mov	ah, 19h	; Get drive
	int	21h	; Drive is now in AL
	inc	al	; IMPORTANT, 0 = default drive!
	mov	dl, al
	add	al, 40h	; Convert to a letter
	mov	[drive], al

	mov	ah, 47h	; Get directory
	mov	si, offset dir
	int	21h
	invoke	dos_string_terminate, offset dir
	sub	di, offset full
	mov	full_len, di

	print	offset msg_fixing, offset full, offset msg_overwrite

bcroot:	invoke	file_open, offset bcroot_fn
	file_write	bcroot_1, full
	invoke	file_close

thelp:	invoke	file_open, offset thelp_fn
	file_write	thelp_1, full, thelp_2
	invoke	file_close

tlink:	invoke	file_open, offset tlink_fn
	invoke	file_write_link
	invoke	file_close

turboc:	invoke	file_open, offset turboc_fn
	file_write	dash_I, full, dir_inc, crlf
	invoke	file_write_link
	invoke	file_close

tc:	invoke	file_open, offset tc_fn
	file_seek	6, 632fh
	file_write	full, dir_inc, null
	file_seek	6, 63f3h
	file_write	full, dir_lib, null
	mov	ah, 3eh	; No truncation here, of course
	int	21h

	print	offset msg_done
	ret

msg_fixing	db 'Fixing Turbo C++ 4.0J installation directory to $'
msg_overwrite	db 0dh, 0ah
		db 'This will overwrite any custom edits you may have made to the affected files!', 0dh, 0ah, '$'
msg_done	db 'Done.$'
msg_wrong	db 'Please run this program in the Turbo C++ 4.0J installation directory,', 0dh, 0ah
		db 'and make sure to remove any write protection on its files.$'
msg_bullet	db '* $'
msg_crlf	db 0dh, 0ah, '$'

bcroot_fn	db 'BIN\BCROOT.INC', 0
thelp_fn	db 'BIN\THELP.CFG', 0
tlink_fn	db 'BIN\TLINK.CFG', 0
turboc_fn	db 'BIN\TURBOC.CFG', 0
tc_fn	db 'BIN\TC.EXE', 0

string_declare	bcroot_1, 'BCROOT='
string_declare	thelp_1, '/f'
string_declare	thelp_2, '\BIN\TCHELP.TCH', 0dh, 0ah

string_declare	dash_I, '-I'
string_declare	dash_L, '-L'
string_declare	null, 0

string_declare	dir_inc, '\INCLUDE'
string_declare	dir_lib, '\LIB'
string_declare	crlf, 0dh, 0ah

full_len	dw 0
full	label byte
drive	db 0
	db ':\'
dir	db 64 dup (0)

end entry
