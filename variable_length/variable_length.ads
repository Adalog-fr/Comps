----------------------------------------------------------------------
--  Variable_Length - Package specification                         --
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

with Ada.Strings;
package Variable_Length is
   pragma Pure (Variable_Length);
   pragma Elaborate_Body;

   type Variable_String (Max : Positive) is private;

   function Length (Source : Variable_String) return Natural;

   procedure Move (Source : in  Variable_String;
                   Target : out Variable_String;
                   Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error);

   function  To_String  (Source : Variable_String) return String;
   function  To_Variable_String (Max    : Positive;
                                 Source : String := "";
                                 Drop   : Ada.Strings.Truncation := Ada.Strings.Error)
      return Variable_String;
   procedure To_Variable_String (Source : in  String := "";
                                 Target : out Variable_String;
                                 Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error);

   function "&" (Left : Variable_String; Right : String)          return Variable_String ;
   function "&" (Left : Variable_String; Right : Character)       return Variable_String ;
   function "&" (Left : Variable_String; Right : Variable_String) return Variable_String ;

   function "="  (Left : Variable_String; Right : Variable_String) return Boolean;
   function "="  (Left : Variable_String; Right : String         ) return Boolean;
   function "="  (Left : String;          Right : Variable_String) return Boolean;

   function "<"  (Left : Variable_String; Right : Variable_String) return Boolean;
   function "<"  (Left : Variable_String; Right : String         ) return Boolean;
   function "<"  (Left : String;          Right : Variable_String) return Boolean;

   function "<=" (Left : Variable_String; Right : Variable_String) return Boolean;
   function "<=" (Left : Variable_String; Right : String         ) return Boolean;
   function "<=" (Left : String;          Right : Variable_String) return Boolean;

   function ">"  (Left : Variable_String; Right : Variable_String) return Boolean;
   function ">"  (Left : Variable_String; Right : String         ) return Boolean;
   function ">"  (Left : String;          Right : Variable_String) return Boolean;

   function ">=" (Left : Variable_String; Right : Variable_String) return Boolean;
   function ">=" (Left : Variable_String; Right : String         ) return Boolean;
   function ">=" (Left : String;          Right : Variable_String) return Boolean;

   Length_Error : exception renames Ada.Strings.Length_Error;

private
   type Variable_String (Max : Positive) is
      record
         Length  : Natural := 0;
         Content : String (1..Max);
      end record;
end Variable_Length;
