; ============================================================
; Smart City: A 2D Interactive City Simulation
; Module 2 - Moving Cars (adds road + 2 animated cars)
;
; Assemble : nasm -f bin smart_city_module2.asm -o city2.com
; Run      : DOSBox  ->  mount folder, then run  city2
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

main_loop:
    call check_key
    jc  exit_program

    ; ---- car 1 (moves right, lane y=160) ----
    push word 8               ; erase with road-gray
    push word 8
    push word 16
    push word 160
    push word [car1_x]
    call draw_rect
    add sp, 10

    add word [car1_x], 3       ; speed = 3 px/frame
    cmp word [car1_x], 320
    jb  .car1_ok
    mov word [car1_x], 0
.car1_ok:

    push word 4                 ; red car
    push word 8
    push word 16
    push word 160
    push word [car1_x]
    call draw_rect
    add sp, 10

    ; ---- car 2 (moves left, lane y=175) ----
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

    push word 14                 ; yellow car
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

; ---------------- draw_sky: rows 0-139, color 3 (cyan) ----------------
draw_sky:
    xor di, di
    mov cx, 320*140
    mov al, 3
    rep stosb
    ret

; ---------------- draw_ground: rows 140-199, color 2 (green) ----------------
draw_ground:
    mov di, 320*140
    mov cx, 320*60
    mov al, 2
    rep stosb
    ret

; ---------------- draw_road: rows 155-184, color 8 (gray) ----------------
draw_road:
    mov di, 320*155
    mov cx, 320*30
    mov al, 8
    rep stosb
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

; ---------------- delay: controls animation speed ----------------
; bigger bx value = slower cars, smaller = faster
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
car1_x dw 0
car2_x dw 280