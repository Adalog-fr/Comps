with  -- Standard units
  Ada.Calendar.Formatting;

--  with  -- Application units
--    Globals;

package body Mysql_Interface.Variable is
--     use Globals;

   ---------
   -- Set --
   ---------

   procedure Set (Variable : String; To : String) is
      Request : constant String :=
        "replace into variables values ('" & Variable & "', '" & To & "');";
      Nb_Rows : Natural;
   begin
      Start_Transaction;
      Exec_SQL (Request, Nb_Rows);
      if Nb_Rows in 1 .. 2 then   -- 1: added, 2: replaced
         Commit_Transaction;
      else
         Rollback_Transaction;
         DB_Failure ("Set", "variables", Request, "Incorrect affected rows:" & Natural'Image (Nb_Rows));
      end if;
   exception
      when Occur : others =>
         DB_Failure ("Set", "variables", Request, Occur);
   end Set;

   -----------
   -- Value --
   -----------

   function Value (Variable : String) return String is
      Request : constant String := "select value from variables where name = '" & Variable & "';";
   begin
      Start_Transaction;
      return Result : String := Exec_SQL (Request) do
         Commit_Transaction;
      end return;
   exception
      when Occur : others =>
         Rollback_Transaction;
         DB_Failure ("Value", "variables", Request, Occur);
   end Value;

   ---------
   -- Set --
   ---------

   procedure Set (Variable : String; To : Boolean) is
   begin
      Set (Variable, Boolean'Image (To));
   end Set;

   -----------
   -- Value --
   -----------

   function Value (Variable : String) return Boolean is
   begin
      return Boolean'Value (Value (Variable));
   end Value;

   ---------
   -- Set --
   ---------

   procedure Set (Variable : String; To : Integer) is
   begin
      Set (Variable, Integer'Image (To));
   end Set;

   -----------
   -- Value --
   -----------

   function Value (Variable : String) return Integer is
   begin
      return Integer'Value (Value (Variable));
   end Value;

   ---------
   -- Set --
   ---------

   procedure Set (Variable : String; To : Ada.Calendar.Time) is
      use Ada.Calendar.Formatting;
   begin
      Set (Variable, Image (To));
   end Set;

   -----------
   -- Value --
   -----------

   function  Value (Variable : String) return Ada.Calendar.Time is
   begin
      return Ada.Calendar.Formatting.Value (Value (Variable)(1..19)); -- 1..19: YYYY-MM-DD hh:mm:ss
   end Value;

end Mysql_Interface.Variable;
