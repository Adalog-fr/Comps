--                              -*- Mode: Ada -*-
-- Filename        : odbc2.adb
-- Author          : Sune Falck
-- Created On      : 1998-02-03 20:33
--
-- Copyright (C) 2000 Sune Falck, Tullinge, SWEDEN
--
-- Sune.Falck@swipnet.se
--
---------------------------------------------------------------------------
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Library General Public
-- License as published by the Free Software Foundation; either
-- version 2 of the License, or (at your option) any later version.
--
-- This library is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Library General Public License for more details.
--
-- You should have received a copy of the GNU Library General Public
-- License along with this library; if not, write to the Free
-- Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
--
-- As a special exception, if other files instantiate generics from this
-- unit, or you link  this unit with other files  to produce an executable,
-- this unit does not by itself cause the resulting executable to be
-- covered  by the  GNU  General  Public  License. This exception does not
-- however invalidate any other reasons why the executable file might be
-- covered by the GNU Public License.
---------------------------------------------------------------------------
--
-- File version    : $Revision: 1.1 $  $Date: 2003/06/25 15:19:09 $
--
-- PURPOSE
--      "High" level binding to odbc 2.0
--
-- HISTORY
-- 1999-07-09   Sune Falck
--    Added Bind_Output/Bind_Input for access to Integer, Float and Long_Float
--
-- 1999-07-05   Sune Falck
--    Added pragma Warnings to eliminate warning messages during compilation.
--
-- 1999-04-20   Sune Falck
--    Replaced win32 bindings to sql and sqlext with new binding iodbc.
--    Made some type conversions to adjust for the new binding
--    No visibible changes to users of the package
--    New internal procedure Move instead of C memcpy function
--
-- 1999-01-26   Sune Falck
--    Bind_Output and Bind_Input cunversion functions To_A_Sdword
--    changed to convert from address value instead of access
--    value because that the previous construction was illegal according
--    to gnat 3.11p. The calls of SQLBindCol and SQLBind_Parameter were
--    changed.
--
-- 26-Nov-1997          Sune Falck
--    Mimer 7.3.2 has the following bug:
--    Insert into an emty table takes exponentially longer time
--    for each insert. If the table contains just one record before
--    the start, everything works OK. Stopped UPDATE_NODNR after
--    a couple of hours and 3000 inserts. Test with inserting a dummy
--    record before start reduced the time to 5 minutes for 9000 inserts.
--
-- 25-Nov-1997          Sune Falck
--    Removed the setting of connection attributes for
--    LOGIN_TIMEOUT and TXN_ISOLATION because Mimer DB does
--    not support these attributes.
--
-- 07-Nov-1997          Sune Falck
--    Changed handling of Bind_Output for strings so that it is
--    possible to bind direct to a string of the correct size,
--    no need to strip trailing nul. (Work around for Mimer DB)
--    Removed setting of statement attribute for CONCURRENCY,
--    Mimer only acepts CONCUR_READ_ONLY and CONCUR_LOCK.
--

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces.C;
with Iodbc;
with System.Address_To_Access_Conversions;
with System.Storage_Elements;


