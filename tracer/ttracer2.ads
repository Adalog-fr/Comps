with Ada.Finalization;
package TTracer2 is
   type Emergency_Exit is new Ada.Finalization.Controlled with null record;
   overriding procedure Finalize (Item : in out Emergency_Exit);


   procedure Test_Trace (Level : Integer; Hold_Time : Duration);
   task type Test_Task  (Period : Positive);

   procedure Process1;
   procedure Process2;
   procedure Put_Count;

   protected Barrier is
      entry Wait;
      function Count return Natural;
   private
      Go: Boolean := False;
   end Barrier;


 end TTracer2;
