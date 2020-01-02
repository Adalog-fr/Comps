with   -- Ada Standard units
  Ada.Calendar;

generic
   Query : in String;
package Mysql_Interface.Cursor is

   -- raised exception if next is performed and is_exhausted set to true
   End_Of_Result_Set : exception;

   --gets the iterator on the next row of the resultset
   procedure Next;

   -- returns true if iterator is beyond the nb of rows
   function Is_Exhausted return Boolean;

   -- returns the number of rows returned by the query
   function Nb_Of_Rows return Natural;

   -- raised exception if line is beyond nb_of_rows;
   Unknown_Row : exception;

   --gets the iterator in front of the specified line
   procedure Go_To_Row (Row : Positive);

   Unknown_Column : exception;
   -- these functions return "meta" information
   function Get_Column_Name     (Column : Positive) return String;
   function Get_Column_size     (Column : Positive) return Natural;
   type Column_Type is (String_Type, Integer_Type, Date, Float_Type, Unknown);
   function Get_Column_Type     (Column : Positive) return Column_Type;
   function Get_Column_Decimals (Column : Positive) return Natural;

   function Has_Value (Column : Positive) return Boolean;

   -- Raised exception if the requested value (in the following functions) is null
   -- (Has_Value is false)
   Null_Value : exception;

   -- These functions return the value in the nth column from the current_line
   function Get_String  (Column : Positive) return String;
   function Get_Integer (Column : Positive) return Integer;
   function Get_Date    (Column : Positive) return Ada.Calendar.Time;
   function Get_Float   (Column : Positive) return Float;

end Mysql_Interface.Cursor;
