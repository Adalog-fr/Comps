with Options_Analyzer;
with Ada.Exceptions; use Ada.Exceptions;
with Text_Io; use Text_IO;
procedure Toptions is
   package Options is new Options_Analyzer (Binary_Options => "abc",
                                            Valued_Options => "xyz",
                                            Tail_Separator => "--");
   use Options;
begin
   for C in Character range 'a'..'c' loop
      Put (C);
      Put (" is ");
      if Is_Present (C) then
         Put_Line ("present");
      else
         Put_Line ("absent");
      end if;
   end loop;

   for C in Character range 'x'..'z' loop
      Put (C);
      Put (" is ");
      if Is_Present (C) then
         Put ("present");
      else
         Put ("absent");
      end if;
      Put (". Value=");
      Put_Line (Value (C, Default => "DEFAULT"));
   end loop;

   Put_Line ("Tail=" & Tail_Value ("TAIL_DEFAULT"));

   Put_Line ("Parameters:");
   for I in 1..Parameter_Count loop
      Put_Line (Integer'Image (I) & ':' & Parameter (I));
   end loop;
exception
   when Occur : Options_Error =>
      Set_Col (1);
      Put_Line ("Error: " & Exception_Message (Occur));
end Toptions;
