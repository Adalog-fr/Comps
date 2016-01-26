----------------------------------------------------------------------
--  Variable_Length.Io - Package body                               --
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

package body Variable_Length.IO is

   --------------
   -- Get_Line --
   --------------

   procedure Get_Line (File : in  File_Type ;
                       Item : out Variable_String )  is
   begin
      Get_Line (File, Item.Content, Item.Length);
   end Get_Line;

   --------------
   -- Get_Line --
   --------------

   procedure Get_Line (Item : out Variable_String)  is
   begin
      Get_Line (Item.Content, Item.Length);
   end Get_Line;

   --------------
   -- Get_Line --
   --------------

   function Get_Line (Max : Natural := 0) return Variable_String is
   begin
      if Max = 0 then
         declare
            Str : constant String := Get_Line;
         begin
            return (Str'Length, Str'Length, Str);
         end;
      else
         declare
            Str : String (1 .. Max);
            Len : Natural;
         begin
            Get_Line (Str, Len);
            return (Max, Len, Str (1..Len));
         end;
      end if;
   end Get_Line;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (File : in File_Type ;
                       Item : in Variable_String)  is
   begin
      Put_Line (File, To_String (Item));
   end Put_Line;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Item : in Variable_String)  is
   begin
      Put_Line (To_String (Item));
   end Put_Line;

   ---------
   -- Put --
   ---------

   procedure Put (File : in File_Type ;
                  Item : in Variable_String)  is
   begin
      Put (File, To_String (Item));
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (Item : in Variable_String)  is
   begin
      Put (To_String (Item));
   end Put;

end Variable_Length.IO;
