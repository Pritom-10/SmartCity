; ============================================================
; Smart City: A 2D Interactive City Simulation
; Module 5 - Weather Effect (Rain)
;
; Assemble : nasm -f bin smart_city_module5.asm -o city5.com
; Run      : DOSBox  ->  mount folder, then run  city5
; Controls : N = Day/Night, R = Rain, UP/DOWN = car speed, ESC = exit
; ============================================================

org 100h

start:
    mov ah, 4Ah              ; shrink our own memory block first, so free memory exists
    mov bx, 1000               ; keep 1000 paragraphs (16000 bytes) for our code+stack
    int 21h

    mov sp, 3E00h              ; move stack safely inside our shrunk block

    mov ax, 0013h
    int 10h

    mov ah, 48h             ; allocate back-buffer segment (off-screen drawing area)
    mov bx, 4000              ; 4000 paragraphs = 64000 bytes = 320x200
    int 21h
    jc exit_program
    mov [buffer_seg], ax
    mov es, ax                 ; es = back buffer for all drawing, from now on

main_loop:
    call check_key
    cmp al, 27
    je exit_program
    cmp al, 'n'
    je .toggle_night
    cmp al, 'N'
    je .toggle_night
    cmp al, 'r'
    je .toggle_rain
    cmp al, 'R'
    je .toggle_rain
    jmp .after_toggle
.toggle_night:
    xor byte [day_night], 1
    jmp .after_toggle
.toggle_rain:
    xor byte [rain_on], 1
.after_toggle:

    cmp ah, 72              ; up arrow -> speed up
    je .speed_up
    cmp ah, 80                ; down arrow -> speed down
    je .speed_down
    jmp .after_speed
.speed_up:
    cmp byte [car_speed], 8
    jae .after_speed
    inc byte [car_speed]
    jmp .after_speed
.speed_down:
    cmp byte [car_speed], 1
    jbe .after_speed
    dec byte [car_speed]
.after_speed:

    call redraw_environment
    call update_signal
    call draw_signal_lights

    cmp byte [rain_on], 0
    je .skip_rain
    call draw_rain
.skip_rain:

    ; ---- car 1 (moves right, lane y=160) - stops on red/yellow ----
    mov ax, [car1_x]
    add ax, 16
    cmp ax, 130
    jb .car1_move
    cmp byte [light_state], 1
    je .car1_move
    cmp ax, 150
    ja .car1_move
    jmp .car1_skip
.car1_move:
    mov al, [car_speed]
    mov ah, 0
    add word [car1_x], ax
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
    mov al, [car_speed]
    mov ah, 0
    cmp word [car2_x], ax
    jae .car2_move
    mov word [car2_x], 300
    jmp .car2_ok
.car2_move:
    sub word [car2_x], ax
.car2_ok:

    push word 14
    push word 8
    push word 16
    push word 175
    push word [car2_x]
    call draw_rect
    add sp, 10

    call blit_to_screen
    call delay
    jmp main_loop

exit_program:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

; ---------------- blit_to_screen: copies finished back buffer to the real screen ----------------
blit_to_screen:
    push ax
    push cx
    push si
    push di
    push ds
    push es

    call wait_vsync

    mov ax, [buffer_seg]
    mov ds, ax
    xor si, si

    mov ax, 0A000h
    mov es, ax
    xor di, di

    mov cx, 32000            ; 32000 words = 64000 bytes
    rep movsw

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret

; ---------------- wait_vsync: pauses until screen retrace, prevents flicker ----------------
wait_vsync:
    push ax
    push dx
    mov dx, 03DAh
.wait_end:
    in al, dx
    test al, 08h
    jnz .wait_end
.wait_start:
    in al, dx
    test al, 08h
    jz .wait_start
    pop dx
    pop ax
    ret

; ---------------- redraw_environment: sky/ground/road/buildings/signal/lamps ----------------
redraw_environment:
    mov al, 3
    cmp byte [day_night], 0
    je .sky_day
    mov al, 1
