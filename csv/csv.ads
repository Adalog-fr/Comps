----------------------------------------------------------------------
--  CSV - Package specification                                     --
--  Copyright (C) 2021 Adalog                                       --
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

package CSV is
   type Bounds is
      record
         Start : Positive;
         Stop  : Natural;
      end record;
   type Fields_Bounds is array (Positive range <>) of Bounds;

   function Get_Bounds (Item : String; Separator : Character := ',') return Fields_Bounds;
   -- Give the bounds of the various "fields" in Item.
   -- Fields are substrings, separated by (unquoted) Separator

   function Extract (Item : String; Fields : Fields_Bounds; Column : Positive) return String;
   -- Get the Column'th Field of Item (trusting Fields for bounds)
   -- The field is provided "as is", i.e. with quotation marks if it is quoted.

   function Quote (Item : String) return String;
   -- Surrounds Item with " and doubles any " inside Item.

   function Unquote (Item : String) return String;
   -- If the first character of Item is ", removes the quotes and change any inner double quotes to
   -- single quotes. Returns Item as-is if it doesn't start with ".
   -- Raises CSV_Data_Error if first character is " and last character isn't ".

   function Unquote (Item : String; Slice : Bounds; Size : Natural := 0) return String;
   -- (fixed size version of previous function).
   -- If unquoted Item is smaller than Size, extend it to Size with spaces.
   -- If unquoted Item is longer than Size, truncate it to Size.

   CSV_Data_Error : exception;

end CSV;
