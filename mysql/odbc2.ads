--                              -*- Mode: Ada -*-
--  Filename        : odbc2.ads
--  Author          : Sune Falck
--  Created On      : Tue Nov 04 16:14:18 1997
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
-- HISTORY
--
-- 1999-07-09   Sune Falck
--    Added Bind_Output/Bind_Input for access to Integer, Float and Long_Float
--
-- 1999-05-10   Sune Falck
--    Changed mode for Cursor in Open to in out
--
-- 1999-04-20   Sune Falck
--    Changes to the private part of the specification, added
--    destination length for field and used chars_ptr:s from
--    interfaces.c.strings
--
-- 97-10-04 Sune Falck  Changed Execute to procedure
--                      Added Procedure Logon
--
-- 97-10-05 Sune Falck  Added function Get_Sqlstate to be used in
--                      exception routines for analysing the cause
--                      of the odbc exception
--
-- 97-11-08 Sune Falck  Added Auto_Commit routine and Read_Only
--                      parameter for Connect
--
-- 97-12-02 Sune Falck  Added Set_Not_Null and modified cursor record
--                      for saving old length
with System;

package Odbc2 is
   pragma Elaborate_Body (Odbc2);

   -- ----------------------------------------------------------------------
   --  Types used in package
   -- ----------------------------------------------------------------------

   Odbc_Error                : exception;
   Odbc_Transaction_Conflict : exception;

   type Connection_Handle is private;

   type Cursor_Type (Num_Fields : Natural := 0;
                     Num_Params : Natural := 0) is private;

   type Status is private;
   Db_Success           : constant Status;
   Db_Success_With_Info : constant Status;
   Db_No_Data_Found     : constant Status;
   Db_Error             : constant Status;


   type Data_Type is (Db_Char,  Db_Smallint,   Db_Integer,
                      Db_Float, Db_Long_Float, Db_String);

   -- ----------------------------------------------------------------------
   --  Report all occurences of SQL_SUCCESS_WITH_INFO on stdout
   -- ----------------------------------------------------------------------
   procedure Report_Info (On : Boolean);

   -- ----------------------------------------------------------------------
   --  Get SQLSTATE corrsponding to last odbc exception
   -- ----------------------------------------------------------------------
   function Get_Sqlstate return String;    --  Returns a 5 chars long string
                                           --  with the ODBC SQLSTATE
   -- ----------------------------------------------------------------------
   --  Connect/disconnect from database
   -- ----------------------------------------------------------------------
   procedure Logon (Connection : out Connection_Handle);

   Command_Syntax_Error : exception;

   --
   --  Read DSN, user and password from command line and connect
   --  raise Command_Syntax_Error if not 3 command arguments on command line
   --

   procedure Connect (Connection :    out Connection_Handle;
                      Source     : in     String;
                      Username   : in     String;
                      Password   : in     String;
                      Read_Only  : in     Boolean := False);

   procedure Disconnect (Connection : in Connection_Handle);

   function Get_Connection return Connection_Handle;  --  Current Connection

   function Get_Connection (Cursor : in Cursor_type) return Connection_Handle;

   -- ----------------------------------------------------------------------
   --  Transactions, affects all statements on a connection
   -- ----------------------------------------------------------------------

   procedure Commit (Connection : in Connection_Handle);

   procedure Rollback (connection : in Connection_handle);
   --
   --  The exception ODBC_TRANSACTION_CONFLICT is raised if
   --  any routine returns serialization failure (41000)
   --
   procedure Auto_Commit (Connection : in Connection_Handle;
                          On         : in Boolean);
   -- Default is manual commit

   -- ----------------------------------------------------------------------
   --  Open/Close statement
   -- ----------------------------------------------------------------------

   procedure Open (Cursor     : in out Cursor_Type;
                   Connection : in     Connection_Handle;
                   Sql_Query  : in     String;
                   Read_Only  : in     Boolean := False;
                   Forward_Only : in   Boolean := True);

   procedure Close (Cursor : in out Cursor_Type);
   -- Frees allocated resources and calls SQL_DROP on the statement
   -- It is a no-op to close a non open cursor

   function Create_Cursor(Connection   : Connection_Handle;
                          Query        : String;
                          Read_Only    : Boolean := False;
                          Forward_Only : Boolean := True) return Cursor_Type;

   function Is_Open (Cursor : in Cursor_type) return Boolean;

   -- ----------------------------------------------------------------------
   --  Operations on statement
   -- ----------------------------------------------------------------------

   --
   --  Execute prepared query created by Open
   --
   procedure  Execute (Cursor : Cursor_Type);
   --
   --  Get number of rows affected for insert/update/delete command
   --
   function  Row_Count (Cursor : Cursor_Type) return Natural;
   --
   --  Retrieves info about a column
   --
   type Column_Type is (Integer_Type, Float_Type, String_Type, Date, Unknown);
   function Get_Column_Name (Cursor : Cursor_Type; Column : Natural) return String;
   function Get_Column_Size (Cursor : Cursor_Type; Column : Natural) return Natural;
   function Get_Column_Decimals (Cursor : Cursor_Type; Column : Natural) return Natural;
   function Get_Column_Type (Cursor : Cursor_Type; Column : Natural) return Column_Type;

