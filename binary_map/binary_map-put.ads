with Text_IO;
generic
   with function Image (X : Key_Type) return String;
procedure Binary_Map.Put (The_Map : Map; Indent : Text_IO.Count := 1);
