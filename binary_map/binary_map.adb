----------------------------------------------------------------------
--  Binary_Map - Package body                                       --
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

with Ada.Unchecked_Deallocation;
package body Binary_Map is
   procedure Free is new Ada.Unchecked_Deallocation (Node, Map);

   --
   -- Internal utilities
   --

   --------------
   -- Get_Node --
   --------------

   function Get_Node (M : Map; Key : Key_Type) return Map is
      Current : Map := M;
   begin
      loop
         if Current = null then
            -- Not found
            return null;

         elsif Key < Current.Key then
            Current := Current.Children (Before);

         elsif Key > Current.Key then
            Current := Current.Children (After);

         else
            -- Found
            return Current;
         end if;
      end loop;
   end Get_Node;

   ---------------
   -- Linearize --
   ---------------

   procedure Linearize (M : Map; First, Last : out Map; Count : out Natural) is
      -- Precondition: M is not null
      -- Postconditions: First is the first element of a linear tree (all Left pointers are null)
      --                 Last is the last element
      --                 Count is the number of elements in the tree

      Temp_Map   : Map;
      Temp_Count : Natural;
   begin
      Count := 1;
      if M.Children (Before) = null then
         First := M;
      else
         Linearize (M.Children (Before), First, Temp_Map, Temp_Count);
         Temp_Map.Children (After) := M;
         Count          := Count + Temp_Count;
      end if;
      M.Children (Before) := null;

      if M.Children (After) = null then
         Last := M;
      else
         Linearize (M.Children (After), Temp_Map, Last, Temp_Count);
         M.Children (After) := Temp_Map;
         Count   := Count + Temp_Count;
      end if;
   end Linearize;

   --------------
   --Rebalance --
   --------------

   procedure Rebalance (M : in out Map; Size : Natural; Rest : out Map) is
      -- Precondition: M is a linear tree (all Before pointers are null)
      -- Postcondions: M is a balanced tree containing the first Size elements
      --               Rest is the first of the remaining elements from the linear tree
      Top : Map;
      Left : Map;
   begin
      case Size is
         when 0 =>
            Rest := M;
            M    := null;

         when 1 =>
            Rest    := M.Children (After);
            M.Children (After) := null;

         when others =>
            Left := M;
            Rebalance (Left, (Size-1) / 2, Top);
            Top.Children (Before) := Left;
            Rebalance (Top.Children (After), Size - (Size-1)/2 - 1, Rest);
            M := Top;
      end case;
   end Rebalance;


   --
   -- Exported subprograms
   --

   ---------
   -- Add --
   ---------

   procedure Add (To    : in out Map;
                  Key   : in     Key_Type;
                  Value : in     Value_Type)
   is
   begin
      if To = null then
         To := new Node'(Key, Value, (null, null));
         return;
      end if;

      if Key < To.Key then
         Add (To.Children (Before), Key, Value);
      elsif Key = To.Key then
         To.Value := Value;
      else
         Add (To.Children (After), Key, Value);
      end if;
   end Add;

   -------------
   -- Balance --
   ------------

   procedure Balance (The_Map : in out Map) is
      First, Last : Map;
      Count       : Natural;
   begin
      if The_Map = null then
         return;
      end if;

      Linearize (The_Map, First, Last, Count);
      The_Map := First;
      Rebalance  (The_Map, Count, First);
   end Balance;

   ------------
   -- Delete --
   ------------

   procedure Delete (From : in out Map; Key : Key_Type) is
      Count1, Count2: Natural;
      Last     : Map;
      Parent   : Map := null;
      Slot     : Slots;
      Cur_Node : Map := From;
      Result   : Map;
   begin
      loop
         if Cur_Node = null then
            -- Not found
            raise Not_Present;

         elsif Key > Cur_Node.Key then
            Slot   := After;

         elsif Key < Cur_Node.Key then
            Slot   := Before;

         else
            -- Found
            exit;
         end if;
         Parent   := Cur_Node;
         Cur_Node := Cur_Node.Children (Slot);
      end loop;

      if Cur_Node.Children (Before) = null then
         if Cur_Node.Children (After) = null then
            Result := null;
         else
            Result := Cur_Node.Children (After);
         end if;

      elsif Cur_Node.Children (After) = null then
         Result := Cur_Node.Children (Before);

      else
         -- At this point, deleting the node involves walking down the tree.
         -- it is not much more effort to rebalance (and actually simpler to program)
         Linearize (Cur_Node.Children (Before), Result,                 Last, Count1);
         Linearize (Cur_Node.Children (After),  Last.Children (After),  Last, Count2);
         Rebalance (Result, Count1 + Count2, Last);
      end if;

      if Parent = null then
         From := Result;
      else
         Parent.Children (Slot) := Result;
      end if;
      Free (Cur_Node);
   end Delete;

   -----------
   -- Fetch --
   -----------

   function Fetch (From : Map; Key : Key_Type) return Value_Type is
      Cur_Node : constant Map := Get_Node (From, Key);
   begin
      if Cur_Node = null then
         raise Not_Present;
      end if;

      return Cur_Node.Value;
   end Fetch;

   -----------
   -- Fetch --
   -----------

   function Fetch (From : Map; Key : Key_Type; Default_Value : Value_Type) return Value_Type is
      Cur_Node : constant Map := Get_Node (From, Key);
   begin
      if Cur_Node = null then
         return Default_Value;
      end if;

      return Cur_Node.Value;
   end Fetch;

   ----------------
   -- Is_Present --
   ----------------

   function Is_Present (Within : Map; Key : Key_Type) return Boolean is
   begin
      return Get_Node (Within, Key) /= null;
   end Is_Present;

   -------------
   -- Iterate --
   -------------

   procedure Iterate (On : in out Map) is
      Delete_Node : Boolean := False;
   begin
      if On = null then
         return;
      end if;

      Iterate(On.Children (Before));
      begin
         Action(On.Key, On.Value);
      exception
         when Delete_Current =>
            Delete_Node := True;
      end;
      Iterate(On.Children (After));

      -- Deleting the node *after* traversing On.Children (After)
      -- makes sure that there is no problem with the tree being
      -- rearranged due to delete.
      if Delete_Node then
         Delete (On, On.Key);
      end if;
   end Iterate;

   -----------
   -- Clear --
   -----------

   procedure Clear (The_Map : in out Map) is
   begin
      if The_Map = null then
         return;
      end if;

      Clear (The_Map.Children (Before));
      Clear (The_Map.Children (After));
      Free (The_Map);
   end Clear;

   -------------------------------
   -- Generic_Clear_And_Release --
   -------------------------------

   procedure Generic_Clear_And_Release (The_Map : in out Map) is
   begin
      if The_Map = null then
         return;
      end if;

      Clear (The_Map.Children (Before));
      Clear (The_Map.Children (After));
      Release (The_Map.Value);
      Free (The_Map);
   end Generic_Clear_And_Release;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (The_Map : in Map) return Boolean is
   begin
      return The_Map = Empty_Map;
   end Is_Empty;

end Binary_Map;

