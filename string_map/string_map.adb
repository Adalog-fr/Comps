pragma Ada_2012;
with   -- Standard units
   Ada.Strings.Fixed;

package body String_Map is

   type String_Iterator (Length : Natural) is new Iterator.Forward_Iterator with
      record
         To_Parse : String (1 .. Length);
      end record;
   function First (Object : String_Iterator) return Cursor;
   function Next  (Object : String_Iterator; Position : Cursor) return Cursor;

   -----------
   -- First --
   -----------

   function First (Object : String_Iterator) return Cursor is
   begin
      return Next (Object, (Length  => Object.Length,
                            Params  => Object.To_Parse,
                            Current => 1,
                            others  => <>));
   end First;


   ----------
   -- Next --
   ----------

   function Next (Object : String_Iterator; Position : Cursor) return Cursor is
      pragma Unreferenced (Object);

      Result : Cursor := Position;

      type Skip_State is (Key, Value);

      ---------------
      -- Skip_Item --
      ---------------

      procedure Skip_Item (State : Skip_State) is
         Quoted : Boolean;
      begin
         if Result.Current > Result.Params'Last then
            raise Parse_Error with "Unterminated parameter string";
         end if;

         if Result.Params (Result.Current) = '"' then
            if State = Key then
               raise Parse_Error with "Illegal character in key: " & Result.Params (Result.Current);
            end if;
            Quoted := True;
            Result.Current := Result.Current + 1;
         else
            Quoted := False;
         end if;

         loop
            case Result.Params (Result.Current) is
               when 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' =>
                  Result.Current := Result.Current + 1;
               when '"' =>
                  if State = Key then
                     raise Parse_Error with "Illegal character in key: """;
                  end if;
                  Result.Current := Result.Current + 1;
                  if Quoted then
                     if Result.Current <= Result.Params'Last
                       and then Result.Params (Result.Current) = '"'
                     then
                        Result.Current := Result.Current + 1;
                     else
                        exit;
                     end if;
                  end if;
               when ' ' | ';' =>
                  if Quoted then
                     Result.Current := Result.Current + 1;
                  else
                     exit;
                  end if;
               when '=' =>
                  if State = Value then
                     Result.Current := Result.Current + 1;
                  else
                     exit;
                  end if;
               when others =>
                  if State = Key then
                     raise Parse_Error with "Illegal character in key: " & Result.Params (Result.Current);
                  end if;
                  Result.Current := Result.Current + 1;
            end case;

         end loop;
      end Skip_Item;

      procedure Skip_Char (Char : Character) is
      begin
         if Result.Current > Result.Params'Last
           or else Result.Params (Result.Current) /= Char
         then
            raise Parse_Error with Char & " expected";
         end if;
         Result.Current := Result.Current + 1;
      end Skip_Char;

      procedure Skip_Spaces is
      begin
         while Result.Current <= Result.Params'Last
              and then Result.Params (Result.Current) = ' '
         loop
            Result.Current := Result.Current + 1;
         end loop;
      end Skip_Spaces;
   begin
      -- Invariant: Result.Current points at the first charactor of the next key
      -- (or outside the string if no more parameters).
      Result.K_First := Result.Current;
      if Result.Current > Result.Params'Last then
         return Result;
      end if;

      Skip_Item (Key);
      Result.K_Last := Result.Current - 1;
      Skip_Spaces;
      Skip_Char ('=');
      Skip_Spaces;
      Result.V_First := Result.Current;
      Skip_Item (Value);
      Result.V_Last := Result.Current - 1;
      Skip_Spaces;
      Skip_Char (';');
      Skip_Spaces;  -- Go to beginning of next key

      return Result;
   end Next;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (Position : Cursor) return Boolean is
   begin
      --return Position /= Empty_Cursor;
      return Position.K_First <= Position.Params'Last;
   end Has_Element;

   -----------
   -- Parse --
   -----------

   function Parse (Params : String) return Iterator.Forward_Iterator'Class is
      use Ada.Strings, Ada.Strings.Fixed;
      Good_String : constant String := Trim (Params, Both);
   begin
      return String_Iterator'(Length => Good_String'Length, To_Parse => Good_String);
   end Parse;

   ---------
   -- Key --
   ---------

   function Key (C : Cursor) return String is
   begin
      return C.Params (C.K_First .. C.K_Last);
   end Key;

   -----------
   -- Value --
   -----------

   function Value (C : Cursor) return String is
   begin
      if C.Params (C.V_First) /= '"' then
         return C.Params (C.V_First .. C.V_Last);
      end if;

      -- Quoted string
      declare
         Result : String (1 .. C.V_Last - C.V_First + 1 - 2);  -- -2: don't include surrounding quotes
         Inx    : Natural := 0;
         Ignore : Boolean := False;
      begin
         for Char of C.Params (C.V_First + 1 .. C.V_Last - 1) loop
            if Ignore then
               Ignore := False;
            else
               Inx := Inx + 1;
               Result (Inx) := Char;
               if Char = '"' then  -- necessarily doubled
                  Ignore := True;
               end if;
            end if;
         end loop;
         return Result (1..Inx);
      end;
   end Value;

end String_Map;
