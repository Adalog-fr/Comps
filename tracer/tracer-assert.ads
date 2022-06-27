----------------------------------------------------------------------
-- Package Tracer.Assert (specification)                            --
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
private with
  Ada.Finalization;
package Tracer.Assert is
   procedure Check (Assumption : Boolean; Message : String);

   -- Reentrancy detector
   Max_Detector : constant := 10;
   type Detector_Index is range 1..Max_Detector;
   type R_Detector (Num : Detector_Index; Message : Tracer_String_Access) is limited private;

private
   type R_Detector (Num : Detector_Index; Message : Tracer_String_Access) is
     new Ada.Finalization.Limited_Controlled with null record;
   overriding procedure Finalize (Item : in out R_Detector);
   overriding procedure Initialize (Item : in out R_Detector);
end Tracer.Assert;
