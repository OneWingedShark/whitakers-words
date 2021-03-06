-- WORDS, a Latin dictionary, by Colonel William Whitaker (USAF, Retired)
--
-- Copyright William A. Whitaker (1936–2010)
--
-- This is a free program, which means it is proper to copy it and pass
-- it on to your friends. Consider it a developmental item for which
-- there is no charge. However, just for form, it is Copyrighted
-- (c). Permission is hereby freely given for any and all use of program
-- and data. You can sell it as your own, but at least tell me.
--
-- This version is distributed without obligation, but the developer
-- would appreciate comments and suggestions.
--
-- All parts of the WORDS system, source code and data files, are made freely
-- available to anyone who wishes to use them, for whatever purpose.

with Ada.Text_IO;
with Latin_Utils.Strings_Package; use Latin_Utils.Strings_Package;
with Latin_Utils.Latin_File_Names; use Latin_Utils.Latin_File_Names;
with word_parameters; use word_parameters;
with developer_parameters; use developer_parameters;
with Latin_Utils.Inflections_Package; use Latin_Utils.Inflections_Package;
with Latin_Utils.Dictionary_Package; use Latin_Utils.Dictionary_Package;
with word_support_package; use word_support_package;
with Latin_Utils.Preface;
with word_package; use word_package;
with Latin_Utils.Config; use Latin_Utils.Config;
with english_support_package; use english_support_package;
with banner; use banner;
use Latin_Utils;

with parse; use parse;

pragma Elaborate (word_parameters);

procedure process_Input (configuration : configuration_type;
                         Command_Line : String := "")
is
   -- use Inflections_Package.Integer_IO;
   -- use Inflection_Record_IO;
   use Ada.Text_IO;

   procedure delete_if_Open (filename : String; dict_name : Dictionary_Kind) is
   begin
      begin
         if Dict_IO.Is_Open (Dict_File (dict_name)) then
            Dict_IO.Delete (Dict_File (dict_name));
         else
            Dict_IO.Open (Dict_File (dict_name), Dict_IO.In_File,
              add_file_name_extension (dict_file_name, filename));
            Dict_IO.Delete (Dict_File (dict_name));
         end if;
      exception when others => null;
      end;   --  not there, so don't have to DELETE
   end delete_if_Open;

   -- Get and handle a line of Input
   -- return value says whether there is more Input, i.e. False -> quit
   function Get_Input_Line return Boolean
   is
      blank_line : constant String (1 .. 2500) := (others => ' ');
      line : String (1 .. 2500) := (others => ' ');
      l : Integer := 0;
   begin
      --  Block to manipulate file of lines
      if Name (Current_Input) = Name (Standard_Input) then
         scroll_line_number :=
           Integer (Ada.Text_IO.Line (Ada.Text_IO.Standard_Output));
         Preface.New_Line;
         Preface.Put ("=>");
      end if;

      line := blank_line;
      Get_Line (line, l);
      if (l = 0) or else (Trim (line (1 .. l)) = "")  then
         --  Count blank lines
         --LINE_NUMBER := LINE_NUMBER + 1;
         if Name (Current_Input) = Name (Standard_Input) then
            --  INPUT is keyboard
            Preface.Put ("Blank exits =>");
            Get_Line (line, l);
            -- Second try
            if (l = 0) or else (Trim (line (1 .. l)) = "")  then
               -- Two in a row
               return False;
            end if;
         else
            --  INPUT is file

            --LINE_NUMBER := LINE_NUMBER + 1;
            --  Count blank lines in file
            if End_Of_File (Current_Input) then
               Set_Input (Standard_Input);
               Close (Input);
            end if;
         end if;
      end if;

      if Trim (line (1 .. l)) /= "" then
         -- Not a blank line so L (1) (in file Input)
         if line (1) = start_file_Character  then
            if Name (Current_Input) /= Name (Standard_Input) then
               Ada.Text_IO.Put_Line ("Cannot have file of words (@FILE) " &
                 "in an @FILE");
            else
               Ada.Text_IO.Open
                 (Input, Ada.Text_IO.In_File, Trim (line (2 .. l)));
               Ada.Text_IO.Set_Input (Input);
            end if;
         elsif line (1) = change_parameters_Character  and then
           (Name (Current_Input) = Name (Standard_Input)) and then
           not Config.suppress_preface
         then
            change_parameters;
         elsif line (1) = change_language_Character  then
            change_language (line (2));
         elsif
           line (1) = change_developer_modes_Character  and then
           (Name (Current_Input) = Name (Standard_Input)) and then
           not Config.suppress_preface
         then
            change_developer_modes;
         else
            if Name (Current_Input) /= Name (Standard_Input) then
               Preface.New_Line;
               Preface.Put_Line (line (1 .. l));
            end if;
            if words_mode (Write_Output_to_file)     then
               if not Config.suppress_preface     then
                  New_Line (Output);
                  Ada.Text_IO.Put_Line (Output, line (1 .. l));
               end if;
            end if;
            --  Count lines to be parsed
            line_number := line_number + 1;

            parse.parse_line (configuration, line (1 .. l));
         end if;
      end if;

      return True;

   exception
      when Name_Error | Use_Error =>
         if Name (Current_Input) /= Name (Standard_Input) then
            Set_Input (Standard_Input);
            Close (Input);
         end if;
         Put_Line ("An unknown or unacceptable file name. Try Again");
         return True;
      when End_Error =>
         --  The end of the input file resets to CON:
         if Name (Current_Input) /= Name (Standard_Input) then
            Set_Input (Standard_Input);
            Close (Input);
            if method = Command_Line_files then
               raise give_up;
            end if;
            return True;
         else
            Put_Line ("Raised END_ERROR, although in STANDARD_INPUT");
            Put_Line ("^Z is inappropriate keyboard Input, " &
              "WORDS should be terminated with a blank line");
            raise give_up;
         end if;
      when Status_Error =>
         --  The end of the Input file resets to CON:
         Put_Line ("Raised STATUS_ERROR");
         return False;
   end Get_Input_Line;

