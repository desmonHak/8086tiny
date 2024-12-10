%line 8+1 bios.asm
[cpu 8086]





%line 17+1 bios.asm

%line 21+1 bios.asm

%line 25+1 bios.asm

%line 29+1 bios.asm

[org 100h]

main:

 jmp bios_entry



 dw rm_mode12_reg1
 dw rm_mode012_reg2
 dw rm_mode12_disp
 dw rm_mode12_dfseg
 dw rm_mode0_reg1
 dw rm_mode012_reg2
 dw rm_mode0_disp
 dw rm_mode0_dfseg
 dw xlat_ids
 dw ex_data
 dw std_flags
 dw parity
 dw base_size
 dw i_w_adder
 dw i_mod_adder
 dw jxx_dec_a
 dw jxx_dec_b
 dw jxx_dec_c
 dw jxx_dec_d
 dw flags_mult



biosstr db '8086tiny BIOS Revision 1.61!', 0, 0
mem_top db 0xea, 0, 0x01, 0, 0xf0, '03/08/14', 0, 0xfe, 0

bios_entry:



 mov sp, 0xf000
 mov ss, sp

 push cs
 pop es

 push ax








 cld

 xor ax, ax
 mov di, 24
 stosw
 mov di, 49
 stosb



 mov [cs:boot_device], dl



 push dx

 mov dx, 0x3b8
 mov al, 0
 out dx, al

 mov dx, 0x3b4
 mov al, 1
 out dx, al
 mov dx, 0x3b5
 mov al, 0x2d
 out dx, al
 mov dx, 0x3b4
 mov al, 6
 out dx, al
 mov dx, 0x3b5
 mov al, 0x57
 out dx, al

 pop dx

 pop ax



 cmp byte [cs:boot_state], 0
 jne boot

 mov byte [cs:boot_state], 1








 mov dx, cx
 mov cx, ax

 mov [cs:hd_secs_hi], dx
 mov [cs:hd_secs_lo], cx

 cmp cx, 0
 je maybe_no_hd

 mov word [cs:num_disks], 2
 jmp calc_hd

maybe_no_hd:

 cmp dx, 0
 je no_hd

 mov word [cs:num_disks], 2
 jmp calc_hd

no_hd:

 mov word [cs:num_disks], 1

calc_hd:

 mov ax, cx
 mov word [cs:hd_max_track], 1
 mov word [cs:hd_max_head], 1

 cmp dx, 0
 ja sect_overflow
 cmp ax, 63
 ja sect_overflow

 mov [cs:hd_max_sector], ax
 jmp calc_heads

sect_overflow:

 mov cx, 63
 div cx
 mov [cs:hd_max_track], ax
 mov word [cs:hd_max_sector], 63

calc_heads:

 mov dx, 0
 mov ax, [cs:hd_max_track]
 cmp ax, 1024
 ja track_overflow

 jmp calc_end

track_overflow:

 mov cx, 1024
 div cx
 mov [cs:hd_max_head], ax
 mov word [cs:hd_max_track], 1024

calc_end:




 mov ax, [cs:hd_max_head]
 mov [cs:int41_max_heads], al
 mov ax, [cs:hd_max_track]
 mov [cs:int41_max_cyls], ax
 mov ax, [cs:hd_max_sector]
 mov [cs:int41_max_sect], al

 dec word [cs:hd_max_track]
 dec word [cs:hd_max_head]



boot: mov ax, 0
 push ax
 popf

 push cs
 push cs
 pop ds
 pop ss
 mov sp, 0xf000



 cld

 xor ax, ax
 mov es, ax
 xor di, di
 mov cx, 512
 rep stosw



 mov di, 0
 mov si, int_table
 mov cx, [itbl_size]
 rep movsb



 mov cx, int41
 mov word [es:4*0x41], cx
 mov cx, 0xf000
 mov word [es:4*0x41 + 2], cx



 mov ax, 0xffff
 mov es, ax
 mov di, 0
 mov si, mem_top
 mov cx, 16
 rep movsb



 mov ax, 0x40
 mov es, ax
 mov di, 0
 mov si, bios_data
 mov cx, 0x100
 rep movsb



 mov ax, 0xb800
 mov es, ax
 mov di, 0
 mov cx, 80*25
 mov ax, 0x0700
 rep stosw



 mov ax, 0xc800
 mov es, ax
 mov di, 0
 mov cx, 80*25
 mov ax, 0x0700
 rep stosw



 mov dx, 0x61
 mov al, 0
 out dx, al

 mov dx, 0x60
 out dx, al

 mov dx, 0x64
 out dx, al

 mov dx, 0
 mov al, 0xFF

next_out:

 inc dx

 cmp dx, 0x40
 je next_out
 cmp dx, 0x42
 je next_out
 cmp dx, 0x3B8
 je next_out
 cmp dx, 0x60
 je next_out
 cmp dx, 0x61
 je next_out
 cmp dx, 0x64
 je next_out

 out dx, al

 cmp dx, 0xFFF
 jl next_out

 mov al, 0

 mov dx, 0x3DA
 out dx, al

 mov dx, 0x3BA
 out dx, al

 mov dx, 0x3B8
 out dx, al

 mov dx, 0x3BC
 out dx, al

 mov dx, 0x62
 out dx, al



 push cs
 pop es
 mov bx, timetable
%line 19+1 bios.asm
 db 0x0f, 0x01
%line 342+1 bios.asm
 mov ax, [es:tm_msec]
 mov [cs:last_int8_msec], ax



 mov ax, 0
 mov es, ax

 mov ax, 0x0201
 mov dh, 0
 mov dl, [cs:boot_device]
 mov cx, 1
 mov bx, 0x7c00
 int 13h



 jmp 0:0x7c00



