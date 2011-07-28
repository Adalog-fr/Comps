with Binary_Map, Binary_Map.Put;
with Text_IO;
with Ada.Strings.Unbounded;
procedure T_Binary_Map is
   use Ada.Strings.Unbounded;
   function "+" (S : String) return Unbounded_String renames To_Unbounded_String;
   function "+" (S : Unbounded_String) return String renames To_String;

   package Test is new Binary_Map (Unbounded_String, Integer);
   use Test;

   procedure Check_One (K : Unbounded_String; V : in out Integer) is
      use Text_IO;
   begin
      Put_Line(+K & ")" & Integer'Image (V));
   end Check_One;
   procedure Check is new Iterate (Check_One);

   procedure Check_Del_One (K : Unbounded_String; V : in out Integer) is
   begin
      if V rem 5 = 0 then
         raise Delete_Current;
      end if;
   end;
   procedure Check_Del is new Iterate (Check_Del_One);

   procedure Put_Tree is new Test.Put ("+");
   M : Map;
begin
   for I in 1..10 loop
      Add (M, +"V" & Integer'Image (I), I);
   end loop;

   Check (M);
   Put_Tree (M);

   Balance (M);
   Put_Tree (M);

   Check_Del (M);
   Put_Tree (M);
end T_Binary_Map;
