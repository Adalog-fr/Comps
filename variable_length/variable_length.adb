----------------------------------------------------------------------
--  Variable_Length - Package body                                  --
--  Copyright (C) 1997-2015 Adalog                                  --
--  Author: J-P. Rosen                                              --
--                                                                  --
--  ADALOG   is   providing   training,   consultancy,   expertise, --
--  assistance and custom developments  in Ada and related software --
--  engineering techniques.  For more info about our services:      --
--  ADALOG                          Tel: +33 1 45 29 21 52          --
--  2 rue du Docteur Lombard        Fax: +33 1 45 29 25 00          --
--  92441 ISSY LES MOULINEAUX CEDEX E-m: info@adalog.fr             --
--  FRANCE                          URL: http://www.adalog.fr       --
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

package body Variable_Length is

   ------------
   -- Length --
   ------------

   function Length (Source : Variable_String) return Natural is
   begin
      return Source.Length;
   end Length;

   ----------
   -- Move --
   ----------

   procedure Move (Source : in  Variable_String;
                   Target : out Variable_String;
                   Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error) is
   begin
      To_Variable_String (To_String(Source), Target, Drop);
   end Move;

   ---------------
   -- To_String --
   ---------------

   function To_String (Source : Variable_String) return String is
   begin
      return Source.Content (1..Source.Length);
   end To_String;

   ------------------------
   -- To_Variable_String --
   ------------------------

   function To_Variable_String (Max    : Positive;
                                Source : in  String := "";
                                Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error)
      return Variable_String
   is
      Local_Object : Variable_String (Max);
   begin
      To_Variable_String (Source, Local_Object, Drop);
      return Local_Object;
   end To_Variable_String;

   ------------------------
   -- To_Variable_String --
   ------------------------

   procedure To_Variable_String (Source : in  String := "";
                                 Target : out Variable_String;
                                 Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error)
   is
      use Ada.Strings;
   begin
      if Target.Max >= Source'Length then
         Target.Length := Source'Length;
         Target.Content (1..Target.Length) := Source;
      else
         case Drop is
         when Left  =>
            Target.Length  := Source'Length;
            Target.Content := Source(Source'Last-Target.Max+1 .. Source'Last);
         when Right =>
            Target.Length  := Source'Length;
            Target.Content := Source(Source'First .. Source'First+Target.Max-1);
         when Error =>
            raise Length_Error;
         end case;
      end if;
   end To_Variable_String;

   ---------
   -- "&" --
   ---------

   function "&" (Left : Variable_String; Right : String) return Variable_String is
      Result : Variable_String := Left;
   begin
      if Result.Length + Right'Length > Result.Max then
         raise Length_Error;
      else
         Result.Content(Result.Length+1 .. Result.Length+Right'Length) := Right;
         Result.Length := Result.Length + Right'Length;
      end if;
      return Result;
   end "&";

   ---------
   -- "&" --
   ---------

   function "&" (Left : Variable_String; Right : Character) return Variable_String is
      Result : Variable_String := Left;
   begin
      if Result.Length = Result.Max then
         raise Length_Error;
      else
         Result.Length := Result.Length + 1;
         Result.Content(Result.Length) := Right;
      end if;
      return Result;
   end "&";

   ---------
   -- "&" --
   ---------

   function "&" (Left : Variable_String; Right : Variable_String) return Variable_String is
   begin
      return Left & To_String(Right);
   end "&";

   ---------
   -- "=" --
   ---------

   function "=" (Left : Variable_String; Right : Variable_String) return Boolean is
   begin
      return To_String(Left) = To_String(Right);
   end "=";

   ---------
   -- "=" --
   ---------

   function "=" (Left : Variable_String; Right : String) return Boolean is
   begin
      return To_String(Left) = Right;
   end "=";

   ---------
   -- "=" --
   ---------

   function "=" (Left : String; Right : Variable_String) return Boolean is
   begin
      return Left = To_String(Right);
   end "=";

   ---------
   -- "<" --
   ---------

   function "<" (Left : Variable_String; Right : Variable_String) return Boolean is
   begin
      return To_String(Left) < To_String(Right);
   end "<";

   ---------
   -- "<" --
   ---------

   function "<" (Left : Variable_String; Right : String) return Boolean is
   begin
      return To_String(Left) < Right;
   end "<";

   ---------
   -- "<" --
   ---------

   function "<" (Left : String; Right : Variable_String) return Boolean is
   begin
      return Left < To_String(Right);
   end "<";

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Variable_String; Right : Variable_String) return Boolean is
   begin
      return To_String(Left) <= To_String(Right);
   end "<=";

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Variable_String; Right : String) return Boolean is
   begin
      return To_String(Left) <= Right;
   end "<=";

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : String; Right : Variable_String) return Boolean is
   begin
      return Left <= To_String(Right);
   end "<=";

   ---------
   -- ">" --
   ---------

   function ">" (Left : Variable_String; Right : Variable_String) return Boolean is
   begin
      return To_String(Left) > To_String(Right);
   end ">";

   ---------
   -- ">" --
   ---------

   function ">" (Left : Variable_String; Right : String) return Boolean is
   begin
      return To_String(Left) > Right;
   end ">";

   ---------
   -- ">" --
   ---------

   function ">" (Left : String; Right : Variable_String) return Boolean is
   begin
      return Left > To_String(Right);
   end ">";

   ----------
   -- ">=" --
   ----------

   function ">=" (Left : Variable_String; Right : Variable_String) return Boolean is
   begin
      return To_String(Left) >= To_String(Right);
   end ">=";

   ----------
   -- ">=" --
   ----------

   function ">=" (Left : Variable_String; Right : String) return Boolean is
   begin
      return To_String(Left) >= Right;
   end ">=";

   ----------
   -- ">=" --
   ----------

   function ">=" (Left : String; Right : Variable_String) return Boolean is
   begin
      return Left >= To_String(Right);
   end ">=";

end Variable_Length;