int7:


 push ds
 push es
 push ax
 push bx
 push bp

 push cs
 pop ds

 mov bx, 0x40
 mov es, bx



 mov ax, [es:this_keystroke-bios_data]
 mov byte [es:this_keystroke+1-bios_data], 0

 real_key:

 mov byte [cs:last_key_sdl], 0

 test ah, 4
 jz check_linux_bksp

 mov byte [es:keyflags1-bios_data], 0
 mov byte [es:keyflags2-bios_data], 0

 mov byte [cs:last_key_sdl], 1

 test ah, 0x40
 jz sdl_check_specials

 mov byte [cs:last_key_sdl], 2

 sdl_check_specials:

 mov bx, ax
 and bh, 7
 cmp bx, 0x52f
 je sdl_just_press_shift
 cmp bx, 0x530
 je sdl_just_press_shift
 cmp bx, 0x533
 je sdl_just_press_alt
 cmp bx, 0x534
 je sdl_just_press_alt
 cmp bx, 0x531
 je sdl_just_press_ctrl
 cmp bx, 0x532
 je sdl_just_press_ctrl
 jmp sdl_check_alt

 sdl_just_press_shift:

 mov al, 0x36
 and ah, 0x40
 add al, ah
 add al, ah
 call io_key_available
 jmp i2_dne

 sdl_just_press_alt:

 mov al, 0x38
 and ah, 0x40
 add al, ah
 add al, ah
 call io_key_available
 jmp i2_dne

 sdl_just_press_ctrl:

 mov al, 0x1d
 and ah, 0x40
 add al, ah
 add al, ah
 call io_key_available
 jmp i2_dne

 sdl_check_alt:

 test ah, 8
 jz sdl_no_alt
 add byte [es:keyflags1-bios_data], 8
 add byte [es:keyflags2-bios_data], 2

 sdl_no_alt:

 test ah, 0x20
 jz sdl_no_ctrl
 add byte [es:keyflags1-bios_data], 4

 sdl_no_ctrl:

 test ah, 0x10
 jz sdl_no_mods
 add byte [es:keyflags1-bios_data], 1

 sdl_no_mods:

 and ah, 1






 check_sdl_f_keys:

 cmp ax, 0x125
 ja i2_dne

 cmp ax, 0x11a
 jb check_sdl_pgup_pgdn_keys

 sub ax, 0xdf
 cmp ax, 0x45
 jb check_sdl_f_keys2
 add ax, 0x12

 check_sdl_f_keys2:

 mov bh, al
 mov al, 0
 jmp sdl_scancode_xlat_done

 check_sdl_pgup_pgdn_keys:

 cmp ax, 0x116
 jb check_sdl_cursor_keys
 cmp ax, 0x119
 ja check_sdl_cursor_keys

 sub ax, 0x116
 mov bx, pgup_pgdn_xlt
 cs xlat

 mov bh, al
 mov al, 0
 jmp sdl_scancode_xlat_done

 check_sdl_cursor_keys:

 cmp ax, 0x111
 jb sdl_process_key

 sub ax, 0x111
 mov bx, unix_cursor_xlt
 xlat

 mov bh, al
 mov al, 0
 mov byte [es:this_keystroke-bios_data], 0
 jmp sdl_scancode_xlat_done

 sdl_process_key:

 cmp ax, 0x100
 jae i2_dne
 cmp al, 0x7f
 jne sdl_process_key2
 mov al, 8

 sdl_process_key2:

 push ax
 mov bx, a2scan_tbl
 xlat
 mov bh, al
 pop ax

 sdl_scancode_xlat_done:

 add bh, 0x80
 cmp byte [cs:last_key_sdl], 2
 je sdl_not_in_buf

 sub bh, 0x80

 sdl_key_down:

 mov [es:this_keystroke-bios_data], al

 sdl_not_in_buf:

 mov al, bh
 call io_key_available
 jmp i2_dne

 check_linux_bksp:

 cmp al, 0
 je i2_dne

 cmp al, 0x7f
 jne after_check_bksp

 mov al, 8
 mov byte [es:this_keystroke-bios_data], 8

 after_check_bksp:

 cmp byte [es:next_key_fn-bios_data], 1
 je i2_n

 cmp al, 0x01
 jne i2_not_alt

 mov byte [es:keyflags1-bios_data], 8
 mov byte [es:keyflags2-bios_data], 2
 mov al, 0x38
 call io_key_available

 mov byte [es:next_key_alt-bios_data], 1
 jmp i2_dne

 i2_not_alt:

 cmp al, 0x06
 jne i2_not_fn

 mov byte [es:next_key_fn-bios_data], 1
 jmp i2_dne

 i2_not_fn:

 cmp byte [es:notranslate_flg-bios_data], 1
 mov byte [es:notranslate_flg-bios_data], 0
 jne need_to_translate

 mov byte [es:this_keystroke-bios_data], 0
 jmp after_translate

 need_to_translate:

 cmp al, 0xe0
 mov byte [es:notranslate_flg-bios_data], 1
 je i2_dne

 mov byte [es:notranslate_flg-bios_data], 0

 cmp al, 0x1b
 jne i2_escnext


 cmp byte [es:escape_flag-bios_data], 1
 jne i2_sf



 mov byte [es:this_keystroke-bios_data], 0x1b

 mov al, 0x01
 call keypress_release

 i2_sf:

 mov byte [es:escape_flag-bios_data], 1
 jmp i2_dne

 i2_escnext:


 cmp byte [es:escape_flag-bios_data], 1
 jne i2_noesc


 cmp al, '['
 je i2_esc



 mov byte [es:this_keystroke-bios_data], 0x1b

 mov al, 0x01
 call keypress_release


 mov byte [es:escape_flag-bios_data], 0
 mov al, [es:this_keystroke-bios_data]
 jmp i2_noesc

 i2_esc:


 mov byte [es:escape_flag-bios_data], 2
 jmp i2_dne

 i2_noesc:

 cmp byte [es:escape_flag-bios_data], 2
 jne i2_regular_key


 mov byte [es:keyflags1-bios_data], 0
 mov byte [es:keyflags2-bios_data], 0


 sub al, 'A'
 mov bx, unix_cursor_xlt
 xlat

 mov byte [es:this_keystroke-bios_data], 0
 jmp after_translate

 i2_regular_key:

 mov byte [es:notranslate_flg-bios_data], 0

 mov bx, a2shift_tbl
 xlat




 push ax


 mov ah, [es:next_key_alt-bios_data]
[cpu 186]
 shl ah, 3
[cpu 8086]
 add al, ah

 cmp byte [es:this_keystroke-bios_data], 0x1A
 ja i2_no_ctrl
 cmp byte [es:this_keystroke-bios_data], 0
 je i2_no_ctrl
 cmp byte [es:this_keystroke-bios_data], 0xD
 je i2_no_ctrl
 cmp byte [es:this_keystroke-bios_data], 0xA
 je i2_no_ctrl
 cmp byte [es:this_keystroke-bios_data], 0x8
 je i2_no_ctrl
 cmp byte [es:this_keystroke-bios_data], 0x9
 je i2_no_ctrl
 add al, 4

 push ax
 mov al, 0x1d
 call io_key_available
 pop ax

 i2_no_ctrl:

 mov [es:keyflags1-bios_data], al

[cpu 186]
 shr ah, 2
[cpu 8086]
 mov [es:keyflags2-bios_data], ah

 pop ax

 test al, 1
 jz i2_n

 mov al, 0x36
 call io_key_available

 i2_n:

 mov al, [es:this_keystroke-bios_data]

 mov bx, a2scan_tbl
 xlat

 cmp byte [es:next_key_fn-bios_data], 1
 jne after_translate

 cmp byte [es:this_keystroke-bios_data], 1
 je after_translate

 cmp byte [es:this_keystroke-bios_data], 6
 je after_translate

 mov byte [es:this_keystroke-bios_data], 0
 add al, 0x39

 after_translate:

 mov byte [es:escape_flag-bios_data], 0
 mov byte [es:escape_flag_last-bios_data], 0



 cmp byte [es:next_key_alt-bios_data], 1
 jne skip_ascii_zero

 mov byte [es:this_keystroke-bios_data], 0

 skip_ascii_zero:


 call keypress_release


 cmp al, 0xe0
 je i2_dne

 test byte [es:keyflags1-bios_data], 1
 jz check_ctrl

 mov al, 0xb6
 call io_key_available

 check_ctrl:

 test byte [es:keyflags1-bios_data], 4
 jz check_alt

 mov al, 0x9d
 call io_key_available

 check_alt:

 mov al, byte [es:next_key_alt-bios_data]
 mov byte [es:next_key_alt-bios_data], 0
 mov byte [es:next_key_fn-bios_data], 0

 cmp al, 1
 je endalt

 jmp i2_dne

 endalt:

 mov al, 0xb8
 call io_key_available

 i2_dne:

 pop bp
 pop bx
 pop ax
 pop es
 pop ds
 iret



int9:

 push es
 push ax
 push bx
 push bp

 in al, 0x60

 cmp al, 0x80
 jae no_add_buf
 cmp al, 0x36
 je no_add_buf
 cmp al, 0x38
 je no_add_buf
 cmp al, 0x1d
 je no_add_buf

 mov bx, 0x40
 mov es, bx

 mov bh, al
 mov al, [es:this_keystroke-bios_data]



 mov bp, [es:kbbuf_tail-bios_data]
 mov byte [es:bp], al
 mov byte [es:bp+1], bh


 add word [es:kbbuf_tail-bios_data], 2
 call kb_adjust_buf

 no_add_buf:

 mov al, 1
 out 0x64, al

 pop bp
 pop bx
 pop ax
 pop es

 iret



inta:








 push ax
 push bx
 push dx
 push bp
 push es

 push cx
 push di
 push ds
 push si

 call vmem_driver_entry



 push cs
 pop es
 mov bx, timetable
%line 19+1 bios.asm
 db 0x0f, 0x01
%line 883+1 bios.asm

 mov ax, [cs:tm_msec]
 sub ax, [cs:last_int8_msec]

 make_ctr_positive:

 cmp ax, 0
 jge no_add_1000

 add ax, 1000
 jmp make_ctr_positive

 no_add_1000:

 mov bx, 0x40
 mov es, bx

 mov dx, 0
 mov bx, 1193
 mul bx

 mov bx, [es:timer0_freq-bios_data]

 cmp bx, 0
 jne no_adjust_10000

 mov bx, 0xffff

 no_adjust_10000:

 div bx

 cmp ax, 0
 je i8_end

 add word [es:0x6C], ax
 adc word [es:0x6E], 0

inta_call_int8:

 push ax
 int 8
 pop ax

 dec ax
 cmp ax, 0
 jne inta_call_int8

 mov ax, [cs:tm_msec]
 mov [cs:last_int8_msec], ax

