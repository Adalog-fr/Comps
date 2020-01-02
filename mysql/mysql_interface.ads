with   -- Standard Ada units
  Ada.Finalization;

with    -- Application specific units
  Odbc2;

package Mysql_Interface is

   -- connection to the datasource
   procedure Connect (Login       : in String;
                      Password    : in String;
                      Data_Source : in String;
                      Data_Base   : in String);

   procedure Disconnect;

   procedure Set_Autocommit (To : in Boolean);
   procedure Commit;
   procedure Rollback;

   -- procedure to execute any SQL statement without result (like UPDATE...)
   procedure Exec_SQL (Query         : in     String;
                       Affected_Rows :    out Natural);

   -- function to execute any SQL statement and return the value of the
   -- first (or specified) column of the first row.
   -- Normally used for queries with single-valued results (like COUNT()...)
   function Exec_SQL (Query : String; Column : Positive := 1) return String;

   procedure Set_SQL_Variable   (Name : String; Value : String);
   function  SQL_Variable_Value (Name : String) return String;

   -- Exception raised by two above functions if no data is available
   No_Data : exception;

private
   Connection : Odbc2.Connection_Handle;

   type Query_Result is new Ada.Finalization.Controlled with record
      Statement   : Odbc2.Cursor_Type;
      Nb_Of_Rows  : Natural;
      Current_Row : Positive;
   end record;

   procedure Finalize (Object : in out Query_Result);

   -- Mutual exclusion
   type Excluder_Object is new Ada.Finalization.Limited_Controlled with null record;
   procedure Initialize (Item : in out Excluder_Object);
   procedure Finalize   (Item : in out Excluder_Object);

end Mysql_Interface;
