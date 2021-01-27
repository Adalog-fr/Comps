--## rule off No_Debug ## we obviously need to use Tracer here
with Tracer.Assert;
use Tracer, Tracer.Assert;
pragma Elaborate_All (Tracer);
package body Ttracer2 is
   procedure Finalize (Item : in out Emergency_Exit) is
   begin
      Trace ("I must be dying...");
   end Finalize;

   procedure Test_Trace (Level : Integer; Hold_Time : Duration) is
      Tracer : Auto_Tracer (+"Test_Trace");
      R_Trace: R_Detector (1, +"Test_Trace");
   begin
      Trace ("Level", Any_Int(Level));
      Check (Level /= 0, "Last recursion level");
      delay (Hold_Time);
      if Level > 0 then
         Test_Trace (Level-1, Hold_Time);
      end if;
   end Test_Trace;

   procedure Put_Count is
   begin
      Trace ("Number of tasks waiting on the barrier:", Any_Int (Barrier.Count));
   end Put_Count;

   procedure Process1 is
   begin
      Trace(Start, "Process1 called");
      Pause("This is a timer-triggered pause");
      Trace("Changing Watch-Dog from pause to abort");
      Set_Timer (2.0, Process2'Access);
      Trace(Stop, "Process1");
   end Process1;

   procedure Process2 is
   begin
      Trace(Start, "Process2 called, end the game");
      Put_Count;
      Abort_Main;
   end Process2;

   protected body Barrier is
      entry Wait when Wait'Count = 3  or Go is
      begin
         Keep_Trace (Start, "Barrier.Wait", Wait'Caller);
         Go := Wait'Count /= 0;
         Keep_Trace ("Queued behind me: ", Any_Int (Wait'Count), Wait'Caller);
         Keep_Trace (Stop, "Barrier.Wait", Wait'Caller);
      end Wait;
      function Count return Natural is
      begin
         return Wait'Count;
      end Count;
   end Barrier;

   task body Test_Task is
      Sleep_Unit : constant Duration := 0.1;
      At_End  : Emergency_Exit;
   begin
      Trace ("I'm a Test_Task");
      loop
         Test_Trace(2, Period*Sleep_Unit);
         Barrier.Wait;
      end loop;
   end Test_Task;

   -- Register P as a Last Will procedure:
   Intended_Exception : exception;
   procedure P is
   begin
      Trace ("Calling the last-will procedure for the main program");
      Pause;
      Trace ("Now, let's raise an exception...");
      raise Intended_Exception;
   end P;
   package Pause_Last_Will is new Last_Will (P, "This is our last pause before terminating");

end Ttracer2;