skip_timer_increment:


 cmp byte [cs:last_key_sdl], 0
 jne i8_end


 cmp byte [es:key_now_down-bios_data], 0
 je i8_no_key_down

 mov al, [es:key_now_down-bios_data]
 mov byte [es:key_now_down-bios_data], 0
 add al, 0x80
 call io_key_available

 i8_no_key_down:


 cmp byte [es:escape_flag-bios_data], 1
 jne i8_end


 cmp byte [es:escape_flag_last-bios_data], 1
 je i8_stuff_esc

 inc byte [es:escape_flag_last-bios_data]
 jmp i8_end

i8_stuff_esc:


 mov byte [es:escape_flag-bios_data], 0
 mov byte [es:escape_flag_last-bios_data], 0









 mov byte [es:this_keystroke-bios_data], 0x1b


 mov al, 0x01
 call keypress_release

i8_end:


 mov dx, 0x3BA
 in al, dx
 xor al, 0x80
 out dx, al

 pop si
 pop ds
 pop di
 pop cx

 pop es
 pop bp
 pop dx
 pop bx
 pop ax

 iret



int8:

 int 0x1c
 iret



int10:

 cmp ah, 0x00
 je int10_set_vm
 cmp ah, 0x01
 je int10_set_cshape
 cmp ah, 0x02
 je int10_set_cursor
 cmp ah, 0x03
 je int10_get_cursor
 cmp ah, 0x06
 je int10_scrollup
 cmp ah, 0x07
 je int10_scrolldown
 cmp ah, 0x08
 je int10_charatcur
 cmp ah, 0x09
 je int10_write_char_attrib
 cmp ah, 0x0e
 je int10_write_char
 cmp ah, 0x0f
 je int10_get_vm



 iret

 int10_set_vm:

 push dx
 push cx
 push bx
 push es

 cmp al, 4
 je int10_switch_to_cga_gfx
 cmp al, 5
 je int10_switch_to_cga_gfx
 cmp al, 6
 je int10_switch_to_cga_gfx

 push ax

 mov dx, 0x3b8
 mov al, 0
 out dx, al

 mov dx, 0x3b4
 mov al, 1
 out dx, al
 mov dx, 0x3b5
 mov al, 0x2d
 out dx, al
 mov dx, 0x3b4
 mov al, 6
 out dx, al
 mov dx, 0x3b5
 mov al, 0x57
 out dx, al

 mov dx, 0x40
 mov es, dx

 mov byte [es:0xac], 0

 pop ax

 cmp al, 7
 je int10_set_vm_3
 cmp al, 2
 je int10_set_vm_3

 jmp int10_set_vm_continue

 int10_switch_to_cga_gfx:



 mov dx, 0x40
 mov es, dx

 mov [es:0x49], al
 mov byte [es:0xac], 1

 mov dx, 0x3b4
 mov al, 1
 out dx, al
 mov dx, 0x3b5
 mov al, 0x28
 out dx, al
 mov dx, 0x3b4
 mov al, 6
 out dx, al
 mov dx, 0x3b5
 mov al, 0x64
 out dx, al

 mov dx, 0x3b8
 mov al, 0x8a
 out dx, al

 mov bh, 7
 call clear_screen

 mov ax, 0x30
 jmp svmn_exit

 int10_set_vm_3:

 mov al, 3

 int10_set_vm_continue:

 mov bx, 0x40
 mov es, bx

 mov [es:vidmode-bios_data], al

 mov bh, 7
 call clear_screen

 cmp byte [es:vidmode-bios_data], 6
 je set6
 mov al, 0x30
 jmp svmn

 set6:

 mov al, 0x3f

 svmn:


 push ax
 mov dx, 0x3B8
 mov al, 0
 out dx, al
 pop ax

 svmn_exit:

 pop es
 pop bx
 pop cx
 pop dx
 iret

 int10_set_cshape:

 push ds
 push ax
 push cx

 mov ax, 0x40
 mov ds, ax

 mov byte [cursor_visible-bios_data], 1

 and ch, 01100000b
 cmp ch, 00100000b
 jne cur_visible

 mov byte [cursor_visible-bios_data], 0
 call ansi_hide_cursor
 jmp cur_done

 cur_visible:

 call ansi_show_cursor

 cur_done:

 pop cx
 pop ax
 pop ds
 iret

 int10_set_cursor:

 push ds
 push ax

 mov ax, 0x40
 mov ds, ax

 mov [curpos_y-bios_data], dh
 mov [crt_curpos_y-bios_data], dh
 mov [curpos_x-bios_data], dl
 mov [crt_curpos_x-bios_data], dl

 cmp dh, 24
 jbe skip_set_cur_row_max


 call ansi_hide_cursor
 jmp skip_set_cur_ansi

 skip_set_cur_row_max:

 cmp dl, 79
 jbe skip_set_cur_col_max


 call ansi_hide_cursor
 jmp skip_set_cur_ansi

 skip_set_cur_col_max:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1222+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1224+1 bios.asm
 mov al, dh
 inc al
 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1229+1 bios.asm
 mov al, dl
 inc al
 call puts_decimal_al
 mov al, 'H'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1234+1 bios.asm

 cmp byte [cursor_visible-bios_data], 1
 jne skip_set_cur_ansi
 call ansi_show_cursor

 skip_set_cur_ansi:

 pop ax
 pop ds
 iret

 int10_get_cursor:

 push es

 mov cx, 0x40
 mov es, cx

 mov cx, 0x0607
 mov dl, [es:curpos_x-bios_data]
 mov dh, [es:curpos_y-bios_data]

 pop es

 iret

 int10_scrollup:

 push bx
 push cx
 push bp
 push ax

 mov bp, bx
 mov cl, 12
 ror bp, cl
 and bp, 7
 mov bl, byte [cs:bp+colour_table]
 add bl, 10

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1276+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1278+1 bios.asm
 mov al, bl
 call puts_decimal_al
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1282+1 bios.asm

 pop ax
 pop bp
 pop cx
 pop bx

 cmp al, 0
 jne cls_partial

 cmp cx, 0
 jne cls_partial

 cmp dl, 0x4f
 jb cls_partial

 cmp dh, 0x18
 jb cls_partial

 call clear_screen
 iret

 cls_partial:

 push ax
 push bx

 mov bl, al
 cmp bl, 0
 jne cls_partial_up_whole

 mov bl, 25

 cls_partial_up_whole:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1318+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1320+1 bios.asm

 cmp ch, 0
 je cls_maybe_fs
 jmp cls_not_fs

 cls_maybe_fs:

 cmp dh, 24
 je cls_fs

 cls_not_fs:

 mov al, ch
 inc al
 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1337+1 bios.asm
 mov al, dh
 inc al
 call puts_decimal_al

 cls_fs:

 mov al, 'r'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1345+1 bios.asm

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1348+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1350+1 bios.asm

 cmp bl, 1
 jne cls_fs_multiline

 mov al, 'M'
 jmp cs_fs_ml_out

cls_fs_multiline:

 mov al, bl
 call puts_decimal_al
 mov al, 'S'

cs_fs_ml_out:

%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1366+1 bios.asm

 pop bx
 pop ax




 push ax
 push bx
 push dx
 push es

 mov ax, 0x40
 mov es, ax

 mov ah, 2
 mov bh, 0
 mov dh, [es:curpos_y-bios_data]
 mov dl, [es:curpos_x-bios_data]
 int 10h

 pop es
 pop dx
 pop bx
 pop ax

int10_scroll_up_vmem_update:



 push bx
 push ax

 push ds
 push es
 push cx
 push dx
 push si
 push di

 mov byte [cs:vram_dirty], 1

 push bx

 mov bx, 0xb800
 mov es, bx
 mov ds, bx

 pop bx
 mov bl, al

 cls_vmem_scroll_up_next_line:

 cmp bl, 0
 je cls_vmem_scroll_up_done

 cls_vmem_scroll_up_one:

 push bx
 push dx

 mov ax, 0
 mov al, ch
 mov bx, 80
 mul bx
 add al, cl
 adc ah, 0
 mov bx, 2
 mul bx

 pop dx
 pop bx

 mov di, ax
 mov si, ax
 add si, 2*80

 mov ax, 0
 add al, dl
 adc ah, 0
 inc ax
 sub al, cl
 sbb ah, 0

 cmp ch, dh
 jae cls_vmem_scroll_up_one_done

