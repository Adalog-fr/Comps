----------------------------------------------------------------------
-- Package PROTECTION (specification)                               --
-- (C) Copyright 1998, 2001 ADALOG                                  --
-- Author: J-P. Rosen                                               --
--                                                                  --
--  ADALOG   is   providing   training,   consultancy,   expertise, --
--  assistance and custom developments  in Ada and related software --
--  engineering techniques.  For more info about our services:      --
--  ADALOG                                                          --
--  2 rue du Docteur Lombard                                        --
--  92441 ISSY LES MOULINEAUX CEDEX E-m: info@adalog.fr             --
--  FRANCE                          URL: https://www.adalog.fr/     --
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
      Owner      : Ada.Task_Identification.Task_Id;
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
      procedure Finalize (Item : in out Anti_Abort_Object);
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
      procedure Finalize (Item : in out Anti_Abort_Object);
   end Generic_Limited_Protected_Call;
end Protection;
