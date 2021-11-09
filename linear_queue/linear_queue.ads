----------------------------------------------------------------------
--  Linear_Queue - Package specification                            --
--  Copyright (C) 2006, 2021 Adalog                                 --
--  Author: J-P. Rosen, Pierre-Louis Escouflaire                    --
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

with  -- Ada
  Ada.Finalization;  --## rule line off WITH_CLAUSES ## no message about private with (95 compatible)

generic
   type Component (<>) is private;
package Linear_Queue is

   -- Type Queue has value semantics and automatic memory management
   type Queue is private;
   Empty_Queue : constant Queue;

   procedure Append  (To        : in out Queue; Element   : in Component);
   procedure Append  (To        : in out Queue; Container : in Queue);
   procedure Prepend (To        : in out Queue; Element   : in Component);
   procedure Clear   (Container : in out Queue; Nb_Elems  : in Natural := Natural'Last);
   -- Removes the first Nb_Elems elements from the Queue.
   -- Any cursor pointing into the removed elements must be reinitialized (no tampering checks!)
   function  Is_Empty (Container : in Queue) return Boolean;


   --
   -- Iterator
   --

   type Cursor is private;

   function  First       (Container : in Queue)  return Cursor;
   function  Last        (Container : in Queue)  return Cursor;
   function  Next        (Position  : in Cursor) return Cursor;
   function  Has_Element (Position  : in Cursor) return Boolean;

   -- These subprograms raise Constraint_Error if not Has_Element (Position)
   function  Fetch       (Position  : in Cursor) return Component;
   procedure Replace     (Position  : in Cursor; Element : in Component);

private

   -- As the component type can be indefinite, we need
   -- to define an access type to the component type.
   type Component_Access is access Component;

   type Node;
   type Cursor is access Node;
   type Node is
      record
         Element : Component_Access;
         Next    : Cursor;
      end record;

   type Queue is new Ada.Finalization.Controlled with
      record
         First : Cursor;
         Last  : Cursor;
      end record;

   -- No need to initialize, pointers are initialized to null
   overriding procedure Adjust   (Container : in out Queue);
   overriding procedure Finalize (Container : in out Queue);

   Empty_Queue : constant Queue  := (Ada.Finalization.Controlled with null, null);
end Linear_Queue;
