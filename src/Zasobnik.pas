unit Zasobnik;

// Tato unita resi zasobnik jizdnich cest jedne oblasti rizeni.

interface

uses Generics.Collections, Types, Classes, SysUtils, PGraphics, Graphics,
      StrUtils, RPConst, Windows;

type
  TORStackVolba = (PV = 0, VZ = 1);
  TOREZVolba = (closed = 0, please = 1, openned = 2);

  TORStackJC = record
   JC:string;
   id:Integer;
  end;

  TORStack = class
   private const
    _JC_TEXT_WIDTH = 25;

   private
     index:Integer;
     stack:TList<TORStackJC>;
     volba:TORStackVolba;
     hint:string;
     EZ:TOREZVolba;
     pos:TPoint;
     parent:string;
     fenabled:boolean;
     selected:Integer;
     first_enabled:boolean;
     UPOenabled:boolean;

     Graphics:TPanelGraphics;

      procedure SetEnabled(new:boolean);
      procedure ParseList(list:string);

      procedure AddJC(data:string);
      procedure RemoveJC(id:Integer);

   public


      constructor Create(Graphics:TPanelGraphics; parent:string; pos:TPoint);
      destructor Destroy(); override;

      procedure Show();

      procedure ParseCommand(data:TStrings);

      procedure MouseClick(Position:TPoint; Button:TPanelButton; var handled:boolean);
      procedure KeyPress(key:Integer; var handled:boolean);

      property enabled:boolean read fenabled write SetEnabled;

  end;//TORStack


implementation

uses TCPCLientPanel, Symbols;

////////////////////////////////////////////////////////////////////////////////

constructor TORStack.Create(Graphics:TPanelGraphics; parent:string; pos:TPoint);
begin
 inherited Create();

 Self.index         := 0;
 Self.stack         := TList<TORStackJC>.Create();
 Self.volba         := PV;
 Self.hint          := '';
 Self.EZ            := closed;
 Self.pos           := pos;
 Self.parent        := parent;
 Self.fenabled      := false;
 Self.selected      := -1;
 Self.first_enabled := true;

 Self.Graphics := Graphics;
end;//ctor

destructor TORStack.Destroy();
begin
 Self.stack.Free();
 inherited Destroy();
end;//dtor

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.ParseCommand(data:TStrings);
begin
 try
   if (data[2] = 'VZ') then
    Self.volba := VZ
   else if (data[2] = 'PV') then
    Self.volba := PV
   else if (data[2] = 'LIST') then
    begin
     if (data.Count > 4) then
       Self.ParseList(data[4])
     else
      Self.stack.Clear();
      if (Self.EZ = TOREZVolba.please) then
        Self.EZ := TOREZVolba.openned;
    end
   else if (data[2] = 'FIRST') then
    begin
     if (data[3] = '1') then
      Self.first_enabled := true
     else
      Self.first_enabled := false;
      if (Self.selected = 0) then
       Self.selected := 1;
    end
   else if (data[2] = 'INDEX') then
    Self.index := StrToInt(data[3])
   else if (data[2] = 'RM') then
    Self.RemoveJC(StrToInt(data[3]))
   else if (data[2] = 'ADD') then
    Self.AddJC(data[3])
   else if (data[2] = 'HINT') then
    begin
    if (data.Count > 3) then begin
      if (Length(data[3]) > 8) then
        Self.hint := LeftStr(data[3], 7) + '.'
      else
        Self.hint := data[3]
    end else
      Self.hint := '';
    end
   else if (data[2] = 'UPO') then
    begin
     if (data[3] = '1') then
      Self.UPOenabled := true
     else
      Self.UPOenabled := false;
    end;
 except

 end;

end;//procedure

procedure TORStack.SetEnabled(new:boolean);
begin
 if ((not new) and (Self.enabled)) then
  begin
   Self.stack.Clear();
   Self.hint          := '';
   Self.EZ            := closed;
   Self.volba         := PV;
   Self.selected      := -1;
   Self.first_enabled := true;
  end;

 Self.fenabled := new;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.ParseList(list:string);
var str1, str2:TStrings;
    i:Integer;
    stack_jc:TORStackJC;
begin
 str1 := TStringList.Create();
 str2 := TStringList.Create();
 ExtractStringsEx([']'], ['['], list, str1);

 Self.stack.Clear();
 for i := 0 to str1.Count-1 do
  begin
   str2.Clear();
   ExtractStringsEx(['|'], [], str1[i], str2);

   try
    stack_jc.id := StrToInt(str2[0]);
    stack_jc.JC := str2[1];
    Self.stack.Add(stack_JC);
   except

   end;
  end;//for i

 if (Self.EZ = TOREZVolba.please) then
   Self.EZ := TOREZVolba.openned;

 str2.Free();
 str1.Free();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.RemoveJC(id:Integer);
