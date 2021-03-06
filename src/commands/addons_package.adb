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

with Latin_Utils.Strings_Package; use Latin_Utils.Strings_Package;
with developer_parameters; use developer_parameters;
with Latin_Utils.Preface;
package body addons_package is
   use Ada.Text_IO;
   use Part_Of_Speech_Type_IO;
   use Target_entry_io;
   use Part_Entry_IO;
   --use KIND_ENTRY_IO;
   use Stem_Key_Type_IO;

   function equ (c, d : Character) return Boolean is
   begin
      if (d = 'u') or (d = 'v')  then
         if (c = 'u') or (c = 'v')  then
            return True;
         else
            return False;
         end if;
      else
         return c = d;
      end if;
   end equ;

   function equ (s, t : String) return Boolean is
   begin
      if s'Length /= t'Length  then
         return False;
      end if;

      for i in 1 .. s'Length  loop
         if not equ (s (s'First + i - 1), t (t'First + i - 1))  then
            return False;
         end if;
      end loop;

      return True;
   end equ;

   procedure load_addons (file_name : in String) is
      use tackon_entry_io;
      use prefix_entry_io;
      use suffix_entry_io;
      --use DICT_IO;

      s : String (1 .. 100);
      l, last, tic, pre, suf, tac, pac : Integer := 0;
      addons_file : Ada.Text_IO.File_Type;
      pofs : Part_Of_Speech_Type;
      mean : Meaning_Type := Null_Meaning_Type;
      m : Integer := 1;
      --TG : TARGET_ENTRY;
      tn : tackon_entry;
      pm : prefix_item;
      ts : Stem_Type;

      procedure Get_no_comment_line (f : in Ada.Text_IO.File_Type;
                                     s : out String; last : out Integer) is
         t : String (1 .. 250) := (others => ' ');
         l : Integer := 0;
      begin
         last := 0;
         while not End_Of_File (f)  loop
            Get_Line (f, t, l);
            if l >= 2  and then
              (Head (Trim (t), 250)(1 .. 2) = "--"  or
              Head (Trim (t), 250)(1 .. 2) = "  ")
            then
               null;
            else
               s (s'First .. l) := t (1 .. l);
               last := l;
               exit;
            end if;
         end loop;
      end Get_no_comment_line;

      procedure extract_fix (s : in String;
                             xfix : out fix_type; xc : out Character) is
         st : constant String := Trim (s);
         l : constant Integer := st'Length;
         j : Integer := 0;
      begin
         for i in 1 .. l  loop
            j := i;
            exit when (i < l) and then (st (i + 1) = ' ');
         end loop;
         xfix := Head (st (1 .. j), max_fix_size);
         if j = l  then     --  there is no CONNECT CHARACTER
            xc := ' ';
            return;
         else
            for i in j + 1 .. l  loop
               if st (i) /= ' '  then
                  xc := st (i);
                  exit;
               end if;
            end loop;
         end if;
         return;
      end extract_fix;

   begin
      Open (addons_file, In_File, file_name);
      Preface.Put ("ADDONS");
      Preface.Put (" loading ");

      --FIXME this code looks like it's duplicated somewhere else

      --    if DICT_IO.IS_OPEN (DICT_FILE (D_K))  then
      --      DICT_IO.DELETE (DICT_FILE (D_K));
      --    end if;
      --    DICT_IO.CREATE (DICT_FILE (D_K), DICT_IO.INOUT_FILE,
      ---ADD_FILE_NAME_EXTENSION (DICT_FILE_NAME, DICTIONARY_KIND'IMAGE (D_K)));
      --       "");
      --
      while not End_Of_File (addons_file)  loop

         Get_no_comment_line (addons_file, s, last);
         --TEXT_IO.PUT_LINE (S (1 .. LAST));
         Get (s (1 .. last), pofs, l);
         case pofs is
            when Tackon  =>
               ts := Head (Trim (s (l + 1 .. last)), Max_Stem_Size);

               Get_Line (addons_file, s, last);
               Get (s (1 .. last), tn, l);
               Get_Line (addons_file, s, last);
               mean := Head (s (1 .. last), Max_Meaning_Size);

               if  tn.base.pofs = Pack   and then
                 (tn.base.pack.Decl.Which = 1 or
                 tn.base.pack.Decl.Which = 2)  and then
                 mean (1 .. 9) = "PACKON w/"
               then
                  pac := pac + 1;
                  packons (pac).pofs := pofs;
                  packons (pac).tack := ts;
                  packons (pac).entr := tn;
                  --            DICT_IO.SET_INDEX (DICT_FILE (D_K), M);
                  --            DE.MEAN := MEAN;
                  --            DICT_IO.WRITE (DICT_FILE (D_K), DE);
                  packons (pac).MNPC := m;
                  means (m) := mean;
                  m := m + 1;
               else
                  tac := tac + 1;
                  tackons (tac).pofs := pofs;
                  tackons (tac).tack := ts;
                  tackons (tac).entr := tn;
                  --            DICT_IO.SET_INDEX (DICT_FILE (D_K), M);
                  --            DE.MEAN := MEAN;
                  --            DICT_IO.WRITE (DICT_FILE (D_K), DE);
                  --            --DICT_IO.WRITE (DICT_FILE (D_K), MEAN);
                  tackons (tac).MNPC := m;
                  means (m) := mean;
                  m := m + 1;
               end if;

               number_of_packons  := pac;
               number_of_tackons  := tac;

            when Prefix  =>

               extract_fix (s (l + 1 .. last), pm.fix, pm.connect);
               Get_Line (addons_file, s, last);
               Get (s (1 .. last), pm.entr, l);
               Get_Line (addons_file, s, last);
               mean := Head (s (1 .. last), Max_Meaning_Size);

               if pm.entr.root = Pack then
                  tic := tic + 1;
                  tickons (tic).pofs := pofs;
                  tickons (tic).fix  := pm.fix;
                  tickons (tic).connect  := pm.connect;
                  tickons (tic).entr := pm.entr;
                  --            DICT_IO.SET_INDEX (DICT_FILE (D_K), M);
                  --            DE.MEAN := MEAN;
                  --            DICT_IO.WRITE (DICT_FILE (D_K), DE);
                  --            --DICT_IO.WRITE (DICT_FILE (D_K), MEAN);
                  tickons (tic).MNPC := m;
                  means (m) := mean;
                  m := m + 1;
               else
                  pre := pre + 1;
                  prefixes (pre).pofs := pofs;
                  prefixes (pre).fix  := pm.fix;
                  prefixes (pre).connect  := pm.connect;
                  prefixes (pre).entr := pm.entr;
                  --            DICT_IO.SET_INDEX (DICT_FILE (D_K), M);
                  --            DICT_IO.WRITE (DICT_FILE (D_K), DE);
                  --            --DICT_IO.WRITE (DICT_FILE (D_K), MEAN);
                  prefixes (pre).MNPC := m;
                  means (m) := mean;
                  m := m + 1;
               end if;

               number_of_tickons  := tic;
               number_of_prefixes := pre;

            when Suffix  =>
               suf := suf + 1;
               suffixes (suf).pofs := pofs;
               --TEXT_IO.PUT_LINE (S (1 .. LAST));
               extract_fix (s (l + 1 .. last),
                 suffixes (suf).fix, suffixes (suf).connect);
               --TEXT_IO.PUT ("@1");
               Get_Line (addons_file, s, last);
               --TEXT_IO.PUT ("@2");
               --TEXT_IO.PUT_LINE (S (1 .. LAST) & "<");
               --TEXT_IO.PUT ("@2");
               Get (s (1 .. last), suffixes (suf).entr, l);
               --TEXT_IO.PUT ("@3");
               Get_Line (addons_file, s, last);
               --TEXT_IO.PUT ("@4");
               mean := Head (s (1 .. last), Max_Meaning_Size);
               --TEXT_IO.PUT ("@5");
               --
               --        DICT_IO.SET_INDEX (DICT_FILE (D_K), M);
               --        DE.MEAN := MEAN;
               --        DICT_IO.WRITE (DICT_FILE (D_K), DE);
               --        --DICT_IO.WRITE (DICT_FILE (D_K), MEAN);
               suffixes (suf).MNPC := m;
               means (m) := mean;
               m := m + 1;

               number_of_suffixes := suf;

            when others  =>
               Ada.Text_IO.Put_Line
                 ("Bad ADDON    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
               Ada.Text_IO.Put_Line (s (1 .. last));
               raise Ada.Text_IO.Data_Error;
         end case;

      end loop;

      Preface.Put (tac, 1); Preface.Put ("+");
      Preface.Put (pac, 2); Preface.Put (" TACKONS ");
      Preface.Put (tic, 1); Preface.Put ("+");
      Preface.Put (pre, 3); Preface.Put (" PREFIXES ");
      Preface.Put (suf, 3); Preface.Put (" SUFFIXES ");

      Preface.Set_Col (60); Preface.Put_Line ("--  Loaded correctly");
      Close (addons_file);

   exception
      when Ada.Text_IO.Name_Error  =>
         Preface.Put_Line ("No ADDONS file ");
         null;
      when Ada.Text_IO.Data_Error  =>
         Preface.Put_Line (s (1 .. last));
         Preface.Put_Line ("No further ADDONS read ");
         Close (addons_file);
      when others      =>
         Preface.Put_Line ("Exception in LOAD_ADDONS");
         Preface.Put_Line (s (1 .. last));
   end load_addons;

   function subtract_tackon (w : String; x : tackon_item) return String is
      wd : constant String := Trim (w);
      l  : constant Integer := wd'Length;
      xf : constant String := Trim (x.tack);
      z  : constant Integer := xf'Length;
   begin
      --PUT_LINE ("In SUB TACKON " & INTEGER'IMAGE (L) & INTEGER'IMAGE (Z));
      if words_mdev (use_tackons) and then
        l > z  and then
        --WD (L-Z + 1 .. L) = XF (1 .. Z)  then
        equ (wd (l - z + 1 .. l),  xf (1 .. z))
      then
         --PUT ("In SUBTRACT_TACKON we got a hit   "); PUT_LINE (X.TACK);
         return wd (1 .. l - z);
      else
         --PUT ("In SUBTRACT_TACKON    NO    hit   "); PUT_LINE (X.TACK);
         return w;
      end if;
   end subtract_tackon;

   function subtract_prefix (w : String; x : prefix_item) return Stem_Type is
      wd : constant String := Trim (w);
      xf : constant String := Trim (x.fix);
      z  : constant Integer := xf'Length;
      st : Stem_Type := Head (wd, Max_Stem_Size);
   begin
      if words_mdev (use_prefixes) and then
        x /= null_prefix_item and then
        wd'Length > z  and then
        --WD (1 .. Z) = XF (1 .. Z)  and then
        equ (wd (1 .. z),  xf (1 .. z)) and then
        ((x.connect = ' ') or (wd (z + 1) = x.connect))
      then
         st (1 .. wd'Length - z) := wd (z + 1 .. wd'Last);
         st (wd'Length - z + 1 .. Max_Stem_Size) :=
           Null_Stem_Type (wd'Length - z + 1 .. Max_Stem_Size);
      end if;
      return st;
   end subtract_prefix;

   function subtract_suffix (w : String; x : suffix_item) return Stem_Type is
      wd : constant String := Trim (w);
      l  : constant Integer := wd'Length;
      xf : constant String := Trim (x.fix);
      z  : constant Integer := xf'Length;
      st : Stem_Type := Head (wd, Max_Stem_Size);
   begin
      --PUT_LINE ("In SUBTRACT_SUFFIX  Z = " & INTEGER'IMAGE (Z) &
      --"  CONNECT >" & X.CONNECT & '<');
      if words_mdev (use_suffixes) and then
        x /= null_suffix_item and then
        wd'Length > z  and then
        --WD (L-Z + 1 .. L) = XF (1 .. Z)  and then
        equ (wd (l - z + 1 .. l),  xf (1 .. z))  and then
        ((x.connect = ' ') or (wd (l - z) = x.connect))
      then
         --PUT_LINE ("In SUBTRACT_SUFFIX we got a hit");
         st (1 .. wd'Length - z) := wd (1 .. wd'Length - z);
         st (wd'Length - z + 1 .. Max_Stem_Size) :=
           Null_Stem_Type (wd'Length - z + 1 .. Max_Stem_Size);
      end if;
      return st;
   end subtract_suffix;

   function add_prefix (stem : Stem_Type;
                        prefix : prefix_item) return Stem_Type is
      fpx : constant String := Trim (prefix.fix) & stem;
   begin
      if words_mdev (use_prefixes)  then
         return Head (fpx, Max_Stem_Size);
      else
         return stem;
      end if;
   end add_prefix;

   function add_suffix (stem : Stem_Type;
                        suffix : suffix_item) return Stem_Type is
      fpx : constant String := Trim (stem) & suffix.fix;
   begin
      if words_mdev (use_suffixes)  then
         return Head (fpx, Max_Stem_Size);
      else
         return stem;
      end if;
   end add_suffix;

   --  package body TARGET_ENTRY_IO is separate;

   --  package body TACKON_ENTRY_IO is separate;

   --  package body TACKON_LINE_IO is separate;

   --  package body PREFIX_ENTRY_IO is separate;

   --  package body PREFIX_LINE_IO is separate;

   --  package body SUFFIX_ENTRY_IO is separate;

   --  package body SUFFIX_LINE_IO is separate;

   package body Target_entry_io is
      use Noun_Entry_IO;
      use Pronoun_Entry_IO;
      use Propack_Entry_IO;
      use Adjective_Entry_IO;
      use Numeral_Entry_IO;
      use Adverb_Entry_IO;
      use Verb_Entry_IO;
      --  use KIND_ENTRY_IO;
      --
      --  use NOUN_KIND_TYPE_IO;
      --  use PRONOUN_KIND_TYPE_IO;
      --  use INFLECTIONS_PACKAGE.INTEGER_IO;
      --  use VERB_KIND_TYPE_IO;

      spacer : Character := ' ';

      noun  : Noun_Entry;
      pronoun : Pronoun_Entry;
      propack : Propack_Entry;
      adjective : Adjective_Entry;
      numeral : Numeral_Entry;
      adverb : Adverb_Entry;
      verb : Verb_Entry;

      --  NOUN_KIND  : NOUN_KIND_TYPE;
      --  PRONOUN_KIND : PRONOUN_KIND_TYPE;
      --  PROPACK_KIND : PRONOUN_KIND_TYPE;
      --  NUMERAL_VALUE : NUMERAL_VALUE_TYPE;
      --  VERB_KIND : VERB_KIND_TYPE;

      --KIND : KIND_ENTRY;

      procedure Get (f : in File_Type; p : out Target_entry) is
         ps : Target_pofs_type := X;
      begin
         Get (f, ps);
         Get (f, spacer);
         case ps is
            when N =>
               Get (f, noun);
               --GET (F, NOUN_KIND);
               p := (N, noun);  --, NOUN_KIND);
            when Pron =>
               Get (f, pronoun);
               --GET (F, PRONOUN_KIND);
               p := (Pron, pronoun);  --, PRONOUN_KIND);
            when Pack =>
               Get (f, propack);
               --GET (F, PROPACK_KIND);
               p := (Pack, propack);  --, PROPACK_KIND);
            when Adj =>
               Get (f, adjective);
               p := (Adj, adjective);
            when Num =>
               Get (f, numeral);
               --GET (F, NUMERAL_VALUE);
               p := (Num, numeral);  --, NUMERAL_VALUE);
            when Adv =>
               Get (f, adverb);
               p := (Adv, adverb);
            when V =>
               Get (f, verb);
               --GET (F, VERB_KIND);
               p := (V, verb);  --, VERB_KIND);
            when X =>
               p := (pofs => X);
         end case;
         return;
      end Get;

      procedure Get (p : out Target_entry) is
         ps : Target_pofs_type := X;
      begin
         Get (ps);
         Get (spacer);
         case ps is
            when N =>
               Get (noun);
               --GET (NOUN_KIND);
               p := (N, noun);  --, NOUN_KIND);
            when Pron =>
               Get (pronoun);
               --GET (PRONOUN_KIND);
               p := (Pron, pronoun);  --, PRONOUN_KIND);
            when Pack =>
               Get (propack);
               --GET (PROPACK_KIND);
               p := (Pack, propack);  --, PROPACK_KIND);
            when Adj =>
               Get (adjective);
               p := (Adj, adjective);
            when Num =>
               Get (numeral);
               --GET (NUMERAL_VALUE);
               p := (Num, numeral);  --, NUMERAL_VALUE);
            when Adv =>
               Get (adverb);
               p := (Adv, adverb);
            when V =>
               Get (verb);
               --GET (VERB_KIND);
               p := (V, verb);  --, VERB_KIND);
            when X =>
               p := (pofs => X);
         end case;
         return;
      end Get;

      procedure Put (f : in File_Type; p : in Target_entry) is
         c : constant Positive := Positive (Col (f));
      begin
         Put (f, p.pofs);
         Put (f, ' ');
         case p.pofs is
            when N =>
               Put (f, p.n);
               --PUT (F, P.NOUN_KIND);
            when Pron =>
               Put (f, p.pron);
               --PUT (F, P.PRONOUN_KIND);
            when Pack =>
               Put (f, p.pack);
               --PUT (F, P.PROPACK_KIND);
            when Adj =>
               Put (f, p.adj);
            when Num =>
               Put (f, p.num);
               --PUT (F, P.NUMERAL_VALUE);
            when Adv =>
               Put (f, p.adv);
            when V =>
               Put (f, p.v);
               --PUT (F, P.VERB_KIND);
            when others =>
               null;
         end case;
         Put (f, String'((Integer (Col (f)) ..
           Target_entry_io.Default_Width + c - 1 => ' ')));
         return;
      end Put;

      procedure Put (p : in Target_entry) is
         c : constant Positive := Positive (Col);
      begin
         Put (p.pofs);
         Put (' ');
         case p.pofs is
            when N =>
               Put (p.n);
               --PUT (P.NOUN_KIND);
            when Pron =>
               Put (p.pron);
               --PUT (P.PRONOUN_KIND);
            when Pack =>
               Put (p.pack);
               --PUT (P.PROPACK_KIND);
            when Adj =>
               Put (p.adj);
            when Num =>
               Put (p.num);
               --PUT (P.NUMERAL_VALUE);
            when Adv =>
               Put (p.adv);
            when V =>
               Put (p.v);
               --PUT (P.VERB_KIND);
            when others =>
               null;
         end case;
         Put (String'(
           (Integer (Col) .. Target_entry_io.Default_Width + c - 1 => ' ')));
         return;
      end Put;

      procedure Get (s : in String; p : out Target_entry; last : out Integer) is
         l : Integer := s'First - 1;
         ps : Target_pofs_type := X;
      begin
         Get (s, ps, l);
         l := l + 1;
         case ps is
            when N =>
               Get (s (l + 1 .. s'Last), noun, last);
               --GET (S (L + 1 .. S'LAST), NOUN_KIND, LAST);
               p := (N, noun);  --, NOUN_KIND);
            when Pron =>
               Get (s (l + 1 .. s'Last), pronoun, last);
               --GET (S (L + 1 .. S'LAST), PRONOUN_KIND, LAST);
               p := (Pron, pronoun);  --, PRONOUN_KIND);
            when Pack =>
               Get (s (l + 1 .. s'Last), propack, last);
               --GET (S (L + 1 .. S'LAST), PROPACK_KIND, LAST);
               p := (Pack, propack);  --, PROPACK_KIND);
            when Adj =>
               Get (s (l + 1 .. s'Last), adjective, last);
               p := (Adj, adjective);
            when Num =>
               Get (s (l + 1 .. s'Last), numeral, last);
               --GET (S (L + 1 .. S'LAST), NUMERAL_VALUE, LAST);
               p := (Num, numeral);  --, NUMERAL_VALUE);
            when Adv =>
               Get (s (l + 1 .. s'Last), adverb, last);
               p := (Adv, adverb);
            when V =>
               Get (s (l + 1 .. s'Last), verb, last);
               --GET (S (L + 1 .. S'LAST), VERB_KIND, LAST);
               p := (V, verb);  --, VERB_KIND);
            when X =>
               p := (pofs => X);
         end case;
         return;
      end Get;

      procedure Put (s : out String; p : in Target_entry) is
         l : Integer := s'First - 1;
         m : Integer := 0;
      begin
         m := l + Part_Of_Speech_Type_IO.Default_Width;
         Put (s (l + 1 .. m), p.pofs);
         l := m + 1;
         s (l) :=  ' ';
         case p.pofs is
            when N =>
               m := l + Noun_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.n);
               --        M := L + NOUN_KIND_TYPE_IO.DEFAULT_WIDTH;
               --        PUT (S (L + 1 .. M), P.NOUN_KIND);
            when Pron =>
               m := l + Pronoun_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.pron);
               --        M := L + PRONOUN_KIND_TYPE_IO.DEFAULT_WIDTH;
               --        PUT (S (L + 1 .. M), P.PRONOUN_KIND);
            when Pack =>
               m := l + Propack_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.pack);
               --        M := L + PRONOUN_KIND_TYPE_IO.DEFAULT_WIDTH;
               --        PUT (S (L + 1 .. M), P.PROPACK_KIND);
            when Adj =>
               m := l + Adjective_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.adj);
            when Num =>
               m := l + Numeral_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.num);
               --        M := L + NUMERAL_VALUE_TYPE_IO_DEFAULT_WIDTH;
               --        PUT (S (L + 1 .. M), P.PRONOUN_KIND);
            when Adv =>
               m := l + Adverb_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.adv);
            when V =>
               m := l + Verb_Entry_IO.Default_Width;
               Put (s (l + 1 .. m), p.v);
               --        M := L + PRONOUN_KIND_TYPE_IO.DEFAULT_WIDTH;
               --        PUT (S (L + 1 .. M), P.PRONOUN_KIND);
            when others =>
               null;
         end case;
         s (m + 1 .. s'Last) := (others => ' ');
      end Put;

   end Target_entry_io;

   package body tackon_entry_io is
      procedure Get (f : in File_Type; i : out tackon_entry) is
      begin
         Get (f, i.base);
      end Get;

      procedure Get (i : out tackon_entry) is
      begin
         Get (i.base);
      end Get;

      procedure Put (f : in File_Type; i : in tackon_entry) is
      begin
         Put (f, i.base);
      end Put;

      procedure Put (i : in tackon_entry) is
      begin
         Put (i.base);
      end Put;

      procedure Get (s : in String; i : out tackon_entry; last : out Integer) is
         l : constant Integer := s'First - 1;
      begin
         Get (s (l + 1 .. s'Last), i.base, last);
      end Get;

      procedure Put (s : out String; i : in tackon_entry) is
         l : constant Integer := s'First - 1;
         m : Integer := 0;
      begin
         m := l + Target_entry_io.Default_Width;
         Put (s (l + 1 .. m), i.base);
         s (s'First .. s'Last) := (others => ' ');
      end Put;

   end tackon_entry_io;

   package body prefix_entry_io is
      spacer : Character := ' ';

      procedure Get (f : in File_Type; p : out prefix_entry) is
      begin
         Get (f, p.root);
         Get (f, spacer);
         Get (f, p.Target);
      end Get;

      procedure Get (p : out prefix_entry) is
      begin
         Get (p.root);
         Get (spacer);
         Get (p.Target);
      end Get;

      procedure Put (f : in File_Type; p : in prefix_entry) is
      begin
         Put (f, p.root);
         Put (f, ' ');
         Put (f, p.Target);
      end Put;

      procedure Put (p : in prefix_entry) is
      begin
         Put (p.root);
         Put (' ');
         Put (p.Target);
      end Put;

      procedure Get (s : in String; p : out prefix_entry; last : out Integer) is
         l : Integer := s'First - 1;
      begin
         Get (s (l + 1 .. s'Last), p.root, l);
         l := l + 1;
         Get (s (l + 1 .. s'Last), p.Target, last);
      end Get;

      procedure Put (s : out String; p : in prefix_entry) is
         l : Integer := s'First - 1;
         m : Integer := 0;
      begin
         m := l + Part_Of_Speech_Type_IO.Default_Width;
         Put (s (l + 1 .. m), p.root);
         l := m + 1;
         s (l) :=  ' ';
         m := l + Part_Of_Speech_Type_IO.Default_Width;
         Put (s (l + 1 .. m), p.Target);
         s (m + 1 .. s'Last) := (others => ' ');
      end Put;

   end prefix_entry_io;

   package body suffix_entry_io is
      spacer : Character := ' ';

      procedure Get (f : in File_Type; p : out suffix_entry) is
      begin
         Get (f, p.root);
         Get (f, spacer);
         Get (f, p.root_key);
         Get (f, spacer);
         Get (f, p.Target);
         Get (f, spacer);
         Get (f, p.Target_key);
      end Get;

      procedure Get (p : out suffix_entry) is
      begin
         Get (p.root);
         Get (spacer);
         Get (p.root_key);
         Get (spacer);
         Get (p.Target);
         Get (spacer);
         Get (p.Target_key);
      end Get;

      procedure Put (f : in File_Type; p : in suffix_entry) is
      begin
         Put (f, p.root);
         Put (f, ' ');
         Put (f, p.root_key, 2);
         Put (f, ' ');
         Put (f, p.Target);
         Put (f, ' ');
         Put (f, p.Target_key, 2);
      end Put;

      procedure Put (p : in suffix_entry) is
      begin
         Put (p.root);
         Put (' ');
         Put (p.root_key, 2);
         Put (' ');
         Put (p.Target);
         Put (' ');
         Put (p.Target_key, 2);
      end Put;

      procedure Get (s : in String; p : out suffix_entry; last : out Integer) is
         l : Integer := s'First - 1;
      begin
         --TEXT_IO.PUT ("#1" & INTEGER'IMAGE (L));
         Get (s (l + 1 .. s'Last), p.root, l);
         --TEXT_IO.PUT ("#2" & INTEGER'IMAGE (L));
         l := l + 1;
         Get (s (l + 1 .. s'Last), p.root_key, l);
         --TEXT_IO.PUT ("#3" & INTEGER'IMAGE (L));
         l := l + 1;
         Get (s (l + 1 .. s'Last), p.Target, l);
         --TEXT_IO.PUT ("#4" & INTEGER'IMAGE (L));
         l := l + 1;
         Get (s (l + 1 .. s'Last), p.Target_key, last);
         --TEXT_IO.PUT ("#5" & INTEGER'IMAGE (LAST));
      end Get;

      procedure Put (s : out String; p : in suffix_entry) is
         l : Integer := s'First - 1;
         m : Integer := 0;
      begin
         m := l + Part_Of_Speech_Type_IO.Default_Width;
         Put (s (l + 1 .. m), p.root);
         l := m + 1;
         s (l) :=  ' ';
         m := l + 2;
         Put (s (l + 1 .. m), p.root_key);
         l := m + 1;
         s (l) :=  ' ';
         m := l + Target_entry_io.Default_Width;
         Put (s (l + 1 .. m), p.Target);
         l := m + 1;
         s (l) :=  ' ';
         m := l + 2;
         Put (s (l + 1 .. m), p.Target_key);
         s (m + 1 .. s'Last) := (others => ' ');
      end Put;

   end suffix_entry_io;

begin    --  Initiate body of ADDONS_PACKAGE
         --TEXT_IO.PUT_LINE ("Initializing ADDONS_PACKAGE");

   prefix_entry_io.Default_Width := Part_Of_Speech_Type_IO.Default_Width + 1 +
     Part_Of_Speech_Type_IO.Default_Width;
   Target_entry_io.Default_Width := Part_Of_Speech_Type_IO.Default_Width + 1 +
     Numeral_Entry_IO.Default_Width; --  Largest

   suffix_entry_io.Default_Width := Part_Of_Speech_Type_IO.Default_Width + 1 +
     2 + 1 +
     Target_entry_io.Default_Width + 1 +
     2;
   tackon_entry_io.Default_Width := Target_entry_io.Default_Width;

end addons_package;