--
   --  Fetch results from select
   --
   function  Fetch   (Cursor : Cursor_Type) return Status;
   type Fetch_Direction is (Next, First, Last, Prior, Absolute, Relative);
   function  Fetch_Scroll   (Cursor : Cursor_Type;
                             Direction : Fetch_Direction;
                             Offset : Integer) return Status;
   --
   --  Clear cursor, discard pending results (SQL_CLOSE)
   --
   procedure Clear   (Cursor : Cursor_Type);

   -----------------------------------------------------------------------
   --  Bindning of program variables to results from a query
   --  (Column is the output column number starting with 1 for the first)
   -- --------------------------------------------------------------------
    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  : access Integer);

    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  : access Float);

    procedure Bind_Output (Cursor : in out Cursor_Type;
                           Column : in     Positive;
                           Value  : access Long_Float);

   procedure Bind_Output (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : out    String);

   procedure Bind_Output (Cursor        : in out Cursor_Type;
                          Column        : in     Positive;
                          Variable_Type : in     Data_Type;
                          Variable_Addr : in     System.Address;
                          Variable_Size : in     Integer := 0);

   -- Variable_Size only used for strings etc but this routine also returns
   -- a trailing nul to the destination string if type = Db_Char

   -- -------------------------------------------------------------------
   --  Query result after a Fetch operation
   ----------------------------------------------------------------------

   function Get_Length (Cursor : in Cursor_Type;
                        Column : in Positive) return Integer;

   -- Returns the actual length of string data in the database

   function Is_null (Cursor : in Cursor_Type;
                     Column : in Positive) return boolean;

   -- Check for NULL value in the database

   -- --------------------------------------------------------------------
   --  Binding of program variabales to input parameters marked with ?
   --  in a SQL-statement.
   --  (Param is the order number for the input parameter in the query
   --  starting with 1 for the first).
   -- --------------------------------------------------------------------
    procedure Bind_Input (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : access Integer);

    procedure Bind_Input (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : access Float);

    procedure Bind_Input (Cursor : in out Cursor_Type;
                          Column : in     Positive;
                          Value  : access Long_Float);

   procedure Bind_Input (Cursor   : in out Cursor_type;
                         Param    : in     Positive;
                         Variable : in     String);

   procedure Bind_Input (Cursor        : in out Cursor_Type;
                         Param         : in     Positive;
                         Variable_Type : in     Data_Type;
                         Variable_Addr : in     System.Address;
                         Variable_Size : in     Integer := 0);

   procedure Set_Length (Cursor : in out Cursor_Type;
                         Param  : in     Positive;
                         Length : in     Integer);

   -- Internally used by Set_Null

   procedure Set_Null (Cursor  : in out Cursor_Type;
                       Param   : in     Positive;
                       Is_Null : in     boolean);

   -- Set an input value to NULL

private

   --
   -- Data base connection
   --
   type Connection_Handle is new System.Address;

   --
   -- Status from Fetch
   --
   type Status is new Integer;
   Db_Success           : constant Status := 0;
   Db_Success_With_Info : constant Status := 1;    -- Truncated data
   Db_No_Data_Found     : constant Status := 100;  -- End Of Data
   Db_Error             : constant Status := -1;

   -- --------------------------------------------------------------------
   --  Cursor_Type - Internal data structure to used to describe a
   --  SQL-statement with result columns (fields) and input parameters
   --
   --  A SQL-query like "SELECT NUMBER, TEXT FROM TEST WHERE NUMBER > ?"
   --  has two output columns and one input variable and the corresponding
   --  Cursor variable must be declared like "Query : Cursor_type (2, 1);"
   -----------------------------------------------------------------------

   --
   -- Description of an output program variable.
   -- Destination_Length, Temp_Array and Destination are used
   -- to handle output of string data which are fetched into
   -- an temporary array and then moved to the real destination
   -- without the trailing nul from the database routines.
   --
   type String_Pointer is access String;
   type Field is record
      Value_Length       : aliased Integer := 0;
      Temp_Array         : String_Pointer := null;
      Destination        : System.Address := System.Null_Address;
   end record;
   --
   -- Description of an input variable, used to signal that
   -- the data is a NULL value.
   --
   type Param is record
      Value_Length : aliased Integer := 0;
      Saved_Length : aliased Integer := 0;
   end record;

   --
   -- Arrays of descriptions for output columns (fields) and
   -- input data
   --
   subtype Field_Index is Integer range 1..20;
   type Fields_Array is array (Field_Index range <>) of Field;
   type Params_Array is array (Field_Index range <>) of Param;

   --
   --  Description of a SQL-statement
   --
   type Cursor_Type (Num_Fields : Natural := 0;
                     Num_Params : Natural := 0) is
      record
         Connection : Connection_Handle := Connection_Handle (System.Null_Address);
         Statement  : System.Address    := System.Null_Address;
         Fields     : Fields_Array (1..Num_Fields);
         Params     : Params_Array (1..Num_Params);
      end record;
end Odbc2;
