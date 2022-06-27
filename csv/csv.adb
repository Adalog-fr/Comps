----------------------------------------------------------------------
--  CSV - Package body                                              --
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
  Ada.Strings.Fixed;
package body CSV is
   use Ada.Strings.Fixed;

   ----------------
   -- Get_Bounds --
   ----------------

   function Get_Bounds (Item : String; Separator : Character := ',') return Fields_Bounds is
      In_Quotes : Boolean := False;
   begin
      if Item = "" then
         raise CSV_Data_Error;
      end if;

      for I in Item'Range loop
         if Item(I) = '"' then
            In_Quotes := not In_Quotes;
         elsif not In_Quotes and Item (I) = Separator then
            return Bounds'(Item'First, I-1) & Get_Bounds (Item (I+1 .. Item'Last), Separator);
         end if;
      end loop;

      return (1 => (Item'First, Item'Last));
   end Get_Bounds;

   -------------
   -- Extract --
   -------------

   function Extract (Item : String; Fields : Fields_Bounds; Column : Positive; Default : String := "") return String is
   begin
      if Column > Fields'Last then
         return Default;
      end if;
      return Item( Fields(Column).Start .. Fields(Column).Stop );
   end Extract;

   -----------
   -- Quote --
   -----------

   function Quote (Item : String) return String is
      Result : String (Item'First .. Item'Last + Count (Item, """") + 2);
      Index  : Positive;
   begin
      Index := Result'First;
      Result (Index) := '"';

      for C : Character of Item loop
         if C = '"' then
            Index := Index + 1;
            Result (Index) := '"';
         end if;
         Index := Index + 1;
         Result (Index) := C;
      end loop;
      Result (Result'Last) := '"';

      return Result;
   end Quote;

   -------------
   -- Unquote --
   -------------

   function Unquote (Item : String) return String is
      Result    : String(Item'Range);
      Index_In  : Positive;
      Index_Out : Natural;
   begin
      if Item = "" or else Item (Item'First) /= '"' then
         return Item;
      end if;

      Index_In  := Item'First+1;
      Index_Out := Result'First-1;
      while Index_In <= Item'Last-1 loop
         if Item (Index_In) = '"' then
            Index_Out := Index_Out + 1;
            Result (Index_Out) := '"';
            if Item (Index_In+1) ='"' then
               Index_In := Index_In + 1;
            end if;
         else
            Index_Out := Index_Out + 1;
            Result (Index_Out) := Item (Index_In);
         end if;
         Index_In := Index_In + 1;
      end loop;

      if Item (Item'Last) /= '"' then
         raise CSV_Data_Error;
      end if;

      return Result (Result'First .. Index_Out);
   end Unquote;

   -------------
   -- Unquote --
   -------------

   function Unquote (Item : String; Slice : Bounds; Size : Natural := 0) return String is
      use Ada.Strings;
      Raw_Line : constant String := Unquote (Item (Slice.Start .. Slice.Stop));
   begin
      if Size = 0 then
         return Trim (Raw_Line, Both);
      elsif Raw_Line'Length < Size then
         return Raw_Line & (Size - Raw_Line'Length) * ' ';
      else
         return Raw_Line (Raw_Line'First .. Raw_Line'First + Size - 1);
      end if;
   end Unquote;

end CSV;