package body Odbc2 is
   use Iodbc;
   use type System.Address;

   ------------------------------------------------------------------------
   --  Static variables
   ------------------------------------------------------------------------
   Null_Env  : constant HENV  := HENV (System.Null_Address);
   Null_Dbc  : constant HDBC  := HDBC (System.Null_Address);
   Null_Stmt : constant HSTMT := HSTMT (System.Null_Address);
   Null_Connection : constant Connection_Handle :=
     Connection_Handle (System.Null_Address);

   Environment : aliased HENV := Null_Env;

   Info_Report : Boolean := False;

   Data_Base   : Connection_Handle := Null_Connection;

   Last_Sqlstate : String (1..5) := "00000";

   ----------------------------------------------------------
   --  Mapping of program variables to C-type and SQL-type  -
   ----------------------------------------------------------
   type Data_Conversions is
      record
         C_Value   : SWORD;
         SQL_Value : SWORD;
      end record;

   SQL_To_C :  constant array (Data_Type) of Data_Conversions :=
     (Db_Char       => (SQL_C_CHAR,   SQL_CHAR),          --  Pre Sca
      Db_Smallint   => (SQL_C_SSHORT, SQL_SMALLINT),      --   5   0
      Db_Integer    => (SQL_C_SLONG,  SQL_INTEGER),       --  10   0
      Db_Float      => (SQL_C_FLOAT,  SQL_REAL),          --   7 digits
      Db_Long_Float => (SQL_C_DOUBLE, SQL_FLOAT),         --  15 digits
      Db_String     => (SQL_C_BINARY, SQL_CHAR)
      );

   ------------------------------------------------
   --  Move - Utility routine only used by Fetch  -
   ------------------------------------------------
   procedure Move (Source      : in String;
                   Destination : in System.Address);

   ------------------------------------------------------------------------
   --  Conversion routines used internaly
   ----------------------------------------------------------------------
   type A_SDWORD is access all SDWORD;
   function To_A_SDWORD is new
     Ada.Unchecked_Conversion (System.Address, A_SDWORD);

    -----------------------------------------------------------------------
    --  Misc minor routines
    -----------------------------------------------------------------------
    procedure Report_Info (On : Boolean)
    is
    begin
       Info_Report := On;
    end Report_Info;

    ----------------------------------------------------------------------
    function Get_Sqlstate return String
    is
    begin
       return Last_Sqlstate;
    end Get_Sqlstate;

    ----------------------------------------------------------------------
    function Error_Text (Env  : HENV;
                         Dbc  : HDBC;
                         Stmt : HSTMT) return String
    is
       use Interfaces.C;
       Sqlstate   : aliased char_array (0..5);           -- Terminating nul
       Error_Code : aliased SDWORD;
       Message    : aliased char_array (0..400);
       Last       : aliased SWORD;
       Rc         : RETCODE;

       pragma Warnings (Off, Sqlstate);
       pragma Warnings (Off, Message);

    begin
       Rc := SQLError (Env, Dbc, Stmt, Sqlstate, Error_Code'Access,
                       Message, SWORD (Message'Length), Last'Access);
       return " (" & To_Ada (Sqlstate) & ") " & To_Ada (Message);
    end Error_Text;

    ------------------------------------------------------------------------
    --  Check return codes and report errors and transaction conflicts
    --  by raising exceptions
    --
    --  SQLSTATE 4001 Serialization failure - starts a rollback of the
    --  transaction, can't hurt
    ------------------------------------------------------------------------
    procedure Check_Retcode (Result : RETCODE;
                             Text   : String;
                             Dbc    : Connection_Handle := Null_Connection;
                             Stmt   : System.address    := System.Null_Address)
    is
    begin
       if Result = SQL_SUCCESS or else Result = SQL_NO_DATA_FOUND then
          null;
       elsif Result = SQL_SUCCESS_WITH_INFO then
          if Info_Report then
             Ada.Text_Io.Put_Line ("Info: " & Text &
                                   Error_Text (Environment,
                                               HDBC (Dbc),
                                               HSTMT (Stmt)));
          end if;
       else
          declare
             use Ada.Exceptions;
             Rc       : RETCODE;
             Message  : String := Error_Text (Environment,
                                              HDBC (Dbc),
                                              HSTMT (Stmt));
             Sqlstate : String (1..5);
          begin
             Sqlstate := Message (3..7);
             Last_Sqlstate := Sqlstate;
             if Sqlstate = "40001" then    --  Serialization Failure
                Rc := SQLTransact (Null_Env, HDBC (Dbc), SQL_ROLLBACK);
                Raise_Exception (Odbc_Transaction_Conflict'Identity,
                                 Text & Message);
             else
                Raise_Exception (Odbc_Error'Identity, Text & Message);
             end if;
          end;
       end if;
    end Check_Retcode;

    -------------------------------------------------------
    --  Connect to database                              --
    --  Uses command line parameters as DSN UID and PWD  --
    -------------------------------------------------------
    procedure Logon (Connection : out Connection_Handle)
    is
       use Ada.Command_Line;
       use Ada.Text_IO;
    begin
       case Argument_Count is
          when 1 =>
             Connect (Connection, Argument (1), "", "");
          when 2 =>
             Connect (Connection, Argument (1), Argument (2), "");
          when 3 =>
             Connect (Connection, Argument (1), Argument (2), Argument (3));
          when others =>
             Put_Line ("Syntax: " & Command_Name & " Dsn [Usr [Pwd]]");
             raise Program_error;
       end case;
    end Logon;

    -----------------------------------------
    --  Connect and login to the database  --
    -----------------------------------------
    procedure Connect (Connection : out Connection_Handle;
                       Source     : in  String;
                       Username   : in  String;
                       Password   : in  String;
                       Read_Only  : in  Boolean := False)
    is
       use Interfaces.C;
       Temp_Connection : aliased HDBC;
    begin
       --
       --  If not done, allocate environment
       --
       if Environment = Null_Env then
          Check_Retcode (SQLAllocEnv (Environment'Access), "AllocEnv" );
       end if;
       --
       --  Allocate connection and set options
       --
       Check_Retcode (SQLAllocConnect (Environment, Temp_Connection'Access),
                      "AllocConnect");
       Connection := Connection_Handle (Temp_Connection);
       --
       -- Rc := SQLSetConnectOption (Temp_Connection,
       --                            SQL_LOGIN_TIMEOUT,
       --                            30);
       -- Check_Retcode (Rc, "SetConnectOption - Login_Timeout", Connection);
       --
       Check_Retcode (SQLSetConnectOption (Temp_Connection,
                                           SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF),
                      "SetConnectOption - Auto_Commit", Connection);

       if Read_Only then
          Check_Retcode
            (SQLSetConnectOption (Temp_Connection,
                                  SQL_ACCESS_MODE, SQL_MODE_READ_ONLY),
             "SetConnectOption - Access_Mode", Connection);
       end if;

       Check_Retcode (SQLConnect (Temp_Connection,
                                  To_C (Source),   SQL_NTS,
                                  To_C (Username), SQL_NTS,
                                  To_C (Password), SQL_NTS),
                      "Connect", Connection);
       Data_Base := Connection;
    end Connect;

    --------------------------------
    --  Disconnect from database  --
    --------------------------------
    procedure Disconnect (Connection : in Connection_Handle) is
    begin
       --
       -- Do a Rollback - can't hurt
       --
       Rollback (Connection);

       Check_Retcode (SQLDisconnect (HDBC (Connection)),
                      "Disconnect", Connection);

       Check_Retcode (SQLFreeConnect (HDBC (Connection)),
                      "FreeConnect", Connection);

       Data_Base := Null_Connection;
    end Disconnect;

    -- ----------------------------------------------------------------------
    --  Get connection to current data base - Use if only one connection
    --  Se also Get_Connection (Cursor ...)
    -- ----------------------------------------------------------------------
    function Get_Connection return Connection_Handle is
    begin
       return Data_Base;
    end Get_Connection;

    -- ----------------------------------------------------------------------
    --  Get Connection handle associated with cursor
    -- ----------------------------------------------------------------------
    function Get_Connection (Cursor : Cursor_Type) return Connection_Handle
    is
    begin
       return Cursor.Connection;
    end Get_Connection;

    -- ----------------------------------------------------------------------
    --  Transaction control
    -- ----------------------------------------------------------------------

    --  Speciell hantering av Mimer
    --  ===========================
    --  Vid konflikter sätts SQLSTATE till 40001
    --  (40001) [MIMER][ODBC MIMER Driver][MIMER/DB]
    --         Transaction aborted due to conflict with other transaction
    --
    --  SQLSTATE = 40001 =>  Serialization failure
    --  Enligt MS dokumentation så förekommer detta vid
    --  SQLExecute/SQLExecDirect/SQLFetch/SQLExtendedFetch
    --  och följande förklaring ges:
    --   The transaction to which the prepared statement associated
    --   with the hstmt belonged was terminated to prevent deadlock.
    --
    --  Mimer returnerar detta först vid commit/rollback av transaktionen
    --
    --  Vid konflikt så trasslar det till sig vid nästa SQLExecute
    --  "Execute (24000) [Microsoft][ODBC Driver Manager] Invalid cursor state"
    --  men om man i det läget gör en Rollback så verkar det fungera
    --
    --  Tester med Solid Database visar att denna stämmer bättre med
    --  dokumentationen. Fel erhålles vid SQLExecute, se nedan
    --   raised ODBC2.ODBC_ERROR : Execute (40001)
    --   [Solid][SOLID ODBC Driver][SOLID Server]SOLID Database Error 10006:
    --   Concurrency conflict, two transactions updated or deleted the same row
    --  Solid kräver dessutom att man gör en SQL_CLOSE på "cursorn" för
    --  att inte ge Invalid Cursor State, kanske samma för Mimer ?
    --
    --  Lösning: Om sqlstate = 40001 i Check_retcode
    --             gör en rollback
    --             och raise odbc_transaction_conflict
    --
    --             Måste hanteras i anropande program
    --

    procedure Commit (Connection : in Connection_Handle) is
    begin
       Check_Retcode (SQLTransact (Null_Env, HDBC (Connection), SQL_COMMIT),
                      "Commit", Connection);
    end Commit;

    procedure Rollback (Connection : in Connection_Handle) is
    begin
       Check_Retcode (SQLTransact (Null_Env, HDBC (Connection), SQL_ROLLBACK),
                      "Rollback", Connection);
    end Rollback;

    procedure Auto_Commit (Connection : in Connection_Handle;
                           On         : in Boolean)
    is
       Off_On : constant array (Boolean) of UDWORD :=
         (False => SQL_AUTOCOMMIT_OFF, True => SQL_AUTOCOMMIT_ON);
    begin
       Check_Retcode (SQLSetConnectOption (HDBC (Connection),
                                           SQL_AUTOCOMMIT, Off_On (On)),
                      "SetConnectOption - Auto_Commit", Connection);
    end Auto_Commit;

    ------------------------------
    --  Test of cursor is open  --
    ------------------------------
    function Is_Open (Cursor : in Cursor_Type) return Boolean is
    begin
       return Cursor.Statement /= System.Null_Address;
    end Is_Open;

    --------------------
    --  Create query  --
    --------------------
    procedure Open (Cursor     : in out Cursor_Type;
                    Connection : in     Connection_Handle;
                    Sql_Query  : in     String;
                    Read_Only  : in     Boolean           := False;
                    Forward_Only : in   Boolean           := True)
    is
       use Interfaces.C;
       use Ada.Strings.Fixed;
       Temp_Statement : aliased HSTMT;
    begin
       --
       --  Check input
       --
       if Count (Sql_Query, "?") /= Cursor.Num_Params then
          Ada.Exceptions.Raise_Exception
            (Odbc_Error'Identity, "Open - wrong number of input paramaters");
       end if;

       for I in 1 .. Cursor.Num_Fields loop
          Cursor.Fields (I).Value_Length       := 0;
          Cursor.Fields (I).Temp_Array  := null;
          Cursor.Fields (I).Destination := System.Null_Address;
       end loop;

       Cursor.Connection := Connection;

       Check_Retcode (SQLAllocStmt (HDBC (Cursor.Connection),
                                    Temp_Statement'Access),
                      "Allocstmt", Connection);

       Cursor.Statement := System.Address (Temp_Statement);

       if Read_Only then
          Check_Retcode (SQLSetStmtOption (HSTMT (Cursor.Statement),
                                           SQL_CONCURRENCY,
                                           SQL_CONCUR_READ_ONLY),
                         "SetStmtOption - Concurrency",
                         Cursor.Connection, Cursor.Statement);
          --
          --      else
          --         Rc := SQLSetStmtOption (Cursor.Statement,
          --                                 SQL_CONCURRENCY,
          --                                 SQL_CONCUR_LOCK);
       end if;
       if not Forward_Only then
          Check_Retcode (SQLSetStmtOption (HSTMT (Cursor.Statement),
                                           SQL_CURSOR_TYPE,
                                           SQL_CURSOR_STATIC),
                         "SetStmtAttr - Scroll Type",
                         Cursor.Connection, Cursor.Statement);
       end if;

       Check_Retcode (SQLPrepare (HSTMT (Cursor.Statement),
                                  To_C (Sql_Query), Sql_Query'Length),
                      "Prepare", Cursor.Connection, Cursor.Statement);

    end Open;

    -----------------------------------------------------
    --  Close the query and free the statement handle  --
    -----------------------------------------------------
    procedure Close (Cursor : in out Cursor_Type)
    is
       procedure Free is new
         Ada.Unchecked_Deallocation (String,
                                     String_Pointer);
    begin
       if Cursor.Statement /= System.Null_Address then

          Check_Retcode (SQLFreeStmt (HSTMT (Cursor.Statement), SQL_DROP),
                         "FreeStmt", Cursor.Connection, Cursor.Statement);
          --
          -- Free temporary strings
          --
          for Column in 1 .. Cursor.Num_Fields loop
             Free (Cursor.Fields (Column).Temp_Array);
          end loop;

          Cursor.Statement := System.Null_Address;
       end if;

    end Close;

    function Create_Cursor(Connection   : Connection_Handle;
                           Query        : String;
                           Read_Only    : Boolean := False;
                           Forward_Only : Boolean := True) return Cursor_Type is
       use Interfaces.C;
       Num_Cols : aliased SWORD;
       Stmt : aliased HSTMT;
    begin
       -- open
       Check_Retcode (SQLAllocStmt (HDBC (Connection),
                                    Stmt'Access),
                      "Create_Cursor - Allocstmt", Connection);
       if Read_Only then
          Check_Retcode (SQLSetStmtOption (HSTMT (System.Address(Stmt)),
                                           SQL_CONCURRENCY,
                                           SQL_CONCUR_READ_ONLY),
                         "SetStmtOption - Concurrency",
                         Connection, System.Address(Stmt));
       end if;

       if not Forward_Only then
          Check_Retcode (SQLSetStmtOption (HSTMT (System.Address(Stmt)),
                                           SQL_CURSOR_TYPE,
                                           SQL_CURSOR_STATIC),
                         "SetStmtAttr - Scroll Type",
                         Connection, System.Address(Stmt));
       end if;

       Check_Retcode (SQLPrepare (HSTMT (System.Address(Stmt)),
                                  To_C (Query), Query'Length),
                      "Prepare", Connection, System.Address(Stmt));

       -- execute
       Check_Retcode (SQLExecute (HSTMT (System.Address(Stmt))),
                      "Create_Cursor - Execute", Connection, System.Address(Stmt));

       Check_Retcode (SQLNumResultCols (HSTMT (System.Address(Stmt)),
                                        Num_Cols'Access),
                      "Create_Cursor - NumResultCol",
                      Connection, System.Address(Stmt));
       declare
          Result : Cursor_Type(Integer(Num_Cols), 0);
       begin
          Result.Statement := System.Address(Stmt);
          Result.Connection := Connection;
          return Result;
       end;
    end Create_Cursor;

    -------------------------
    --  Execute the query  --
    -------------------------
    procedure Execute (Cursor : Cursor_Type)
    is
       use Ada.Exceptions;
       Num_Cols : aliased SWORD;
    begin
       Check_Retcode (SQLExecute (HSTMT (Cursor.Statement)),
                      "Execute", Cursor.Connection, Cursor.Statement);
       --
       --  Check that the right number of columns are returned from the query
       --
       if Cursor.Fields'Last > 0 then
          Check_Retcode (SQLNumResultCols (HSTMT (Cursor.Statement),
                                           Num_Cols'Access),
                         "Execute - NumResultCol",
                         Cursor.Connection, Cursor.Statement);

          if Integer (Num_Cols) /= Cursor.Fields'Last then
             Raise_Exception (Odbc_Error'Identity,
                              "Execute - Wrong number of result columns");
          end if;
       end if;
    end Execute;

    -----------------------------------
    --  Get number of affected rows  --
    -----------------------------------
    function Row_Count (Cursor : Cursor_Type) return Natural
    is
       use type Interfaces.Integer_32;
       Num_Rows : aliased SDWORD;
    begin
       Check_Retcode (SQLRowCount (HSTMT (Cursor.Statement), Num_Rows'Access),
                      "RowCount", Cursor.Connection, Cursor.Statement);
       if Num_Rows = -1 then
          -- Not available
          return 0;
       else
          return Natural (Num_Rows);
       end if;
    end Row_Count;

    ----------------------------------
    --  Retrieves info about column --
    ----------------------------------
    type Column_Descriptor is record
       Name : String(1..30);
       Col_Type : Column_Type;
       Size : Natural;
       Decimals : Natural;
    end record;

    function Describe_Column(Cursor : Cursor_Type; Column : Natural) return Column_Descriptor is
       Result : Column_Descriptor;
       Rc : RETCODE;
       Name : Interfaces.C.Char_Array(1..30);
       Name_Size,Sqltype,Scale,Nullable : aliased SQLSMALLINT;
       Col_Def : aliased SQLUINTEGER;
    begin
       Rc := SQLDESCRIBECOL(HSTMT (Cursor.Statement),
                            Interfaces.Unsigned_16(Column),
                            Name,
                            30,
                            Name_Size'Access,
                            Sqltype'Access,
                            Col_Def'Access,
                            Scale'Access,
                            Nullable'Access);
       Check_Retcode (Rc, "DescribeCol", Cursor.Connection, Cursor.Statement);
       Result.Name := (others => ' ');
       Result.Name(1 .. Integer(Name_Size)) := Interfaces.C.To_Ada (Name);
       case Sqltype is
          when SQL_CHAR | SQL_VARCHAR =>
             Result.Col_Type := String_Type;
          when SQL_NUMERIC | SQL_DECIMAL | SQL_FLOAT | SQL_REAL | SQL_DOUBLE =>
             Result.Col_Type := Float_Type;
          when SQL_INTEGER | SQL_SMALLINT =>
             Result.Col_Type := Integer_Type;
          when SQL_DATE =>
             Result.Col_Type := Date;
          when others =>
             Result.Col_Type := Unknown;
       end case;
       Result.Size := Integer(Col_Def);
       Result.Decimals := Integer(Scale);
       return Result;
    end Describe_Column;

    function Get_Column_Name (Cursor : Cursor_Type; Column : Natural) return String is
    begin
       return Describe_Column (Cursor, Column).Name;
    end Get_Column_Name;

    function Get_Column_Type (Cursor : Cursor_Type; Column : Natural) return Column_type is
    begin
       return Describe_Column (Cursor, Column).Col_Type;
    end Get_Column_Type;

    function Get_Column_Decimals (Cursor : Cursor_Type; Column : Natural) return Natural is
    begin
       return Describe_Column (Cursor, Column).Decimals;
    end Get_Column_Decimals;

    function Get_Column_Size (Cursor : Cursor_Type; Column : Natural) return Natural is
    begin
       return Describe_Column (Cursor, Column).Size;
    end Get_Column_Size;

    ------------------------
    --  Fetch the result  --
    ------------------------
    function Fetch (Cursor : Cursor_Type) return Status
    is
       Rc   : RETCODE;
    begin
       Rc := SQLFetch (HSTMT (Cursor.Statement));
       Check_Retcode (Rc, "Fetch", Cursor.Connection, Cursor.Statement);

       if Rc = SQL_SUCCESS or Rc = SQL_SUCCESS_WITH_INFO then
          for I in 1 .. Cursor.Num_Fields loop
             --
             -- If we are bound to a string, copy result to destination
             --
             if Cursor.Fields (I).Value_Length > 0 and
               Cursor.Fields (I).Destination /= System.Null_Address then

                Move (Cursor.Fields (I).Temp_Array.all,
                      Cursor.Fields (I).Destination);
             end if;
          end loop;
       end if;
       return Status (Rc);
    end Fetch;

    function  Fetch_Scroll   (Cursor : Cursor_Type;
                            Direction : Fetch_Direction;
                            Offset : Integer) return Status is

       Rc   : RETCODE;
       Dir : Interfaces.Integer_32;
    begin
       case Direction is
          when Next =>
             Dir := 1;
          when First =>
             Dir := 2;
          when Last =>
             Dir := 3;
          when Prior =>
             Dir := 4;
          when Absolute =>
             Dir := 5;
          when Relative =>
             Dir := 6;
       end case;
       Rc := SQLFetchScroll (HSTMT (Cursor.Statement), Dir, Interfaces.Integer_32(Offset));
       Check_Retcode (Rc, "FetchScroll", Cursor.Connection, Cursor.Statement);

       if Rc = SQL_SUCCESS or Rc = SQL_SUCCESS_WITH_INFO then
          for I in 1 .. Cursor.Num_Fields loop
             --
             -- If we are bound to a string, copy result to destination
             --
             if Cursor.Fields (I).Value_Length > 0 and
               Cursor.Fields (I).Destination /= System.Null_Address then

                Move (Cursor.Fields (I).Temp_Array.all,
                      Cursor.Fields (I).Destination);
             end if;
          end loop;
       end if;
       return Status (Rc);
    end Fetch_Scroll;

    -----------------------------------------------------
    --  Clear - discard pending results in result set  --
    -----------------------------------------------------
    procedure Clear (Cursor : Cursor_Type) is
    begin
       Check_Retcode (SQLFreeStmt (HSTMT (Cursor.Statement), SQL_CLOSE),
                      "FreeStmt - Close", Cursor.Connection, Cursor.Statement);
    end Clear;

    ------------------------------------------------------------------------
    --  Get length of the column in the database - may be larger than
    --  what has been written, Trailing space seems to be ignored if the
    --  receiving string is to small for MIMER.
    ------------------------------------------------------------------------
    function Get_Length (Cursor : Cursor_Type;
                         Column : Positive) return Integer is
    begin
       return Integer (Cursor.Fields (Column).Value_Length);
    end Get_Length;

    ---------------------------------------
    --  Check if a result column is NULL  --
    ----------------------------------------
    function Is_Null (Cursor : Cursor_Type;
                      Column : Positive) return Boolean is
    begin
       return Get_Length (Cursor, Column) = SQL_NULL_DATA;
    end Is_Null;

    ----------------------------------------------
    --  Bind result column to program variable  --
    ----------------------------------------------
    procedure Bind_Output (Cursor        : in out Cursor_Type;
                           Column        : in     Positive;
                           Variable_Type : in     Data_Type;
                           Variable_Addr : in     System.Address;
                           Variable_Size : in     Integer := 0)
    is
    begin
       Cursor.Fields (Column).Value_Length  := Variable_Size;

       Check_Retcode (SQLBindCol (HSTMT (Cursor.Statement),
                                  UWORD (Column),
                                  Sql_To_C (Variable_Type).C_Value,
                                  Variable_Addr,
                                  SDWORD (Variable_Size),
                                  To_A_SDWORD (Cursor.Fields
                                               (Column).Value_Length'Address)),
                      "BindCol", Cursor.Connection, Cursor.Statement);

    end Bind_Output;

    -------------------------------------------------
    --  Bind result column to an Integer variable  --
    -------------------------------------------------
    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  : access Integer) is
    begin
       Bind_Output (Cursor, Column, Db_Integer, Value.all'Address, 0);
    end Bind_Output;

    -------------------------------------------------
    --  Bind result column to a Float variable  --
    -------------------------------------------------
    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  : access Float) is
    begin
       Bind_Output (Cursor, Column, Db_Float, Value.all'Address, 0);
    end Bind_Output;

    -------------------------------------------------
    --  Bind result column to a Long_Float variable  --
    -------------------------------------------------
    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  : access Long_Float) is
    begin
       Bind_Output (Cursor, Column, Db_Long_Float, Value.all'Address, 0);
    end Bind_Output;

    -----------------------------------------------
    --  Bind result column to a string variable  --
    -----------------------------------------------
    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  :    out String)
    is
    begin
       --
       -- Allocate a temporary array with an extra element to hold
       -- the terminating null from SQLFetch
       --
       Cursor.Fields (Column).Temp_Array := new String (1 .. Value'Length + 1);
       --
       -- Save destination address for later use
       --
       Cursor.Fields (Column).Destination := Value (Value'First)'Address;
       --
       -- The SQLFetch function will store the result into Temp_Array
       -- and we will then move the result excluding the null to the real
       -- destination
       --
       Bind_Output (Cursor,
                    Column,
                    Db_Char,
                    Cursor.Fields (Column).Temp_Array.all (1)'Address,
                    Value'Length + 1);

    end Bind_Output;

    -----------------------------------------------------------
    --  Set length or the value NULL for an input parameter  --
    -----------------------------------------------------------
    Procedure Set_Length (Cursor : in out Cursor_Type;
                          Param  : in     Positive;
                          Length : in     Integer)
    is
    begin
       Cursor.Params (Param).Value_Length := Length;
       Cursor.Params (Param).Saved_Length := Length;
    end Set_Length;

    ----------------------------------------------------------------------
    procedure Set_Null (Cursor  : in out Cursor_Type;
                        Param   : in     Positive;
                        Is_Null : in     boolean) is
    begin
       if Is_Null then
          Cursor.Params (Param).Value_Length := SQL_NULL_DATA;
       else
          Cursor.Params (Param).Value_Length :=
            Cursor.Params (Param).Saved_Length;
       end if;
    end Set_Null;

    --------------------------------------------------------
    --  Bind input parameter markers to program variable  --
    --------------------------------------------------------
    procedure Bind_Input (Cursor        : in out Cursor_Type;
                          Param         : in     Positive;
                          Variable_Type : in     Data_Type;
                          Variable_Addr : in     System.Address;
                          Variable_Size : in     Integer := 0)
    is
       rc : RETCODE;
    begin
       Cursor.Params (Param).Value_Length := Variable_Size;
       Cursor.Params (Param).Saved_Length := Variable_Size;

       Rc := SQLBindParameter (HSTMT (Cursor.Statement),         --  hstmt
                               UWORD (Param),                    --  ipar
                               SQL_PARAM_INPUT,                  --  fParamType
                               Sql_To_C (Variable_Type).C_Value, --  fCType
                               Sql_To_C (Variable_Type).Sql_Value, --  fSqlType
                               UDWORD (Variable_Size),           --  cbColDef
                               0,                                --  ibScale
                               Variable_Addr,                    --  rgbValue
                               SDWORD (Variable_Size),           --  cbValueMax
                               To_A_SDWORD (Cursor.Params
                                            (Param).Value_Length'Address));
                                                                 --  pcbValue
       Check_Retcode (Rc, "BindParameter",
                      Cursor.Connection, Cursor.Statement);
    end Bind_Input;

    ---------------------------------------------
    --  Bind an input parameter to an Integer  --
    ---------------------------------------------
    procedure Bind_Input (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : access Integer) is
    begin
       Bind_Input (Cursor, Column, Db_Integer, Value.all'Address);
    end;
    ---------------------------------------------
    --  Bind an input parameter to a Float     --
    ---------------------------------------------

    procedure Bind_Input (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : access Float) is
    begin
       Bind_Input (Cursor, Column, Db_Integer, Value.all'Address);
    end;
    ------------------------------------------------
    --  Bind an input parameter to an Long_Float  --
    ------------------------------------------------

    procedure Bind_Input (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : access Long_Float) is
    begin
       Bind_Input (Cursor, Column, Db_Integer, Value.all'Address);
    end;

    -------------------------------------------
    --  Bind an input parameter to a string  --
    -------------------------------------------
    procedure Bind_Input (Cursor   : in out Cursor_Type;
                          Param    : in     Positive;
                          Variable : in     String) is
    begin
       Bind_Input (Cursor, Param, Db_Char,
                   Variable (Variable'First)'Address, Variable'Length);
    end Bind_Input;

    ---------------------------------------------------------
    -- Move - Procedure to transfer a null terminated
    -- string from the database to the address of the
    -- real destination string without the nul and with
    -- extra spaces added if the destination is longer
    -- than the result from the database
    --
    -- The length of the destination is one element
    -- less than the source string
    --------------------------------------------------------
   procedure Move (Source      : in String;
                   Destination : in System.Address)
   is
      use type System.Storage_Elements.Storage_Offset;

      package Character_Access is new
        System.Address_To_Access_Conversions (Character);

      Index      : System.Storage_Elements.Storage_Offset := 0;
      Before_Nul : Boolean := True;
      Char       : Character;
   begin
      for I in Source'First .. Source'Last - 1 loop
         if Before_Nul then
            Char := Source (I);
            if Char = Character'Val (0) then
               Char       := ' ';
               Before_Nul := False;
            end if;
         end if;
         Character_Access.To_Pointer (Destination + Index).all := Char;
         Index := Index + 1;
      end loop;
   end Move;

end Odbc2;
