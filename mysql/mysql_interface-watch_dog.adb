separate (Mysql_Interface)
task body Watch_Dog is
   use Ada.Calendar;

   Hour          : constant        := 3600;
   Dummy_Request : constant String := "SELECT 1 FROM client WHERE 0";
   My_Statement  : Odbc2.Cursor_Type (0,0);
   Granted       : Boolean;
begin
   loop
      select
         accept Start;
      or
         accept Stop;
      or
         terminate;
      end select;

      loop
         select
            accept Stop;
            exit;
         or
            accept Reset_Time_Out;
         or
            delay 3.0*Hour;

            Sema.Non_Blocking_P (Granted);
            -- If not granted, somebody is issuing a request, this will reset the data base
            -- => no need to do anything special
            if Granted then
               begin
                  -- We don't call Exec_SQL here, since it would call
                  -- Watch_Dog.Reset_Time_Out and dead-lock.
                  Odbc2.Open    (My_Statement, Connection, Dummy_Request);
                  Odbc2.Execute (My_Statement);
                  Odbc2.Close   (My_Statement);
                  Sema.V;
               exception
                  when others =>
                     Sema.V;
                     raise;
               end;
            end if;

         end select;
      end loop;
   end loop;

   --TBSL: Report error
--  exception
--     when The_Error : others =>
--        Message (Log, "Exception dans Watch_Dog : " & Ada.Exceptions.Exception_Information(The_Error));
end Watch_Dog;
