----------------------------------------------------------------------
--  Generic_File_Iterator - Generic procedure body                  --
--  Copyright (C) 2018, 2021 Adalog                                 --
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
   Ada.Text_IO;

procedure Generic_File_Iterator (Name : String) is
   use Ada.Text_IO;

   Units_File : File_Type;

   function Read_Line return String is
      Buffer : String (1 .. 250);
      Last   : Natural;
   begin
      Get_Line (Units_File, Buffer, Last);
      if Last = Buffer'Last then
         return Buffer & Read_Line;
      else
         return Buffer (1 .. Last);
      end if;
   end Read_Line;

begin  -- Generic_File_Iterator
   Open (Units_File, In_File, Name);

   -- Exit on End_Error
   -- This is the simplest way to deal with improperly formed files
   loop
      Action (Read_Line);
   end loop;

   -- Never comes here

exception
   when End_Error =>
      -- normal exit
      Close (Units_File);
   when others =>
      if Is_Open (Units_File) then
         Close (Units_File);
      end if;
      raise;
end Generic_File_Iterator;