vmem_scroll_up_copy_next_row:

 push cx
 mov cx, ax
 cld
 rep movsw
 pop cx

 inc ch
 jmp cls_vmem_scroll_up_one

 cls_vmem_scroll_up_one_done:

 push cx
 mov cx, ax
 mov ah, bh
 mov al, 0
 cld
 rep stosw
 pop cx

 dec bl
 jmp cls_vmem_scroll_up_next_line

 cls_vmem_scroll_up_done:










 pop di
 pop si
 pop dx
 pop cx
 pop es
 pop ds

 pop ax
 pop bx

 iret

 int10_scrolldown:

 push bx
 push cx
 push bp
 push ax

 mov bp, bx
 mov cl, 12
 ror bp, cl
 and bp, 7
 mov bl, byte [cs:bp+colour_table]
 add bl, 10

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1516+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1518+1 bios.asm
 mov al, bl
 call puts_decimal_al
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1522+1 bios.asm

 pop ax
 pop bp
 pop cx
 pop bx

 cmp al, 0
 jne cls_partial_down

 cmp cx, 0
 jne cls_partial_down

 cmp dl, 0x4f
 jne cls_partial_down

 cmp dh, 0x18
 jl cls_partial_down

 call clear_screen
 iret

 cls_partial_down:

 push ax
 push bx

 mov bx, 0
 mov bl, al

 cmp bl, 0
 jne cls_partial_down_whole

 mov bl, 25

 cls_partial_down_whole:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1560+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1562+1 bios.asm

 cmp ch, 0
 je cls_maybe_fs_down
 jmp cls_not_fs_down

 cls_maybe_fs_down:

 cmp dh, 24
 je cls_fs_down

 cls_not_fs_down:

 mov al, ch
 inc al
 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1579+1 bios.asm
 mov al, dh
 inc al
 call puts_decimal_al

 cls_fs_down:

 mov al, 'r'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1587+1 bios.asm

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1590+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1592+1 bios.asm

 cmp bl, 1
 jne cls_fs_down_multiline

 mov al, 'D'
 jmp cs_fs_down_ml_out

 cls_fs_down_multiline:

 mov al, bl
 call puts_decimal_al
 mov al, 'T'

 cs_fs_down_ml_out:

%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1608+1 bios.asm




 pop bx
 pop ax

 push ax
 push bx
 push dx
 push es

 mov ax, 0x40
 mov es, ax

 mov ah, 2
 mov bh, 0
 mov dh, [es:curpos_y-bios_data]
 mov dl, [es:curpos_x-bios_data]
 int 10h

 pop es
 pop dx
 pop bx
 pop ax

int10_scroll_down_vmem_update:



 push ax
 push bx

 push ds
 push es
 push cx
 push dx
 push si
 push di

 mov byte [cs:vram_dirty], 1

 push bx

 mov bx, 0xb800
 mov es, bx
 mov ds, bx

 pop bx
 mov bl, al

 cls_vmem_scroll_down_next_line:

 cmp bl, 0
 je cls_vmem_scroll_down_done

 cls_vmem_scroll_down_one:

 push bx
 push dx

 mov ax, 0
 mov al, dh
 mov bx, 80
 mul bx
 add al, cl
 adc ah, 0
 mov bx, 2
 mul bx

 pop dx
 pop bx

 mov di, ax
 mov si, ax
 sub si, 2*80

 mov ax, 0
 add al, dl
 adc ah, 0
 inc ax
 sub al, cl
 sbb ah, 0

 cmp ch, dh
 jae cls_vmem_scroll_down_one_done

 push cx
 mov cx, ax
 rep movsw
 pop cx

 dec dh
 jmp cls_vmem_scroll_down_one

 cls_vmem_scroll_down_one_done:

 push cx
 mov cx, ax
 mov ah, bh
 mov al, 0
 rep stosw
 pop cx

 dec bl
 jmp cls_vmem_scroll_down_next_line

 cls_vmem_scroll_down_done:

 pop di
 pop si
 pop dx
 pop cx
 pop es
 pop ds










 pop bx
 pop ax
 iret

 int10_charatcur:






 push ds
 push es
 push bx
 push dx

 mov bx, 0x40
 mov es, bx

 mov bx, 0xc000
 mov ds, bx

 mov bx, 160
 mov ax, 0
 mov al, [es:curpos_y-bios_data]
 mul bx

 mov bx, 0
 mov bl, [es:curpos_x-bios_data]
 add ax, bx
 add ax, bx
 mov bx, ax

 mov ah, 7
 mov al, [bx]

 pop dx
 pop bx
 pop es
 pop ds

 iret

 i10_unsup:

 iret

 int10_write_char:





 push ds
 push es
 push cx
 push dx
 push ax
 push bp
 push bx

 push ax

 mov cl, al
 mov ch, 7

 mov bx, 0x40
 mov es, bx

 mov bx, 0xc000
 mov ds, bx

 mov bx, 160
 mov ax, 0
 mov al, [es:curpos_y-bios_data]
 mul bx

 mov bx, 0
 mov bl, [es:curpos_x-bios_data]
 shl bx, 1
 add bx, ax

 mov [bx], cx

 pop ax
 push ax

%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1821+1 bios.asm

 jmp int10_write_char_skip_lines

 int10_write_char_attrib:





 push ds
 push es
 push cx
 push dx
 push ax
 push bp
 push bx

 push ax
 push cx

 mov cl, al
 mov ch, bl

 mov bx, 0x40
 mov es, bx

 mov bx, 0xc000
 mov ds, bx

 mov bx, 160
 mov ax, 0
 mov al, [es:curpos_y-bios_data]
 mul bx

 mov bx, 0
 mov bl, [es:curpos_x-bios_data]
 shl bx, 1
 add bx, ax

 mov [bx], cx

 mov bl, ch

 mov bh, bl
 and bl, 7

 mov bp, bx
 and bp, 0xff
 mov bl, byte [cs:bp+colour_table]

 and bh, 8
[cpu 186]
 shr bh, 3
[cpu 8086]

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1878+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1880+1 bios.asm
 mov al, bh
 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1884+1 bios.asm
 mov al, bl
 call puts_decimal_al

 mov bl, ch

 mov bh, bl
[cpu 186]
 shr bl, 4
[cpu 8086]
 and bl, 7

 mov bp, bx
 and bp, 0xff
 mov bl, byte [cs:bp+colour_table]

 add bl, 10



 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1905+1 bios.asm
 mov al, bl
 call puts_decimal_al
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1909+1 bios.asm

 pop cx
 pop ax
 push ax

 out_another_char:

%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1917+1 bios.asm
 dec cx
 cmp cx, 0
 jne out_another_char

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1923+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1925+1 bios.asm
 mov al, '0'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1927+1 bios.asm
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 1929+1 bios.asm

 int10_write_char_skip_lines:

 pop ax

 push es
 pop ds

 cmp al, 0x08
 jne int10_write_char_attrib_inc_x

 dec byte [curpos_x-bios_data]
 dec byte [crt_curpos_x-bios_data]
 cmp byte [curpos_x-bios_data], 0
 jg int10_write_char_attrib_done

 mov byte [curpos_x-bios_data], 0
 mov byte [crt_curpos_x-bios_data], 0
 jmp int10_write_char_attrib_done

 int10_write_char_attrib_inc_x:

 cmp al, 0x0A
 je int10_write_char_attrib_newline

 cmp al, 0x0D
 jne int10_write_char_attrib_not_cr

 mov byte [curpos_x-bios_data], 0
 mov byte [crt_curpos_x-bios_data], 0
 jmp int10_write_char_attrib_done

 int10_write_char_attrib_not_cr:

 inc byte [curpos_x-bios_data]
 inc byte [crt_curpos_x-bios_data]
 cmp byte [curpos_x-bios_data], 80
 jge int10_write_char_attrib_newline
 jmp int10_write_char_attrib_done

 int10_write_char_attrib_newline:

 mov byte [curpos_x-bios_data], 0
 mov byte [crt_curpos_x-bios_data], 0
 inc byte [curpos_y-bios_data]
 inc byte [crt_curpos_y-bios_data]

 cmp byte [curpos_y-bios_data], 25
 jb int10_write_char_attrib_done
 mov byte [curpos_y-bios_data], 24
 mov byte [crt_curpos_y-bios_data], 24

 mov bh, 7
 mov al, 1
 mov cx, 0
 mov dx, 0x184f

 pushf
 push cs
 call int10_scroll_up_vmem_update

 int10_write_char_attrib_done:

 pop bx
 pop bp
 pop ax
 pop dx
 pop cx
 pop es
 pop ds

 iret

 int10_get_vm:

 push es

 mov ax, 0x40
 mov es, ax

 mov ah, 80
 mov al, [es:vidmode-bios_data]
 mov bh, 0

 pop es

 iret

 int10_features:









