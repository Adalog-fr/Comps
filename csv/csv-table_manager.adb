----------------------------------------------------------------------
--  CSV.Table_Manager - Package body                                --
--  Copyright (C) 2022 Adalog                                       --
--  Author: J-P. Rosen                                              --
--                                                                  --
--  ADALOG   is   providing   training,   consultancy,   expertise, --
--  assistance and custom developments  in Ada and related software --
--  engineering techniques.  For more info about our services:      --
--  ADALOG                                                          --
--  2 rue du Docteur Lombard                                        --
--  92441 ISSY LES MOULINEAUX CEDEX E-m: info@adalog.fr             --
--  FRANCE                          URL: https://www.adalog.fr/     --
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
  Ada.Characters.Handling,
  Ada.Unchecked_Deallocation;
package body Csv.Table_Manager is

   ----------
   -- Free --
   ----------

   procedure Free is new Ada.Unchecked_Deallocation (Fields_Bounds, Bounds_Access);

   ----------
   -- Open --
   ----------

   procedure Open (The_Table   : in out Table;
                   On_File     : in     String;
                   With_Header : in     Boolean   := True;
                   Separator   : in     Character := ',')
   is
      use Ada.Characters.Handling, Ada.Text_IO, Ada.Strings.Unbounded;
   begin
      if Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;

      Open (The_Table.The_File, In_File, On_File);
      The_Table.At_End         := False;
      The_Table.Separator      := Separator;
      if With_Header then
         The_Table.Header_Line    := To_Unbounded_String (To_Upper (Get_Line (The_Table.The_File)));
         The_Table.Header_Bounds  := new Fields_Bounds'(Get_Bounds (To_String (The_Table.Header_Line)));
         -- above line raises CSV_Data_Error if Header_Line = "", which is appropriate
      else
         The_Table.Header_Line := Null_Unbounded_String;
      end if;

      Skip (The_Table);
   end Open;

   -----------
   -- Close --
   -----------

   procedure Close (The_Table : in out Table) is
      use Ada.Text_IO;
   begin
      if not Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;

      Close (The_Table.The_File);
      Free (The_Table.Header_Bounds);
      Free (The_Table.Current_Bounds);
   end Close;

   ----------
   -- Skip --
   ----------

   procedure Skip (The_Table : in out Table) is
      use Ada.Strings.Unbounded, Ada.Text_IO;
   begin
      if not Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;
      if The_Table.At_End then
         raise Table_End_Error;
      end if;

      begin
         The_Table.Current_Line := To_Unbounded_String (Get_Line (The_Table.The_File));
      exception
         when End_Error =>
            The_Table.At_End := True;
            return;
      end;

      -- A CSV file may contain LF's, if the quote of the last field is open
      while Ada.Strings.Unbounded.Count (The_Table.Current_Line, """") rem 2 /= 0 loop
         Append (The_Table.Current_Line, Ascii.LF);
         Append (The_Table.Current_Line, Get_Line (The_Table.The_File));
      end loop;

      Free (The_Table.Current_Bounds);
      The_Table.Current_Bounds := new Fields_Bounds'(Get_Bounds (To_String (The_Table.Current_Line)));
   exception
      when End_Error =>
         -- End_Error while reading extra lines: there was an unclosed quoted last field
         The_Table.At_End := True;
         raise Table_End_Error;
   end Skip;

   ------------------
   -- End_Of_Table --
   ------------------

   function End_Of_Table (The_Table : Table) return Boolean is
   begin
      if not Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;

      return The_Table.At_End;
   end End_Of_Table;

   --------------
   -- Is_Open --
   --------------

   function  Is_Open (The_Table : Table) return Boolean is
      use Ada.Text_Io;
   begin
      return Is_Open (The_Table.The_File);
   end Is_Open;

   ------------
   -- Header --
   ------------

   function Header (The_Table : in Table) return String is
      use Ada.Strings.Unbounded;
   begin
      if not Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;
      return To_String (The_Table.Header_Line);
   end Header;

   -----------------
   -- Source_Line --
   -----------------

   function Source_Line (The_Table : in Table) return String is
      use Ada.Strings.Unbounded;
   begin
      if not Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;
      if The_Table.At_End then
         raise Table_End_Error;
      end if;

      return To_String (The_Table.Current_Line);
   end Source_Line;

   ----------------------
   -- Number_Of_Fields --
   ----------------------

   function Number_Of_Fields (The_Table : Table) return Positive is
   begin
      if not Is_Open (The_Table) then
         raise Table_Status_Error;
      end if;

      return The_Table.Current_Bounds'Length;
   end Number_Of_Fields;

   -----------------
   -- Position_Of --
   -----------------

   function Position_Of (In_Table : Table; Name : String) return Positive is
      use Ada.Characters.Handling, Ada.Strings.Unbounded;

      Upper_Name : constant String := To_Upper (Name);
      Header     : constant String := To_String (In_Table.Header_Line);
   begin
      if not Is_Open (In_Table) then
         raise Table_Status_Error;
      end if;
      if In_Table.Header_Line = Null_Unbounded_String then
         raise Table_Status_Error;
      end if;

      for I in Positive range 1 .. Number_Of_Fields (In_Table) loop
         if Unquote (Extract (Header, In_Table.Header_Bounds.all, I)) = Upper_Name then
            return I;
         end if;
      end loop;

      -- Not found
      raise Constraint_Error;
   end Position_Of;

   -------------
   -- Name_Of --
   -------------

   function Name_Of (In_Table : Table; Position : Positive) return String is
      use Ada.Strings.Unbounded;
   begin
      if not Is_Open (In_Table) then
         raise Table_Status_Error;
      end if;
      if In_Table.Header_Line = Null_Unbounded_String then
         raise Table_Status_Error;
      end if;

      if Position > In_Table.Header_Bounds'Length then
         return "";
      end if;
      return Unquote (Extract (To_String (In_Table.Header_Line), In_Table.Header_Bounds.all, Position));
   end Name_Of;

   ----------
   -- Item --
   ----------

   function Item (From_Table : Table; Name : String; Mapping : Character_Mapping := Identity) return String is
   begin
      return Item (From_Table, Position_Of (From_Table, Name), Mapping);
      -- Position_Of raises Table_Status_Error if no header, otherwise Constraint_Error if Name not found
   end Item;

   ----------
   -- Item --
   ----------

   function Item (From_Table : Table;
                  Position   : Positive;
                  Mapping    : Character_Mapping := Identity;
                  Default    : String            := "")
                  return String
   is
      use Ada.Strings.Unbounded;

      function Convert (S : String) return String is
         -- Apply mapping to string (standard provides only for single characters)
         Result : String := S;
      begin
         for C : Character of Result loop
            C := Value (Mapping, C);
         end loop;
         return Result;
      end Convert;
   begin  -- Item
      if not Is_Open (From_Table) then
         raise Table_Status_Error;
      end if;
      if From_Table.At_End then
         raise Table_End_Error;
      end if;

      return Convert (Unquote (Extract (To_String (From_Table.Current_Line),
                                        From_Table.Current_Bounds.all,
                                        Position,
                                        Default)));
   end Item;

end Csv.Table_Manager;
