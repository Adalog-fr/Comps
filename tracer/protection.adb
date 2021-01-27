-------------------------------------------------------------------------------
-- Package Protection (body)                                                 --
-- (C) Copyright 2000 ADALOG                                                 --
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
-- ADALOG                   Tel: +33 1 41 24 31 40                          --
-- 19-21 rue du 8 mai 1945  Fax: +33 1 41 24 07 36                           --
-- 94110 ARCUEIL            E-m: rosen.adalog@wanadoo.fr                     --
--                          URL: http://pro.wanadoo.fr/adalog                --
--                                                                           --
-- This package is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY  --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                      --
-------------------------------------------------------------------------------
package body Protection is

   protected body Semaphore is
      entry P when True is
         use Ada.Task_Identification;
      begin
         if P'Caller = Owner then
            Busy_Level := Busy_Level + 1;
         elsif Is_Closed then
            raise Closed_Semaphore;
         else
            requeue Blocking_P;
         end if;
      end P;

      entry Blocking_P when Busy_Level = 0 or Is_Closed is
      begin
         if Is_Closed then
            raise Closed_Semaphore;
         end if;

         Busy_Level := 1;
         Owner      := Blocking_P'Caller;
      end Blocking_P;

      procedure V is
         use Ada.Task_Identification;
      begin
         if Busy_Level = 0  or else Owner /= Current_Task then
            Busy_Level := 0;
            raise Semaphore_Error;
         end if;
         Busy_Level := Busy_Level - 1;

         if Busy_Level = 0 then
            Owner := Null_Task_Id;
         end if;
      end V;

      function Holder return Ada.Task_Identification.Task_Id is
      begin
         return Owner;
      end Holder;

      entry Open when True is
         use Ada.Task_Identification;
      begin
         if Is_Closed and Open'Caller /= Owner then
            requeue Blocking_Open;
         end if;
         Is_Closed := False;
      end Open;

      entry Close when True is
         use Ada.Task_Identification;
      begin
         if not Is_Closed and Close'Caller /= Owner then
            requeue Blocking_Close;
         end if;
         Is_Closed := True;
      end Close;

      entry Blocking_Open when Busy_Level = 0 is
      begin
         Is_Closed := False;
      end Blocking_Open;

      entry Blocking_Close when Busy_Level = 0 is
      begin
         Is_Closed := True;
      end Blocking_Close;

   end Semaphore;

   use Ada.Exceptions;

   type Anti_Abort_Object (The_Procedure    : Procedure_Access;
      The_Semaphore    : Semaphore_Access;
      Raised_Exception : access Exception_Occurrence) is
   new Ada.Finalization.Limited_Controlled with null record;
   procedure Finalize (Item : in out Anti_Abort_Object);

   procedure Finalize (Item : in out Anti_Abort_Object) is
   begin
      if Item.The_Semaphore /= null then
         Item.The_Semaphore.P;
      end if;

      begin
         Item.The_Procedure.all;
      exception
         when others =>
            if Item.The_Semaphore /= null then
               Item.The_Semaphore.V;
            end if;
            raise;
      end;

      if Item.The_Semaphore /= null then
         Item.The_Semaphore.V;
      end if;
   exception
      when Occur : others =>
         Save_Occurrence (Item.Raised_Exception.all, Occur);
   end Finalize;

   procedure Protected_Call (Subprogram : Procedure_Access;
                             Lock       : Semaphore_Access := null)
   is
      Raised_Exception : aliased Exception_Occurrence;
   begin
      Save_Occurrence (Raised_Exception, Null_Occurrence);
      declare
         Do_The_Job : Anti_Abort_Object (Subprogram,
                                         Lock,
                                         Raised_Exception'Access);
      begin
         null;
         -- Everything is done by the finalization of Do_The_Job
         -- Since a finalization is an abort deferred operation,
         -- this ensures that a task cannot be aborted between
         -- "P" and "V".
      end;
      Reraise_Occurrence (Raised_Exception);
      -- No effect if Null_Occurrence
   end Protected_Call;

   package body Generic_Protected_Call is
      procedure Protected_Call (Subprogram : Parametered_Procedure_Access;
                                Parameter  : Parameter_Type;
                                Lock       : Semaphore_Access := null)
      is
         Raised_Exception : aliased Exception_Occurrence;
         Copy             : aliased Parameter_Type := Parameter;
         --  We need a copy of the parameter, since we need an access to it
         --  and a formal parameter cannot be declared aliased.
      begin
         Save_Occurrence (Raised_Exception, Null_Occurrence);
         declare
            Do_The_Job : Anti_Abort_Object(Subprogram,
               Copy'Access,
               Lock,
               Raised_Exception'Access);
         begin
            null;      -- See comment in the non generic case
         end;
         Reraise_Occurrence (Raised_Exception);
         -- No effect if Null_Occurrence
      end Protected_Call;

      procedure Finalize (Item : in out Anti_Abort_Object) is
      begin
         if Item.The_Semaphore /= null then
            Item.The_Semaphore.P;
         end if;
         begin
            Item.The_Procedure (Item.The_Parameter.all);
         exception
            when others =>
               if Item.The_Semaphore /= null then
                  Item.The_Semaphore.V;
               end if;
               raise;
         end;
         if Item.The_Semaphore /= null then
            Item.The_Semaphore.V;
         end if;
      exception
         when Occur : others =>
            Save_Occurrence (Item.Raised_Exception.all, Occur);
      end Finalize;
   end Generic_Protected_Call;

   package body Generic_Limited_Protected_Call is
      procedure Protected_Call (Subprogram : Parametered_Procedure_Access;
                                Parameter  : access Parameter_Type;
                                Lock       : Semaphore_Access := null)
      is
         Raised_Exception : aliased Exception_Occurrence;
      begin
         Save_Occurrence (Raised_Exception, Null_Occurrence);
         declare
            Do_The_Job : Anti_Abort_Object(Subprogram,
               Parameter,
               Lock,
               Raised_Exception'Access);
         begin
            null;      -- See comment in the non generic case
         end;
         Reraise_Occurrence (Raised_Exception);
         -- No effect if Null_Occurrence
      end Protected_Call;

      procedure Finalize (Item : in out Anti_Abort_Object) is
      begin
         if Item.The_Semaphore /= null then
            Item.The_Semaphore.P;
         end if;
         begin
            Item.The_Procedure (Item.The_Parameter.all);
         exception
            when others =>
               if Item.The_Semaphore /= null then
                  Item.The_Semaphore.V;
               end if;
               raise;
         end;
         if Item.The_Semaphore /= null then
            Item.The_Semaphore.V;
         end if;
      exception
         when Occur : others =>
            Save_Occurrence (Item.Raised_Exception.all, Occur);
      end Finalize;
   end Generic_Limited_Protected_Call;
end Protection;
