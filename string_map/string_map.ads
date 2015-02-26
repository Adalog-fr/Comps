-- This package provides an iterator over strings with the following syntax:
--    <to_parse>       ::= <association> {';' <association>} [';']
--    <association>    ::= <key> '=' <value>
--    <key>            ::= 'a'..'z' | 'A'..'Z' | '0'..'9' | '_'
--    <value>          ::= <quoted_value> | <unquoted_value>
--    <quoted_value>   ::= '"' <any character with quotes doubled> '"'
--    <unquoted_value> ::= <any character except quote> {<any character except ';' and ' '>}
-- Spaces before and after <key> and <value> are skipped
-- Example:
-- P1 = "some value including "";""";  P_2=  simple_value  ;
-- First key= P1
-- First value = some value including ";"
-- Second_Key = P_2
-- Second value = simple_value  (without leading and trailing spaces)
--
-- Any syntax error raises Parse_Error

pragma Ada_2012;
with  -- Standard units
  Ada.Iterator_Interfaces;

package String_Map is
   type Cursor (<>) is private;
   Empty_Cursor : constant Cursor;
   function Has_Element (Position : Cursor) return Boolean;

   package Iterator is new Ada.Iterator_Interfaces (Cursor, Has_Element);
   function Parse (Params : String) return Iterator.Forward_Iterator'Class;

   function Key   (C : Cursor) return String;
   function Value (C : Cursor) return String;

   Parse_Error : exception;
private
   type Cursor (Length : Natural) is
      record
         Params  : String (1..Length);
         Current : Natural := 0;
         K_First : Natural;
         K_Last  : Positive;
         V_First : Positive;
         V_Last  : Positive;
      end record;

   Empty_Cursor : constant Cursor := (Length => 0, Params => "", K_First => 0, others => 1);
end string_map;