int11:
 mov ax, [cs:equip]
 iret



int12:
 mov ax, 0x280
 iret



int13:
 cmp ah, 0x00
 je int13_reset_disk
 cmp ah, 0x01
 je int13_last_status

 cmp dl, 0x80
 jne i13_diskok


 cmp word [cs:num_disks], 2
 jge i13_diskok


 mov ah, 15
 jmp reach_stack_stc

 i13_diskok:

 cmp ah, 0x02
 je int13_read_disk
 cmp ah, 0x03
 je int13_write_disk
 cmp ah, 0x04
 je int13_verify
 cmp ah, 0x05
 je int13_format
 cmp ah, 0x08
 je int13_getparams
 cmp ah, 0x0c
 je int13_seek
 cmp ah, 0x10
 je int13_hdready
 cmp ah, 0x15
 je int13_getdisktype
 cmp ah, 0x16
 je int13_diskchange

 mov ah, 1
 jmp reach_stack_stc

 iret

 int13_reset_disk:

 jmp reach_stack_clc

 int13_last_status:

 mov ah, [cs:disk_laststatus]
 je ls_no_error

 stc
 iret

 ls_no_error:

 clc
 iret

 int13_read_disk:

 push dx

 cmp dl, 0
 je i_flop_rd
 cmp dl, 0x80
 je i_hd_rd

 pop dx
 mov ah, 1
 jmp reach_stack_stc

 i_flop_rd:

 push si
 push bp

 cmp cl, [cs:int1e_spt]
 ja rd_error

 pop bp
 pop si

 mov dl, 1
 jmp i_rd

 i_hd_rd:

 mov dl, 0

 i_rd:

 push si
 push bp



 call chs_to_abs



 mov ah, 0
[cpu 186]
 shl ax, 9
%line 23+1 bios.asm
 db 0x0f, 0x02
%line 2145+1 bios.asm
 shr ax, 9
[cpu 8086]
 mov ah, 0x02

 cmp al, 0
 je rd_error




 cmp dx, 1
 jne rd_noerror
 cmp cx, 1
 jne rd_noerror

 push ax

 mov al, [es:bx+24]



 cmp al, 9
 je rd_update_spt
 cmp al, 18
 je rd_update_spt

 pop ax

 jmp rd_noerror

 rd_update_spt:

 mov [cs:int1e_spt], al
 pop ax

 rd_noerror:

 clc
 mov ah, 0
 jmp rd_finish

 rd_error:

 stc
 mov ah, 4

 rd_finish:

 pop bp
 pop si
 pop dx

 mov [cs:disk_laststatus], ah
 jmp reach_stack_carry

 int13_write_disk:

 push dx

 cmp dl, 0
 je i_flop_wr
 cmp dl, 0x80
 je i_hd_wr

 pop dx
 mov ah, 1
 jmp reach_stack_stc

 i_flop_wr:

 mov dl, 1
 jmp i_wr

 i_hd_wr:

 mov dl, 0

 i_wr:

 push si
 push bp
 push cx
 push di



 call chs_to_abs



 cmp dl, 0
 jne wr_fine





 mov cx, bp
 mov di, si

 mov ah, 0
 add cx, ax
 adc di, 0

 cmp di, [cs:hd_secs_hi]
 ja wr_error
 jb wr_fine
 cmp cx, [cs:hd_secs_lo]
 ja wr_error

wr_fine:

 mov ah, 0
[cpu 186]
 shl ax, 9
%line 27+1 bios.asm
 db 0x0f, 0x03
%line 2261+1 bios.asm
 shr ax, 9
[cpu 8086]
 mov ah, 0x03

 cmp al, 0
 je wr_error

 clc
 mov ah, 0
 jmp wr_finish

 wr_error:

 stc
 mov ah, 4

 wr_finish:

 pop di
 pop cx
 pop bp
 pop si
 pop dx

 mov [cs:disk_laststatus], ah
 jmp reach_stack_carry

 int13_verify:

 mov ah, 0
 jmp reach_stack_clc

 int13_getparams:

 cmp dl, 0
 je i_gp_fl
 cmp dl, 0x80
 je i_gp_hd

 mov ah, 0x01
 mov [cs:disk_laststatus], ah
 jmp reach_stack_stc

 i_gp_fl:

 push cs
 pop es
 mov di, int1e

 mov ax, 0
 mov bx, 4
 mov ch, 0x4f
 mov cl, [cs:int1e_spt]
 mov dx, 0x0101

 mov byte [cs:disk_laststatus], 0
 jmp reach_stack_clc

 i_gp_hd:

 mov ax, 0
 mov bx, 0
 mov dl, 1
 mov dh, [cs:hd_max_head]
 mov cx, [cs:hd_max_track]
 ror ch, 1
 ror ch, 1
 add ch, [cs:hd_max_sector]
 xchg ch, cl

 mov byte [cs:disk_laststatus], 0
 jmp reach_stack_clc

 int13_seek:

 mov ah, 0
 jmp reach_stack_clc

 int13_hdready:

 cmp byte [cs:num_disks], 2
 jne int13_hdready_nohd
 cmp dl, 0x80
 jne int13_hdready_nohd

 mov ah, 0
 jmp reach_stack_clc

 int13_hdready_nohd:

 jmp reach_stack_stc

 int13_format:

 mov ah, 0
 jmp reach_stack_clc

 int13_getdisktype:

 cmp dl, 0
 je gdt_flop
 cmp dl, 0x80
 je gdt_hd

 mov ah, 15
 mov [cs:disk_laststatus], ah
 jmp reach_stack_stc

 gdt_flop:

 mov ah, 1
 jmp reach_stack_clc

 gdt_hd:

 mov ah, 3
 mov cx, [cs:hd_secs_hi]
 mov dx, [cs:hd_secs_lo]
 jmp reach_stack_clc

 int13_diskchange:

 mov ah, 0
 jmp reach_stack_clc



int14:
 cmp ah, 0
 je int14_init

 jmp reach_stack_stc

 int14_init:

 mov ax, 0
 jmp reach_stack_stc



int15:













 mov ah, 0x86

 jmp reach_stack_stc




























int16:
 cmp ah, 0x00
 je kb_getkey
 cmp ah, 0x01
 je kb_checkkey
 cmp ah, 0x02
 je kb_shiftflags
 cmp ah, 0x12
 je kb_extshiftflags

 iret

 kb_getkey:

 push es
 push bx
 push cx
 push dx

 mov bx, 0x40
 mov es, bx

 kb_gkblock:

 cli

 mov cx, [es:kbbuf_tail-bios_data]
 mov bx, [es:kbbuf_head-bios_data]
 mov dx, [es:bx]

 sti


 cmp cx, bx
 je kb_gkblock

 add word [es:kbbuf_head-bios_data], 2
 call kb_adjust_buf

 mov ah, dh
 mov al, dl

 pop dx
 pop cx
 pop bx
 pop es

 iret

 kb_checkkey:

 push es
 push bx
 push cx
 push dx

 mov bx, 0x40
 mov es, bx

 mov cx, [es:kbbuf_tail-bios_data]
 mov bx, [es:kbbuf_head-bios_data]
 mov dx, [es:bx]

 sti


 cmp cx, bx

 mov ah, dh
 mov al, dl

 pop dx
 pop cx
 pop bx
 pop es

 retf 2

 kb_shiftflags:

 push es
 push bx

 mov bx, 0x40
 mov es, bx

 mov al, [es:keyflags1-bios_data]

 pop bx
 pop es

 iret

 kb_extshiftflags:

 push es
 push bx

 mov bx, 0x40
 mov es, bx

 mov al, [es:keyflags1-bios_data]
 mov ah, al

 pop bx
 pop es

 iret



