with   -- Standard Ada units
  Ada.Calendar,
  Ada.Exceptions;

package body Mysql_Interface is

   protected Sema is
      entry P;
      procedure Non_BLocking_P (Granted : out Boolean);
      procedure V;
   private
      Busy : Boolean := False;
   end Sema;

   protected body Sema is
      entry P when not Busy is
      begin
         Busy := True;
      end P;

      procedure Non_BLocking_P (Granted : out Boolean) is
      begin
         if Busy then
            Granted := False;
         else
            Granted := True;
            Busy    := True;
         end if;
      end Non_Blocking_P;

      procedure V is
      begin
         Busy := False;
      end V;
  end Sema;

   -------------------------------------------------------------------------
   -- Internal subprograms                                                --
   -------------------------------------------------------------------------

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Item : in out Excluder_Object) is
   begin
      Sema.P;
   end Initialize;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Item : in out Excluder_Object) is
   begin
      Sema.V;
   end Finalize;

   ---------------
   -- Watch_Dog --
   ---------------

   -- Prevents My_Sql from killing the connection if it stays
   -- inactive for several hours
   -- SQL Requests call Reset_Time_Out, since the watch dog will not
   -- be needed for another period. This prevents the (unlikely) case
   -- of the Watch_Dog being awaken while a transaction is going on.
   task Watch_Dog is
      entry Start;
      entry Stop;
      entry Reset_Time_Out;
   end Watch_Dog;

   task body Watch_Dog is separate;

   -------------------------------------------------------------------------
   -- Exported subprograms                                                --
   -------------------------------------------------------------------------

   ------------
   -- Commit --
   ------------

   procedure Commit is
      Lock : Excluder_Object;
   begin
      Odbc2.Commit (Connection);
   end Commit;

   -------------
   -- Connect --
   -------------

   procedure Connect (Login       : in String;
                      Password    : in String;
                      Data_Source : in String;
                      Data_Base   : in String)
   is
      -- No need to lock; if any request were issued, it would fail since the
      -- database is not yet connected...
      Nb_Lignes : Natural;
   begin
      Odbc2.Connect (Connection, Data_Source, Login, Password);
      Set_Autocommit (False);

      -- Watch_Dog must be started before any request is issued.
      Watch_Dog.Start;
      Exec_SQL("use " & Data_Base, Nb_Lignes);
   end Connect;

   ----------------
   -- Disconnect --
   ----------------

   procedure Disconnect is
      Lock : Excluder_Object;
   begin
      begin
         Watch_Dog.Stop;
      exception
         when Tasking_Error =>
            -- Watch_Dog is dead!
            -- Should not prevent us from disconnecting
            null;
      end;
      Odbc2.Disconnect (Connection);
   end Disconnect;

   --------------
   -- Exec_SQL --
   --------------

   function Exec_SQL (Query : String; Column : Positive := 1) return String is
      use Odbc2, Ada.Exceptions;
      Lock : Excluder_Object;
      My_Statement : Odbc2.Cursor_Type := Create_Cursor (Connection,
                                                         Query,
                                                         Read_Only    => True,
                                                         Forward_Only => False);
      Ignored : Boolean;
   begin
      Watch_Dog.Reset_Time_Out;

      if Fetch_Scroll (My_Statement, First, 0) = Db_Success then
         declare
            Result : String (1 .. Odbc2.Get_Column_Size (My_Statement, Column));
         begin
            Odbc2.Bind_Output (My_Statement, Column, Result);
            Ignored := Fetch_Scroll (My_Statement, First, 0) = Db_Success;
            Odbc2.Close (My_Statement);
            return Result;
         end;
      else
         Raise_Exception (No_Data'Identity, Message => "Query: " & Query);
      end if;
   end Exec_SQL;

   --------------
   -- Exec_SQL --
   --------------

   procedure Exec_SQL (Query         : in     String;
                       Affected_Rows :    out Natural) is
      Lock : Excluder_Object;
      My_Statement : Odbc2.Cursor_Type (0,0);
   begin
      Watch_Dog.Reset_Time_Out;

      Odbc2.Open (My_Statement, Connection, Query);
      Odbc2.Execute (My_Statement);
      Affected_Rows := Odbc2.Row_Count (My_Statement);
      Odbc2.Close (My_Statement);
   end Exec_SQL;

   --------------
   -- Finalize --
   --------------

   procedure Finalize(Object : in out Query_Result) is
      Lock : Excluder_Object;
   begin
      Odbc2.Close (Object.Statement);
   end Finalize;

  --------------
   -- Rollback --
   --------------

   procedure Rollback is
      Lock : Excluder_Object;
   begin
      Odbc2.Rollback (Connection);

      -- Do not call Set_Autocommit to avoid dead-lock:
      Odbc2.Auto_Commit (Connection, False);
   end Rollback;

   --------------------
   -- Set_Autocommit --
   --------------------

   procedure Set_Autocommit (To : in Boolean) is
      Lock : Excluder_Object;
   begin
      Odbc2.Auto_Commit (Connection, To);
   end Set_Autocommit;

   ----------------------
   -- Set_SQL_Variable --
   ----------------------

   procedure Set_SQL_Variable (Name : String; Value : String) is
      SQL : constant String := "set " & Name & " = '" & Value & ''';
      Ignored : Natural;
   begin
      Exec_SQL (SQL, Ignored);
   end Set_SQL_Variable;

   ------------------------
   -- SQL_Variable_Value --
   ------------------------

   function SQL_Variable_Value (Name : String) return String is
      SQL : constant String := "show variables like '" & Name & ''';
   begin
      return Exec_SQL (SQL, Column => 2);
   end SQL_Variable_Value;


end Mysql_Interface;
