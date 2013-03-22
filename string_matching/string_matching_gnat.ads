----------------------------------------------------------------------
--  String_Matching_Gnat - Package specification                    --
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

with  -- Gnat specific units
  -- For private part only:
  GNAT.Regpat;  --## rule line off WITH_CLAUSES ## no message about private with (95 compatible)
package String_Matching_Gnat is
   pragma Elaborate_Body;

   -- Check if "Name" matches "Pattern"
   function Match (Source      : Wide_String;
                   Pattern     : Wide_String;
                   Ignore_Case : Boolean := False) return Boolean;

   -- Using precompiled pattern
   type Compiled_Pattern (<>) is private;
   function Compile (Pattern     : Wide_String;
                     Ignore_Case : Boolean := False) return Compiled_Pattern;
   function Match   (Source : Wide_String; Pattern : Compiled_Pattern) return Boolean;

   Pattern_Error : exception;

private
   type Compiled_Pattern is new GNAT.Regpat.Pattern_Matcher;

end String_Matching_Gnat;
