----------------------------------------------------------------------
-- Package Tracer (body)                                            --
-- (C) Copyright 1997, 2021 ADALOG                                  --
-- Author: J-P. Rosen                                               --
--                                                                  --
--  ADALOG   is   providing   training,   consultancy,   expertise, --
--  assistance and custom developments  in Ada and related software --
--  engineering techniques.  For more info about our services:      --
--  ADALOG                          Tel: +33 1 45 29 21 52          --
--  2 rue du Docteur Lombard        Fax: +33 1 45 29 25 00          --
--  92441 ISSY LES MOULINEAUX CEDEX E-m: info@adalog.fr             --
--  FRANCE                          URL: https://www.adalog.fr      --
--                                                                  --
--  This  unit is  free software;  you can  redistribute  it and/or --
--  modify  it under  terms of  the GNU  General Public  License as --
--  published by the Free Software Foundation; either version 2, or --
--  (at your  option) any later version.  This  unit is distributed --
--  in the hope  that it will be useful,  but WITHOUT ANY WARRANTY; --
--  without even the implied warranty of MERCHANTABILITY or FITNESS --
--  FOR A  PARTICULAR PURPOSE.  See the GNU  General Public License --
--  for more details.   You should have received a  copy of the GNU --
--  General Public License distributed  with this program; see file --
--  COPYING.   If not, write  to the  Free Software  Foundation, 59 --
--  Temple Place - Suite 330, Boston, MA 02111-1307, USA.           --
--                                                                  --
--  As  a special  exception, if  other files  instantiate generics --
--  from  this unit,  or you  link this  unit with  other  files to --
--  produce an executable,  this unit does not by  itself cause the --
--  resulting executable  to be covered  by the GNU  General Public --
--  License.  This exception does  not however invalidate any other --
--  reasons why  the executable  file might be  covered by  the GNU --
--  Public License.                                                 --
----------------------------------------------------------------------

with    -- Standard Ada units
  Ada.Calendar,
  Ada.Characters.Handling,
  Ada.Strings.Fixed,
  Ada.Task_Attributes,
  Ada.Text_IO;

with    -- Reusable components
  Protection;
pragma Elaborate_All (Protection);

with    -- Application specific units
  Tracer_Messages;