begin
   --  PARSE
   if method = Command_Line_Input  then
      if Trim (Command_Line) /= ""  then
         parse.parse_line (configuration, Command_Line);
      end if;

   else
      banner.print_main_banner (start_file_Character,
        change_parameters_Character, help_Character);

      if English_Dictionary_Available (general)  then
         Preface.Put_Line ("English-to-Latin available");
         Preface.Put_Line (
           change_language_Character & "E changes to English-to-Latin, " &
           change_language_Character & "L changes back     [tilde E]");
      end if;

      if configuration = only_meanings  then
         banner.print_mode_warning;
      end if;

      while Get_Input_Line loop
         null;
      end loop;

   end if;     --  On command line Input

   begin
      stem_io.Open (stem_file (local), stem_io.In_File,
        add_file_name_extension (stem_file_name,
        "LOCAL"));
      --  Failure to OPEN will raise an exception, to be handled below
      if stem_io.Is_Open (stem_file (local)) then
         stem_io.Delete (stem_file (local));
      end if;
   exception
      when others =>
         null;      --  If cannot OPEN then it does not exist, so is deleted
   end;
   --  The rest of this seems like overkill, it might have been done elsewhere

   delete_if_Open ("LOCAL", local);
   delete_if_Open ("ADDONS", addons);
   delete_if_Open ("UNIQUE", unique);

exception
   when Storage_Error  =>    --  Have tried at least twice, fail
      Preface.Put_Line ("Continuing STORAGE_ERROR Exception in PARSE");
      Preface.Put_Line ("If insufficient memory in DOS, try removing TSRs");
   when give_up  =>
      Preface.Put_Line ("Giving up!");
   when others  =>
      Preface.Put_Line ("Unexpected exception raised in PARSE");
end process_Input;
