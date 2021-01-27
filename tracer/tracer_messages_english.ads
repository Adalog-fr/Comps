----------------------------------------------------------------------
-- Package TRACER_MESSAGES_ENGLISH (specification, no body)          --
-- (C) Copyright 1997, 2001 ADALOG                                  --
-- Author: J-P. Rosen                                               --
--                                                                  --
-- ADALOG is providing training, consultancy and expertise in Ada   --
-- and related software engineering techniques. For more info about --
-- our services:                                                    --
-- ADALOG                   Tel: +33 1 41 24 31 40                  --
-- 19-21 rue du 8 mai 1945  Fax: +33 1 41 24 07 36                  --
-- 94110 ARCUEIL            E-m: info@adalog.fr                     --
-- FRANCE                   URL: http://www.adalog.fr               --
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
package Tracer_Messages_English is
   --  All characters used for responses and all messages printed by Tracer are
   --  defined here, so if you want to customize it to another language, you
   --  only need to make a new version of this package, and modify the package
   --  Tracer_Messages to make it a renaming of it.

   --
   --  Characters used for responses
   --
   Yes_Char        : constant Character := 'Y'; -- "Yes" response
   No_Char         : constant Character := 'N'; -- "No" response

   -- Following characters must be different
   Status_Char     : constant Character := '?'; -- Status
   All_Char        : constant Character := 'A'; -- All (General)
   Blocking_Char   : constant Character := 'B'; -- toggle Block
   Console_Char    : constant Character := 'C'; -- Console
   Delay_Char      : constant Character := 'D'; -- Timer Delay
   Exclude_Char    : constant Character := 'E'; -- Exclude
   File_Char       : constant Character := 'F'; -- File
   Go_Char         : constant Character := 'G'; -- Go (=0)
   Help_Char       : constant Character := 'H'; -- Help
   Ignore_Char     : constant Character := 'I'; -- silent (Ignore)
   Mark_Char       : constant Character := 'M'; -- toggle mark state of task
   None_Char       : constant Character := 'N'; -- No output
   Only_Char       : constant Character := 'O'; -- Only marked tasks
   Quit_Char       : constant Character := 'Q'; -- Quit
   Step_Char       : constant Character := 'S'; -- Step (=1)
   Watch_Char      : constant Character := 'W'; -- call Watch procedure

   --
   --  General messages
   --
   Tracer_Message          : constant String := "**Trace** ";
   Task_Separator          : constant String := "--------------------";
   Main_Task_Message       : constant String := "Main-task ID = ";
   Initial_Message         : constant String := "V2.3. Initialization";
   Start_Message           : constant String := "Starting main program";
   Trace_Message           : constant String := "Trace Mode: Enter=Normal, " &
                                                ''' & Step_Char   & "'=Step, " &
                                                ''' & Ignore_Char & "'=Ignore Trace";
   Pause_Message           : constant String := "Pause";
   Quit_Message            : constant String := "Really quit ? ";
   Lost_Message            : constant String := "No more memory, some messages lost";
   Mismatched_Message      : constant String := "!!! Start/Stop Mismatched";
   Overwrite_Message       : constant String := ": file exists, overwrite ?";
   Multi_Task_Message      : constant String := "Entering multi-task mode, main task id = ";
   Watch_Exception_Message : constant String := "User watch procedure raised ";
   Timer_Exception_Message : constant String := "Timer procedure raised ";
   Timer_Message           : constant String := "Timer elapsed";
   End_Inifile_Message     : constant String := "End of ""Ini"" file, switching back to console";
   Syntax_Message          : constant String := "Illegal syntax in command : ";
   Bug_Message             : constant String := "Tracer internal error in ";
   Bug_Mess_Message        : constant String := "Exception message : ";
   Bug_Info_Message        : constant String := "Exception information : ";
   Command_Message         : constant String := "Command? ('" & Help_Char & "' for help) :";

   --
   --  Help and status messages
   --
   Help_Message : constant String :=  -- '\' is replaced by LF
      "Possible answers are :\" &
      "<Enter>"     &       "    : Resume execution with previous 'Go' value\" &
      Status_Char   & "          : Print current status\"                 &
      All_Char      & "          : trace All tasks (default)\"            &
      Blocking_Char & "          : toggle Blocking mode\"                 &
      Console_Char  & "          : trace to Console (default)\"           &
      Delay_Char    & "[Value]   : set Delay for timer\"                  &
      "             (0 or nothing = disable timer)\"       &
      Exclude_Char  & "          : trace Except marked tasks\"            &
      File_Char     & "          : trace to File\"                        &
      Go_Char       & "[<Number>]: Go, pause after <Number> messages\"    &
      "             (0 or nothing = don't pause)\"         &
      Help_Char     & "          : this Help\"                            &
      Ignore_Char   & "          : Ignore all calls to Tracer\"           &
      Mark_Char     & "          : Mark current task\"                    &
      None_Char     & "          : trace to None (no messages printed)\"  &
      Only_Char     & "          : trace Only marked tasks\"              &
      Quit_Char     & "          : Quit, stop execution\"                 &
      Step_Char     & "          : Step, pause after next message (=G1)\" &
      Watch_Char    & "          : call user Watch procedure";

   Message_Message    : constant String := "Pause message : ";
   Seltask_Message    : constant String := "Selected task : ";
   Reg_Message        : constant String := "Marked";
   Unreg_Message      : constant String := "Not marked";
   Completed_Message  : constant String := "Completed";
   Terminated_Message : constant String := "Terminated";
   Unmarkable_Message : constant String := "No selected task";
   General_Message    : constant String := "Tracing all tasks";
   Included_Message   : constant String := "Tracing only marked tasks";
   Excepted_Message   : constant String := "Tracing all but marked tasks";
   Console_Message    : constant String := "Trace output to console";
   File_Message       : constant String := "Trace output to file";
   None_Message       : constant String := "Trace output disabled";
   Go_Message         : constant String := "No pause";
   Step_Message       : constant String := "Pausing after each message";
   N_Message_1        : constant String := "Pausing after";
   N_Message_2        : constant String := " messages";
   Remaining_Message  : constant String := "Remaining time for timer: ";
   Infinite_Message   : constant String := "Infinite";
   Seconds_Message    : constant String := " seconds.";
   Aborting_Message   : constant String := "General abort in progress";
   Queued_Message     : constant String := "Number of queued messages:";
   Blocking_Message   : constant String := "Trace calls are ";
   Block_Yes_Message  : constant String := "blocking";
   Block_No_Message   : constant String := "not blocking";

   --  Syntax error messages
   Synt_Bad_Int : constant String := "Illegal integer value";
   Synt_Bad_Dur : constant String := "Illegal duration value";
   Synt_Bad_Com : constant String := "Not a tracer command - type " &
                                     ''' & Help_Char & "'' for help";

   --  Default file names
   Trace_File_Name   : constant String := "trace";
   Initial_File_Name : constant String := "trace.ini";

   --  Tracer.Timing messages
   Timer_Name               : constant String := "Timer";
   Timer_Not_Called_Message : constant String := " not called";
   Timer_Running_Message    : constant String := " currently running";
   Total_Message            : constant String := " Total:";
   Nb_Calls_Message         : constant String := ", Nb. calls:";
   Average_Message          : constant String := ", Average:";
   Seconds                  : constant String := "s.";
   No_Timer_Message         : constant String := "No timer called";
   Last_Timer_Message       : constant String := "Final timers report:";
end Tracer_Messages_English;
