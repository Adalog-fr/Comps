with -- Standard units
  Ada.Calendar;

package DB_Interface.Variable is
   procedure Set   (Variable : String; To : String);
   function  Value (Variable : String) return String;

   procedure Set   (Variable : String; To : Boolean);
   function  Value (Variable : String) return Boolean;

   procedure Set   (Variable : String; To : Integer);
   function  Value (Variable : String) return Integer;

   procedure Set   (Variable : String; To : Ada.Calendar.Time);
   function  Value (Variable : String) return Ada.Calendar.Time;

end DB_Interface.Variable;
