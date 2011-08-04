procedure Binary_Map.Put (The_Map : Map; Indent : Text_IO.Count := 1) is
   use Text_IO;
   Pos : Count;
begin
   Set_Col (Indent);
   if The_Map = null then
      Put ("()");
      return;
   end if;

   Put ("(");
   Put (Image (The_Map.Key));
   Pos := Col+1;
   Put (The_Map.Children (Before), Pos);
   Put (The_Map.Children (After), Pos);
   Set_Col (Indent);
   Put (')');
   New_Line;

end Binary_Map.Put;
