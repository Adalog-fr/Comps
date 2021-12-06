----------------------------------------------------------------------
--  CSV.Table_Manager - Package specification                       --
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

with
  Ada.Strings.Maps;

private with
  Ada.Strings.Unbounded,
  Ada.Text_IO;
package Csv.Table_Manager is
   use Ada.Strings.Maps;

   type Table is limited private;
   -- A Table represented as a CSV file.
   -- First line is assumed to contain column names

   -- Iterator
   procedure Open  (The_Table : in out Table; On_File : in String; Separator : in Character := ',');
   procedure Close (The_Table : in out Table);
   procedure Skip  (The_Table : in out Table);
   function  End_Of_Table (The_Table : Table) return Boolean;
   function  Is_Open (The_Table : Table) return Boolean;

   function Header      (The_Table : in Table) return String;
   function Source_Line (The_Table : in Table) return String;

   function Number_Of_Fields (The_Table : Table)                      return Positive;

   -- Mapping between column positions and column names
   function Position_Of      (In_Table  : Table; Name : String)       return Natural;
   function Name_Of          (In_Table  : Table; Position : Positive) return String;

   -- Accessors (by name or position)
   function Item (From_Table : Table; Name     : String;   Mapping : Character_Mapping := Identity) return String;
   function Item (From_Table : Table; Position : Positive; Mapping : Character_Mapping := Identity) return String;

   Table_Status_Error : exception;
private
   type Bounds_Access is access Fields_Bounds;
   type Table is
      record
         The_File       : Ada.Text_IO.File_Type;
         At_End         : Boolean;
         Separator      : Character;
         Header_Line    : Ada.Strings.Unbounded.Unbounded_String;
         Header_Bounds  : Bounds_Access;
         Current_Line   : Ada.Strings.Unbounded.Unbounded_String;
         Current_Bounds : Bounds_Access;
      end record;
end Csv.Table_Manager;
