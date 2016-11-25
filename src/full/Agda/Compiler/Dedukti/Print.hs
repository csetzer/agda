{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module Agda.Compiler.Dedukti.Print where

-- pretty-printer generated by the BNF converter

import Data.Char

import Agda.Compiler.Dedukti.Syntax

-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : ts@(p:_) | closing p -> showString t . rend i ts
    -- t  : "," :ts -> showString t . space "," . rend i ts
    -- t  : ")" :ts -> showString t . showChar ')' . rend i ts
    -- t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else (' ':s))
  closing [c] = c `elem` ")],;."
  closing _ = False

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

spaceD :: Doc
spaceD = doc $ showString ""

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: Int -> [a] -> Doc
  prtList i = concatD . map (prt i)

instance Print a => Print [a] where
  prt = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)



instance Print Id where
  prt _ (Id i) = doc (showString ( i))



instance Print Program where
  prt i e = case e of
    Program prelude lines -> prPrec i 0 (concatD [prt 0 prelude, prt 0 lines])

instance Print Prelude where
  prt i e = case e of
    Prelude id -> prPrec i 0 (concatD [doc (showString "#NAME"), prt 0 id, doc (showString ".")])

instance Print Line where
  prt i e = case e of
    Decl head term -> prPrec i 0 (concatD [prt 0 head, doc (showString ":"), prt 0 term, doc (showString ".")])
    Def head term -> prPrec i 0 (concatD [prt 0 head, doc (showString ":="), prt 0 term, doc (showString ".")])
    DefWithType head term1 term2 -> prPrec i 0 (concatD [prt 0 head, doc (showString ":"), prt 0 term1, doc (showString ":="), prt 0 term2, doc (showString ".")])
    Rules rules -> prPrec i 0 (concatD [prt 0 rules, doc (showString ".")])
    Command command -> prPrec i 0 (concatD [prt 0 command])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print DefOpt where
  prt i e = case e of
    DefYes -> prPrec i 0 (concatD [doc (showString "def")])
    DefNo -> prPrec i 0 (concatD [])

instance Print Head where
  prt i e = case e of
    Head defopt id params -> prPrec i 0 (concatD [prt 0 defopt, prt 0 id, prt 0 params])
    OpaqueHead defopt id params -> prPrec i 0 (concatD [doc (showString "{"), prt 0 defopt, prt 0 id, prt 0 params, doc (showString "}")])

instance Print Param where
  prt i e = case e of
    Param id term -> prPrec i 0 (concatD [doc (showString "("), prt 0 id, doc (showString ":"), prt 0 term, doc (showString ")")])
  prtList _ [] = (concatD [])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print VarDecl where
  prt i e = case e of
    VarUntyped id -> prPrec i 0 (concatD [prt 0 id])
    VarTyped id term -> prPrec i 0 (concatD [prt 0 id, doc (showString ":"), prt 0 term])
  prtList _ [] = (concatD [])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, doc (showString ","), prt 0 xs])
instance Print Rule where
  prt i e = case e of
    Rule vardecls term1 term2 -> prPrec i 0 (concatD [doc (showString "["), prt 0 vardecls, doc (showString "]"), prt 0 term1, doc (showString "-->"), prt 0 term2])
  prtList _ [x] = (concatD [prt 0 x])
  prtList _ (x:xs) = (concatD [prt 0 x, prt 0 xs])
instance Print Term where
  prt i e = case e of
    Atom id -> prPrec i 2 (concatD [prt 0 id])
    Type -> prPrec i 2 (concatD [doc (showString "Type")])
    App term1 term2 -> prPrec i 1 (concatD [prt 1 term1, prt 2 term2])
    Pi id term1 term2 -> prPrec i 0 (concatD [prt 0 id, doc (showString ":"), prt 1 term1, doc (showString "->"), prt 0 term2])
    Fun term1 term2 -> prPrec i 0 (concatD [prt 1 term1, doc (showString "->"), prt 0 term2])
    LamTyped id term1 term2 -> prPrec i 0 (concatD [prt 0 id, doc (showString ":"), prt 1 term1, doc (showString "=>"), prt 0 term2])
    LamUntyped id term -> prPrec i 0 (concatD [prt 0 id, doc (showString "=>"), prt 0 term])

instance Print Command where
  prt i e = case e of
    CmdWhnf term -> prPrec i 0 (concatD [doc (showString "#WHNF"), prt 0 term, doc (showString ".")])
    CmdHnf term -> prPrec i 0 (concatD [doc (showString "#HNF"), prt 0 term, doc (showString ".")])
    CmdSnf term -> prPrec i 0 (concatD [doc (showString "#SNF"), prt 0 term, doc (showString ".")])
    CmdStep term -> prPrec i 0 (concatD [doc (showString "#STEP"), prt 0 term, doc (showString ".")])
    CmdConv term1 term2 -> prPrec i 0 (concatD [doc (showString "#CONV"), prt 0 term1, doc (showString ","), prt 0 term2, doc (showString ".")])
    CmdCheck term1 term2 -> prPrec i 0 (concatD [doc (showString "#CHECK"), prt 0 term1, prt 0 term2, doc (showString ".")])
    CmdInfer term -> prPrec i 0 (concatD [doc (showString "#INFER"), prt 0 term, doc (showString ".")])