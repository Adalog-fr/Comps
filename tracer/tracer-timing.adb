----------------------------------------------------------------------
-- Package Tracer.Timing (body)                                     --
-- (C) Copyright 1999, 2021 ADALOG                                  --
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
with Ada.Calendar; use Ada.Calendar;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Tracer_Messages;
package body Tracer.Timing is

   Bad_Time : constant Time := Time_Of(1901, 1, 2);
   -- Flag for the start date of a stopped timer

   --
   -- The timers themselves:
   --
   type Timer_Data is
      record
         Name     : Unbounded_String;
         Start    : Time     := Bad_Time;
         Total    : Duration := 0.0;
         Nb_Calls : Natural  := 0;
      end record;

   Timer_Tab : array (Timer_Index) of Timer_Data;

   --
   --
   --  Internal utilities
   --
   --

   ------------------
   -- Timer_Header --
   ------------------

   function Timer_Header (The_Timer : Timer_Index) return String is
      use Tracer_Messages;
      Timer_Obj   : Timer_Data renames Timer_Tab (The_Timer);
      Common_Part : constant String := Timer_Name & Timer_Index'Image(The_Timer);
   begin
      if Timer_Obj.Name = Null_Unbounded_String then
         return Common_Part;
      else
         return Common_Part & " (" & To_String (Timer_Obj.Name) & ')';
      end if;
   end Timer_Header;

   --
   --
   --  Provided subprograms
   --
   --

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Item : in out Auto_Timer) is
   begin
      Start (Item.The_Timer);
   end Initialize;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Item : in out Auto_Timer) is
   begin
      Stop (Item.The_Timer, Item.With_Trace);
   end Finalize;

   ----------
   -- Name --
   ----------

   procedure Name   (The_Timer : Timer_Index; As : String) is
   begin
      Timer_Tab(The_Timer).Name := To_Unbounded_String (As);
   end Name;

   ------------
   -- Report --
   ------------

   procedure Report (The_Timer : Timer_Index) is
      use Tracer_Messages;

      Timer_Obj : Timer_Data renames Timer_Tab (The_Timer);
   begin
      if Timer_Obj.Nb_Calls = 0 then
         Trace (Timer_Header (The_Timer) & Timer_Not_Called_Message);

      elsif Timer_Obj.Start /= Bad_Time then
         Trace (Timer_Header (The_Timer) & Timer_Running_Message);

      else
         Trace (Timer_Header (The_Timer)
                & Total_Message    & Duration'Image (Timer_Obj.Total) & Seconds_Message
                & Nb_Calls_Message & Integer'Image (Timer_Obj.Nb_Calls)
                & Average_Message  & Duration'Image (Timer_Obj.Total/Timer_Obj.Nb_Calls)
                & Seconds_Message);
      end if;
   exception
      when Occur : others =>
         Debug_Error (Occur, "Timing.Report");
   end Report;

   ----------------
   -- Report_All --
   ----------------

   procedure Report_All is
      use Tracer_Messages;
      Found : Boolean := False;
   begin
      for I in Timer_Index loop
         if Timer_Tab(I).Nb_Calls /= 0 then
            Found := True;
            Report (I);
         end if;
      end loop;
      if not Found then
         Trace (No_Timer_Message);
      end if;
   end Report_All;

   -----------
   -- Reset --
   -----------

   procedure Reset (The_Timer : Timer_Index) is
      Timer_Obj : Timer_Data renames Timer_Tab (The_Timer);
   begin
      Timer_Obj := (Timer_Obj.Name, Bad_Time, 0.0, 0);
   end Reset;

   -----------
   -- Start --
   -----------

   procedure Start (The_Timer : Timer_Index) is
      Timer_Obj : Timer_Data renames Timer_Tab (The_Timer);
   begin
      if Timer_Obj.Start /= Bad_Time then
        -- Already started, ignore Start
        return;
      end if;

      Timer_Obj.Start    := Clock;
      Timer_Obj.Nb_Calls := Timer_Obj.Nb_Calls+1;
   end Start;

   ----------
   -- Stop --
   ----------

   procedure Stop (The_Timer : Timer_Index; With_Trace : Boolean := False) is
      Timer_Obj : Timer_Data renames Timer_Tab (The_Timer);

   begin
      if Timer_Obj.Start = Bad_Time then
        -- not started, ignore Stop
        return;
      end if;

      Timer_Obj.Total    := Timer_Obj.Total + (Clock-Timer_Obj.Start);
      if With_Trace then
         Trace (Timer_Header (The_Timer)
                & ':' & Duration'Image (Clock-Timer_Obj.Start) );
      end if;
      Timer_Obj.Start    := Bad_Time;
   end Stop;

   -- Package finalization:
   -- Make sure timings are reported at the end of run.
   -- This MUST be declared at the end of the package, to make sure
   -- Report_All is called before any other finalization (notably the names)
   -- takes place.
   package Timing_Last_Will is new Last_Will (To_Do => Report_All,
                                              Label => Tracer_Messages.Last_Timer_Message);

end Tracer.Timing;