.sky_day:
    xor di, di
    mov cx, 320*140
    rep stosb

    mov di, 320*140
    mov cx, 320*60
    mov al, 2
    rep stosb

    mov di, 320*155
    mov cx, 320*30
    mov al, 8
    rep stosb

    ; sun / moon icon (circle)
    mov ax, 14
    cmp byte [day_night], 0
    je .icon_day
    mov ax, 15
.icon_day:
    push ax
    push word 10
    push word 30
    push word 290
    call draw_circle
    add sp, 8

    ; buildings
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

    ; traffic signal housing
    push word 0
    push word 45
    push word 20
    push word 110
    push word 135
    call draw_rect
    add sp, 10

    ; street lamp 1
    push word 8
    push word 25
    push word 3
    push word 130
    push word 55
    call draw_rect
    add sp, 10

    mov ax, 8
    cmp byte [day_night], 0
    je .lamp1_off
    mov ax, 14
.lamp1_off:
    push ax
    push word 8
    push word 10
    push word 125
    push word 51
    call draw_rect
    add sp, 10

    ; street lamp 2
    push word 8
    push word 25
    push word 3
    push word 130
    push word 250
    call draw_rect
    add sp, 10

    mov ax, 8
    cmp byte [day_night], 0
    je .lamp2_off
    mov ax, 14
.lamp2_off:
    push ax
    push word 8
    push word 10
    push word 125
    push word 246
    call draw_rect
    add sp, 10

    ret

; ---------------- draw_rain: 12 falling drops ----------------
draw_rain:
    push ax
    push bx
    push si

    xor si, si
.rain_loop:
    cmp si, 12
    jge .rain_done

    mov bx, si
    shl bx, 1

    push word 15
    push word 4
    push word 2
    push word [rain_y+bx]
    push word [rain_x+bx]
    call draw_rect
    add sp, 10

    add word [rain_y+bx], 6
    cmp word [rain_y+bx], 195
    jb .no_reset
    mov word [rain_y+bx], 0
.no_reset:

    inc si
    jmp .rain_loop
.rain_done:
    pop si
    pop bx
    pop ax
    ret

; ---------------- update_signal ----------------
update_signal:
    dec word [light_timer]
    jnz .done

    mov al, [light_state]
    cmp al, 0
    je .to_green
    cmp al, 1
    je .to_yellow

    mov byte [light_state], 0
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

; ---------------- draw_signal_lights ----------------
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

; ---------------- check_key: returns AL = ascii key, or 0 if none ----------------
check_key:
    mov ah, 01h
    int 16h
    jz .none
    mov ah, 00h
    int 16h
    ret
.none:
    xor al, al
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

; ---------------- draw_circle(cx, cy, radius, color) - filled circle ----------------
draw_circle:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, [bp+8]
    imul ax, ax
    mov cx, ax

    mov bx, [bp+8]
    neg bx
.dy_loop:
    cmp bx, [bp+8]
    jg .dy_done

    mov si, [bp+8]
    neg si
.dx_loop:
    cmp si, [bp+8]
    jg .dx_done

    mov ax, si
    imul ax, ax
    mov dx, ax
    mov ax, bx
    imul ax, ax
    add ax, dx
    cmp ax, cx
    jg .skip_pixel

    mov ax, [bp+6]
    add ax, bx
    mov dx, 320
    mul dx
    mov di, ax
    mov ax, [bp+4]
    add ax, si
    add di, ax
    mov al, byte [bp+10]
    mov [es:di], al

.skip_pixel:
    inc si
    jmp .dx_loop
.dx_done:
    inc bx
    jmp .dy_loop
.dy_done:

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; ---------------- variables ----------------
car_speed   db 3
buffer_seg  dw 0
car1_x      dw 0
car2_x      dw 280
light_state db 0
light_timer dw 60
day_night   db 0
rain_on     db 0
rain_x      dw 10,40,70,100,130,160,190,220,250,280,300,315
rain_y      dw 0,15,30,45,60,75,90,105,120,10,50,90