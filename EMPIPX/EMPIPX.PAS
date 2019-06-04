Unit EMPIPX;

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

Function  EMP_IPX_Install:boolean;
Procedure EMP_IPX_Open_Socket(Socket_Number:integer);
Procedure EMP_IPX_Close_Socket(Socket_number:integer);
Procedure EMP_IPX_Send_Packet(ECB_Pointer:pointer);
Procedure EMP_IPX_Listen_Packet(ECB_Pointer:pointer);
Procedure EMP_IPX_breath;
Procedure EMP_IPX_cancel(ECB_Pointer:pointer);
Procedure EMP_IPX_get_localtarget(inbuf,outbuf: pointer );
Procedure EMP_IPX_delay(ECB_Pointer:pointer; timeout: integer);
Procedure EMP_GetUserName(var s: string);

{=========================================================}

Implementation
{-------------------------------------}

Function EMP_IPX_Install:boolean;
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
    if Result<> 255 then EMP_IPX_Install:=False
    else EMP_IPX_Install:=True;
  end;
{-------------------------------------}

Procedure EMP_IPX_Get_Address(IPX_Header:pointer);
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

Procedure EMP_IPX_Open_Socket(Socket_Number:integer);
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

Procedure EMP_IPX_Close_Socket(Socket_number:integer);
begin
    Asm
      mov  bx,1
      mov  dx,Socket_Number
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_IPX_Send_Packet(ECB_Pointer:pointer);
begin
    Asm
      mov  bx,3
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_IPX_Listen_Packet(ECB_Pointer:pointer);
begin
    Asm
      mov  bx,4
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_IPX_breath;
begin
    Asm
      mov  bx,0Ah
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_IPX_cancel(ECB_Pointer:pointer);
begin
    Asm
      mov  bx,6
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_IPX_get_localtarget(inbuf,outbuf: pointer );
begin
    Asm
      mov  bx,2
      les  si,inbuf
      les  di,outbuf
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_IPX_delay(ECB_Pointer:pointer; timeout: integer);
begin
    Asm
      mov  bx,5
      mov  ax, timeout
      les  si,ECB_Pointer
      int  07Ah
    end;
end;
{-------------------------------------}

Procedure EMP_GetUserName(var s: string);
var
   goi:   record
              Length: word;
              SubFnc: byte;
              LinkNo: byte;
          end;
   nhan:  record
              Length  : word;
              ObjectID: LongInt;
              Obj_Type: word;
              Obj_Name: array[1..48] of char;
              log_time: array[1..7] of char;
          end;
   i: byte;
begin
  goi.Length  :=  2; goi.SubFnc := $16;
  nhan.Length := 61;
  asm
      push   es
      push   ds

      mov    ah, 0DCh
      int    021h

      mov    dx, ss
      mov    ds, dx
      mov    es, dx

      mov    byte ptr goi.LinkNo, al
      MOV    AH, 0E3h
      lea    si, goi
      lea    di, nhan
      int    021h

      pop    ds
      pop    es
  end;
  i := 1;
  while (nhan.Obj_Name[i] <> #0) do begin
        s[i] := nhan.Obj_Name[i]; i := i + 1;
  end;
  s[0] := Chr(i-1);
end;

end.