
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                                                                         *
; *     Remark Infos for this Source Code  ÄÄ  AZ-Group Club                *
; *                                                                         *
; *     Author:  Le Ngoc Thanh                                              *
; *                                                                         *
; *     From:    The University of Economics - Informatics Department       *
; *                                                                         *
; *     Purpose: Ready To Run Library for IPX Programming                   *
; *                                                                         *
; *     Product: IPX.TPU                                                    *
; *                                                                         *
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Unit IPX;

{$F+}
{$A-}
{$S-}
{$W-}

Interface

Type

  byte2=array [1..2] of byte;
  byte4=array [1..4] of byte;
  byte6=array [1..6] of byte;

  Fragment_type = record
     Address:Pointer;
     Length :integer;
    end;


  IPXHeader = record
     CheckSum             :word;
     Length               :word;
     Transport_control    :byte;
     Packet_type          :byte;
     Dest_Network_number  :byte4;
     Dest_Network_node    :byte6;
     Dest_Network_socket  :byte2;
     Source_Network_number:byte4;
     Source_Network_node  :byte6;
     Source_Network_socket:byte2;
    end;

  ECB = record
     Link_address         : pointer;
     Event_svc_routine    : pointer;
     In_use               : byte;
     Completion_code      : byte;
     Socket_number        : byte2;
     Connection_ID        : word;
     Reserved_1           : word;
     Reserved_2           : array [1..12] of byte;
     Immediate_address    : byte6;
     Fragment_count       : word;
     Fragment             : array [1..2] of Fragment_type;
    end;

Var
  IPX_Addr      :pointer;
  IPX_Result    :byte;
  Network_Number:byte4;
  Node_address  :byte6;

Function  Mouse_install:boolean;
Function  IPX_Install:boolean;
Function  Inkey: byte;
procedure Getexecpath(chuoi: pointer);
Procedure IPX_Open_Socket(Socket_Number:integer);
Procedure IPX_Close_Socket(Socket_number:integer);
Procedure IPX_Send_Packet(ECB_Pointer:pointer);
Procedure IPX_Listen_Packet(ECB_Pointer:pointer);
Procedure IPX_breath;
Procedure IPX_cancel(ECB_Pointer:pointer);
Procedure IPX_get_localtarget(inbuf,outbuf: pointer );
Procedure IPX_delay(ECB_Pointer:pointer; timeout: integer);

{=========================================================}

Implementation

{-------------------------------------}

Function Mouse_Install:boolean;
  var
    Result : word;

  begin
    asm
      mov  ax,0
      int  033h
      mov  ss:Result,ax
    end;
    if Result = 0 then mouse_Install:=False
    else Mouse_Install:=True;
  end;
{-------------------------------------}

Function IPX_Install:boolean;
  Label
    IPX_Check_end;
  var
    Result:byte;

  begin
    asm
      mov  ax,07A00h
      int  02Fh
      mov  ss:Result,al
      cmp  al,0FFh
      jne  IPX_Check_end
      mov  word ptr IPX_Addr[0],di
      mov  word ptr IPX_Addr[2],es
      mov  bx,09h                   ; {IPXGetInternetworkAddress}
      push ds
      pop  es
      lea  si,Network_number        ;
      int  07Ah                     ;
    IPX_Check_end:
    end;
    if Result<> 255 then IPX_Install:=False
    else IPX_Install:=True;
  end;
{-------------------------------------}

Function Inkey: byte;
  var
    Result : word;

  begin
    asm
       mov  ah,0
       int  016h
       Jnc  @I2
    @I1:
       mov  ah, 1
       int  016h
       or   al, al
       je   @I1
       mov  ss:result, ax
    @I2:
       or   al, al
       mov  ss:Result,ax
    end;
    Inkey := Lo(Result);
  end;
{-------------------------------------}

procedure Getexecpath(chuoi: pointer);

begin
   asm
        push    es
        push    ds
        mov     ah, 062h
        int     021h
        mov     es, bx                          { PSP segment }
        mov     ax, word ptr ES:[02Ch]
        mov     es, ax
        mov     di, 0
   @m1:
        cld
        mov     cx, -1
        mov     al, 'P'
        repne   scasb

        or      cx, cx
        je      @m1
        cmp     byte ptr ES:[DI], 'A'
        jne     @m1
        cmp     byte ptr ES:[DI+1], 'T'
        jne     @m1
        cmp     byte ptr ES:[DI+2], 'H'
        jne     @m1
        cmp     byte ptr ES:[DI+3], '='
        jne     @m1

        add     di, 4                   { point to next of "path=" }

        mov     cx, 0FFh

        mov     al, 0
        repne   scasb
        mov     cx, 0FFh
        repe    scasb
        mov     cx, 0FFh
        repne   scasb
        mov     cx, 0FFh
        repe    scasb
        dec     di

        { DI: begin of exec_path }
        lds     si, chuoi
        xor     bx, bx
        xor     cx, cx
   @m2:
        mov     al, byte ptr es:[di+bx]
        inc     bx
        or      al, al
        je      @m3
        mov     byte ptr ds:[si+bx], al
        cmp     al, '\'
        jne     @m2
        mov     cx, bx
        jmp     @m2
   @m3:
        mov     byte ptr ds:[si], cl
        pop     ds
        pop     es
   end;
end;
{-------------------------------------}

Procedure IPX_Get_Address(IPX_Header:pointer);
  var
    pp:pointer;
  Begin
    Asm
      mov  si,word ptr ss:IPX_Header[0]
      mov  es,word ptr ss:IPX_Header[2]
      add  si,18
      mov  bx,9
      int  07Ah
      mov  IPX_Result,al
    end;
  end;
{-------------------------------------}

Procedure IPX_Open_Socket(Socket_Number:integer);
begin
    Asm
      mov  bx,0
      mov  al,0                  {Short lived}
      mov  dx,Socket_Number
      int  07Ah
      mov  IPX_Result,al
    end;
end;
{-------------------------------------}

Procedure IPX_Close_Socket(Socket_number:integer);
begin
    Asm
      mov  bx,1
      mov  dx,Socket_Number
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure IPX_Send_Packet(ECB_Pointer:pointer);
begin
    Asm
      mov  bx,3
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure IPX_Listen_Packet(ECB_Pointer:pointer);
begin
    Asm
      mov  bx,4
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure IPX_breath;
begin
    Asm
      mov  bx,0Ah
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure IPX_cancel(ECB_Pointer:pointer);
begin
    Asm
      mov  bx,6
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure IPX_get_localtarget(inbuf,outbuf: pointer );
begin
    Asm
      mov  bx,2
      les  si,inbuf
      les  di,outbuf
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure IPX_delay(ECB_Pointer:pointer; timeout: integer);
begin
    Asm
      mov  bx,5
      mov  ax, timeout
      les  si,ECB_Pointer
      int  07Ah
    end;
end;

end.
