----------------------------------------------------------------------
--  Options_Analyzer - Package specification                        --
--  Copyright (C) 2002 Adalog                                       --
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

generic
   Binary_Options : String := "";
   Valued_Options : String := "";
   Tail_Separator : String := "";
package Options_Analyzer is
   pragma Elaborate_Body;

   -- Check if an option has been given on the command line.
   -- Option can be a Binary_Option, a Valued_Option, or ' ' for Tail
   function Is_Present (Option : Character) return Boolean;
   Tail : constant Character := ' ';

   -- Get the value of a Valued_Option
   -- Returns Default if the option was not given, or if there is no
   --   value and Explicit_Required is false. If Explicit_Required
   --   is true, and the option was given without value, Options_Error
   --   is raised.
   -- Whether the option was actually given can be tested with Is_Present
   function Value (Option            : Character;
                   Default           : String    := "";
                   Explicit_Required : Boolean   := False) return String;

   function Value (Option            : Character;
                   Default           : Integer   := 0;
                   Explicit_Required : Boolean   := False) return Integer;

   -- Returns everything that follows the Tail_Separator if any,
   -- or Default otherwise
   function Tail_Value (Default : String := "") return String;

   -- Number of parameters that are not options, nor values associated with
   -- Valued_Options
   function Parameter_Count return Natural;

   -- Returns the value of Number'th parameter
   function Parameter (Number : Positive) return String;

   -- Returns the raw option string
   -- If with_command is True, include the command name
   function Option_String (With_Command : Boolean := False) return String;

   -- Exception raised by analyze when the command line
   -- is invalid.
   -- Note that an invalid use of any of the provided facilities
   -- will raise Program_Error.
   Options_Error : exception;
end Options_Analyzer;
