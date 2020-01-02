with    -- Standard Ada units
  Ada.Calendar.Formatting,
  Ada.Strings.Fixed;

with    -- Application specific units
  Odbc2;
pragma Elaborate_All (Odbc2);

package body Mysql_Interface.Cursor is
   use Ada.Strings, Ada.Strings.Fixed;
   use Odbc2;

   -- gestion de la fermeture du statement;
   Stmt : Query_Result;

   -- this function actually performs the query and retrieves the number of fields in
   -- the result set (used to allocate the rowset with exact nuber of fields)
   function Init return Natural is
      Lock : Excluder_Object;
   begin
      Stmt.Statement  := Create_Cursor (Connection,
                                        Query,
                                        Read_Only    => True,
                                        Forward_Only => False);
      Stmt.Nb_Of_Rows := Row_Count (Stmt.Statement);
      return Stmt.Statement.Num_Fields;
   end Init;

   Nb_Of_Fields : constant Natural := Init;

   -- this function search for the longest field to allocate the rowset
   -- with the best size for the fields
   function Get_Max_Length_Of_Column return Positive is
      Lock : Excluder_Object;
      Result : Positive := 1;
   begin
      for I in 1 .. Nb_Of_Fields loop
         Result := Positive'Max (Result, Odbc2.Get_Column_Size (Stmt.Statement, I));
      end loop;
      return Result;
   end Get_Max_Length_Of_Column;


   type Row_Set_type is array (1 .. Nb_Of_Fields) of String (1 .. Get_Max_Length_Of_Column);
   Row_Set : Row_Set_Type := (others => (others => ' '));


   -------------------------
   -- Get_Column_Decimals --
   -------------------------

   function Get_Column_Decimals (Column : Positive) return Natural is
      Lock : Excluder_Object;
   begin
      if Column > Nb_Of_Fields then
         raise Unknown_Column;
      else
         return Odbc2.Get_Column_Decimals (Stmt.Statement, Column);
      end if;
   end Get_Column_Decimals;

   ---------------------
   -- Get_Column_Name --
   ---------------------

   function Get_Column_Name (Column : Positive) return String is
      Lock : Excluder_Object;
   begin
      if Column > Nb_Of_Fields then
         raise Unknown_Column;
      else
         return Odbc2.Get_Column_Name (Stmt.Statement, Column);
      end if;
   end Get_Column_Name;

   ---------------------
   -- Get_Column_Size --
   ---------------------

  function Get_Column_Size (Column : Positive) return Natural is
      Lock : Excluder_Object;
  begin
      if Column > Nb_Of_Fields then
         raise Unknown_Column;
      else
         return Odbc2.Get_Column_Size (Stmt.Statement, Column);
      end if;
   end Get_Column_Size;

   ---------------------
   -- Get_Column_Type --
   ---------------------

   function Get_Column_Type (Column : Positive) return Column_Type is
      Lock : Excluder_Object;
   begin
      if Column > Nb_Of_Fields then
         raise Unknown_Column;
      else
         case Odbc2.Get_Column_Type (Stmt.Statement, Column) is
            when Integer_Type =>
               return Integer_Type;
            when Date =>
               return Date;
            when Float_Type =>
               return Float_Type;
            when String_Type =>
               return String_Type;
            when Unknown =>
               return Unknown;
         end case;
      end if;
   end Get_Column_Type;

   --------------
   -- Get_Date --
   --------------

   function Get_Date (Column : Positive) return Ada.Calendar.Time is
      use Ada.Calendar.Formatting;
   begin
      return Value (Get_String (Column) & " 00:00:00");
   end Get_Date;

   ---------------
   -- Get_Float --
   ---------------

   function Get_Float (Column : Positive) return Float is
   begin
      return Float'Value (Get_String (Column));
   end Get_Float;

   -----------------
   -- Get_Integer --
   -----------------

   function Get_Integer (Column : Positive) return Integer is
   begin
      return Integer'Value(Get_String (Column));
   end Get_Integer;

   ----------------
   -- Get_String --
   ----------------

   function Get_String (Column : Positive) return String is
       Lock : Excluder_Object;
   begin
      if Column > Nb_Of_Fields then
         raise Unknown_Column;
      elsif Is_Null (Stmt.Statement, Column) then
         raise Null_Value;
      else
         return Trim(Row_Set (Column), Both);
      end if;
   end Get_String;

   ---------------
   -- Go_To_Row --
   ---------------

   procedure Go_To_Row (Row : Positive) is
      Lock : Excluder_Object;
      Success : Boolean;
   begin
      Success := Fetch_Scroll (Stmt.Statement, Absolute, Row) = Db_Success;
      if not Success then
         raise Unknown_Row;
      end if;
      Stmt.Current_Row := Row;
   end Go_To_Row;

   ---------------
   -- Has_Value --
   ---------------

   function Has_Value (Column : Positive) return Boolean is
      Lock : Excluder_Object;
   begin
      return not Is_Null (Stmt.Statement, Column);
   end Has_Value;

   ------------------
   -- Is_Exhausted --
   ------------------

   function Is_Exhausted return Boolean is
   begin
      return Stmt.Current_Row > Stmt.Nb_Of_Rows;
   end Is_Exhausted;

   ----------------
   -- Nb_Of_Rows --
   ----------------

   function Nb_Of_Rows return Natural is
   begin
      return Stmt.Nb_Of_Rows;
   end Nb_Of_Rows;

   ----------
   -- Next --
   ----------

   procedure Next is
      Lock : Excluder_Object;
      Success : Boolean;
   begin
      Success := Fetch_Scroll (Stmt.Statement, Next, 0) = Db_Success;
      Stmt.Current_Row := Stmt.Current_Row + 1;
   end Next;

begin
   declare
      Lock : Excluder_Object;
   begin
      if Stmt.Nb_Of_Rows /= 0 then
         for I in 1 .. Nb_Of_Fields loop
            Odbc2.Bind_Output (Stmt.Statement, I, Row_Set(I));
         end loop;

         if Fetch_Scroll (Stmt.Statement, First, 0) /= Db_Success then
            -- ??? There should be at least one row
            raise Program_Error;
         end if;
      end if;
   end;
   Stmt.Current_Row := 1;
end Mysql_Interface.Cursor;
