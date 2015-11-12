------------------------------------------------------------------------------
-- Package VARIABLE_LENGTH (specification)                                   --
-- (C) Copyright 1997 ADALOG                                                 --
-- Author: J-P. Rosen                                                        --
--                                                                           --
-- Rights to use, distribute or modify this package in any way is hereby     --
-- granted, provided this header is kept unchanged in all versions and the   --
-- associated documentation file is distributed unchanged. Additionnal       --
-- headers or documentation may be added.                                    --
-- All modifications must be properly marked as not originating from Adalog. --
-- If you make a valuable addition, please keep us informed by sending a     --
-- message to rosen.adalog@wanadoo.fr                                        --
--                                                                           --
-- ADALOG is providing training, consultancy and expertise in Ada and        --
-- related software engineering techniques. For more info about our services:--
-- ADALOG                   Tel: +33 1 41 24 31 40                           --
-- 19-21 rue du 8 mai 1945  Fax: +33 1 41 24 07 36                           --
-- 94110 ARCUEIL            E-m: rosen.adalog@wanadoo.fr                     --
-- FRANCE                   URL: http://pro.wanadoo.fr/adalog                --
--                                                                           --
-- This package is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY  --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                      --
-------------------------------------------------------------------------------
with Ada.Strings;
package Variable_Length is
   pragma Pure (Variable_Length);
   pragma Elaborate_Body;

   type Variable_String (Max : Positive) is private;

   function Length (Source : Variable_String) return Natural;

   procedure Move (Source : in  Variable_String;
                   Target : out Variable_String;
                   Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error);

   function  To_String  (Source : Variable_String) return String;
   function  To_Variable_String (Max    : Positive;
                                 Source : String := "";
                                 Drop   : Ada.Strings.Truncation := Ada.Strings.Error)
      return Variable_String;
   procedure To_Variable_String (Source : in  String := "";
                                 Target : out Variable_String;
                                 Drop   : in  Ada.Strings.Truncation := Ada.Strings.Error);

   function "&" (Left : Variable_String; Right : String)          return Variable_String ;
   function "&" (Left : Variable_String; Right : Character)       return Variable_String ;
   function "&" (Left : Variable_String; Right : Variable_String) return Variable_String ;

   function "="  (Left : Variable_String; Right : Variable_String) return Boolean;
   function "="  (Left : Variable_String; Right : String         ) return Boolean;
   function "="  (Left : String;          Right : Variable_String) return Boolean;

   function "<"  (Left : Variable_String; Right : Variable_String) return Boolean;
   function "<"  (Left : Variable_String; Right : String         ) return Boolean;
   function "<"  (Left : String;          Right : Variable_String) return Boolean;

   function "<=" (Left : Variable_String; Right : Variable_String) return Boolean;
   function "<=" (Left : Variable_String; Right : String         ) return Boolean;
   function "<=" (Left : String;          Right : Variable_String) return Boolean;

   function ">"  (Left : Variable_String; Right : Variable_String) return Boolean;
   function ">"  (Left : Variable_String; Right : String         ) return Boolean;
   function ">"  (Left : String;          Right : Variable_String) return Boolean;

   function ">=" (Left : Variable_String; Right : Variable_String) return Boolean;
   function ">=" (Left : Variable_String; Right : String         ) return Boolean;
   function ">=" (Left : String;          Right : Variable_String) return Boolean;

   Length_Error : exception renames Ada.Strings.Length_Error;

private
   type Variable_String (Max : Positive) is
      record
         Length  : Natural := 0;
         Content : String (1..Max);
      end record;
end Variable_Length;

