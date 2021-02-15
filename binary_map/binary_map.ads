----------------------------------------------------------------------
--  Binary_Map - Package specification                              --
--  Copyright (C) 2005, 2021 Adalog                                 --
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

generic
   type Key_Type   is private;
   type Value_Type is private;
   with function "<" (Left, Right : Key_Type) return Boolean is <>;
   with function ">" (Left, Right : Key_Type) return Boolean is <>;
package Binary_Map is
   type Map is private;     -- Object semantic
   Empty_Map : constant Map;

   Not_Present : exception;

   procedure Add        (To     : in out Map; Key : in Key_Type; Value : in Value_Type);
   -- Adds Value to map for key
   -- If key already present, replaces the existing value
   procedure Delete     (From   : in out Map; Key : in Key_Type);
   -- Removes Key from map
   function  Fetch      (From   : in     Map; Key : in Key_Type) return Value_Type;
   -- Get a value from Map
   -- Raises Not_Present if Key not found
   function  Fetch   (From : in Map; Key : in Key_Type; Default_Value : in Value_Type)
                      return Value_Type;
   -- Get a value from Map
   -- Returns Default_Value if Key not found

   function Is_Empty (The_Map : in Map) return Boolean;
   -- Check if there are elements

   function  Is_Present (Within : in Map; Key : in Key_Type) return Boolean;

   Delete_Current : exception;
   -- If this exception is propagated from the Action procedure during Iterate,
   -- the corresponding node is removed from the map

   generic
      with procedure Action (Key : in Key_Type; Value : in out Value_Type);
   procedure Iterate (On : in out Map);
   -- Inner iterator

   procedure Balance (The_Map : in out Map);
   -- Rebalance the binary map.

   procedure Clear (The_Map : in out Map);
   -- Clear all elements

   generic
      with procedure Release (Value : in out Value_Type);
   procedure Generic_Clear_And_Release (The_Map : in out Map);
   -- Clear all elements, calling Release on each node value

private
   type Slots is (Before, After);
   type Two_Pool is array (Slots) of Map;
   type Node is
      record
         Key      : Key_Type;
         Value    : Value_Type;
         Children : Two_Pool;
      end record;
   type Map is access Node;
   Empty_Map : constant Map := null;
end Binary_Map;