int17:
 cmp ah, 0x01
 je int17_initprint

 jmp reach_stack_stc

 int17_initprint:

 mov ah, 1
 jmp reach_stack_stc



int19:
 jmp boot



int1a:
 cmp ah, 0
 je int1a_getsystime
 cmp ah, 2
 je int1a_gettime
 cmp ah, 4
 je int1a_getdate
 cmp ah, 0x0f
 je int1a_init

 iret

 int1a_getsystime:

 push ax
 push bx
 push ds
 push es

 push cs
 push cs
 pop ds
 pop es

 mov bx, timetable

%line 19+1 bios.asm
 db 0x0f, 0x01
%line 2602+1 bios.asm

 mov ax, 182
 mul word [tm_msec]
 mov bx, 10000
 div bx
 mov [tm_msec], ax

 mov ax, 182
 mul word [tm_sec]
 mov bx, 10
 mov dx, 0
 div bx
 mov [tm_sec], ax

 mov ax, 1092
 mul word [tm_min]
 mov [tm_min], ax

 mov ax, 65520
 mul word [tm_hour]

 add ax, [tm_msec]
 adc dx, 0
 add ax, [tm_sec]
 adc dx, 0
 add ax, [tm_min]
 adc dx, 0

 push dx
 push ax
 pop dx
 pop cx

 pop es
 pop ds
 pop bx
 pop ax

 mov al, 0
 iret

 int1a_gettime:




 push ds
 push es
 push ax
 push bx

 push cs
 push cs
 pop ds
 pop es

 mov bx, timetable

%line 19+1 bios.asm
 db 0x0f, 0x01
%line 2661+1 bios.asm

 mov ax, 0
 mov cx, [tm_hour]
 call hex_to_bcd
 mov bh, al

 mov ax, 0
 mov cx, [tm_min]
 call hex_to_bcd
 mov bl, al

 mov ax, 0
 mov cx, [tm_sec]
 call hex_to_bcd
 mov dh, al

 mov dl, 0

 mov cx, bx

 pop bx
 pop ax
 pop es
 pop ds

 jmp reach_stack_clc

 int1a_getdate:



 push ds
 push es
 push bx
 push ax

 push cs
 push cs
 pop ds
 pop es

 mov bx, timetable

%line 19+1 bios.asm
 db 0x0f, 0x01
%line 2705+1 bios.asm

 mov ax, 0x1900
 mov cx, [tm_year]
 call hex_to_bcd
 mov cx, ax
 push cx

 mov ax, 1
 mov cx, [tm_mon]
 call hex_to_bcd
 mov dh, al

 mov ax, 0
 mov cx, [tm_mday]
 call hex_to_bcd
 mov dl, al

 pop cx
 pop ax
 pop bx
 pop es
 pop ds

 jmp reach_stack_clc

 int1a_init:

 jmp reach_stack_clc



int1c:

 iret



int1e:

 db 0xdf
 db 0x02
 db 0x25
 db 0x02
int1e_spt db 18
 db 0x1B
 db 0xFF
 db 0x54
 db 0xF6
 db 0x0F
 db 0x08



int41:

int41_max_cyls dw 0
int41_max_heads db 0
 dw 0
 dw 0
 db 0
 db 11000000b
 db 0
 db 0
 db 0
 dw 0
int41_max_sect db 0
 db 0



rom_config dw 16
 db 0xfe
 db 'A'
 db 'C'
 db 0b00100000
 db 0b00000000
 db 0b00000000
 db 0b00000000
 db 0b00000000
 db 0, 0, 0, 0, 0, 0



num_disks dw 0
hd_secs_hi dw 0
hd_secs_lo dw 0
hd_max_sector dw 0
hd_max_track dw 0
hd_max_head dw 0
drive_tracks_temp dw 0
drive_sectors_temp dw 0
drive_heads_temp dw 0
drive_num_temp dw 0
boot_state db 0
cga_refresh_reg db 0



int0:
int1:
int2:
int3:
int4:
int5:
int6:
intb:
intc:
intd:
inte:
intf:
int18:
int1b:
int1d:

iret





hex_to_bcd:

 push bx

 jcxz h2bfin

 h2bloop:

 inc ax


 mov bh, al
 and bh, 0x0f
 cmp bh, 0x0a
 jne c1
 add ax, 0x0006


 c1:
 mov bh, al
 and bh, 0xf0
 cmp bh, 0xa0
 jne c2
 add ax, 0x0060


 c2:
 mov bh, ah
 and bh, 0x0f
 cmp bh, 0x0a
 jne c3
 add ax, 0x0600

 c3:
 loop h2bloop
 h2bfin:
 pop bx
 ret



puts_decimal_al:

 push ax

 aam
 add ax, 0x3030

 cmp ah, 0x30
 je pda_2nd

 xchg ah, al
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 2878+1 bios.asm
 xchg ah, al

 pda_2nd:

%line 15+1 bios.asm
 db 0x0f, 0x00
%line 2883+1 bios.asm

 pop ax
 ret




kb_adjust_buf:

 push ax
 push bx




 mov ax, [es:kbbuf_end_ptr-bios_data]
 cmp [es:kbbuf_head-bios_data], ax
 jnge kb_adjust_tail

 mov bx, [es:kbbuf_start_ptr-bios_data]
 mov [es:kbbuf_head-bios_data], bx

 kb_adjust_tail:




 mov ax, [es:kbbuf_end_ptr-bios_data]
 cmp [es:kbbuf_tail-bios_data], ax
 jnge kb_adjust_done

 mov bx, [es:kbbuf_start_ptr-bios_data]
 mov [es:kbbuf_tail-bios_data], bx

 kb_adjust_done:

 pop bx
 pop ax
 ret






chs_to_abs:

 push ax
 push bx
 push cx
 push dx

 mov [cs:drive_num_temp], dl



 push cx
 mov bh, cl
 mov cl, 6
 shr bh, cl
 mov bl, ch



 cmp byte [cs:drive_num_temp], 1

 push dx

 mov dx, 0
 xchg ax, bx

 jne chs_hd

 shl ax, 1
 push ax
 xor ax, ax
 mov al, [cs:int1e_spt]
 mov [cs:drive_sectors_temp], ax
 pop ax

 jmp chs_continue

chs_hd:

 mov bp, [cs:hd_max_head]
 inc bp
 mov [cs:drive_heads_temp], bp

 mul word [cs:drive_heads_temp]

 mov bp, [cs:hd_max_sector]
 mov [cs:drive_sectors_temp], bp

chs_continue:

 xchg ax, bx

 pop dx

 xchg dh, dl
 mov dh, 0
 add bx, dx

 mov ax, [cs:drive_sectors_temp]
 mul bx



 pop cx
 mov ch, 0
 and cl, 0x3F
 dec cl

 add ax, cx
 adc dx, 0
 mov bp, ax
 mov si, dx



 pop dx
 pop cx
 pop bx
 pop ax
 ret



clear_screen:

 push ax

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3017+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3019+1 bios.asm
 mov al, 'r'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3021+1 bios.asm

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3024+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3026+1 bios.asm
 mov al, '0'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3028+1 bios.asm
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3030+1 bios.asm

 push bx
 push cx
 push bp
 push ax
 push es

 mov bp, bx
 mov cl, 12
 ror bp, cl
 and bp, 7
 mov bl, byte [cs:bp+colour_table]
 add bl, 10

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3046+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3048+1 bios.asm
 mov al, bl
 call puts_decimal_al
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3052+1 bios.asm

 mov ax, 0x40
 mov es, ax
 mov byte [es:curpos_x-bios_data], 0
 mov byte [es:crt_curpos_x-bios_data], 0
 mov byte [es:curpos_y-bios_data], 0
 mov byte [es:crt_curpos_y-bios_data], 0

 pop es
 pop ax
 pop bp
 pop cx
 pop bx

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3068+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3070+1 bios.asm
 mov al, '2'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3072+1 bios.asm
 mov al, 'J'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3074+1 bios.asm

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3077+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3079+1 bios.asm
 mov al, '1'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3081+1 bios.asm
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3083+1 bios.asm
 mov al, '1'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3085+1 bios.asm
 mov al, 'H'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3087+1 bios.asm

 push es
 push di
 push cx

 cld
 mov ax, 0xb800
 mov es, ax
 mov di, 0
 mov al, 0
 mov ah, bh
 mov cx, 80*25
 rep stosw

 cld
 mov di, 0xc800
 mov es, di
 mov di, 0
 mov cx, 80*25
 rep stosw

 cld
 mov di, 0xc000
 mov es, di
 mov di, 0
 mov cx, 80*25
 rep stosw

 pop cx
 pop di
 pop es

 pop ax

 mov byte [cs:vram_dirty], 1

 ret




