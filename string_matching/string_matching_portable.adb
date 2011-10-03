----------------------------------------------------------------------
--  String_Matching_Portable - Package body                         --
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

with
  Ada.Strings.Wide_Maps,
  Ada.Strings.Wide_Maps.Wide_Constants;

package body String_Matching_Portable is

   --------------
   -- To_Upper --
   --------------

   function To_Upper (Item : in Wide_String) return Wide_String is
      use Ada.Strings.Wide_Maps, Ada.Strings.Wide_Maps.Wide_Constants;

      Result : Wide_String (1 .. Item'Length);
   begin
      for I in Item'Range loop
         Result (I - (Item'First - 1)) := Value (Upper_Case_Map, Item (I));
      end loop;

      return Result;
   end To_Upper;

   -------------
   -- Compile --
   -------------

   function Compile (Pattern     : Wide_String;
                     Ignore_Case : Boolean := False) return Compiled_Pattern
   is
   begin
      return ((Pattern'Length, Ignore_Case, Pattern));
   end Compile;

   ------------------------------
   -- Match (Compiled_Pattern) --
   ------------------------------

   function Match (Source : Wide_String; Pattern : Compiled_Pattern) return Boolean is
   begin
      return Match (Source, Pattern.Pattern, Pattern.Ignore_Case);
   end Match;

   --------------------
   -- Match (String) --
   --------------------

   function Match (Source      : Wide_String;
                   Pattern     : Wide_String;
                   Ignore_Case : Boolean := False) return Boolean
   is
      function Basic_Match (Source : Wide_String; Pattern : Wide_String) return Boolean is
         Pattern_Inx : Positive := Pattern'First;
         Source_Inx  : Positive := Source'First;
      begin
         loop
            case Pattern (Pattern_Inx) is
               when '?' =>
                  -- allways matches
                  null;

               when '*' =>
                  if Pattern_Inx = Pattern'Last then
                     -- Final '*'
                     return True;
                  end if;

                  for I in Source_Inx .. Source'Last loop
                     if Basic_Match (Source (I .. Source'Last), Pattern (Pattern_Inx + 1 .. Pattern'Last)) then
                        return True;
                     end if;
                  end loop;
                  return False;

               when others =>
                  if Pattern (Pattern_Inx) /= Source (Source_Inx) then
                     return False;
                  end if;
            end case;

            if Source_Inx = Source'Last then
               if Pattern_Inx = Pattern'Last then
                  return True;
               elsif Pattern_Inx = Pattern'Last - 1 and then Pattern (Pattern_Inx + 1) = '*' then
                  return True;
               else
                  return False;
               end if;
            elsif Pattern_Inx = Pattern'Last then
               return False;
            end if;

            Pattern_Inx := Pattern_Inx + 1;
            Source_Inx  := Source_Inx  + 1;
         end loop;
      end Basic_Match;

   begin
      if Ignore_Case then
         return Basic_Match (To_Upper (Source), To_Upper (Pattern));
      else
         return Basic_Match (Source, Pattern);
      end if;
   end Match;

end String_Matching_Portable;