var i:Integer;
begin
 for i := 0 to Self.stack.Count-1 do
  if (Self.stack[i].id = id) then
   begin
    if (Self.selected = i) then
     Self.selected := -1;
    Self.stack.Delete(i);
    if ((Self.stack.Count = 0) and (Self.EZ <> TOREZVolba.closed)) then
      Self.EZ := TOREZVolba.closed;
    if (i = 0) then
     begin
      if (not Self.first_enabled) then
        Self.first_enabled := true;
      Self.UPOenabled := false;
     end;
    Exit();
   end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.AddJC(data:string);
var str:TStrings;
    stack_jc:TORStackJC;
begin
 str := TStringList.Create();
 ExtractStringsEx(['|'], [], data, str);

 try
   stack_jc.id := StrToInt(str[0]);
   stack_jc.JC := str[1];
   Self.stack.Add(stack_JC);
 except

 end;

 str.Free();
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.Show();
var i, j:Integer;
    bk:TColor;
    txt:string;
begin
 // zasobnik Disabled
 if (not Self.fenabled) then
  begin
   Self.Graphics.TextOutput(Self.pos, Format('%.2d',[Self.index]), clFuchsia, clBlack);
   Self.Graphics.TextOutput(Point(Self.pos.X+3, Self.pos.Y), 'VZ', clFuchsia, clBlack);
   Self.Graphics.TextOutput(Point(Self.pos.X+6, Self.pos.Y), 'PV', clFuchsia, clBlack);
   Self.Graphics.TextOutput(Point(Self.pos.X+9, Self.pos.Y), 'EZ', clFuchsia, clBlack);
   Self.Graphics.TextOutput(Point(Self.pos.X+12, Self.pos.Y), Format('%.2d',[Self.stack.Count]), clFuchsia, clBlack);
   Exit();
  end;

 Self.Graphics.TextOutput(Self.pos, Format('%.2d',[Self.index]), $A0A0A0, clBlack);

 case (Self.EZ) of
   TOREZVolba.closed  : Self.Graphics.TextOutput(Point(Self.pos.X+9, Self.pos.Y), 'EZ', $A0A0A0, clBlack);
   TOREZVolba.please  : Self.Graphics.TextOutput(Point(Self.pos.X+9, Self.pos.Y), 'EZ', clYellow, clBlack);
   TOREZVolba.openned : Self.Graphics.TextOutput(Point(Self.pos.X+9, Self.pos.Y), 'EZ', clWhite, clBlack);
 end;//case

 if (Self.EZ = TOREZVolba.openned) then
  begin
   Self.Graphics.TextOutput(Point(Self.pos.X+3, Self.pos.Y), 'VZ', $A0A0A0, clBlack);
   Self.Graphics.TextOutput(Point(Self.pos.X+6, Self.pos.Y), 'PV', $A0A0A0, clBlack);

   //vypsani jizdnich cest v zasobniku
   for i := 0 to Self.stack.Count-1 do
    begin
     if (Self.selected = i) then
      bk := clOlive
     else begin
      if (i = 0) then
        bk := clTeal
      else
        bk := $A0A0A0;
     end;

     if (Length(Self.stack[i].JC) > _JC_TEXT_WIDTH) then
       txt := LeftStr(Self.stack[i].JC, _JC_TEXT_WIDTH)
     else begin
       txt := Self.stack[i].JC;
       for j := 0 to _JC_TEXT_WIDTH-Length(Self.stack[i].JC) do txt := txt + ' ';
     end;

     Self.Graphics.TextOutput(Point(Self.pos.X, Self.pos.Y+i+1), ' '+txt, clBlack, bk);
    end;//for i

  end else begin
   // pokud neni EZ
   if (Self.volba = VZ) then
    begin
     Self.Graphics.TextOutput(Point(Self.pos.X+3, Self.pos.Y), 'VZ', clWhite, clBlack);
     Self.Graphics.TextOutput(Point(Self.pos.X+6, Self.pos.Y), 'PV', $A0A0A0, clBlack);
    end else begin
     Self.Graphics.TextOutput(Point(Self.pos.X+3, Self.pos.Y), 'VZ', $A0A0A0, clBlack);
     Self.Graphics.TextOutput(Point(Self.pos.X+6, Self.pos.Y), 'PV', clWhite, clBlack);
    end;

   // pokud je alespon jedna cesta v zasobniku, vypiseme ji
   if (Self.stack.Count > 0) then
    begin
     if (Length(Self.stack[0].JC) > _JC_TEXT_WIDTH) then
       txt := LeftStr(Self.stack[0].JC, _JC_TEXT_WIDTH)
     else begin
       txt := Self.stack[0].JC;
       for j := 0 to _JC_TEXT_WIDTH-Length(Self.stack[0].JC) do txt := txt + ' ';
     end;
     Self.Graphics.TextOutput(Point(Self.pos.X, Self.pos.Y+1), ' '+txt, clBlack, clTeal);
    end;

   Self.Graphics.TextOutput(Point(Self.pos.X+12, Self.pos.Y), Format('%.2d', [Self.stack.Count]), $A0A0A0, clBlack);

   if ((Self.hint <> '') or (Self.UPOenabled)) then
    begin
     if (Self.UPOenabled) then begin
       Self.Graphics.TextOutput(Point(Self.pos.X+15, Self.pos.Y), 'UPO', clYellow, clBlack);
       Self.Graphics.TextOutput(Point(Self.pos.X+19, Self.pos.Y), Self.hint, clYellow, clBlack);
     end else begin
       Self.Graphics.TextOutput(Point(Self.pos.X+15, Self.pos.Y), 'UPO', $A0A0A0, clBlack);
       Self.Graphics.TextOutput(Point(Self.pos.X+19, Self.pos.Y), Self.hint, $A0A0A0, clBlack);
     end;
    end;
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.MouseClick(Position:TPoint; Button:TPanelButton; var handled:boolean);
begin
 // klik na horni symboly
 if (Position.Y = Self.pos.Y) then
  begin
   if (Self.EZ = TOREZVolba.closed) then
    begin
     if ((Position.X >= Self.pos.X+3) and (Position.X <= Self.pos.X+4)) then
       // VZ
      PanelTCPClient.SendLn(Self.parent+';ZAS;VZ;')
     else if ((Position.X >= Self.pos.X+6) and (Position.X <= Self.pos.X+7)) then
      // PV
      PanelTCPClient.SendLn(Self.parent+';ZAS;PV;')
    end;

   if ((Position.X >= Self.pos.X+9) and (Position.X <= Self.pos.X+10)) then
    // EZ
    begin
     case (Self.EZ) of
      TOREZVolba.closed                     : begin
        if (Self.stack.Count = 0) then Exit();        
        Self.EZ := please;
        PanelTCPClient.SendLn(Self.parent+';ZAS;EZ;1');
      end;
      TOREZVolba.openned, TOREZVolba.please : begin
        Self.selected := -1;
        Self.EZ := closed;
        PanelTCPClient.SendLn(Self.parent+';ZAS;EZ;0;');
      end;
     end;//case
    end;

   //UPO
   if ((Position.X >= Self.pos.X+15) and (Position.X <= Self.pos.X+17+1+Length(Self.hint)) and (Self.UPOenabled)) then
     PanelTCPClient.SendLn(Self.parent+';ZAS;UPO;');
   
  end;//if Position.Y = Self.pos.Y

 // klik na cestu v zasobniku
 if ((Self.EZ = TOREZVolba.openned) and (Position.X >= Self.pos.X) and (Position.X <= Self.pos.X+_JC_TEXT_WIDTH) and
     (Position.Y > Self.pos.Y) and (Position.Y <= Self.pos.Y+Self.stack.Count)) then
  begin
   if (((Position.Y - Self.pos.Y - 1) <> 0) or (Self.first_enabled)) then
    begin
     Self.selected := Position.Y - Self.pos.Y - 1;
     handled := true;
    end;
  end;

end;//procedure

////////////////////////////////////////////////////////////////////////////////

procedure TORStack.KeyPress(key:Integer; var handled:boolean);
begin
 if (Self.EZ = TOREZVOlba.openned) then
  begin
   case (key) of
    VK_DELETE:begin
       if (Self.selected = 0) and (not Self.first_enabled) then Exit();
       if ((Self.selected >= Self.stack.Count) or (Self.selected < 0)) then Exit();

       PanelTCPClient.SendLn(Self.parent+';ZAS;RM;'+IntToStr(Self.stack[Self.selected].id));
       handled := true;
    end;

    VK_ESCAPE:begin
      if (Self.EZ <> TOREZVolba.closed) then
       begin
        Self.EZ := TOREZVolba.closed;
        handled := true;
       end;
    end;
   end;//case
  end;
end;//procedure

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

end.//unit