keypress_release:

 push ax

 cmp byte [es:key_now_down-bios_data], 0
 je kpr_no_prev_release

 mov al, [es:key_now_down-bios_data]
 add al, 0x80
 call io_key_available

 pop ax
 push ax

 kpr_no_prev_release:

 mov [es:key_now_down-bios_data], al
 call io_key_available

 pop ax

 ret



io_key_available:

 push ax
 mov al, 1
 out 0x64, al
 pop ax

 out 0x60, al
 int 9
 ret



reach_stack_stc:

 xchg bp, sp
 or word [bp+4], 1
 xchg bp, sp
 iret



reach_stack_clc:

 xchg bp, sp
 and word [bp+4], 0xfffe
 xchg bp, sp
 iret




reach_stack_carry:

 jc reach_stack_stc
 jmp reach_stack_clc









vmem_driver_entry:

 cmp byte [cs:in_update], 1
 je just_finish

 inc byte [cs:int8_ctr]
 cmp byte [cs:int8_ctr], 8
 jne just_finish

gmode_test:

 mov byte [cs:int8_ctr], 0
 mov dx, 0x3b8
 in al, dx
 test al, 2
 jz vram_zero_check

just_finish:

 ret

vram_zero_check:

 mov byte [cs:in_update], 1

 sti

 mov bx, 0x40
 mov ds, bx

 mov di, [vmem_offset-bios_data]
 shl di, 1
 push di

 mov bx, 0xb800
 mov es, bx
 mov cx, 0x7d0
 mov ax, 0x0700

 cld
 repz scasw
 pop di
 je vmem_done

 cmp byte [cs:vram_dirty], 1
 je vram_update

 mov bx, 0xc800
 mov ds, bx
 mov si, 0
 mov cx, 0x7d0

 cld
 repz cmpsw
 jne vram_update

 mov bx, 0x40
 mov ds, bx
 mov bh, [crt_curpos_y-bios_data]
 mov bl, [crt_curpos_x-bios_data]

 cmp bh, [cs:crt_curpos_y_last]
 jne restore_cursor
 cmp bl, [cs:crt_curpos_x_last]
 jne restore_cursor

 jmp vmem_done

vram_update:

 mov bx, 0x40
 mov es, bx

 push cs
 pop ds

 mov byte [int_curpos_x], 0xff
 mov byte [int_curpos_y], 0xff

 cmp byte [es:cursor_visible-bios_data], 0
 je dont_hide_cursor

 call ansi_hide_cursor

dont_hide_cursor:

 mov byte [last_attrib], 0xff

 mov bx, 0x40
 mov es, bx

 mov di, [es:vmem_offset-bios_data]
 shl di, 1
 sub di, 2

 mov bx, 0xb800
 mov es, bx




 mov bp, -1
 mov si, 79

disp_loop:



 add di, 2
 inc si
 cmp si, 80
 jne cont



loop_next_line:

 mov si, 0
 inc bp



 cmp bp, 25
 je restore_attrib



 cmp byte [cs:vram_dirty], 1
 je cont

 push si
 push di

 mov bx, 0xb800
 mov ds, bx
 mov bx, 0xc800
 mov es, bx
 mov si, di

 push es
 mov bx, 0x40
 mov es, bx
 sub di, [es:vmem_offset-bios_data]
 sub di, [es:vmem_offset-bios_data]
 pop es

 mov cx, 80

 cld
 repz cmpsw
 pop di
 pop si

 je vmem_next_line

vmem_copy_buf:



 push cx
 push si
 push di

 push es
 mov bx, 0x40
 mov es, bx
 mov si, di
 sub di, [es:vmem_offset-bios_data]
 sub di, [es:vmem_offset-bios_data]
 pop es

 mov cx, 80
 cld
 rep movsw

 pop di
 pop si
 pop cx



 mov bx, 79
 sub bx, cx

 add di, bx
 add di, bx
 add si, bx

 push ds
 pop es

 jmp cont

vmem_next_line:

 add di, 160
 jmp loop_next_line

cont:
 push cs
 pop ds

 cmp byte [es:di], 0
 je disp_loop

 mov ax, bp
 mov bx, si
 mov dh, al
 mov dl, bl

 cmp dh, [int_curpos_y]
 jne ansi_set_cur_pos
 push dx
 dec dl
 cmp dl, [int_curpos_x]
 pop dx
 je skip_set_cur_pos

ansi_set_cur_pos:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3420+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3422+1 bios.asm
 mov al, dh
 inc al
 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3427+1 bios.asm
 mov al, dl
 inc al
 call puts_decimal_al
 mov al, 'H'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3432+1 bios.asm

 mov [int_curpos_y], dh

skip_set_cur_pos:

 mov [int_curpos_x], dl

 mov dl, [es:di+1]
 cmp dl, [last_attrib]
 je skip_attrib

 mov [last_attrib], dl

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3447+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3449+1 bios.asm

 mov al, dl
 and al, 8
[cpu 186]
 shr al, 3
[cpu 8086]

 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3459+1 bios.asm

 push dx

 and dl, 7
 mov bx, colour_table
 mov al, dl
 xlat

 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3470+1 bios.asm

 pop dx

[cpu 186]
 shr dl, 4
[cpu 8086]
 and dl, 7

 mov al, dl
 xlat

 add al, 10
 call puts_decimal_al
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3485+1 bios.asm

skip_attrib:

 mov al, [es:di]

 cmp al, 32
 jae just_show_it

 mov bx, low_ascii_conv
 cs xlat

just_show_it:

%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3499+1 bios.asm

 jmp disp_loop

restore_attrib:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3506+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3508+1 bios.asm
 mov al, '0'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3510+1 bios.asm
 mov al, 'm'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3512+1 bios.asm

restore_cursor:





 mov bx, 0x40
 mov ds, bx

 mov bh, [crt_curpos_y-bios_data]
 mov bl, [crt_curpos_x-bios_data]
 mov [cs:crt_curpos_y_last], bh
 mov [cs:crt_curpos_x_last], bl

 cmp bh, 24
 ja vmem_end_hidden_cursor
 cmp bl, 79
 ja vmem_end_hidden_cursor

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3534+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3536+1 bios.asm
 mov al, bh
 inc al
 call puts_decimal_al
 mov al, ';'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3541+1 bios.asm
 mov al, bl
 inc al
 call puts_decimal_al
 mov al, 'H'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3546+1 bios.asm

restore_cursor_visible:

 cmp byte [cursor_visible-bios_data], 1
 jne vmem_end_hidden_cursor

 call ansi_show_cursor
 jmp vmem_done

vmem_end_hidden_cursor:

 call ansi_hide_cursor

vmem_done:

 mov byte [cs:vram_dirty], 0
 mov byte [cs:in_update], 0
 ret



ansi_show_cursor:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3571+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3573+1 bios.asm
 mov al, '?'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3575+1 bios.asm
 mov al, '2'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3577+1 bios.asm
 mov al, '5'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3579+1 bios.asm
 mov al, 'h'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3581+1 bios.asm

 ret



ansi_hide_cursor:

 mov al, 0x1B
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3590+1 bios.asm
 mov al, '['
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3592+1 bios.asm
 mov al, '?'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3594+1 bios.asm
 mov al, '2'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3596+1 bios.asm
 mov al, '5'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3598+1 bios.asm
 mov al, 'l'
%line 15+1 bios.asm
 db 0x0f, 0x00
%line 3600+1 bios.asm

 ret







bios_data:

com1addr dw 0
com2addr dw 0
com3addr dw 0
com4addr dw 0
lpt1addr dw 0
lpt2addr dw 0
lpt3addr dw 0
lpt4addr dw 0
equip dw 0b0000000000100001

 db 0
