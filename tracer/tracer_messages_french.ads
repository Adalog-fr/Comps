----------------------------------------------------------------------
-- Package TRACER_MESSAGES_FRENCH (specification, no body)          --
-- (C) Copyright 1997, 2021 ADALOG                                  --
-- Author: J-P. Rosen                                               --
--                                                                  --
--  ADALOG   is   providing   training,   consultancy,   expertise, --
--  assistance and custom developments  in Ada and related software --
--  engineering techniques.  For more info about our services:      --
--  ADALOG                          Tel: +33 1 45 29 21 52          --
--  2 rue du Docteur Lombard        Fax: +33 1 45 29 25 00          --
--  92441 ISSY LES MOULINEAUX CEDEX E-m: info@adalog.fr             --
--  FRANCE                          URL: https://www.adalog.fr      --
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

--  Note pour la version francaise:
--  Nous n'avons pas mis d'accents dans les messages pour eviter les problemes
--  de compatibilite Unix/Dos437/Win850
--  Ceux qui preferent des accents peuvent toujours les rajouter...

package Tracer_Messages_French is
   --  All characters used for responses and all messages printed by Tracer are
   --  defined here, so if you want to customize it to another language, you
   --  only need to make a new version of this package, and modify the package
   --  Tracer_Messages to make it a renaming of it.

   --
   --  Characters used for responses
   --
   Yes_Char        : constant Character := 'O'; -- "Yes" response, Oui
   No_Char         : constant Character := 'N'; -- "No"  response, Non

   -- Following characters must be different
   Status_Char     : constant Character := '?'; -- Status
   Help_Char       : constant Character := 'A'; -- Help                        Aide
   Blocking_Char   : constant Character := 'B'; -- toggle Block                Blocage
   Console_Char    : constant Character := 'C'; -- Console                     Console
   Delay_Char      : constant Character := 'D'; -- Timer Delay                 Delai
   Exclude_Char    : constant Character := 'E'; -- Exclude                     Exclure
   File_Char       : constant Character := 'F'; -- File                        Fichier
   Go_Char         : constant Character := 'G'; -- Go (=G0)                    Go ;-)
   Only_Char       : constant Character := 'I'; -- Only registered tasks       Inclure
   Mark_Char       : constant Character := 'M'; -- toggle Registration of task Marquer
   Step_Char       : constant Character := 'P'; -- Step (=G1)                  Pas a pas
   Quit_Char       : constant Character := 'Q'; -- Quit                        Quitter
   None_Char       : constant Character := 'R'; -- No output                   Rien
   Ignore_Char     : constant Character := 'S'; -- silent (Ignore)             Silencieux
   All_Char        : constant Character := 'T'; -- All (General)               Toutes
   Watch_Char      : constant Character := 'U'; -- call Watch procedure        Utilisateur

   --
   --  General messages
   --
   Tracer_Message          : constant String := "**Trace** ";
   Task_Separator          : constant String := "--------------------";
   Main_Task_Message       : constant String := "ID tache principale = ";
   Initial_Message         : constant String := "V2.3. Initialisation";
   Start_Message           : constant String := "Demarrage du programme principal";
   Trace_Message           : constant String := "Mode: Entree=Normal, "                 &
                                                ''' & Step_Char   & "'=Pas a pas, "     &
                                                ''' & Ignore_Char & "'=Ignorer Trace";
   Pause_Message           : constant String := "Pause";
   Quit_Message            : constant String := "Vraiment quitter ? ";
   Lost_Message            : constant String :=
      "Manque de mémoire, des messages perdus";
   Mismatched_Message      : constant String := "!!! Start/Stop desequilibres";
   Overwrite_Message       : constant String := ": le fichier existe deja, ecraser ?";
   Multi_Task_Message      : constant String :=
      "Passage en mode multi-tache, ID tache principale = ";
   Watch_Exception_Message : constant String := "La procedure utilisateur a leve ";
   Timer_Exception_Message : constant String := "La procedure de surveillance a leve ";
   Timer_Message           : constant String := "Declenchement de la surveillance";
   End_Inifile_Message     : constant String := "Fin du fichier ""Ini"", retour à la console";
   Syntax_Message          : constant String := "Faute de syntaxe dans la commande : ";
   Bug_Message             : constant String := "Erreur interne de Tracer dans ";
   Bug_Mess_Message        : constant String := "Exception message : ";
   Bug_Info_Message        : constant String := "Exception information : ";
   Command_Message         : constant String := "Commande ? ('" & Help_Char & "' pour l'aide) :";

   --
   --  Help and status messages
   --
   Help_Message : constant String :=  -- '\' is replaced by LF
      "Reponses autorisees :\" &
      "<Entree>"    &        "   : Reprendre l'execution avec la precedente valeur de 'Go'\" &
      Status_Char   & "          : Imprimer l'etat courant\"                         &
      All_Char      & "          : tracer Toutes les taches (defaut)\"               &
      Blocking_Char & "          : inverser le mode Bloquant\"                       &
      Console_Char  & "          : tracer vers la Console (defaut)\"                 &
      Delay_Char    & "[Valeur]  : ajuster le Delai de surveillance\"                &
                     "             (0 ou rien = annuler la surveillance)\"           &
      Exclude_Char  & "          : Exclure les taches marquees de la trace\"         &
      File_Char     & "          : tracer vers Fichier\"                             &
      Go_Char       & "[<Nombre>]: Go, pause apres <Nombre> messages\"               &
                     "             (0 ou rien = pas de pause)\"                      &
      Help_Char     & "          : cette Aide\"                                      &
      Ignore_Char   & "          : Silence, ignorer tous les appels a Tracer\"       &
      None_Char     & "          : tracer vers Rien (pas de messages)\"              &
      Only_Char     & "          : n'Inclure que les taches marquees dans la trace\" &
      Quit_Char     & "          : Quitter, arret de l'execution\"                   &
      Mark_Char     & "          : Marquer la tache\"                                &
      Step_Char     & "          : Pas a pas, pauser apres chaque message (=G1)\"    &
      Watch_Char    & "          : appeler la procedure Utilisateur";

   Message_Message    : constant String := "Message de pause   : ";
   Seltask_Message    : constant String := "Tache selectionnee : ";
   Reg_Message        : constant String := "Marquee";
   Unreg_Message      : constant String := "Non marquee";
   Completed_Message  : constant String := "achevee";
   Terminated_Message : constant String := "terminee";
   Unmarkable_Message : constant String := "Pas de tache selectionnee";
   General_Message    : constant String := "Trace de toutes les taches";
   Included_Message   : constant String := "Trace des taches marquees";
   Excepted_Message   : constant String := "Trace sauf des taches marquees";
   Console_Message    : constant String := "Sortie de trace sur la console";
   File_Message       : constant String := "Sortie de trace sur fichier";
   None_Message       : constant String := "Sortie de trace desactivee";
   Go_Message         : constant String := "Pas de pause";
   Step_Message       : constant String := "Pause a chaque message";
   N_Message_1        : constant String := "Pause apres";
   N_Message_2        : constant String := " messages";
   Remaining_Message  : constant String := "Temps restant avant surveillance: ";
   Infinite_Message   : constant String := "Infini";
   Seconds_Message    : constant String := " secondes.";
   Aborting_Message   : constant String := "Avortement general en cours";
   Queued_Message     : constant String := "Nombre de messages en attente:";
   Blocking_Message   : constant String := "Statut des traces : ";
   Block_Yes_Message  : constant String := "bloquantes";
   Block_No_Message   : constant String := "non bloquantes";

   --  Syntax error messages
   Synt_Bad_Int : constant String := "Mauvaise valeur entiere";
   Synt_Bad_Dur : constant String := "Mauvaise valeur de duree";
   Synt_Bad_Com : constant String := "Commande incorrecte - taper " &
                                     ''' & Help_Char & "' pour l'aide";

   --  Default file names
   Trace_File_Name   : constant String := "trace";
   Initial_File_Name : constant String := "trace.ini";

   --  Tracer.Timing messages
   Timer_Name               : constant String := "Chrono";
   Timer_Not_Called_Message : constant String := " non utilise";
   Timer_Running_Message    : constant String := " actif actuellement";
   Total_Message            : constant String := " Total:";
   Nb_Calls_Message         : constant String := ", Nb. appels:";
   Average_Message          : constant String := ", Moyenne:";
   Seconds                  : constant String := "s.";
   No_Timer_Message         : constant String := "Aucun chrono utilise";
   Last_Timer_Message       : constant String := "Rapport final des chronos:";
end Tracer_Messages_French;
