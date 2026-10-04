; ============================================================
; Smart City: A 2D Interactive City Simulation
; Module 3 - Traffic Signal (red/green/yellow timer, car1 obeys it)
;
; Assemble : nasm -f bin smart_city_module3.asm -o city3.com
; Run      : DOSBox  ->  mount folder, then run  city3
; Exit     : press any key while it's running
; ============================================================

org 100h

start:
    mov ax, 0013h
    int 10h

    mov ax, 0A000h
    mov es, ax

    call draw_sky
    call draw_ground
    call draw_road

    ; ---- buildings: x, y, width, height, color ----
    push word 8
    push word 60
    push word 40
    push word 80
    push word 20
    call draw_rect
    add sp, 10

    push word 7
    push word 80
    push word 50
    push word 60
    push word 90
    call draw_rect
    add sp, 10

    push word 11
    push word 50
    push word 35
    push word 90
    push word 170
    call draw_rect
    add sp, 10

    push word 12
    push word 70
    push word 45
    push word 70
    push word 230
    call draw_rect
    add sp, 10

    ; ---- traffic signal housing (static, drawn once) ----
    push word 0
    push word 45
    push word 20
    push word 110
    push word 135
    call draw_rect
    add sp, 10

main_loop:
    call check_key
    jc  exit_program

    call update_signal
    call draw_signal_lights

    ; ---- car 1 (moves right, lane y=160) - stops on red/yellow ----
    push word 8
    push word 8
    push word 16
    push word 160
    push word [car1_x]
    call draw_rect
    add sp, 10

    mov ax, [car1_x]
    add ax, 16                   ; front bumper position
    cmp ax, 130
    jb .car1_move                 ; before stop line -> always move
    cmp byte [light_state], 1
    je .car1_move                  ; green -> move
    cmp ax, 150
    ja .car1_move                   ; already past the signal -> keep going
    jmp .car1_skip

.car1_move:
    add word [car1_x], 3
    cmp word [car1_x], 320
    jb .car1_ok
    mov word [car1_x], 0
.car1_ok:
.car1_skip:

    push word 4
    push word 8
    push word 16
    push word 160
    push word [car1_x]
    call draw_rect
    add sp, 10

    ; ---- car 2 (moves left, lane y=175) - free running ----
    push word 8
    push word 8
    push word 16
    push word 175
    push word [car2_x]
    call draw_rect
    add sp, 10

    cmp word [car2_x], 3
    jae .car2_move
    mov word [car2_x], 300
    jmp .car2_ok
.car2_move:
    sub word [car2_x], 3
.car2_ok:

    push word 14
    push word 8
    push word 16
    push word 175
    push word [car2_x]
    call draw_rect
    add sp, 10

    call delay
    jmp main_loop

exit_program:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

; ---------------- draw_sky ----------------
draw_sky:
    xor di, di
    mov cx, 320*140
    mov al, 3
    rep stosb
    ret

; ---------------- draw_ground ----------------
draw_ground:
    mov di, 320*140
    mov cx, 320*60
    mov al, 2
    rep stosb
    ret

; ---------------- draw_road ----------------
draw_road:
    mov di, 320*155
    mov cx, 320*30
    mov al, 8
    rep stosb
    ret

; ---------------- update_signal: RED(60) -> GREEN(50) -> YELLOW(15) -> RED ----
update_signal:
    dec word [light_timer]
    jnz .done

    mov al, [light_state]
    cmp al, 0
    je .to_green
    cmp al, 1
    je .to_yellow

    mov byte [light_state], 0     ; yellow -> red
    mov word [light_timer], 60
    jmp .done
.to_green:
    mov byte [light_state], 1
    mov word [light_timer], 50
    jmp .done
.to_yellow:
    mov byte [light_state], 2
    mov word [light_timer], 15
.done:
    ret

; ---------------- draw_signal_lights: redraws 3 lights each frame ----------------
draw_signal_lights:
    mov ax, 8
    cmp byte [light_state], 0
    jne .red_off
    mov ax, 4
.red_off:
    push ax
    push word 9
    push word 10
    push word 115
    push word 140
    call draw_rect
    add sp, 10

    mov ax, 8
    cmp byte [light_state], 2
    jne .yellow_off
    mov ax, 14
.yellow_off:
    push ax
    push word 9
    push word 10
    push word 127
    push word 140
    call draw_rect
    add sp, 10

    mov ax, 8
    cmp byte [light_state], 1
    jne .green_off
    mov ax, 10
.green_off:
    push ax
    push word 9
    push word 10
    push word 139
    push word 140
    call draw_rect
    add sp, 10
    ret

; ---------------- check_key: sets CF=1 if a key was pressed ----------------
check_key:
    mov ah, 01h
    int 16h
    jz .no_key
    mov ah, 00h
    int 16h
    stc
    ret
.no_key:
    clc
    ret

; ---------------- delay ----------------
delay:
    push bx
    push cx
    mov bx, 15
.outer:
    mov cx, 0FFFFh
.inner:
    loop .inner
    dec bx
    jnz .outer
    pop cx
    pop bx
    ret

; ---------------- draw_rect(x, y, width, height, color) ----------------
draw_rect:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si
    push di

    mov bx, [bp+6]
    mov si, [bp+10]

.row_loop:
    cmp si, 0
    je .done

    mov ax, bx
    mov cx, 320
    mul cx
    mov di, ax
    mov ax, [bp+4]
    add di, ax

    mov cx, [bp+8]
    mov al, byte [bp+12]
    rep stosb

    inc bx
    dec si
    jmp .row_loop

.done:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; ---------------- variables ----------------
car1_x      dw 0
car2_x      dw 280
light_state db 0            ; 0=RED  1=GREEN  2=YELLOW
light_timer dw 60