memsize dw 0x280
 db 0
 db 0
keyflags1 db 0
keyflags2 db 0
 db 0
kbbuf_head dw kbbuf-bios_data
kbbuf_tail dw kbbuf-bios_data
kbbuf: times 32 db 'X'
drivecal db 0
diskmotor db 0
motorshutoff db 0x07
disk_laststatus db 0
times 7 db 0
vidmode db 0x03
vid_cols dw 80
page_size dw 0x1000
 dw 0
curpos_x db 0
curpos_y db 0
times 7 dw 0
cur_v_end db 7
cur_v_start db 6
disp_page db 0
crtport dw 0x3d4
 db 10
 db 0
times 5 db 0
clk_dtimer dd 0
clk_rollover db 0
ctrl_break db 0
soft_rst_flg dw 0x1234
 db 0
num_hd db 0
 db 0
 db 0
 dd 0
 dd 0
kbbuf_start_ptr dw 0x001e
kbbuf_end_ptr dw 0x003e
vid_rows db 25
 db 0
 db 0
vidmode_opt db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
 db 0
kb_mode db 0
kb_led db 0
 db 0
 db 0
 db 0
 db 0
boot_device db 0
crt_curpos_x db 0
crt_curpos_y db 0
key_now_down db 0
next_key_fn db 0
cursor_visible db 1
escape_flag_last db 0
next_key_alt db 0
escape_flag db 0
notranslate_flg db 0
this_keystroke db 0
this_keystroke_ext db 0
timer0_freq dw 0xffff
timer2_freq dw 0
cga_vmode db 0
vmem_offset dw 0
ending: times (0xff-($-com1addr)) db 0



a2scan_tbl db 0xFF, 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x0E, 0x0F, 0x24, 0x25, 0x26, 0x1C, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C, 0x01, 0x00, 0x00, 0x00, 0x00, 0x39, 0x02, 0x28, 0x04, 0x05, 0x06, 0x08, 0x28, 0x0A, 0x0B, 0x09, 0x0D, 0x33, 0x0C, 0x34, 0x35, 0x0B, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x27, 0x27, 0x33, 0x0D, 0x34, 0x35, 0x03, 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26, 0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C, 0x1A, 0x2B, 0x1B, 0x07, 0x0C, 0x29, 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26, 0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C, 0x1A, 0x2B, 0x1B, 0x29, 0x0E
a2shift_tbl db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0



int_table dw int0
 dw 0xf000
 dw int1
 dw 0xf000
 dw int2
 dw 0xf000
 dw int3
 dw 0xf000
 dw int4
 dw 0xf000
 dw int5
 dw 0xf000
 dw int6
 dw 0xf000
 dw int7
 dw 0xf000
 dw int8
 dw 0xf000
 dw int9
 dw 0xf000
 dw inta
 dw 0xf000
 dw intb
 dw 0xf000
 dw intc
 dw 0xf000
 dw intd
 dw 0xf000
 dw inte
 dw 0xf000
 dw intf
 dw 0xf000
 dw int10
 dw 0xf000
 dw int11
 dw 0xf000
 dw int12
 dw 0xf000
 dw int13
 dw 0xf000
 dw int14
 dw 0xf000
 dw int15
 dw 0xf000
 dw int16
 dw 0xf000
 dw int17
 dw 0xf000
 dw int18
 dw 0xf000
 dw int19
 dw 0xf000
 dw int1a
 dw 0xf000
 dw int1b
 dw 0xf000
 dw int1c
 dw 0xf000
 dw int1d
 dw 0xf000
 dw int1e

itbl_size dw $-int_table



colour_table db 30, 34, 32, 36, 31, 35, 33, 37



low_ascii_conv db ' ', 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, '><|!|$', 250, '|^v><--^v'



unix_cursor_xlt db 0x48, 0x50, 0x4d, 0x4b



pgup_pgdn_xlt db 0x47, 0x4f, 0x49, 0x51



int8_ctr db 0
in_update db 0
vram_dirty db 0
last_attrib db 0
int_curpos_x db 0
int_curpos_y db 0
crt_curpos_x_last db 0
crt_curpos_y_last db 0



last_int8_msec dw 0
last_key_sdl db 0





rm_mode0_reg1 db 3, 3, 5, 5, 6, 7, 12, 3
rm_mode012_reg2 db 6, 7, 6, 7, 12, 12, 12, 12
rm_mode0_disp db 0, 0, 0, 0, 0, 0, 1, 0
rm_mode0_dfseg db 11, 11, 10, 10, 11, 11, 11, 11

rm_mode12_reg1 db 3, 3, 5, 5, 6, 7, 5, 3
rm_mode12_disp db 1, 1, 1, 1, 1, 1, 1, 1
rm_mode12_dfseg db 11, 11, 10, 10, 11, 11, 10, 11



xlat_ids db 9, 9, 9, 9, 7, 7, 25, 26, 9, 9, 9, 9, 7, 7, 25, 48, 9, 9, 9, 9, 7, 7, 25, 26, 9, 9, 9, 9, 7, 7, 25, 26, 9, 9, 9, 9, 7, 7, 27, 28, 9, 9, 9, 9, 7, 7, 27, 28, 9, 9, 9, 9, 7, 7, 27, 29, 9, 9, 9, 9, 7, 7, 27, 29, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 51, 54, 52, 52, 52, 52, 52, 52, 55, 55, 55, 55, 52, 52, 52, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 15, 15, 24, 24, 9, 9, 9, 9, 10, 10, 10, 10, 16, 16, 16, 16, 16, 16, 16, 16, 30, 31, 32, 53, 33, 34, 35, 36, 11, 11, 11, 11, 17, 17, 18, 18, 47, 47, 17, 17, 17, 17, 18, 18, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 12, 12, 19, 19, 37, 37, 20, 20, 49, 50, 19, 19, 38, 39, 40, 19, 12, 12, 12, 12, 41, 42, 43, 44, 53, 53, 53, 53, 53, 53, 53, 53, 13, 13, 13, 13, 21, 21, 22, 22, 14, 14, 14, 14, 21, 21, 22, 22, 53, 0, 23, 23, 53, 45, 6, 6, 46, 46, 46, 46, 46, 46, 5, 5
ex_data db 0, 0, 0, 0, 0, 0, 8, 8, 1, 1, 1, 1, 1, 1, 9, 36, 2, 2, 2, 2, 2, 2, 10, 10, 3, 3, 3, 3, 3, 3, 11, 11, 4, 4, 4, 4, 4, 4, 8, 0, 5, 5, 5, 5, 5, 5, 9, 1, 6, 6, 6, 6, 6, 6, 10, 2, 7, 7, 7, 7, 7, 7, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 21, 21, 21, 21, 21, 0, 0, 0, 0, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 12, 12, 12, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 16, 22, 0, 0, 0, 0, 1, 1, 0, 255, 48, 2, 0, 0, 0, 0, 255, 255, 40, 11, 3, 3, 3, 3, 3, 3, 3, 3, 43, 43, 43, 43, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 21, 0, 0, 2, 40, 21, 21, 80, 81, 92, 93, 94, 95, 0, 0
std_flags db 3, 3, 3, 3, 3, 3, 0, 0, 5, 5, 5, 5, 5, 5, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 5, 5, 5, 5, 5, 5, 0, 1, 3, 3, 3, 3, 3, 3, 0, 1, 5, 5, 5, 5, 5, 5, 0, 1, 3, 3, 3, 3, 3, 3, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
base_size db 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 0, 0, 2, 2, 2, 2, 4, 1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2
i_w_adder db 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
i_mod_adder db 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1

flags_mult db 0, 2, 4, 6, 7, 8, 9, 10, 11

jxx_dec_a db 48, 40, 43, 40, 44, 41, 49, 49
jxx_dec_b db 49, 49, 49, 43, 49, 49, 49, 43
jxx_dec_c db 49, 49, 49, 49, 49, 49, 44, 44
jxx_dec_d db 49, 49, 49, 49, 49, 49, 48, 48

parity db 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1



timetable:

tm_sec equ $
tm_min equ $+4
tm_hour equ $+8
tm_mday equ $+12
tm_mon equ $+16
tm_year equ $+20
tm_wday equ $+24
tm_yday equ $+28
tm_dst equ $+32
tm_msec equ $+36