package body Tracer is
   use Tracer_Messages, Ada.Task_Identification;

   -- This package is a bit big, but splitting it into child units
   -- would introduce some difficulties without much benefit for the
   -- user (see file debugimp.htm for a full discussion of this
   -- issue).
   --
   -- It is however divided in a number of "sections", summarized below.
   -- A text search on the name of a section should bring you there faster
   -- than opening another file containing a child unit...
   --
   -- SECTION GLOBAL ELEMENTS:
   --   General types, constants, global variables.
   -- SECTION AUTODEBUG:
   --   Some procedures used to debug Debug itself, or for the diagnosis
   --   of internal failures.
   -- SECTION SERVICES:
   --   internal utilities, not exported by Debug
   -- SECTION PROVIDED SUBPROGRAMS:
   --   implementation of subprograms provided in the specification of Debug


   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------
   --
   -- SECTION GLOBAL ELEMENTS
   --
   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------

   -------------------------------------------------------------------------
   --  General types and constants
   -------------------------------------------------------------------------

   Input_Length : constant Positive := 80;
   -- Maximum length of an input line

   type Debug_Mode is (Silent, Mono_Task, Multi_Task);

   -- Type to represent indentation levels, etc.
   -- We have no clear requirement for bounds here, so let's get the
   -- biggest range possible.
   type    Big_Int     is range System.Min_Int .. System.Max_Int;
   subtype Big_Counter is Big_Int range 0..Big_Int'Last;
   No_Pause : constant Big_Counter := 0;
   Step     : constant Big_Counter := 1;

   Main_Task : constant Task_Id := Current_Task;

   --
   --  The following are variables controlling the behaviour of Debug.
   --  Since they are global and potentially shared, each variable is
   --  followed by its access conditions and possible associated pragma
   --

   Timer_Id : Task_Id;
   Proxy_Id : Task_Id;
   -- ID's of Debug's internal tasks.
   -- Set only once in the statement part of the body. No concurrent
   -- execution is possible at that point (there may be other tasks
   -- running, but they cannot call Debug).

   Debug_File_Input : Boolean := False;
   --  True if Debug reads input from a file rather than the keyboard.
   --  Set in the statement part of the body and Unprotected_Pause, read
   --  from Unprotected_Pause which are protected from concurrent execution

   Input_File : Ada.Text_Io.File_Type;
   -- File variable for reading commands (trace.ini).
   -- Set only once in the statement part of the body. No concurrent
   -- execution is possible at that point (there may be other tasks
   -- running, but they cannot call Debug).

   Debug_Output : Ada.Text_Io.File_Access := Ada.Text_Io.Current_Error;
   --  Access to the file used for actual trace output
   --  Set in Set_Target_Unprotected, and read from Print, which
   --  are protected from concurrent execution

   Trace_File : aliased Ada.Text_Io.File_Type;
   --  File variable for traces to file.
   --  Set in Set_Target_Unprotected, which is protected from concurrent
   --  execution. Pointed at by Debug_Output.

   Source : Trace_Source := All_Tasks;
   pragma Atomic (Source);
   --  Describes which tasks are allowed to provide traces.
   --  Set in Set_Source (simple assignment), read from various places.
   --  Atomic is sufficient for protection.

   Target : Trace_Target := Console;
   pragma Atomic (Target);
   --  Describes the destination of trace messages.
   --  Set in Set_Target_Unprotected, which is protected from concurrent
   --  execution, but read asynchronously by Pause. Atomic is sufficient.

   Current_Mode : Debug_Mode := Mono_Task;
   pragma Atomic (Current_Mode);
   --  Execution mode (Silent, mono-task or multi-task).
   --  Set in Print and Unprotected_Pause, which are protected
   --  from concurrent execution, but read asynchronously from various
   --  places.
   --  Atomic is sufficient.

   Always_Blocking : Boolean := True;
   pragma Atomic (Always_Blocking);
   --  Tells whether Flush should try to not block if another task is
   --  currently flushing, or not.
   --  Set in Execute_Commands and read asynchronously from Flush_Trace.
   --  Atomic is sufficient.

   Dont_Wait_Count : Big_Counter := No_Pause;
   --  Number of messages that are printed without pausing.
   --  0 = Never pause.
   --  Set in Unprotected_Pause, read in Print, which are
   --  protected from concurrent execution.

   Previous_Go : Big_Counter := Dont_Wait_Count;
   --  Memorizes the value of Dont_Wait_Count from previous "go" command
   --  (= Go command to be repeated if the user types "enter")
   --  Set and read in Unprotected_Pause, which is protected from
   --  concurrent execution.

   Previous_Task : Task_Id := Main_Task;
   --  ID of the task that printed the previous message, in order to
   --  track task switches
   --  Set and read in Unprotected print, which is protected from concurrent
   --  execution.

   Exclusion : aliased Protection.Semaphore;
   --  Global semaphore used to protect Flush, Pause, Set_Target and Set_Watch
   --  from concurrent execution.
   --  It is a protected object, no further protection needed.

   User_Watch : Procedure_Access;
   --  Pointer to a user-defined watch procedure
   --  Set by Unprotected_Set_Watch, used by Unprotected_Pause, which are
   --  protected from concurrent execution.

   Aborting_Main : Boolean := False;
   pragma Atomic (Aborting_Main);
   --  True when Abort_Main has been called.
   --  Set by Abort_Main, used by Display_Status and Unprotected_Flush
   -- (never reset).  Atomic is sufficient for protection on reading.

   New_Message : Boolean := True;
   -- True when at the start of a new message, implying that the
   -- "** Debug **" must be printed.
   -- Set by Console_Output and Execute_Commands, checked by
   -- Console_Output which are protected from concurrent execution.


   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------
   --                                                                        --
   --                           SECTION AUTODEBUG                            --
   --                                                                        --
   -- This section contains internal utilities for debugging Debug, and      --
   -- managing internal Debug errors.                                        --
   --                                                                        --
   -- These procedures (and all calls to them) can be removed from a         --
   -- working version. But after all, the whole package Debug could be       --
   -- removed from a working version...  We chose to leave them,             --
   -- because they're harmless, and can be very useful to those who          --
   -- want to bring improvements to the module.                              --
   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------

   -----------------
   -- Debug_Error --
   -----------------

   --
   --  Internal error procedure.
   --  Called when an unexpected exception is raised within Debug
   --

   procedure Debug_Error (Problem : Ada.Exceptions.Exception_Occurrence;
                          Where   : String)
   is
      --  We don't care about protection at this level.
      --  Since this procedure actually prints something, it is erroneous if
      --  the offending procedure was called from a protected object.
      --  Well, since it is not supposed to be called at all...
      use Ada.Text_Io, Ada.Exceptions;
      Message     : constant String := Exception_Message (Problem);
      Information : constant String := Exception_Information (Problem);
   begin
      --  We should use the Print procedure, but at this level
      --  there is nothing we can trust, so we allow ourself no other service.
      Set_Col (Debug_Output.all, 1);
      Put (Debug_Output.all, Tracer_Message);
      Put (Debug_Output.all, Trace_Message);
      Put (Debug_Output.all, Where);
      Put (Debug_Output.all, " : ");
      Put (Debug_Output.all, Exception_Name (Problem));
      New_Line (Debug_Output.all);
      if Message /= "" then
         Put (Debug_Output.all, Tracer_Message);
         Put (Debug_Output.all, "   ");
         Put (Debug_Output.all, Bug_Mess_Message);
         Put (Debug_Output.all, Message);
         New_Line (Debug_Output.all);
      end if;
      if Information /= "" then
         Put (Debug_Output.all, Tracer_Message);
         Put (Debug_Output.all, "   ");
         Put (Debug_Output.all, Bug_Info_Message);
         Put (Debug_Output.all, Information);
         New_Line (Debug_Output.all);
      end if;

      --  Reraise the exception, so we will get the stack trace
      --  (All calling procedures will call Debug_Error in turn)
      Reraise_Occurrence (Problem);
   end Debug_Error;

   ------------
   -- Itrace --
   ------------

   --
   --  Internal trace procedure
   --

   Itrace_Protected : constant Boolean := True;
   --  If this constant is true, ITrace calls are mutually exclusive with
   --  other Debug facilities. Leave it to True, unless you are in a situation
   --  where you don't trust package Protection either.

   Itrace_Active : constant Boolean := True;
   --  When false, disables ITrace.
   --  Used when you want to leave ITrace calls into your code...

   procedure Itrace (Message : String) is
      use Ada.Text_Io;

      -- File used for Itrace output
      -- Normally, the same as Debug_Output, but it may be convenient to
      -- have Itrace output different from "regular" Debug output
      -- (f.e. Standard_Output). Change the following constant if needed
      Itrace_Output : constant File_Access := Debug_Output;
   begin
      if not Itrace_Active then  --## rule line off SIMPLIFIABLE_STATEMENTS ## Conditional compilation
         return;
      end if;

      if Itrace_Protected then  --## rule line off SIMPLIFIABLE_STATEMENTS ## Conditional compilation
         Exclusion.P;
      end if;

      Set_Col (Itrace_Output.all, 1);
      Put (Itrace_Output.all, "+++ (");
      Put (Itrace_Output.all, Image (Current_Task));
      Put (Itrace_Output.all, ") ");
      Put (Itrace_Output.all, Message);
      New_Line (Itrace_Output.all);

      if Itrace_Protected then  --## rule line off SIMPLIFIABLE_STATEMENTS ## Conditional compilation
         Exclusion.V;
      end if;
   exception
      when Occur: others =>
         if Itrace_Protected and then Exclusion.Holder = Current_Task then
            Exclusion.V;
         end if;
         Debug_Error (Occur, "ITrace");
   end Itrace;


   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------
   --                                                                        --
   --                            SECTION SERVICES                            --
   --                                                                        --
   ----------------------------------------------------------------------------
   ----------------------------------------------------------------------------


   -------------------------------------------------------------------------
   --  Management of task attributes
   -------------------------------------------------------------------------

   --  type of information stored as a task attribute.
   type Local_Information is
   record
      Level  : Big_Counter;  --  Indentation level
      Marked : Boolean;      --  True if task is marked
   end record;
   package Task_Info_Package is
      new Ada.Task_Attributes (Local_Information,
                               (Level => 0, Marked => False));

   ---------------
   -- Task_Info --
   ---------------

   --
   --  Protected object to access task attributes
   --  Since Set_registration allows a task to change attributes from other
   --  tasks, it is necessary to protect accesses against concurrency
   --

   protected Task_Info is
      procedure Set_Level (Difference : Big_Int);  --  Always on Current_Task
      function  Get_Level return Big_Counter;      --  Always on Current_Task

      procedure Set_Mark  (To : Boolean; On : Task_Id);
      function  Is_Marked (On : Task_Id) return Boolean;
   end Task_Info;

   protected body Task_Info is
      procedure Set_Level (Difference : Big_Int) is
         use Task_Info_Package;
         Info : Local_Information := Value;
      begin
         Info.Level := Info.Level + Difference;
         Set_Value (Info);
         --  No Tasking_Error can happen, since this Set_Value operates on
         --  Current_Task
      end Set_Level;

      function  Get_Level return Big_Counter is
         use Task_Info_Package;
      begin
         return Value.Level;
         --  No Tasking_Error can happen, since this Value operates on
         --  Current_Task
      end Get_Level;

      procedure Set_Mark (To : Boolean; On : Task_Id)is
         use Task_Info_Package;
         Info : Local_Information; -- Do not use initialization
                                   -- since we want to catch Tasking_Error
      begin
         Info        := Value (On);
         Info.Marked := To;
         Set_Value (Info, On);
      exception
         when Tasking_Error =>  --  On is terminated (C.7.2(13))
            null;
      end Set_Mark;

      function Is_Marked (On : Task_Id) return Boolean is
         use Task_Info_Package;
      begin
         return Value (On).Marked;
      exception
         when Tasking_Error =>  --  On is terminated (C.7.2(13))
            return False;
      end Is_Marked;
   end Task_Info;


   -------------------------------------------------------------------------
   --  Misc. utilities
   -------------------------------------------------------------------------

   -----------
   -- Timer --
   -----------

   --
   --  Timer management
   --

   task Timer is
      entry Set_Delay (How_Long : Duration; Processing : Procedure_Access);
      entry Cancel_Delay;
      entry Suspend;
      entry Resume;
      entry Get_Remaining_Time (Remaining_Time : out Duration);

      pragma Priority (System.Priority'Last);
   end Timer;

   task body Timer is
      -- The Timer is an abstract state machine.
      -- Each call moves it from a state to another (or the same) one
      -- This behaviour is properly modelled with Goto's...
      -- Presumably the last proper use of Goto's in Ada.

      use Ada.Calendar;

      Remaining     : Duration;      --  Remaining time while suspended
      End_Time      : Time;          --  Absolute end time for the timer
      Timer_Proc    : Procedure_Access := Pause'Access;
      Suspend_Level : Natural := 0;  --  /= 0 when suspended

      --  A proxy subtask is used to execute Timer_Proc
      --  to prevent dead-locks if Timer_Proc calls Timer operations
      --  (like setting a new delay with Set_Delay)
      task Proxy is
         entry Process (Subprogram : Procedure_Access);
         pragma Priority (System.Priority'Last);
      end Proxy;
      task body Proxy is
         To_Process : Procedure_Access;
      begin
         loop
            select
               accept Process (Subprogram : Procedure_Access) do
                  To_Process := Subprogram;
               end Process;
               begin
                  Trace (Timer_Message);
                  To_Process.all;
               exception
                  when Occur : others =>
                     Trace (Timer_Exception_Message, Occur);
               end;
            or
               terminate;
            end select;
         end loop;
      end Proxy;

   begin   --  Timer
      Timer_Id := Timer'Identity;  --  Note ID's of Debug's tasks
      Proxy_Id := Proxy'Identity;

      <<Inactive_State>>
      select
         accept Set_Delay (How_Long   : Duration;
                           Processing : Procedure_Access)
         do
            Remaining := How_Long;
            if Processing /= null then
               Timer_Proc := Processing;
            end if;
         end Set_Delay;
         if Suspend_Level = 0 then
            End_Time  := Clock + Remaining;
            goto Active_State;
         else
            goto Suspended_State;
         end if;
      or
         accept Get_Remaining_Time (Remaining_Time : out Duration) do
            Remaining_Time := Off;
         end Get_Remaining_Time;
         goto Inactive_State;
      or
         accept Cancel_Delay;   --  Ignored entry call in this state
         goto Inactive_State;
      or
         accept Suspend;
         Suspend_Level := Suspend_Level + 1;
         goto Inactive_State;
      or
         accept Resume;
         if Suspend_Level > 0 then
            Suspend_Level := Suspend_Level - 1;
         end if;
         goto Inactive_State;
      or
         terminate;
      end select;

      <<Active_State>>
      select
         accept Set_Delay (How_Long   : Duration;
                           Processing : Procedure_Access)
         do
            End_Time  := Clock + How_Long;
            if Processing /= null then
               Timer_Proc := Processing;
            end if;
         end Set_Delay;
         goto Active_State;
      or
         accept Cancel_Delay;
         goto Inactive_State;
      or
         accept Suspend;
         Remaining     := End_Time - Clock;
         Suspend_Level := 1;
         goto Suspended_State;
      or
         accept Resume;        --  Ignored entry call in this state
         goto Active_State;
      or
         accept Get_Remaining_Time (Remaining_Time : out Duration) do
            Remaining_Time := End_Time - Clock;
         end Get_Remaining_Time;
         goto Active_State;
      or
         delay until End_Time;
         Proxy.Process (Timer_Proc);  --  Timer_Proc cannot be null
         goto Inactive_State;
      end select;

      <<Suspended_State>>
      select
         accept Set_Delay (How_Long   : Duration;
                           Processing : Procedure_Access)
         do
            Remaining := How_Long;
            if Processing /= null then
               Timer_Proc := Processing;
            end if;
         end Set_Delay;
         goto Suspended_State;
      or
         accept Cancel_Delay;
         Suspend_Level := 0;
         goto Inactive_State;
      or
         accept Suspend;
         Suspend_Level := Suspend_Level + 1;
         goto Suspended_State;
      or
         accept Resume;
         Suspend_Level := Suspend_Level - 1;
         if Suspend_Level = 0 then
            End_Time := Clock + Remaining;
            goto Active_State;
         else
            goto Suspended_State;
         end if;
      or
         accept Get_Remaining_Time (Remaining_Time : out Duration) do
            Remaining_Time := Remaining;
         end Get_Remaining_Time;
         goto Suspended_State;
      or
         terminate;
      end select;
   end Timer;


   --
   -- Entering silent mode
   -- It is not possible to exit silent mode, since all calls to Debug
   -- are ignored in this mode.
   --
   procedure Enter_Silent_Mode is
      use Ada.Text_Io;
   begin
      -- Get rid of as much as we can
      abort Timer;

      if Is_Open (Trace_File) then
         Close (Trace_File);
      end if;
      if Is_Open (Input_File) then
         Close (Input_File);
         Debug_File_Input := False;
      end if;

      -- If other tasks are waiting on the semaphore, do not allow
      -- them to proceed
      Exclusion.Close;

      Current_Mode := Silent;
   end Enter_Silent_Mode;


   --------------------
   --  General Abort --
   --------------------

   --  Does not check that Current_Mode /= Silent
   --  This was necessary to make an "IQ" command work, otherwise the "I"
   --  would have prevented the "Q" from working!
   --  Note that it *is* possible to return from this procedure, if
   --  invoked from an abort-deferred region !
   --

   procedure General_Abort is
      Local_Main : Task_Id := Main_Task;
      --  Because Abort_Task requires a variable, not a constant, as parameter
   begin
      Aborting_Main := True;
      Abort_Task (Local_Main);
      delay 0.0;  -- Synchronization point, in case abort is not immediate.
   end General_Abort;

   -------------------
   -- Is_Debug_Task --
   -------------------

   --
   --  Check whether a task is one of Debug internal tasks
   --  (these tasks should never appear to the user)
   --

   function Is_Debug_Task (Id : Task_Id) return Boolean is
   begin
      return Id = Proxy_Id or Id = Timer_Id;
   end Is_Debug_Task;

   ----------------
   -- Not_Traced --
   ----------------

   --
   --  Determines if the current task should *not* be traced
   --

   function Not_Traced (Caller : Task_Id) return Boolean is
   begin
      if Current_Mode = Silent then
         return True;

      elsif Is_Debug_Task (Caller) then
         -- allways trace calls from the timer proc, for example.
         return False;

      else
         case Source is
         when All_Tasks =>
            return False;
         when Marked_Only =>
            return not Task_Info.Is_Marked (Caller);
         when Marked_Excepted =>
            return Task_Info.Is_Marked (Caller);
         end case;
      end if;
   end Not_Traced;

   ------------
   -- Format --
   ------------

   --
   --  Format a Task_Id
   --

   function Format (Id : Task_Id) return String is
   begin
      if Current_Mode /= Multi_Task then
         return "";
      elsif Is_Debug_Task (Id) then
         return "";
      else
         return '(' &  Image (Id) & ") ";
      end if;
   end Format;


   -------------------------------------------------------------------------
   --  I/O utilities
   -------------------------------------------------------------------------

   package Duration_Io is new Ada.Text_Io.Fixed_Io   (Duration);
   package Any_Int_Io  is new Ada.Text_Io.Integer_Io (Any_Int);
   package Big_Int_IO  is new Ada.Text_IO.Integer_IO (Big_Int);

   ---------------------
   --  Console output --
   ---------------------

   --
   --  Outputs to Current_Error, irrespectively of target setting
   --

   procedure Console_Output (Message      : String;
                             Stay_On_Line : Boolean := False)
   is
      use Ada.Text_Io;
      Save_Current_Output : constant File_Access := Current_Output;
   begin
      --  Output Debug_Message if we are at the start of a new message
      if New_Message then
         Put (Current_Error, Trace_Message);
         New_Message := False;
      end if;

      Put (Current_Error, Message);
      if Stay_On_Line then
         -- There is a bug in the ARM, where Flush is declared with
         -- an "in out" (rather than "in") parameter. Some compilers
         -- did implement this bug.  As a consequence, it is not
         -- possible to write: Flush (Current_Error); Fortunately,
         -- Flush without parameters operates on Current_Output, so we
         -- have the following work-around:
         Set_Output (Current_Error);
         Flush;
         Set_Output (Save_Current_Output.all);
      else
         New_Line (Current_Error);
         New_Message := True;
      end if;
   end Console_Output;

   procedure Console_Output (Message : Character) is
      use Ada.Text_Io;
   begin
      --  Output Debug_Message if we are at the start of a new message
      if New_Message then
         Put (Current_Error, Trace_Message);
         New_Message := False;
      end if;

      Put (Current_Error, Message);
   end Console_Output;

   -----------
   -- Query --
   -----------

   --
   --  Asks a question with response Y/N
   --  Doesn't ask the question and always returns "Yes" if called while
   --    reading commmands from file
   --

   function Query (Message : String) return Boolean is
      C : Character;
      use Ada.Text_Io, Ada.Characters.Handling;
   begin
      New_Message := True;  --  Query always terminates current message
      loop
         Console_Output (Message & " ([" & Yes_Char & "]," & No_Char & ") : ",
                         Stay_On_Line => True);
         if Debug_File_Input then
            Console_Output ( (1 => Yes_Char) ); -- Make it a string to avoid
                                                -- staying on line
            return True;
         elsif End_Of_Line (Standard_Input) then
            Console_Output ( (1 => Yes_Char) ); -- See comment above
            Skip_Line (Standard_Input);
            return True;
         else
            Get (Standard_Input, C);
            C := To_Upper (C);
            Skip_Line(Standard_Input);

            case C is
               when No_Char =>
                  return False;
               when Yes_Char =>
                  return True;
               when others =>
                  null;
            end case;
         end if;
      end loop;
   end Query;

   -----------
   -- Print --
   -----------

   --
   --  Actual printing of message.
   --  Called only from contexts that ensure protection against concurrency
   --  This is the only place where a "Put" to the official trace file is
   --  performed.
   --

   procedure Print (Message : String; Source_Id : Task_Id) is
      use Ada.Text_Io;

      function Translate (Source : String) return String is
         -- Translates all control charcters in Source into the "^C" form.
         -- Why is this function written recursively ? Because it ensures minimum
         -- overhead if there are no control characters in Source - which is assumed
         -- to be (by far) the most common case
      begin
         for Inx in Source'Range loop
            if Source (Inx) < ' ' then
               return
                 Source (Source'First..Inx-1) &
                 '^' & Character'Val (Character'Pos (Source (Inx)) + Character'Pos ('@')) &
                 Translate (Source (Inx+1 .. Source'Last));
            end if;
         end loop;
         return Source;
      end Translate;

      Id : Task_Id := Source_Id;
   begin  --  Print
      if Target /= None then
         Set_Col (Debug_Output.all, 1);
         -- Outputs a New_Line only if not already in column 1

         if Current_Mode = Mono_Task and then Is_Debug_Task (Source_Id) then
            --  Pretend the task is main task to avoid entering multi-task mode
            Id := Main_Task;
         end if;

         if Id /= Previous_Task and then
            not (Is_Debug_Task (Id) and then Is_Debug_Task (Previous_Task))
            --  Do not show switches between internal (hidden) tasks
         then
            if Current_Mode = Mono_Task then
               Put_Line (Debug_Output.all, Trace_Message      &
                                           Multi_Task_Message &
                                           Image (Main_Task));
               Current_Mode := Multi_Task;
            end if;
            Put_Line (Debug_Output.all, Trace_Message & Task_Separator);

            Previous_Task := Id;
         end if;

         Put_Line (Debug_Output.all, Trace_Message &
                                     Format (Id)   &
                                     ": "          &
                                     Translate (Message));
      end if;   --  Target /= None

   end Print;

   ---------------
   -- Safe_Open --
   ---------------

   --
   --  Open the trace file, checking for overwrite
   --  returns True if OK, False if overwriting is denied by the user
   --

   function Safe_Open (Name : String) return Boolean is
      use Ada.Text_Io;
   begin
      begin  --  Check if file exists
         Open (Trace_File, In_File, Name);

         --  No exception, file exists
         if not Query (Name & Overwrite_Message) then
            return False;
         end if;
         Reset (Trace_File, Out_File);
      exception
         when Name_Error =>  --  File does not exist
            Create (Trace_File, Out_File, Name);
      end;

      return True;
   exception
      when Occur : others =>
         Debug_Error (Occur, "Safe_Open");

         --  The following statement will never be executed, since Debug_Error
         --  reraises the exception. It is here to avoid a warning message
         --  from the compiler that could worry the user.
         return False;
   end Safe_Open;

   -------------------------------------------------------------------------
   --
   --  Management of kept messages
   --
   -------------------------------------------------------------------------

   type Delayed_Message (Message_Length : Natural);
   type Message_Access is access Delayed_Message;
   type Delayed_Message (Message_Length : Natural) is
   record
      Next    : Message_Access;
      Content : String (1 .. Message_Length);
      Id      : Task_Id;
      Pausing : Boolean;
      Lost_Id : Task_Id := Null_Task_Id;
   end record;
   procedure Free is
      new Ada.Unchecked_Deallocation (Delayed_Message, Message_Access);

   -----------
   -- Chain --
   -----------

   --  The chain itself is a protected object.
   --  Note that these are only procedures, and thus not potentially
   --  blocking operations

   protected Chain is

      procedure Add (Message : String; Caller : Task_Id; With_Pause : Boolean);

      procedure Remove (Message : out Message_Access);
      --  Remove returns null when the chain is empty.
      --  We do NOT want to provide a separate Is_Empty function because
      --  we want to ensure that Test/Removal is atomic to avoid a race
      --  condition between testing and removing

      procedure Load_And_Reset (Id : out Task_Id);
      --  If messages have been lost, provides the Task_ID of the first task
      --  which lost messages, and resets it to Null_Task_ID;
      --  returns Null_Task_ID if no messages lost

      function Already_Flushing return Boolean;
      --  True if someone is currently flushing

     function Queue_Length return Big_Counter;
     --  Length of message queue

   private
      Head : Message_Access;
      Tail : Message_Access;   --  Tail is meaningless if Head = null
      Messages_Lost_Id : Task_Id := Null_Task_Id;
      --  Id of task that first lost messages
      Flush_Active : Boolean := False;
   end Chain;

   protected body Chain is
      procedure Add (Message    : String;
                     Caller     : Task_Id;
                     With_Pause : Boolean)
      is
         --  The whole Message creation is protected to prevent nasty
         --  interferences, especially if several tasks raised Storage_Error...
         --  Note that new is *not* a potentially blocking operation
         use Ada.Strings.Fixed;
         Link        : Message_Access;
         Indentation : constant String := 2*Integer(Task_Info.Get_Level) * ' ';
      begin
         Link := new Delayed_Message'
            (Message_Length => Indentation'Length + Message'Length,
             Next           => null,
             Content        => Indentation & Message,
             Id             => Caller,
             Pausing        => With_Pause,
             Lost_Id        => Messages_Lost_Id);

         Messages_Lost_Id := Null_Task_Id;

         if Head = null then
            Head := Link;
         else
            Tail.Next := Link;
         end if;
         Tail := Link;

      exception
         when Storage_Error =>
            if Messages_Lost_Id = Null_Task_Id then
               Messages_Lost_Id := Current_Task;
               --  else do nothing since it is not the first lost message
               --  Note that calling Current_Task from a protected
               -- *procedure* is NOT a bounded error.
            end if;
      end Add;

      procedure Remove (Message : out Message_Access) is
      begin
         Message      := Head;
         Flush_Active := Head /= null;
         if Head /= null then
            Head := Head.Next;
         end if;
      end Remove;

      procedure Load_And_Reset (Id : out Task_Id) is
      begin
         Id               := Messages_Lost_Id;
         Messages_Lost_Id := Null_Task_Id;
      end Load_And_Reset;

      function Already_Flushing return Boolean is
      begin
         return Flush_Active;
      end Already_Flushing;

     function Queue_Length return Big_Counter is
        Count : Big_Counter := 0;
        Ptr   : Message_Access := Head;
     begin
        while Ptr /= null loop
           Count := Count + 1;
           Ptr   := Ptr.Next;
        end loop;
        return Count;
      end Queue_Length;
   end Chain;

   -------------------------------------------------------------------------
   -- Termination Management
   -------------------------------------------------------------------------

   ----------------
   -- Last_will  --
   ----------------

   package body Last_Will is
      Obj : Proxy;
      procedure Finalize (Object : in out Proxy) is
      begin
         if Current_Mode = Silent then
            return;
         end if;

         if Label /= "" then
            Trace (Label);
         end if;

         To_Do;

      exception
         when Occur : others =>
            if Label = "" then
               Trace ("Exception raised during a ""last will"" call: ", Occur);
            else
               Trace ("Exception raised during ""last will"" call labelled """ & Label & """: ", Occur);
            end if;
      end Finalize;
   end Last_Will;

   --------------------
   -- Finalize_Debug --
   --------------------

   --
   --  Our own last will ensure that all outstanding
   --  messages are printed, and files are cleanly closed.
   --  This procedure is attached (through an instantiation of
   --  Last_Will package) at the end of the declarative section,
   --  to make sure that it is finalized *before* any other required
   --  object from the package body.
   --

   procedure Finalize_Debug is
      use Ada.Text_Io;
   begin
      -- Print outstanding messages
      Flush_Trace;

      -- Cleanly close files
      if Is_Open (Trace_File) then
         Close (Trace_File);
      end if;
      if Is_Open (Input_File) then
         Close (Input_File);
      end if;

   exception
      when Occur : others =>
         Debug_Error (Occur, "Debug finalization");
   end Finalize_Debug;


   ----------------------
   -- Execute_Commands --
   ----------------------

   --
   --  Read commands from the keyboard and execute them
   --

   procedure Execute_Commands (Current_Message : Message_Access) is
      Selected_Task : Task_Id renames Current_Message.Id;

      Input_Line  : String (1..Input_Length);
      Line_Length : Natural;
      Cur_Pos     : Natural;
      C           : Character;

      Go_Command_Received    : Boolean := False;
      Abort_Command_Received : Boolean := False;
      Ignore_Command_Received: Boolean := False;

      procedure Display_Help is
      begin
         for Ch : Character of Help_Message loop
            if Ch = '\' then
               Console_Output ("", Stay_On_Line => False);
            else
               Console_Output (Ch);
            end if;
         end loop;
         Console_Output ("", Stay_On_Line => False);
      end Display_Help;

      type Status_Kind is (All_Status,    Task_Status, Source_Status,
                           Target_Status, Go_Status,   Timer_Status,
                           Blocking_Status);
      procedure Display_Status (To_Display : Status_Kind := All_Status) is
         Remaining : Duration;
         Buffer    : String (1..Duration'Fore + 1 + 2);
         use Ada.Strings, Ada.Strings.Fixed, Duration_Io;
      begin
         case To_Display is
            when All_Status =>
               if Current_Message.Pausing then
                  Console_Output (Message_Message & Current_Message.Content);
               end if;
               Display_Status (Task_Status);
               Display_Status (Blocking_Status);
               if Aborting_Main then
                  Console_Output (Aborting_Message);
               end if;
               Console_Output (Queued_Message &
                               Big_Int'Image (Chain.Queue_Length));
               Display_Status (Source_Status);
               Display_Status (Target_Status);
               Display_Status (Go_Status);
               Display_Status (Timer_Status);

            when Task_Status =>
               if Is_Debug_Task (Selected_Task) then
                  Console_Output (Unmarkable_Message);
               else
                  Console_Output (Seltask_Message & Image (Selected_Task) &
                                  " (",
                                  Stay_On_Line => True);
                  if Task_Info.Is_Marked (Selected_Task) then
                     Console_Output (Reg_Message, Stay_On_Line => True);
                  else
                     Console_Output (Unreg_Message, Stay_On_Line => True);
                  end if;
                  if Is_Terminated (Selected_Task) then
                     Console_Output (", " & Terminated_Message,
                                     Stay_On_Line => True);
                  elsif not Is_Callable (Selected_Task) then
                     Console_Output (", " & Completed_Message,
                                     Stay_On_Line => True);
                  end if;
                  Console_Output (")");
               end if;

            when Source_Status =>
               case Source is
                  when All_Tasks =>
                     Console_Output (General_Message);
                  when Marked_Only =>
                     Console_Output (Included_Message);
                  when Marked_Excepted =>
                     Console_Output (Excepted_Message);
               end case;

            when Target_Status =>
               case Target is
                  when Console =>
                     Console_Output (Console_Message);
                  when File =>
                     Console_Output (File_Message);
                  when None =>
                     Console_Output (None_Message);
               end case;

            when Go_Status =>
               case Previous_Go is
                  when 0 =>
                     Console_Output (Go_Message);
                  when 1 =>
                     Console_Output (Step_Message);
                  when others =>
                     Console_Output (N_Message_1                     &
                                     Big_Counter'Image (Previous_Go) &
                                     N_Message_2);
               end case;

            when Timer_Status =>
               Console_Output (Remaining_Message, Stay_On_Line => True);
               Remaining := Remaining_Time;
               if Remaining = Off then
                  Console_Output (Infinite_Message);
               else
                  Put (Buffer, Remaining, Aft => 2);
                  Console_Output (Trim(Buffer, Left), Stay_On_Line => True);
                  Console_Output (Seconds_Message);
               end if;
            when Blocking_Status =>
               Console_Output (Blocking_Message, Stay_On_Line => True);
               if Always_Blocking then
                  Console_Output (Block_Yes_Message);
               else
                  Console_Output (Block_No_Message);
               end if;
         end case;
      end Display_Status;

      procedure Syntax_Error (Reason : String) is
         use Ada.Strings.Fixed;
      begin
         Console_Output (Syntax_Message & Input_Line (1..Line_Length));
         Console_Output ((Syntax_Message'Length + Cur_Pos - 1)*' ' & "^ "
                         & Reason);
         Go_Command_Received    := False;
         Abort_Command_Received := False;
         Ignore_Command_Received:= False;
      end Syntax_Error;


      use Ada.Characters.Handling;
      use Ada.Text_Io, Big_Int_Io;
   begin  --  Execute_Commands
      Suspend_Timer;   -- Ignored if Timer is not active

   Over_Messages :
      while not Go_Command_Received loop    --  Over messages
         if Debug_File_Input then
            -- Read from file before printing the "pause" message to
            -- get the "end" message at the right place
            begin
               loop
                  Get_Line (Input_File, Input_Line, Last => Line_Length);
                  exit when Line_Length /= 0 and then  -- Ignore empty lines
                     Input_Line (1) /= '#';            -- and lines with '#'
               end loop;
               exception
                  when End_Error =>
                     Close (Input_File);
                     Debug_File_Input := False;
                     Console_Output (End_Inifile_Message);
            end;
         end if;

         Console_Output (Command_Message, Stay_On_Line => True);
         New_Message := True;  --  An input always terminates current message

         if Debug_File_Input then
            -- Echo the command line
            Console_Output (Input_Line (1..Line_Length));
         else
            Get_Line (Standard_Input, Input_Line, Last => Line_Length);
         end if;
         exit Over_Messages when Line_Length = 0;

         Cur_Pos := 0;

      Over_Tags : --  Loop over tags in message
         while Cur_Pos < Line_Length loop
            Cur_Pos := Cur_Pos + 1;
            --  Skip separators
            while Input_Line (Cur_Pos) = ' '      or
            Input_Line (Cur_Pos) = Ascii.Ht or
            Input_Line (Cur_Pos) = ','
            loop
               exit Over_Tags when Cur_Pos = Line_Length;
               Cur_Pos := Cur_Pos + 1;
            end loop;

            C := To_Upper (Input_Line(Cur_Pos));
            case C is

               --  "Go" commands
               when Go_Char =>
                  if Cur_Pos < Line_Length and then
                    Input_Line (Cur_Pos+1) in '0'..'9'
                  then
                     declare
                        Last : Natural;
                     begin
                        Cur_Pos := Cur_Pos + 1;
                        -- To get a better placement of the error
                        -- message if the value is wrong

                        Get (Input_Line (Cur_Pos..Line_Length), Previous_Go,
                             Last);
                        Cur_Pos := Last;
                        exception
                           when Data_Error =>
                              Syntax_Error (Synt_Bad_Int);
                              exit Over_Tags;
                     end;
                  else
                     Previous_Go := No_Pause;
                  end if;
                  Go_Command_Received := True;
               when Step_Char =>
                  Previous_Go         := Step;
                  Go_Command_Received := True;
               when Ignore_Char =>
                  Ignore_Command_Received := True;
                  Go_Command_Received     := True;

               --  "Source" commands
               when All_Char =>
                  Set_Source (All_Tasks);
                  Display_Status (Source_Status);
               when Only_Char =>
                  Set_Source (Marked_Only);
                  Display_Status (Source_Status);
               when Exclude_Char =>
                  Set_Source (Marked_Excepted);
                  Display_Status (Source_Status);

               --  Mark and blocking commands
               when Mark_Char =>
                  if not Is_Debug_Task (Selected_Task) then
                     if Is_Marked (Selected_Task) then
                        Unmark (Selected_Task);
                     else
                        Mark (Selected_Task);
                     end if;
                  end if;
                  Display_Status (Task_Status);
               when Blocking_Char =>
                  Always_Blocking := not Always_Blocking;
                  Display_Status (Blocking_Status);

               --  "Target" commands
               when Console_Char =>
                  Set_Target (Console);
                  Display_Status (Target_Status);
               when File_Char =>
                  begin
                     Set_Target (File);
                     exception
                        when File_Trace_Denied =>
                           null;
                  end;
                  Display_Status (Target_Status);
               when None_Char =>
                  Set_Target (None);
                  Display_Status (Target_Status);

               --  Timer
               when Delay_Char =>
                  declare
                     use Duration_Io;
                     Last  : Natural;
                     Value : Duration := Off;
                  begin
                     if Cur_Pos < Line_Length and then
                       (Input_Line (Cur_Pos+1) in '0'..'9' or
                        Input_Line (Cur_Pos+1) = '.')
                     then
                        Cur_Pos := Cur_Pos + 1;
                        -- To get a better placement of the error
                        -- message if the value is wrong

                        Get (Input_Line (Cur_Pos..Line_Length), Value, Last);
                        Cur_Pos := Last;
                     end if;
                     Set_Timer (Value);
                     Display_Status (Timer_Status);
                  exception
                     when Data_Error =>
                        Syntax_Error (Synt_Bad_Dur);
                        exit Over_Tags;
                  end;

                  --  Information and help
               when Watch_Char =>
                  if User_Watch /= null then
                     begin
                        User_Watch.all;
                     exception
                        when Raised : others =>  -- Propagated from User_Watch
                           Trace (Watch_Exception_Message, Raised);
                     end;
                  end if;
               when Status_Char =>
                  Display_Status;
               when Help_Char =>
                  Display_Help;

               --  Quit and others
               when Quit_Char =>
                  if Aborting_Main then
                     -- Let's not beat this dead horse...
                     Console_Output (Aborting_Message);
                     Go_Command_Received := True;
                  else
                     Abort_Command_Received := True;
                  end if;
               when others =>
                  Syntax_Error (Synt_Bad_Com);
                  exit Over_Tags;
            end case;
         end loop Over_Tags;

         if Abort_Command_Received and then Query (Quit_Message) then
            Go_Command_Received := True;
         else
            Abort_Command_Received := False;
         end if;
      end loop Over_Messages;

      Dont_Wait_Count := Previous_Go;

      --  Process Abort and Ignore commands only after the rest of
      --  the command line has been processed.
      if Ignore_Command_Received then
         Enter_Silent_Mode;
      end if;
      if Abort_Command_Received then
         General_Abort;
      end if;

      Resume_Timer;   -- Ignored if Timer not active
   exception
      when Occur : others =>
         Debug_Error (Occur, "Execute_Commands");
   end Execute_Commands;


   -------------------------------------------------------------------------
   --  "Unprotected" subprograms
   --  These subprograms do the actual job, and rely on the fact that there
   --  is some external mechanism to protect them from concurrency.
   -------------------------------------------------------------------------

   -----------------------
   -- Unprotected_Flush --
   -----------------------

   --
   --  Management of Flush
   --
   --  Protection for Flush:
   --  use the non-generic Protected_Call
   --
   --  This is where all actual printing, pause, etc. takes place
   --

   procedure Unprotected_Flush is
      --  Called only from contexts that ensure protection against concurrency.
      --  Like other Unprotected_* procedures, this procedure is never
      --  called reentrantly.  This ensures that no race condition can
      --  occur that would lead to an incorrect placement of the "Lost
      --  messages" message.
      Messages_Lost_Id : Task_Id;
      Current_Message  : Message_Access;

   begin
      loop
         Chain.Remove (Current_Message);
         exit when Current_Message = null;

         if Current_Message.Lost_Id /= Null_Task_Id then
            Print (Lost_Message, Current_Message.Lost_Id);
         end if;

         Print (Current_Message.Content, Current_Message.Id);

         if Current_Message.Pausing or Dont_Wait_Count = 1 then
            Execute_Commands (Current_Message);
            --  The "go" command will reinitialize Dont_Wait_Count.
         elsif Dont_Wait_Count >= 1 then
            Dont_Wait_Count := Dont_Wait_Count - 1;
         end if;

         Free (Current_Message);
      end loop;

      Chain.Load_And_Reset (Messages_Lost_Id);
      if Messages_Lost_Id /= Null_Task_Id  then
         -- This is the case when messages were lost after the last
         -- message in the chain
         Print (Lost_Message, Messages_Lost_Id);
      end if;
   exception         --  Safety exception handler
      when Occur : others =>
         Debug_Error (Occur, "Unprotected_Flush");
   end Unprotected_Flush;

   ----------------------------
   -- Unprotected_Set_Target --
   ----------------------------

   --
   --  Actual, unprotected, setting of target
   --
   --  Protection for Set_Target:
   package Trace_Target_Protected_Call is
      new Protection.Generic_Protected_Call (Trace_Target);

   procedure Unprotected_Set_Target (To : Trace_Target) is
      use Ada.Text_Io;
   begin
      case To is
         when File =>
            if not Is_Open (Trace_File) then
               if not Safe_Open (Trace_File_Name) then
                  raise File_Trace_Denied;
               end if;
            end if;
            Debug_Output := Trace_File'Access;
         when Console =>
            Debug_Output := Current_Error;
         when None =>
            null;
      end case;

      Target := To;
   end Unprotected_Set_Target;

   ---------------------------
   -- Unprotected_Set_Watch --
   ---------------------------

   --
   --  Management of Set_Watch
   --
   --  Protection for Set_Watch:
   package Procedure_Access_Protected_Call is
      new Protection.Generic_Protected_Call (Procedure_Access);

   procedure Unprotected_Set_Watch (To : Procedure_Access) is
   begin
      User_Watch := To;
   end Unprotected_Set_Watch;

   -------------------------------------------------------------------------
   -------------------------------------------------------------------------
   --                                                                     --
   --                     SECTION PROVIDED SUBPROGRAMS                    --
   --                                                                     --
   -- This section provides the implementation for subprograms            --
   -- provided by package Debug                                           --
   --                                                                     --
   -------------------------------------------------------------------------
   -------------------------------------------------------------------------

   ---------
   -- "+" --
   ---------

   function "+" (Item : String) return Tracer_String_Access is
   begin
      return new Tracer_String'(Tracer_String (Item));
   end "+";

   -----------
   -- Pause --
   -----------

   procedure Pause (Message : String) is
      use Protection;
   begin
      if Not_Traced (Current_Task) then
         return;
      end if;

      if Message = "" then
         Chain.Add (Pause_Message, Current_Task, With_Pause => True);
      else
         Chain.Add (Pause_Message & " (" & Message & ')', Current_Task, With_Pause => True);
      end if;

      Protected_Call (Unprotected_Flush'Access, Exclusion'Access);
      -- We do not simply call Flush_Trace here because we do want to
      -- block even if another task is currently flushing.
   exception
      when Occur : others =>
         Debug_Error (Occur, "Pause");
   end Pause;

   -----------
   -- Pause --
   -----------

   procedure Pause is
   begin
      Pause ("");
   end Pause;

   ----------------
   -- Abort_Main --
   ----------------

   procedure Abort_Main is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      General_Abort;
   end Abort_Main;

   -----------------
   -- Flush_Trace --
   -----------------

   procedure Flush_Trace is
      use Protection;
   begin
      if Current_Mode = Silent then
         return;
      end if;

      if Always_Blocking or else not Chain.Already_Flushing then
         Protected_Call (Unprotected_Flush'Access, Exclusion'Access);
      end if;
   exception
      when Closed_Semaphore =>
         null;
      when Occur : others =>
         Debug_Error (Occur, "Flush_Trace");
   end Flush_Trace;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message : String) is
   begin
      Keep_Trace (Message);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace (Message : String;
                         Caller  : Task_Id := Current_Task)
   is
   begin
      if Not_Traced (Caller) then
         return;
      end if;

      Chain.Add (Message, Caller, With_Pause => False);
   end Keep_Trace;

   -----------
   -- Trace --
   -----------

   procedure Trace (Flag    : Trace_Flag;
                    Message : String)
   is
   begin
      Keep_Trace (Flag, Message);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace (Flag    : Trace_Flag;
                         Message : String;
                         Caller  : Ati.Task_Id := Ati.Current_Task)
   is
      Traced : Boolean;
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Traced := not Not_Traced (Caller);
      --  If the current task is not traced, we must still update the level
      --  since the task may become traced again at any time. Otherwise,
      --  we would get wrong "mismatched" messages.
      case Flag is
         when Start =>
            if Traced then
               Keep_Trace ("=>" & Message, Caller);
            end if;
            Task_Info.Set_Level (+1);
         when Stop =>
            if Task_Info.Get_Level = 0 then
               if Traced then
                  Keep_Trace (Mismatched_Message, Caller);
               end if;
            else
               Task_Info.Set_Level (-1);
            end if;
            if Traced then
               Keep_Trace ("<=" & Message, Caller);
            end if;
      end case;
   end Keep_Trace;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Object : in out Auto_Tracer) is
   begin
      Trace (Start, String (Object.Message.all));
   end Initialize;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Object : in out Auto_Tracer) is
      Junk : Tracer_String_Access := Object.Message;
   begin
      Trace (Stop, String (Object.Message.all));
      Free (Junk);
   end Finalize;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message : String;
                    Value   : Boolean)
   is
   begin
      Keep_Trace (Message, Value);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace (Message : String;
                         Value   : Boolean;
                         Caller  : Ati.Task_Id := Ati.Current_Task)
   is
   begin
      if Not_Traced (Caller) then
         return;
      end if;

      Keep_Trace (Message & ' ' & Boolean'Image (Value));
   end Keep_Trace;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message : String;
                    Value   : Any_Int)
   is
   begin
      Keep_Trace (Message, Value);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace (Message : String;
                         Value   : Any_Int;
                         Caller  : Ati.Task_Id := Ati.Current_Task)
   is
      use Any_Int_Io, Ada.Strings, Ada.Strings.Fixed;
      The_Image : String (1 .. Any_Int'Width);
   begin
      if Not_Traced (Caller) then
         return;
      end if;

      Put (The_Image, Value);
      Keep_Trace (Message & ' ' & Trim (The_Image, Left), Caller);
   end Keep_Trace;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message : String;
                    Value   : Any_Float)
   is
   begin
      Keep_Trace (Message, Value);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace (Message : String;
                         Value   : Any_Float;
                         Caller  : Ati.Task_Id := Ati.Current_Task)
   is
      package Any_Float_Io is new Ada.Text_Io.Float_Io   (Any_Float);

   use Any_Float_Io, Ada.Strings, Ada.Strings.Fixed;
      The_Image : String (1 .. Any_Float'Width);
   begin
      if Not_Traced (Caller) then
         return;
      end if;

      Put (The_Image, Value);
      Keep_Trace (Message & ' ' & Trim (The_Image, Left), Caller);
   end Keep_Trace;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message          : String;
                    Raised_Exception : Ada.Exceptions.Exception_Occurrence)
   is
   begin
      Keep_Trace (Message, Raised_Exception);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace
     (Message          : String;
      Raised_Exception : Ada.Exceptions.Exception_Occurrence;
      Caller           : Ati.Task_Id := Ati.Current_Task)
   is
      use Ada.Exceptions;
   begin
      if Not_Traced (Caller) then
         return;
      end if;

      Keep_Trace (Message & ' ' & Exception_Name (Raised_Exception),
                  Caller);
   end Keep_Trace;

   -----------
   -- Trace --
   -----------

   procedure Trace (Message : String; Value  : Ada.Tags.Tag) is
   begin
      Keep_Trace (Message, Value);
      Flush_Trace;
   end Trace;

   ----------------
   -- Keep_Trace --
   ----------------

   procedure Keep_Trace (Message : String;
                         Value  : Ada.Tags.Tag;
                         Caller : ATI.Task_Id  := ATI.Current_Task)
   is
      use Ada.Tags;
   begin
      if Not_Traced (Caller) then
         return;
      end if;

      Keep_Trace (Message & ' ' & Expanded_Name (Value),
                  Caller);
   end Keep_Trace;

   --
   -- Stream related declarations
   --

   -- Number of hex digits in a Stream_Element:
   Hex_Digits : constant := (Ada.Streams.Stream_Element'Size + 3) / 4;
   Hex_Table  : constant array (Ada.Streams.Stream_Element range 0..15) of Character
     := "0123456789ABCDEF";

   procedure Read (Stream : in out Trace_Stream_Type;
                   Item   :    out Ada.Streams.Stream_Element_Array;
                   Last   :    out Ada.Streams.Stream_Element_Offset)
   is
   begin
      raise Program_Error;
   end Read;

   procedure Write (Stream : in out Trace_Stream_Type;
                    Item   : in     Ada.Streams.Stream_Element_Array)
   is
      use Ada.Streams;
      Message_H : String (1 .. (Hex_Digits+1)*Item'Length - 1) := (others => ' '); -- Hex string
      Message_A : String (1 .. Item'Length)                    := (others => ' '); -- Ascii string

      procedure Decode (Inx : Stream_Element_Offset) is
         Value : Stream_Element := Item (Inx);
      begin
         for I in Integer range 1..Hex_Digits loop
            Message_H (Integer (Inx) * (Hex_Digits + 1) - I) := Hex_Table (Value mod 16);
            Value := Value / 16;
         end loop;

         if Item (Inx) < Character'Pos (' ') or Item (Inx) = Character'Pos (Ascii.Del) then
            Message_A (Integer (Inx)) := '.';
         else
            Message_A (Integer (Inx)) := Character'Val (Item (Inx));
         end if;
      end Decode;
   begin  -- Write
      for I in Item'Range loop
         Decode (I);
      end loop;
      Trace (Message_H & " => " & Message_A);
   end Write;

   --
   --  Counters
   --

   type Counts_Array  is array (Tracer_Counter) of Natural;

   protected Counters is
      procedure Get_Next_Count (C : Tracer_Counter; Value : out Natural);
   private
      Counts : Counts_Array := (others => 0);
   end Counters;

   protected body Counters is
      procedure Get_Next_Count (C : Tracer_Counter; Value : out Natural) is
      begin
         Counts (C) := Counts (C) + 1;
         Value := Counts (C);
      end Get_Next_Count;
   end Counters;

   function Tracer_Count (Counter : Tracer_Counter) return String is
      I : Natural;
   begin
      Counters.Get_Next_Count (Counter, I);
      return Natural'Image (I);
   end Tracer_Count;


   --
   --  Set and retrieve source and target
   --


   ----------------
   -- Set_Source --
   ----------------

   procedure Set_Source (To : Trace_Source) is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Source := To;
   end Set_Source;

   --------------------
   -- Current_Source --
   --------------------

   function Current_Source return Trace_Source is
   begin
      return Source;
   end Current_Source;

   ----------------
   -- Set_Target --
   ----------------

   procedure Set_Target (To : Trace_Target) is
      use Protection, Trace_Target_Protected_Call;
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Protected_Call (Unprotected_Set_Target'Access, To, Exclusion'Access);
   exception
      when Closed_Semaphore =>
         null;
      when File_Trace_Denied =>
         raise;
      when Occur : others =>
         Debug_Error (Occur, "Set_Target");
   end Set_Target;

   --------------------
   -- Current_Target --
   --------------------

   function Current_Target return Trace_Target is
   begin
      return Target;
   end Current_Target;

   --
   --  Registration
   --

   ----------
   -- Mark --
   ----------

   procedure Mark (Target_Task : Ati.Task_Id := Ati.Current_Task) is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Task_Info.Set_Mark (True, Target_Task);
   end Mark;

   ------------
   -- Unmark --
   ------------

   procedure Unmark (Target_Task : Ati.Task_Id := Ati.Current_Task) is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Task_Info.Set_Mark (False, Target_Task);
   end Unmark;

   ---------------
   -- Is_Marked --
   ---------------

   function Is_Marked (Target_Task : Ati.Task_Id := Ati.Current_Task)
         return Boolean
   is
   begin
      return Task_Info.Is_Marked (Target_Task);
   end Is_Marked;

   --
   --  User watch procedure
   --

   ---------------
   -- Set_Watch --
   ---------------

   procedure Set_Watch (To : Procedure_Access) is
      use Protection, Procedure_Access_Protected_Call;
   begin
      if Not_Traced (Current_Task) then
         return;
      end if;

      Protected_Call (Unprotected_Set_Watch'Access, To, Exclusion'Access);

   exception
      when Closed_Semaphore =>
         null;
      when Occur : others =>
         Debug_Error (Occur, "Set_Watch");
   end Set_Watch;

   --
   --  Timer
   --

   ---------------
   -- Set_Timer --
   ---------------

   procedure Set_Timer (How_Long   : Duration;
                        Processing : Procedure_Access := null)
   is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      if How_Long <= Off then
         Timer.Cancel_Delay;
      else
         Timer.Set_Delay (How_Long, Processing);
      end if;
   exception
      when Tasking_Error => --  Set_Timer called after Abort_Main
         null;              --  Ignore it
   end Set_Timer;

   -------------------
   -- Suspend_Timer --
   -------------------

   procedure Suspend_Timer is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Timer.Suspend;

   exception
      when Tasking_Error => --  Suspend_Timer called after Abort_Main
         null;              --  Ignore it
      when Occur : others =>
         Debug_Error (Occur, "Suspend_Timer");
   end Suspend_Timer;

   ------------------
   -- Resume_Timer --
   ------------------

   procedure Resume_Timer is
   begin
      if Current_Mode = Silent then
         return;
      end if;

      Timer.Resume;

   exception
      when Tasking_Error => --  Resume_Timer called after Abort_Main
         null;              --  Ignore it
      when Occur : others =>
         Debug_Error (Occur, "Resume_Timer");
   end Resume_Timer;

   --------------------
   -- Remaining_Time --
   --------------------

   function Remaining_Time return Duration is
      Returned_Value : Duration;
   begin
      Timer.Get_Remaining_Time (Returned_Value);
      return Returned_Value;
   exception
      when Tasking_Error =>  --  Remaining_Time called after Abort_Main
         return Off;         --  The best we can return...
   end Remaining_Time;


   -------------------------------------------------------------------------
   --  Initialization code for debug services
   -------------------------------------------------------------------------

   package Debug_Last_Will is new Last_Will (Finalize_Debug);

begin  -- Tracer

   declare  -- Check TRACE.INI file
      use Ada.Text_Io;
   begin
      Open (Input_File, In_File, Initial_File_Name);
      Debug_File_Input := True;
      if End_Of_File (Input_File) then -- Empty TRACE.INI file
         Enter_Silent_Mode;
      end if;
   exception
      when Name_Error => -- File does not exist
         null;
   end;

   Trace (Initial_Message);
   Pause (Trace_Message);
   Trace (Start_Message);

exception
   when Occur : others =>
      Debug_Error (Occur, "Debug initialization");
end Tracer;
