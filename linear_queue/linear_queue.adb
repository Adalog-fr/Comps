----------------------------------------------------------------------
--  Linear_Queue - Package body                                     --
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

with -- Ada
  Ada.Unchecked_Deallocation;

package body Linear_Queue is

   procedure Free is new Ada.Unchecked_Deallocation (Node,      Cursor);
   procedure Free is new Ada.Unchecked_Deallocation (Component, Component_Access);

   ------------
   -- Append --
   ------------

   procedure Append (To : in out Queue; Element : in Component) is
   begin
      if Has_Element (To.Last) then
         To.Last.Next := new Node'(Element => new Component'(Element), Next => To.Last.Next);
         To.Last := To.Last.Next;
      else
         Prepend (To, Element);
      end if;
   end Append;

   ------------
   -- Append --
   ------------

   procedure Append (To : in out Queue; Container : in Queue) is
      Ptr : Cursor := Container.First;
   begin
      while Ptr /= null loop
         Append (To, Ptr.Element.all);
         Ptr := Ptr.Next;
      end loop;
   end Append;

   -------------
   -- Prepend --
   -------------

   procedure Prepend (To : in out Queue; Element : in Component) is
   begin
      To.First := new Node'(Element => new Component'(Element), Next => To.First);
      if To.First.Next = null then
         To.Last  := To.First;
      end if;
   end Prepend;

   --------------
   -- Is_Empty --
   --------------

   function  Is_Empty (Container : in Queue) return Boolean is (Container = Empty_Queue);

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out Queue; Nb_Elems : in Natural := Natural'Last) is
      Current   : Cursor;
   begin
      for Elem_Count in Natural range 1 .. Nb_Elems loop
         Current := Container.First;
         exit when not Has_Element (Current);
         Container.First := Container.First.Next;
         Free (Current.Element);
         Free (Current);
      end loop;

      if Container.First = null then
         Container.Last := null;
      end if;
   end Clear;

   -----------
   -- First --
   -----------

   function First (Container : in Queue) return Cursor is
   begin
      return Container.First;
   end First;

   ----------
   -- Last --
   ----------

   function Last (Container : in Queue) return Cursor is
   begin
      return Container.Last;
   end Last;


   ----------
   -- Next --
   ----------

   function Next (Position : in Cursor) return Cursor is
   begin
      return Position.Next;
   end Next;

   -----------
   -- Fetch --
   -----------

   function Fetch (Position : in Cursor) return Component is
   begin
      return Position.Element.all;
   end Fetch;

   -------------
   -- Replace --
   -------------

   procedure Replace (Position : in Cursor; Element : in Component) is
   begin
      Free (Position.Element);
      Position.Element := new Component'(Element);
   end Replace;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (Position : in Cursor) return Boolean is
   begin
      return Position /= null;
   end Has_Element;

   ------------
   -- Adjust --
   ------------

   procedure Adjust (Container : in out Queue) is
      Current : Cursor;
   begin
      if not Has_Element (Container.First) then
         return;
      end if;

      Container.First := new Node'(Element => new Component'(Container.First.Element.all),
                                   Next    => Container.First.Next);
      Current := Container.First;
      Container.Last := Current;
      while Has_Element (Current.Next) loop
         Current.Next := new Node'(Element => new Component'(Current.Next.Element.all),
                                   Next    => Current.Next.Next);
         Current := Current.Next;
         Container.Last := Current;
      end loop;
   end Adjust;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Container : in out Queue) is
   begin
      Clear (Container);
   end Finalize;

end Linear_Queue;
