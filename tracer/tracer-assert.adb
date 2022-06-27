----------------------------------------------------------------------
-- Package Tracer.Assert (body)                                     --
-- (C) Copyright 2004, 2021 ADALOG                                  --
-- Author: J-P. Rosen                                               --
--                                                                  --
-- ADALOG is providing training, consultancy and expertise in Ada   --
-- and related software engineering techniques. For more info about --
-- our services:                                                    --
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

--## rule off No_Debug ## we obviously need to use Tracer here
with
  Ada.Task_Identification;
package body Tracer.Assert  is
   use Ada.Task_Identification;

   type Detector_Rec is
      record
         Caller : Task_Id := Null_Task_Id;
         Level  : Natural := 0;
         Message: Tracer_String_Access;
      end record;
   Detector_Table : array (Detector_Index) of Detector_Rec;

   -----------
   -- Check --
   -----------

   procedure Check (Assumption : Boolean; Message : String) is
   begin
      if not Assumption then
         Trace (Message);
      end if;
   end Check;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Item : in out R_Detector) is
      Temp : Tracer_String_Access := Item.Message;
   begin
      if Detector_Table (Item.Num).Caller = Current_Task then
         Detector_Table (Item.Num).Level := Detector_Table (Item.Num).Level - 1;
         if Detector_Table (Item.Num).Level = 0 then
            Detector_Table (Item.Num) := (Null_Task_Id, 0, null);
         end if;
      end if;
      Free (Temp);
   end Finalize;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Item : in out R_Detector) is
   begin
      if Detector_Table (Item.Num).Caller = Null_Task_Id then
         Detector_Table (Item.Num) := (Current_Task, 1, Item.Message);
      elsif Detector_Table (Item.Num).Caller = Current_Task then
         -- Recursive call
         Detector_Table (Item.Num).Level := Detector_Table (Item.Num).Level + 1;
      else
         Trace ("Reentrancy detected with " & Image (Detector_Table (Item.Num).Caller) &
                  ": " & String (Item.Message.all) &
                  " / " & String (Detector_Table (Item.Num).Message.all)) ;
      end if;
   end Initialize;

end Tracer.Assert;
