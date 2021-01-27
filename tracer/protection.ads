-------------------------------------------------------------------------------
-- Package PROTECTION (specification)                                        --
-- (C) Copyright 1998, 2001 ADALOG                                           --
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
with Ada.Task_Identification;
with Ada.Finalization;
with Ada.Exceptions;
package Protection is
   pragma Elaborate_Body;

   --  "Improved" semaphore.
   --  Unlike conventional semaphore, several calls to P from the *same* task
   --  are stacked, rather than dead-locking.
   --  When the semaphore is closed, all attempts to call P result in raising
   --  Closed_Semaphore, *except* for the task that owns currently the semaphore.
   --  The function Holder returns the Task_ID of the task that currently holds
   --  the semaphore, or Null_Task_ID if it is free (this can also be used to query
   --  whether the semaphore is currently being held).
   --  If there are more V's than P's, or if a V is performed by a task not holding
   --  the semaphore, Semaphore_Error is raised and the semaphore returns to the
   --  "free" state.
   protected type Semaphore is
      entry P;
      procedure V;
      function Holder return Ada.Task_Identification.Task_Id;

      entry Open;
      --  blocking if Semaphore is closed and still held by another task.
      entry Close;
      --  blocking if Semaphore is open and still held by another task.
   private
      entry Blocking_P;
      entry Blocking_Open;
      entry Blocking_Close;
      Busy_Level : Natural := 0;
      Owner      : Ada.Task_Identification.Task_Id := Ada.Task_Identification.Null_Task_Id;
      Is_Closed  : Boolean := False;
   end Semaphore;

   Closed_Semaphore : exception;
   Semaphore_Error  : exception;

   --  Protection against abort of a parameterless procedure call.
   --  If a semaphore is also given (Lock parameter), the procedure is also
   --  protected from concurrent access. Note that the same semaphore can be
   --  used to protect calls to different procedures, therefore providing
   --  mutual exclusion.
   --  The benefit of using this rather than a protected type is that there
   --  is no limitation to what can be done in the procedure (potentially
   --  blocking operations ARE allowed).
   type Procedure_Access is access procedure;
   type Semaphore_Access is access all Semaphore;
   procedure Protected_Call (Subprogram : Procedure_Access;
                             Lock       : Semaphore_Access := null);

   --  Generic versions of the previous procedure to allow calling a procedure
   --  with one parameter (whose type is given as the generic formal type).
   --  In the case where several parameters are needed, it is generally possible
   --  to pack them into a record, and use this generic.

   --  Case 1: Non-limited parameter type.
   --  Hidden copy, but allows passing a value.
   generic
      type Parameter_Type (<>) is private;
   package Generic_Protected_Call is
      type Parametered_Procedure_Access is access procedure (Item : Parameter_Type);
      procedure Protected_Call (Subprogram : Parametered_Procedure_Access;
                                Parameter  : Parameter_Type;
                                Lock       : Semaphore_Access := null);
   private
      -- Although used only in the body, the following declaration
      -- must be in the specification. See litterature about the
      -- "new contract model" for the reasons of this restriction.
      use Ada.Exceptions;
      type Anti_Abort_Object (The_Procedure    : Parametered_Procedure_Access;
                              The_Parameter    : access Parameter_Type;
                              The_Semaphore    : Semaphore_Access;
                              Raised_Exception : access Exception_Occurrence)
         is new Ada.Finalization.Limited_Controlled with null record;
      overriding procedure Finalize (Item : in out Anti_Abort_Object);
   end Generic_Protected_Call;

   --  Case 2: Limited parameter type.
   --  No hidden copy, but must pass an access value.
   generic
      type Parameter_Type (<>) is limited private;
   package Generic_Limited_Protected_Call is
      type Parametered_Procedure_Access is access procedure (Item : Parameter_Type);
      procedure Protected_Call (Subprogram : Parametered_Procedure_Access;
                                Parameter  : access Parameter_Type;
                                Lock       : Semaphore_Access := null);
   private
      -- See comment in case 1.
      use Ada.Exceptions;
      type Anti_Abort_Object (The_Procedure    : Parametered_Procedure_Access;
                              The_Parameter    : access Parameter_Type;
                              The_Semaphore    : Semaphore_Access;
                              Raised_Exception : access Exception_Occurrence)
         is new Ada.Finalization.Limited_Controlled with null record;
      overriding procedure Finalize (Item : in out Anti_Abort_Object);
   end Generic_Limited_Protected_Call;
end Protection;
