; ============================================================
; Smart City: A 2D Interactive City Simulation
; Module 1 - Static Scene (sky, ground, buildings)
;
; Assemble : nasm -f bin smart_city_module1.asm -o city.com
; Run      : DOSBox  ->  mount folder, then run  city.com
; ============================================================

org 100h

start:
    mov ax, 0013h          ; VGA mode 13h -> 320x200, 256 colors
    int 10h

    mov ax, 0A000h
    mov es, ax              ; ES = video memory segment (fixed for whole program)

    call draw_sky
    call draw_ground

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

    xor ah, ah
    int 16h                 ; wait for keypress

    mov ax, 0003h            ; back to text mode
    int 10h

    mov ax, 4C00h
    int 21h                   ; exit to DOS

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

; ---------------- draw_rect(x, y, width, height, color) ----------------
; stack params (word-pushed, x pushed last / closest to call):
;   [bp+4]=x  [bp+6]=y  [bp+8]=width  [bp+10]=height  [bp+12]=color
draw_rect:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si
    push di

    mov bx, [bp+6]           ; bx = current row (y)
    mov si, [bp+10]           ; si = rows remaining (height)

.row_loop:
    cmp si, 0
    je .done

    mov ax, bx
    mov cx, 320
    mul cx                     ; ax = y * 320
    mov di, ax
    mov ax, [bp+4]              ; x
    add di, ax                   ; di = y*320 + x  (offset into video memory)

    mov cx, [bp+8]                ; width
    mov al, byte [bp+12]           ; color
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