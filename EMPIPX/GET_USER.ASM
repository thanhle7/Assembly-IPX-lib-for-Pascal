        mov     ax, ds
        mov     es, ax

        mov     ah, 0DCh
        int     021h

        lea     si, goi
        mov     word ptr ds:[si], 2
        mov     byte ptr ds:[si + 2], 22
        mov     byte ptr ds:[si + 3], al

        lea     di, nhan
        mov     word ptr es:[di], 61

        mov     ah, 0E3h
        int     021h

        mov     ah, 09

        lea     dx, nhan + 8
        mov     bx, dx
T1:
        or      byte ptr ds:[bx], 0
        je      T2
        inc     bx
        jmp     T1
T2:
        mov     byte ptr ds:[bx], '$'

        int     021h

        int     020h

goi     db      4 dup(0)
nhan    db      63 dup(0)
