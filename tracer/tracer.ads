----------------------------------------------------------------------
-- Package Tracer (specification)                                   --
-- (C) Copyright 1997,2004 ADALOG                                   --
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
with
  System,

  Ada.Exceptions,
  Ada.Tags,
  Ada.Task_Identification,
  Ada.Finalization,
  Ada.Streams;
private with
  Ada.Unchecked_Deallocation;
package Tracer is
   pragma Elaborate_Body;
   package ATI renames Ada.Task_Identification;

   -- A Debug_String is really a String.
   -- We make it a different type to ensure that the "+" function
   -- does not introduce ambiguities with user defined "+" functions
   -- on strings, even in the presence of use clauses.
   type Tracer_String (<>) is limited private;
   type Tracer_String_Access is access Tracer_String;
   function "+" (Item : String) return Tracer_String_Access;

   --  Trace (...)      prints the message immediately. Potentially blocking
   --                   (cannot be used from a protected operation).
   --  Keep_Trace (...) keeps the message. It will be printed as soon as a
   --                   Trace (...) is performed, or Flush_Trace is called.
   --                   Correct ordering of traces is guaranteed.
   --                   Keep_Trace is NOT a potentially blocking operation and
   --                   CAN be called from a protected operation.
   --                   If called from with a protected entry PE, there is
   --                   no guarantee that the task executing the PE is the one
   --                   which called the operation. In this case, use the form
   --                   Keep_Trace (...., PE'Caller) to make sure the call is
   --                   traced to the right task.
   --  All traces are serialized and can be safely used with multiple tasks.

   --  Simple traces
   procedure Trace      (Message : String);
   procedure Keep_Trace (Message : String;
                         Caller  : ATI.Task_Id := ATI.Current_Task);

   --  Trace nesting of subprogram calls.
   --  Trace (Start, ...) increases indentation level. Put at subprogram entry
   --  Trace (Stop, ...)  decreases indentation level. Put at subprogram exit
   --  Alternatively, declare an object of type Auto_Tracer, initialized with
   --  the name of the subprogram:
   --     Tracer: Auto_Tracer (+"My_Subprogram");
   --  The string is automatically freed at subprogram exit
   type Trace_Flag is (Start, Stop);
   procedure Trace      (Flag    : Trace_Flag; Message : String);
   procedure Keep_Trace (Flag    : Trace_Flag; Message : String;
                                               Caller  : ATI.Task_Id := ATI.Current_Task);
   type Auto_Tracer (Message : Tracer_String_Access) is limited private;

   --  Traces of boolean values;
   procedure Trace      (Message : String; Value   : Boolean);
   procedure Keep_Trace (Message : String; Value   : Boolean;
                                           Caller  : ATI.Task_Id := ATI.Current_Task);

   --  Traces of integer values;
   --  use Trace(Any_Int(V),...) where V is of any integer type.
   type Any_Int is range System.Min_Int .. System.Max_Int;
   procedure Trace      (Message : String; Value   : Any_Int);
   procedure Keep_Trace (Message : String; Value   : Any_Int;
                                           Caller  : ATI.Task_Id := ATI.Current_Task);

   --  Traces of float values;
   --  use Trace(Any_Float(V),...) where V is of any floating-point type.
   type Any_Float is digits System.Max_Digits;
   procedure Trace      (Message : String; Value   : Any_Float);
   procedure Keep_Trace (Message : String; Value   : Any_Float;
                                           Caller  : ATI.Task_Id := ATI.Current_Task);

   --  Traces of exceptions. Generally used in exception handlers.
   procedure Trace      (Message          : String; Raised_Exception : Ada.Exceptions.Exception_Occurrence);
   procedure Keep_Trace (Message          : String; Raised_Exception : Ada.Exceptions.Exception_Occurrence;
                                                    Caller           : ATI.Task_Id  := ATI.Current_Task);

   --  Traces of tags.
   procedure Trace      (Message          : String; Value  : Ada.Tags.Tag);
   procedure Keep_Trace (Message          : String; Value  : Ada.Tags.Tag;
                                                    Caller : ATI.Task_Id  := ATI.Current_Task);

   --  Traces of any type, using streams. Hexadecimal output of the stream representation.
   --  For any type T use:
   --     T'Write (Trace_Stream, X)      --Potentially blocking (cannot be used from a protected operation).
   --  Any use of T'Read on this stream will raise Program_Error.

   type Tracer_Stream_Access is access all Ada.Streams.Root_Stream_Type'Class;
   Trace_Stream : constant Tracer_Stream_Access;

   --  Counters
   type Tracer_Counter is range 1..25;
   function Tracer_Count (Counter : Tracer_Counter) return String;

   --  Flush outstanding messages if any (can be safely called if no
   --  outstanding messages).
   --  Potentially blocking (cannot be used from a protected operation).
   procedure Flush_Trace;

   --  Pause
   --  Blocks all trace operations and returns control to the console
   --  Potentially blocking (cannot be used from a protected operation).
   procedure Pause;
   procedure Pause (Message : String);

   --  User defined watch procedure
   --  Potentially blocking (cannot be used from a protected operation).
   type Procedure_Access is access procedure;
   procedure Set_Watch (To : Procedure_Access);

   --  Unconditionnally terminate main program
   --  All outstanding messages ARE printed
   --  Potentially blocking (cannot be used from a protected operation).
   procedure Abort_Main;

   --  Timer
   --  Triggers some processing after a given time.
   --  Initially, the processing is Pause, but any other processing (including
   --  Abort_Main or a user defined procedure) can be specified.
   --  A null value for Processing (the default) means that the current
   --  processing should not be changed.
   --  Set_Timer (Off) cancels the timer.
   --  The timer can be reset to a new value at any time.
   --  It can be temporarily suspended and resumed with Suspend_Timer and
   --  Resume_Timer.
   --  All are potentially blocking (cannot be used from a protected operation).
   Off : constant Duration := 0.0;
   procedure Set_Timer (How_Long   : Duration;
                        Processing : Procedure_Access := null);
   procedure Suspend_Timer;
   procedure Resume_Timer;
   -- Time remaining before the timer is triggered
   -- returns Off if the timer is not active
   function Remaining_Time return Duration;

   -- Last_Will
   -- Registers a procedure to be called just before the program terminates.
   -- Optionnally, the user can give a label to trace this call.
   -- This package can be instantiated only at static level 0 (library package)
   generic
      with procedure To_Do;
      Label : String := "";
   package Last_Will is
   private
      type Proxy is new Ada.Finalization.Limited_Controlled with null record;
      overriding procedure Finalize (Object : in out Proxy);
   end Last_Will;

   --  Dynamically change and retrieve sources
   --  Sources= which tasks are allowed to generate traces.
   --  Potentially blocking (cannot be used from a protected operation).
   --  (to be honnest, it is not currently, but this may change in future
   --  versions, and there is no reason to invoke this SP from a PO)
   type Trace_Source is (All_Tasks, Marked_Only, Marked_Excepted);
   procedure Set_Source (To : Trace_Source);
   function  Current_Source return Trace_Source;

   procedure Mark      (Target_Task : ATI.Task_Id := ATI.Current_Task);
   procedure Unmark    (Target_Task : ATI.Task_Id := ATI.Current_Task);
   function  Is_Marked (Target_Task : ATI.Task_Id := ATI.Current_Task)
      return Boolean;

   --  Dynamically change and retrieve target
   --  Target= where do the traces go.
   --  Potentially blocking (cannot be used from a protected operation).
   type Trace_Target is (Console, File, None);
   procedure Set_Target (To : Trace_Target);
   function  Current_Target return Trace_Target;
   File_Trace_Denied : exception;

private
   type Tracer_String is new String;
   procedure Free is new Ada.Unchecked_Deallocation (Tracer_String, Tracer_String_Access);

   type Trace_Stream_Type is new Ada.Streams.Root_Stream_Type with null record;
   overriding procedure Read (Stream : in out Trace_Stream_Type;
                   Item   :    out Ada.Streams.Stream_Element_Array;
                   Last   :    out Ada.Streams.Stream_Element_Offset);
   overriding procedure Write (Stream : in out Trace_Stream_Type;
                    Item   : in     Ada.Streams.Stream_Element_Array);
   The_Trace_Stream : aliased Trace_Stream_Type;
   Trace_Stream     : constant Tracer_Stream_Access := The_Trace_Stream'Access;


   type Auto_Tracer (Message : Tracer_String_Access) is
     new Ada.Finalization.Limited_Controlled with null record;
   overriding procedure Initialize (Object : in out Auto_Tracer);
   overriding procedure Finalize   (Object : in out Auto_Tracer);

   -- For use by children of Debug.
   -- Autodebug procedures. (see body).
   procedure Debug_Error (Problem : Ada.Exceptions.Exception_Occurrence;
                          Where   : String);
   procedure Itrace (Message : String);
end Tracer;
