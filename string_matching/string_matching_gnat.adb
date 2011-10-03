----------------------------------------------------------------------
--  String_Matching_Gnat - Package body                             --
--                                                                  --
--  This software  is (c) The European Organisation  for the Safety --
--  of Air  Navigation (EUROCONTROL) and Adalog  2004-2005. The Ada --
--  Controller  is  free software;  you can redistribute  it and/or --
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
--  from the units  of this program, or if you  link this unit with --
--  other files  to produce  an executable, this  unit does  not by --
--  itself cause the resulting executable  to be covered by the GNU --
--  General  Public  License.   This  exception  does  not  however --
--  invalidate any  other reasons why the executable  file might be --
--  covered by the GNU Public License.                              --
--                                                                  --
--  This  software is  distributed  in  the hope  that  it will  be --
--  useful,  but WITHOUT  ANY  WARRANTY; without  even the  implied --
--  warranty  of  MERCHANTABILITY   or  FITNESS  FOR  A  PARTICULAR --
--  PURPOSE.                                                        --
----------------------------------------------------------------------

with  -- Ada
  Ada.Characters.Handling,
  Ada.Exceptions;
package body String_Matching_Gnat is

   -------------
   -- Compile --
   -------------

   function Compile (Pattern     : Wide_String;
                     Ignore_Case : Boolean := False) return Compiled_Pattern
   is
      use GNAT.Regpat, Ada.Exceptions, Ada.Characters.Handling;
   begin
      -- Call the inherited "Compile":
      if Ignore_Case then
         return Compile (To_String (Pattern), Flags => Case_Insensitive);
      else
         return Compile (To_String (Pattern), Flags => No_Flags);
      end if;
   exception
      when Occur : Expression_Error =>
         Raise_Exception (Pattern_Error'Identity, Message => Exception_Message (Occur));
   end Compile;

   ------------------------------
   -- Match (Compiled_Pattern) --
   ------------------------------

   function Match (Source : Wide_String; Pattern : Compiled_Pattern) return Boolean is
      use Ada.Characters.Handling;
      String_Source : constant String := To_String (Source);
   begin
      -- We do not use the version of Match that returns a boolean, because it was not
      -- provided in GNAT 3.15p.
      -- Anyway, the expression below is exactly what it does...
      return Match (Pattern, String_Source) >= String_Source'First;
   end Match;

   --------------------
   -- Match (String) --
   --------------------

   function Match (Source      : Wide_String;
                   Pattern     : Wide_String;
                   Ignore_Case : Boolean := False) return Boolean
   is
   begin
      return Match (Source, Compile (Pattern, Ignore_Case));
   end Match;

end String_Matching_Gnat;
