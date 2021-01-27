--## rule off No_Debug ## we obviously need to use Tracer here
with Tracer.Timing;
with Ada.Text_Io;

with Ttracer2;
procedure Ttracer is
   use Tracer, Ttracer2;

   My_Exception : exception;
   Final : Emergency_Exit;

   procedure Title (Message : String) is
      use Ada.Text_Io;
   begin
      New_Line;
      Put ("----------- ");
      Put_Line (Message);
   end Title;

   type Integer_Array is array (1..4) of Integer;
begin  --Ttracer
   Set_Watch (Put_Count'Access);

   -- Simple trace demo
   Title ("Demonstration of a simple recursive call");
   Timing.Name (1, "Recursive procedure");
   Timing.Start (1);
   Test_Trace (4, 0.0);
   Timing.Stop (1);
   Timing.Report_All;
   Pause;

   -- Stream trace
   Title ("Demonstration of tracing to a stream");
   Trace ("The string ""ABC""");
   String'Write (Trace_Stream, "ABC");
   Trace ("The Integer 16#00414243#");
   Integer'Write (Trace_Stream, 16#00414243#);
   Trace ("An array of Integer");
   Integer_Array'Write (Trace_Stream, (1, 2, 3, 4));
   Pause;

   -- Exception trace demo
   Title ("Demonstration of tracing an exception....");
   begin
      raise My_Exception;
   exception
      when Occur : others =>
         Trace ("This is an expected exception", Occur);
   end;
   Timing.Name (2, "How long you paused...");
   Timing.Start (2);
   Pause;
   Timing.Stop (2);
   -- We do not call Timing.Report here to demonstrate that it will
   -- automatically be called at the end of the program
   -- (although the main program is aborted!)

   -- Tasking trace demo
   Title ("Demonstration of a multi-task program");
   declare
      Task1 : Test_Task(1);
      Task2 : Test_Task(2);
      Task3 : Test_Task(3);
   begin
      Pause ("Tasks have started");
      Set_Timer (3.0, Process1'Access);
   end;
end Ttracer;
