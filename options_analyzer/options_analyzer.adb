----------------------------------------------------------------------
--  Options_Analyzer - Package body                                 --
--  Copyright (C) 2002, 2021 Adalog                                 --
--  Author: J-P. Rosen                                              --
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
with -- Predefined Ada units
  Ada.Command_Line,
  Ada.Exceptions,
  Ada.Strings.Fixed;
package body Options_Analyzer is
   use Ada.Command_Line, Ada.Exceptions;

   -- User errors are dected when the command line is parsed, i.e. when the
   -- body of this package is elaborated.
   -- If we raised Options_Error at that point, the application program would have
   -- a hard time catching the exception (since the elaboration is in a declarative part).
   -- Therefore, we catch the exception in the body, and save the occurrence in the
   -- following variable. Each provided subprogram (except Option_String) does a Reraise_Occurrence
   -- on it; this way, the original error is triggered at the first call of any subprogram.
   -- Reminder: Null_Occurrence is the default for Exception_Occurrence, and
   -- Reraise_Occurrence (Null_Occurrence) does nothing.

   Analyze_Error : Exception_Occurrence;

   Presence_Table : array (Integer range Binary_Options'Range) of Boolean := (others => False);

   subtype Value_Index is Integer range -1 .. Integer'Last;
   Absent   : constant Value_Index := -1;
   No_Value : constant Value_Index := 0;
   Value_Table : array (Valued_Options'Range) of Value_Index := (others => Absent);

   Count : Natural := 0;
   Parameter_Table : array (1 .. Argument_Count) of Positive;

   Tail_Start : Value_Index := Absent;

   ----------------
   -- Is_Present --
   ----------------

   function Is_Present (Option : Character) return Boolean is
      use Ada.Strings.Fixed;

      Inx : Natural;
      Option_Str : constant String (1..1) := (1 => Option);
   begin
      Reraise_Occurrence (Analyze_Error);

      Inx := Index (Binary_Options, Option_Str);
      if Inx /= 0 then
         return Presence_Table (Inx);
      end if;

      Inx := Index (Valued_Options, Option_Str);
      if Inx /= 0 then
         return Value_Table (Inx) /= Absent;
      end if;

      -- Not a valid option character
      raise Program_Error;
   end Is_Present;

   -------------------
   -- Option_String --
   -------------------

   function Option_String (With_Command : Boolean := False) return String is
      function Partial_String (Start_Arg : Positive) return String is
      begin
         if Start_Arg < Argument_Count then
            return Argument (Start_Arg) & ' ' & Partial_String (Start_Arg + 1);
         elsif Start_Arg = Argument_Count then
            return Argument (Start_Arg);
         else
            return "";
         end if;
      end Partial_String;

      Opts : constant String := Partial_String (1);
   begin  -- Option_String
      if not With_Command then
         return Opts;
      end if;

      if Opts = "" then
         return Command_Name;
      else
         return Command_Name & ' ' & Opts;
      end if;
   end Option_String;

   ---------------
   -- Parameter --
   ---------------

   function Parameter (Number : Positive) return String is
   begin
      Reraise_Occurrence (Analyze_Error);

      if Number > Count then
         raise Program_Error;
      end if;

      return Argument (Parameter_Table (Number));
   end Parameter;

   ---------------------
   -- Parameter_Count --
   ---------------------

   function Parameter_Count return Natural is
   begin
      Reraise_Occurrence (Analyze_Error);

      return Count;
   end Parameter_Count;

   ----------------
   -- Tail_Value --
   ----------------

   function Tail_Value (Default : String := "") return String is
      function Parameter_Tail (Pos : Positive) return String is
      begin
         if Pos = Argument_Count then
            return Argument (Pos);
         else
            return Argument (Pos) & ' ' & Parameter_Tail (Pos + 1);
         end if;
      end Parameter_Tail;

   begin  -- Tail_Value
      Reraise_Occurrence (Analyze_Error);

      if Tail_Start in Absent | No_Value then
         return Default;
      end if;

      return Parameter_Tail (Tail_Start);
   end Tail_Value;

   ----------------
   -- User_Error --
   ----------------

   procedure User_Error (Message : String);
   pragma No_Return (User_Error);
   procedure User_Error (Message : String) is
   begin
      Raise_Exception (Options_Error'Identity, Message);
   end User_Error;

   -----------
   -- Value --
   -----------

   function Value (Option            : Character;
                   Default           : String    := "";
                   Explicit_Required : Boolean   := False) return String
   is
      use Ada.Strings.Fixed;

      Option_Str : constant String (1..1) := (1 => Option);
      Inx        : Value_Index := Index (Valued_Options, Option_Str);
   begin
      Reraise_Occurrence (Analyze_Error);

      if Inx = 0 then
         -- Not a valid option character
         raise Program_Error;
      end if;

      Inx := Value_Table (Inx);
      if Inx = No_Value and Explicit_Required then
         User_Error ("Value required for option " & Option);
      elsif Inx in Absent | No_Value then
         return Default;
      else
         return Argument (Inx);
      end if;
   end Value;

   -----------
   -- Value --
   -----------

   function Value (Option            : Character;
                   Default           : Integer   := 0;
                   Explicit_Required : Boolean   := False) return Integer
   is
      String_Result : constant String := Value (Option, Integer'Image (Default), Explicit_Required);
   begin
      return Integer'Value (String_Result);
   exception
      when Constraint_Error =>
         User_Error ("Incorrect integer value for option " & Option);
   end Value;

   Inx : Positive := 1;

   use Ada.Strings.Fixed;
begin -- Options_Analyzer
Analyze_Loop:
   while Inx <= Argument_Count loop
      declare
         The_Arg : constant String := Argument (Inx);
         Opt_Inx : Natural;
      begin
         if The_Arg = Tail_Separator then
            if Inx = Argument_Count then
               -- Nothing after separator
               Tail_Start := No_Value;
            else
               Tail_Start := Inx + 1;
            end if;
            exit Analyze_Loop;
         end if;

         if The_Arg = "" then
            -- Ignore zero-length parameters that can be set by tools
            null;
         elsif The_Arg (1) = '-' and The_Arg'Length /= 1 then
            -- '-' alone is considered a parameter

            for Arg_Inx in Positive range 2 .. The_Arg'Last loop
               Opt_Inx := Index (Binary_Options, The_Arg (Arg_Inx..Arg_Inx));
               if Opt_Inx = 0 then
                  Opt_Inx := Index (Valued_Options, The_Arg (Arg_Inx..Arg_Inx));
                  if Opt_Inx = 0 then
                     -- Unknown option
                     User_Error ("Unknown option: " & The_Arg (Arg_Inx));
                  else
                     -- A valued option
                     if Arg_Inx /= The_Arg'Last then
                        User_Error ("Valued option must appear last: " & The_Arg (Arg_Inx));
                     end if;
                     if Inx = Argument_Count then
                        Value_Table (Opt_Inx) := No_Value;
                     elsif Argument (Inx+1) = Tail_Separator then
                        Value_Table (Opt_Inx) := No_Value;
                     elsif Argument (Inx+1)'Length = 0 then
                        -- Protection if we are launched by a tool that can set zero-length parameters
                        Value_Table (Opt_Inx) := No_Value;
                     elsif Argument (Inx+1)(1) = '-' and Argument (Inx+1)'Length /=1 then
                       -- '-' alone is a value here
                        Value_Table (Opt_Inx) := No_Value;
                     else
                        Value_Table (Opt_Inx) := Inx+1;
                        Inx := Inx+1;
                     end if;
                  end if;
               else
                  -- A binary option
                  Presence_Table (Opt_Inx) := True;
               end if;
            end loop;
         else
            -- A parameter
            Count := Count + 1;
            Parameter_Table (Count) := Inx;
         end if;
      end;
      Inx := Inx + 1;
   end loop Analyze_Loop;
exception
   when Occur : Options_Error =>
      Save_Occurrence (Analyze_Error, Occur);
end Options_Analyzer;

