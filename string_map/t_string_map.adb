pragma Ada_2012;
with Ada.Text_IO;
with String_Map;
procedure T_String_Map is
   use Ada.Text_IO, String_Map;
   Test_String: constant String := "Param1=""Abcd"";Param2="" a;b"""" c"";Non_Quote=  essai  ;  ";
begin
   Put ("Test_String= ");
   Put_Line (Test_String);
   Put_Line ("             123456789012345678901234567890");
   Put_Line ("                      1         2         3");
   for C in Parse (Test_String) loop
      Put ("Key  = '"); Put (Key   (C)); Put ('''); New_Line;
      Put ("Value= '"); Put (Value (C)); Put ('''); New_Line;
   end loop;
end T_String_Map;
