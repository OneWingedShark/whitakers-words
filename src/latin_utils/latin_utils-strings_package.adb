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

pragma Ada_2012;

with
Ada.Characters.Handling,
Ada.Strings.Fixed,
Ada.Text_IO;

use
Ada.Text_IO;

package body Latin_Utils.Strings_Package is

   ---------------------------------------------------------------------------

   function Lower_Case (C : Character) return Character
      renames Ada.Characters.Handling.To_Lower;

   function Lower_Case (S : String) return String
      renames Ada.Characters.Handling.To_Lower;

   function Upper_Case (C : Character) return Character
      renames Ada.Characters.Handling.To_Upper;

   function Upper_Case (S : String) return String
      renames Ada.Characters.Handling.To_Upper;

   ---------------------------------------------------------------------------

   function Trim
      (Source : in String;
       Side   : in Trim_End := Both
      ) return String
       renames Ada.Strings.Fixed.Trim;

   ---------------------------------------------------------------------------

   function Head
      (Source : in String;
       Count  : in Natural
      ) return String is
   begin
      return Ada.Strings.Fixed.Head (Source, Count, ' ');
   end Head;

   ---------------------------------------------------------------------------

   procedure Get_Non_Comment_Line
      (File : in  Ada.Text_IO.File_Type;
       Item : out String;
       Last : out Natural
      ) is
      Noncomment_Line   : String renames Get_Non_Comment_Line (File);
      Noncomment_Length : constant Natural := Noncomment_Line'Length;
      -- LX is Line (Line'First .. Start_Of_Comment)'Length
      subtype Index is Positive range
        Item'First .. Positive'Pred (Item'First + Noncomment_Length);
   begin
      Item (Index) := Noncomment_Line;
      Last := Noncomment_Length; --Possible off-by-one error here; could be the
                                 -- Index'Last that we want to return... depends
                                 -- on how the function is intended to be used.
   end Get_Non_Comment_Line;

   function  Get_Non_Comment_Line
     (File : in  Ada.Text_IO.File_Type
     ) return String is
   begin
      loop
         declare
            Line    : String renames Ada.Text_IO.Get_Line (File);
            Start   : String renames Head (Trim (Line), 250);
            Comment : constant Boolean := Start (1 .. 2) = "--";
            Blank   : constant Boolean := Start (1 .. 2) = "  ";
         begin
            -- Since both cannot be true, Comment = Blank is only true
            -- when both are false.
            if Comment = Blank then
               declare
                  -- Search for start of comment in line (if any).
                  Stop : Natural renames
                    Ada.Strings.Fixed.Index (Line, "--", Line'First);
                  subtype Valid is Positive range Line'First .. Stop;
               begin
                  return Result : constant String := Line (Valid);
               end;
            end if;
         end;
      end loop;
   end Get_Non_Comment_Line;

   ---------------------------------------------------------------------------

end Latin_Utils.Strings_Package;
